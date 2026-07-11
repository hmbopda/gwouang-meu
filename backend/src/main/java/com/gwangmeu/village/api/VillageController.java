package com.gwangmeu.village.api;

import com.gwangmeu.shared.api.ApiResponse;
import com.gwangmeu.shared.security.CurrentUser;
import com.gwangmeu.user.UserRepository;
import com.gwangmeu.village.VillageMapper;
import com.gwangmeu.village.application.CreateVillageCommand;
import com.gwangmeu.village.application.UpdateVillageCommand;
import com.gwangmeu.village.application.VillagePermissionService;
import com.gwangmeu.village.application.VillageService;
import com.gwangmeu.village.domain.Village;
import com.gwangmeu.village.domain.VillagePermission;
import com.gwangmeu.village.domain.VillageSubscription;
import com.gwangmeu.village.dto.CreateVillageRequest;
import com.gwangmeu.village.dto.UpdateVillageRequest;
import com.gwangmeu.village.dto.VillageDto;
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

import java.util.List;
import java.util.Map;
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
}
