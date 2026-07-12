package com.gwangmeu.village.api;

import com.gwangmeu.shared.api.ApiResponse;
import com.gwangmeu.shared.security.CurrentUser;
import com.gwangmeu.user.UserRepository;
import com.gwangmeu.village.application.VillageHeritageService;
import com.gwangmeu.village.application.VillagePermissionService;
import com.gwangmeu.village.domain.VillageChief;
import com.gwangmeu.village.domain.VillageMilestone;
import com.gwangmeu.village.domain.VillagePermission;
import com.gwangmeu.village.dto.ChiefUpsertRequest;
import com.gwangmeu.village.dto.DynastyChiefDto;
import com.gwangmeu.village.dto.MilestoneUpsertRequest;
import com.gwangmeu.village.dto.VillageMilestoneDto;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.persistence.EntityNotFoundException;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Patrimoine d'un village : dynastie des chefs (chef actuel + anciens) et temps forts.
 *
 * <p>Lectures publiques (GET). Ecritures reservees a EDIT_VILLAGE : chef (createur),
 * delegue portant la permission, ou super-admin — via {@link VillagePermissionService}.</p>
 */
@RestController
@RequestMapping("/api/v1/villages/{villageId}")
@RequiredArgsConstructor
@Tag(name = "Patrimoine village", description = "Dynastie des chefs et temps forts d'un village")
public class VillageHeritageController {

    private final VillageHeritageService heritageService;
    private final VillagePermissionService villagePermissionService;
    private final UserRepository userRepository;

    private UUID resolveUserId(Jwt jwt) {
        return userRepository.findBySupabaseId(jwt.getSubject())
                .orElseThrow(() -> new EntityNotFoundException("Utilisateur introuvable"))
                .getId();
    }

    private void requireEdit(Jwt jwt, UUID villageId) {
        UUID userId = resolveUserId(jwt);
        villagePermissionService.requireCan(userId, villageId, VillagePermission.EDIT_VILLAGE);
    }

    // ── Dynastie des chefs ───────────────────────────────────────

    @GetMapping("/chiefs")
    @Operation(summary = "Dynastie du village",
            description = "Liste des chefs (chef actuel + anciens chefs). Acces public.")
    public ResponseEntity<ApiResponse<List<DynastyChiefDto>>> listChiefs(@PathVariable UUID villageId) {
        List<DynastyChiefDto> dtos = heritageService.listChiefs(villageId).stream()
                .map(VillageHeritageController::toDto).toList();
        return ResponseEntity.ok(ApiResponse.ok(dtos));
    }

    @PostMapping("/chiefs")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Ajouter un chef a la dynastie",
            description = "Requiert EDIT_VILLAGE (chef, delegue ou super-admin).")
    public ResponseEntity<ApiResponse<DynastyChiefDto>> addChief(
            @PathVariable UUID villageId,
            @Valid @RequestBody ChiefUpsertRequest req,
            @CurrentUser Jwt jwt) {
        requireEdit(jwt, villageId);
        VillageChief saved = heritageService.addChief(villageId, req);
        return ResponseEntity.ok(ApiResponse.ok(toDto(saved), "Chef ajoute"));
    }

    @PutMapping("/chiefs/{chiefId}")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Modifier un chef", description = "Requiert EDIT_VILLAGE.")
    public ResponseEntity<ApiResponse<DynastyChiefDto>> updateChief(
            @PathVariable UUID villageId,
            @PathVariable UUID chiefId,
            @Valid @RequestBody ChiefUpsertRequest req,
            @CurrentUser Jwt jwt) {
        requireEdit(jwt, villageId);
        VillageChief saved = heritageService.updateChief(villageId, chiefId, req);
        return ResponseEntity.ok(ApiResponse.ok(toDto(saved), "Chef mis a jour"));
    }

    @DeleteMapping("/chiefs/{chiefId}")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Supprimer un chef", description = "Requiert EDIT_VILLAGE.")
    public ResponseEntity<ApiResponse<Void>> deleteChief(
            @PathVariable UUID villageId,
            @PathVariable UUID chiefId,
            @CurrentUser Jwt jwt) {
        requireEdit(jwt, villageId);
        heritageService.deleteChief(villageId, chiefId);
        return ResponseEntity.ok(ApiResponse.noContent());
    }

    // ── Temps forts ──────────────────────────────────────────────

    @GetMapping("/milestones")
    @Operation(summary = "Temps forts du village",
            description = "Liste des jalons historiques du village. Acces public.")
    public ResponseEntity<ApiResponse<List<VillageMilestoneDto>>> listMilestones(@PathVariable UUID villageId) {
        List<VillageMilestoneDto> dtos = heritageService.listMilestones(villageId).stream()
                .map(VillageHeritageController::toDto).toList();
        return ResponseEntity.ok(ApiResponse.ok(dtos));
    }

    @PostMapping("/milestones")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Ajouter un temps fort", description = "Requiert EDIT_VILLAGE.")
    public ResponseEntity<ApiResponse<VillageMilestoneDto>> addMilestone(
            @PathVariable UUID villageId,
            @Valid @RequestBody MilestoneUpsertRequest req,
            @CurrentUser Jwt jwt) {
        requireEdit(jwt, villageId);
        VillageMilestone saved = heritageService.addMilestone(villageId, req);
        return ResponseEntity.ok(ApiResponse.ok(toDto(saved), "Temps fort ajoute"));
    }

    @PutMapping("/milestones/{milestoneId}")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Modifier un temps fort", description = "Requiert EDIT_VILLAGE.")
    public ResponseEntity<ApiResponse<VillageMilestoneDto>> updateMilestone(
            @PathVariable UUID villageId,
            @PathVariable UUID milestoneId,
            @Valid @RequestBody MilestoneUpsertRequest req,
            @CurrentUser Jwt jwt) {
        requireEdit(jwt, villageId);
        VillageMilestone saved = heritageService.updateMilestone(villageId, milestoneId, req);
        return ResponseEntity.ok(ApiResponse.ok(toDto(saved), "Temps fort mis a jour"));
    }

    @DeleteMapping("/milestones/{milestoneId}")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Supprimer un temps fort", description = "Requiert EDIT_VILLAGE.")
    public ResponseEntity<ApiResponse<Void>> deleteMilestone(
            @PathVariable UUID villageId,
            @PathVariable UUID milestoneId,
            @CurrentUser Jwt jwt) {
        requireEdit(jwt, villageId);
        heritageService.deleteMilestone(villageId, milestoneId);
        return ResponseEntity.ok(ApiResponse.noContent());
    }

    // ── Mapping entite → DTO ─────────────────────────────────────

    private static DynastyChiefDto toDto(VillageChief c) {
        return new DynastyChiefDto(
                c.getId(), c.getDisplayName(), c.getReignStart(), c.getReignEnd(),
                c.isCurrent(), c.getOrdinal(), c.getNote(), c.getAvatarUrl(), c.getUserId());
    }

    private static VillageMilestoneDto toDto(VillageMilestone m) {
        return new VillageMilestoneDto(
                m.getId(), m.getYear(), m.getDateLabel(), m.getTitle(), m.getDescription(), m.getOrdinal());
    }
}
