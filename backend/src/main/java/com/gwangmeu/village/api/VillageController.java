package com.gwangmeu.village.api;

import com.gwangmeu.shared.api.ApiResponse;
import com.gwangmeu.shared.security.CurrentUser;
import com.gwangmeu.user.UserRepository;
import com.gwangmeu.village.VillageMapper;
import com.gwangmeu.village.application.CreateVillageCommand;
import com.gwangmeu.village.application.UpdateVillageCommand;
import com.gwangmeu.village.application.VillageInvitationService;
import com.gwangmeu.village.application.VillageJoinService;
import com.gwangmeu.village.application.VillagePermissionService;
import com.gwangmeu.village.application.VillageService;
import com.gwangmeu.village.domain.Village;
import com.gwangmeu.village.domain.VillagePermission;
import com.gwangmeu.village.domain.VillageSubscription;
import com.gwangmeu.village.dto.ChiefDto;
import com.gwangmeu.village.dto.CreateVillageRequest;
import com.gwangmeu.village.dto.InviteToVillageRequest;
import com.gwangmeu.village.dto.UpdateVillageRequest;
import com.gwangmeu.village.dto.VillageDto;
import com.gwangmeu.village.dto.VillageInvitationDto;
import com.gwangmeu.village.dto.VillageMemberDto;
import com.gwangmeu.user.User;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.persistence.EntityNotFoundException;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.time.ZoneOffset;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/villages")
@RequiredArgsConstructor
@Tag(name = "Villages", description = "Gestion des villages GWANG MEU")
public class VillageController {

    private final VillageService villageService;
    private final VillageMapper villageMapper;
    private final UserRepository userRepository;
    private final VillagePermissionService villagePermissionService;
    private final VillageJoinService villageJoinService;
    private final VillageInvitationService villageInvitationService;

    private UUID resolveUserId(Jwt jwt) {
        return userRepository.findBySupabaseId(jwt.getSubject())
                .orElseThrow(() -> new EntityNotFoundException("Utilisateur introuvable"))
                .getId();
    }

    @GetMapping
    @Operation(
            summary = "Lister les villages",
            description = "Retourne les villages avec filtres optionnels par pays (countryCode ISO alpha-3) ou continent (continentCode). Acces public."
    )
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Liste retournee")
    })
    public ResponseEntity<ApiResponse<List<VillageDto>>> list(
            @RequestParam(required = false) String countryCode,
            @RequestParam(required = false) String continentCode) {
        List<VillageDto> dtos;
        if (countryCode != null && !countryCode.isBlank()) {
            dtos = villageService.findByCountry(countryCode.toUpperCase()).stream().map(villageMapper::toDto).toList();
        } else if (continentCode != null && !continentCode.isBlank()) {
            dtos = villageService.findByContinent(continentCode.toUpperCase()).stream().map(villageMapper::toDto).toList();
        } else {
            dtos = villageService.search("").stream().map(villageMapper::toDto).toList();
        }
        return ResponseEntity.ok(ApiResponse.ok(dtos));
    }

    @PostMapping
    @PreAuthorize("hasRole('MEMBRE') or hasRole('AMBASSADEUR') or hasRole('MODERATEUR') or hasRole('SUPER_ADMIN')")
    @Operation(summary = "Creer un village", description = "Cree un nouveau village. Requiert role AMBASSADEUR minimum.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "201", description = "Village cree"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "Validation echouee"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "Non authentifie"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", description = "Role insuffisant")
    })
    public ResponseEntity<ApiResponse<VillageDto>> create(
            @Valid @RequestBody CreateVillageRequest request,
            @CurrentUser Jwt jwt) {
        UUID creatorId = resolveUserId(jwt);
        CreateVillageCommand command = new CreateVillageCommand(
                request.name(), request.description(), request.country(),
                request.region(), request.continentCode(), request.latitude(),
                request.longitude(), request.primaryDialect(),
                creatorId
        );
        VillageDto dto = villageMapper.toDto(villageService.create(command));
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.created(dto));
    }

    @PostMapping("/from-chefferie")
    @PreAuthorize("hasRole('MEMBRE') or hasRole('AMBASSADEUR') or hasRole('MODERATEUR') or hasRole('SUPER_ADMIN')")
    @Operation(summary = "Fonder / rejoindre un village depuis une chefferie du referentiel",
            description = "Materialise la chefferie (referentiel) en communaute si elle n'existe pas encore, "
                    + "puis inscrit l'utilisateur comme membre. Idempotent.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Village fonde/rejoint"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "chefferieId manquant ou invalide"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "Non authentifie")
    })
    public ResponseEntity<ApiResponse<VillageDto>> foundFromChefferie(
            @CurrentUser Jwt jwt,
            @RequestBody Map<String, String> body) {
        UUID userId = resolveUserId(jwt);
        String raw = body.get("chefferieId");
        if (raw == null || raw.isBlank()) {
            throw new IllegalArgumentException("chefferieId requis");
        }
        Village village = villageService.foundFromChefferie(UUID.fromString(raw), userId);
        return ResponseEntity.ok(ApiResponse.ok(villageMapper.toDto(village), "Village rejoint"));
    }

    @GetMapping("/{villageId}")
    @Operation(summary = "Obtenir un village", description = "Retourne les informations publiques d'un village.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Village retourne"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Village introuvable")
    })
    public ResponseEntity<ApiResponse<VillageDto>> getById(@PathVariable UUID villageId) {
        Village village = villageService.findById(villageId)
                .orElseThrow(() -> new EntityNotFoundException("Village introuvable : " + villageId));
        return ResponseEntity.ok(ApiResponse.ok(villageMapper.toDto(village)));
    }

    @PutMapping("/{villageId}")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Mettre a jour un village",
            description = "Modifie les informations d'un village existant. Requiert la permission EDIT_VILLAGE "
                    + "(chef/createur, delegue portant EDIT_VILLAGE, ou super-admin).")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Village mis a jour"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", description = "Permission EDIT_VILLAGE requise"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Village introuvable")
    })
    public ResponseEntity<ApiResponse<VillageDto>> update(
            @PathVariable UUID villageId,
            @Valid @RequestBody UpdateVillageRequest request,
            @CurrentUser Jwt jwt) {
        UUID userId = resolveUserId(jwt);
        villagePermissionService.requireCan(userId, villageId, VillagePermission.EDIT_VILLAGE);
        UpdateVillageCommand command = new UpdateVillageCommand(
                request.description(), request.coverImageUrl(),
                request.foundedYear(), request.populationEstimate(),
                request.historicalSummary()
        );
        VillageDto dto = villageMapper.toDto(villageService.update(villageId, command));
        return ResponseEntity.ok(ApiResponse.ok(dto, "Village mis a jour"));
    }

    @GetMapping("/country/{country}")
    @Operation(summary = "Villages par pays", description = "Retourne tous les villages d'un pays (code ISO alpha-3).")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Liste retournee")
    })
    public ResponseEntity<ApiResponse<List<VillageDto>>> byCountry(@PathVariable String country) {
        List<VillageDto> dtos = villageService.findByCountry(country)
                .stream().map(villageMapper::toDto).toList();
        return ResponseEntity.ok(ApiResponse.ok(dtos));
    }

    @GetMapping("/search")
    @Operation(summary = "Rechercher des villages", description = "Recherche par nom (insensible a la casse).")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Resultats de recherche")
    })
    public ResponseEntity<ApiResponse<List<VillageDto>>> search(@RequestParam String q) {
        List<VillageDto> dtos = villageService.search(q)
                .stream().map(villageMapper::toDto).toList();
        return ResponseEntity.ok(ApiResponse.ok(dtos));
    }

    @GetMapping("/{villageId}/members")
    @Operation(summary = "Membres d'un village", description = "Retourne la liste des membres abonnes a un village.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Liste des membres")
    })
    public ResponseEntity<ApiResponse<List<VillageMemberDto>>> members(@PathVariable UUID villageId) {
        List<VillageSubscription> subs = villageService.getVillageMembers(villageId);
        List<UUID> userIds = subs.stream().map(VillageSubscription::getUserId).toList();
        Map<UUID, User> usersMap = userRepository.findAllById(userIds)
                .stream().collect(java.util.stream.Collectors.toMap(User::getId, u -> u));

        List<VillageMemberDto> members = subs.stream().map(sub -> {
            User u = usersMap.get(sub.getUserId());
            return new VillageMemberDto(
                    sub.getUserId(),
                    u != null ? u.getDisplayName() : "Inconnu",
                    u != null ? u.getAvatarUrl() : null,
                    sub.getType(),
                    sub.getCreatedAt()
            );
        }).toList();

        return ResponseEntity.ok(ApiResponse.ok(members));
    }

    @PostMapping("/{villageId}/join")
    @Operation(summary = "Rejoindre un village", description = "S'abonne au village avec le type specifie.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Abonnement cree"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "Non authentifie"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "409", description = "Deja abonne")
    })
    public ResponseEntity<ApiResponse<VillageSubscription>> join(
            @PathVariable UUID villageId,
            @CurrentUser Jwt jwt,
            @RequestParam(defaultValue = "FOLLOW") VillageSubscription.SubscriptionType type) {
        UUID userId = resolveUserId(jwt);
        VillageSubscription sub = villageService.join(userId, villageId, type);
        return ResponseEntity.ok(ApiResponse.ok(sub, "Abonnement au village enregistre"));
    }

    @DeleteMapping("/{villageId}/leave")
    @Operation(summary = "Quitter un village", description = "Se desabonne du village.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "204", description = "Desabonnement effectue"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "Non authentifie")
    })
    public ResponseEntity<ApiResponse<Void>> leave(
            @PathVariable UUID villageId,
            @CurrentUser Jwt jwt) {
        UUID userId = resolveUserId(jwt);
        villageService.leave(userId, villageId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/my-villages")
    @Operation(summary = "Mes villages", description = "Retourne les villages auxquels l'utilisateur est abonne.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Liste retournee"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "Non authentifie")
    })
    public ResponseEntity<ApiResponse<List<VillageDto>>> myVillages(@CurrentUser Jwt jwt) {
        UUID userId = resolveUserId(jwt);
        List<VillageDto> dtos = villageService.getVillagesForUser(userId)
                .stream().map(villageMapper::toDto).toList();
        return ResponseEntity.ok(ApiResponse.ok(dtos));
    }

    // =====================================================================
    // CHEF REEL (createur du village)
    // =====================================================================

    @GetMapping("/{villageId}/chief")
    @Operation(summary = "Chef du village",
            description = "Retourne le chef = utilisateur createur (creator_id) du village. "
                    + "204 No Content si le village n'a pas de createur renseigne.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Chef retourne"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "204", description = "Aucun createur renseigne"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Village introuvable")
    })
    public ResponseEntity<ApiResponse<ChiefDto>> chief(@PathVariable UUID villageId) {
        Village village = villageService.findById(villageId)
                .orElseThrow(() -> new EntityNotFoundException("Village introuvable : " + villageId));

        UUID creatorId = village.getCreatorId();
        if (creatorId == null) {
            return ResponseEntity.noContent().build();
        }

        User chief = userRepository.findById(creatorId).orElse(null);
        if (chief == null) {
            return ResponseEntity.noContent().build();
        }

        Integer since = village.getFoundedYear();
        if (since == null && village.getCreatedAt() != null) {
            since = village.getCreatedAt().atZone(ZoneOffset.UTC).getYear();
        }

        ChiefDto dto = new ChiefDto(
                chief.getId(), chief.getDisplayName(), chief.getAvatarUrl(), since, true);
        return ResponseEntity.ok(ApiResponse.ok(dto));
    }

    // =====================================================================
    // VILLAGES HERITES (droit d'adhesion par filiation)
    // =====================================================================

    @GetMapping("/eligible")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Villages herites eligibles",
            description = "Villages ou une personne de la famille 1er degre de l'appelant est rattachee "
                    + "(person_villages ou subscription MEMBER), et dont l'appelant n'est pas deja MEMBER.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Liste retournee"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "Non authentifie")
    })
    public ResponseEntity<ApiResponse<List<VillageDto>>> eligible(@CurrentUser Jwt jwt) {
        UUID userId = resolveUserId(jwt);
        Set<UUID> villageIds = villageJoinService.eligibleVillageIds(userId);
        if (villageIds.isEmpty()) {
            return ResponseEntity.ok(ApiResponse.ok(List.of()));
        }

        // Exclure les villages ou l'appelant est deja MEMBER.
        Set<UUID> alreadyMember = villageService.getMemberships(userId).stream()
                .filter(s -> s.getType() == VillageSubscription.SubscriptionType.MEMBER)
                .map(VillageSubscription::getVillageId)
                .collect(java.util.stream.Collectors.toSet());

        List<VillageDto> dtos = villageService.findAllById(villageIds).stream()
                .filter(v -> !alreadyMember.contains(v.getId()))
                .map(villageMapper::toDto)
                .toList();
        return ResponseEntity.ok(ApiResponse.ok(dtos));
    }

    // =====================================================================
    // INVITATIONS VILLAGE
    // =====================================================================

    @GetMapping("/invitations")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Mes invitations recues",
            description = "Invitations PENDING adressees a l'appelant, enrichies du nom du village et de l'inviteur.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Liste retournee"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "Non authentifie")
    })
    public ResponseEntity<ApiResponse<List<VillageInvitationDto>>> myInvitations(@CurrentUser Jwt jwt) {
        UUID userId = resolveUserId(jwt);
        return ResponseEntity.ok(ApiResponse.ok(villageInvitationService.myInvitations(userId)));
    }

    @PostMapping("/invitations/{id}/accept")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Accepter une invitation",
            description = "L'invite accepte : cree une adhesion MEMBER (idempotent) et passe l'invitation en ACCEPTED.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Invitation acceptee"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", description = "Invitation non destinee a l'appelant"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Invitation introuvable")
    })
    public ResponseEntity<ApiResponse<VillageInvitationDto>> acceptInvitation(
            @PathVariable("id") UUID invitationId,
            @CurrentUser Jwt jwt) {
        UUID userId = resolveUserId(jwt);
        VillageInvitationDto dto = villageInvitationService.accept(invitationId, userId);
        return ResponseEntity.ok(ApiResponse.ok(dto, "Invitation acceptee"));
    }

    @PostMapping("/invitations/{id}/decline")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Refuser une invitation",
            description = "L'invite refuse : passe l'invitation en DECLINED.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Invitation refusee"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", description = "Invitation non destinee a l'appelant"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Invitation introuvable")
    })
    public ResponseEntity<ApiResponse<VillageInvitationDto>> declineInvitation(
            @PathVariable("id") UUID invitationId,
            @CurrentUser Jwt jwt) {
        UUID userId = resolveUserId(jwt);
        VillageInvitationDto dto = villageInvitationService.decline(invitationId, userId);
        return ResponseEntity.ok(ApiResponse.ok(dto, "Invitation refusee"));
    }

    @PostMapping("/{villageId}/invite")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Inviter un utilisateur",
            description = "Invite un utilisateur a rejoindre le village. L'inviteur doit etre MEMBER du village.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Invitation enregistree"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", description = "L'inviteur n'est pas membre"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Village ou utilisateur introuvable"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "409", description = "Deja membre")
    })
    public ResponseEntity<ApiResponse<VillageInvitationDto>> invite(
            @PathVariable UUID villageId,
            @Valid @RequestBody InviteToVillageRequest request,
            @CurrentUser Jwt jwt) {
        UUID byUserId = resolveUserId(jwt);
        VillageInvitationDto dto = villageInvitationService.invite(
                villageId, request.invitedUserId(), byUserId, request.message());
        return ResponseEntity.ok(ApiResponse.ok(dto, "Invitation envoyee"));
    }
}
