package com.gwangmeu.village.api;

import com.gwangmeu.shared.api.ApiResponse;
import com.gwangmeu.shared.security.CurrentUser;
import com.gwangmeu.shared.security.UserIdResolver;
import com.gwangmeu.village.application.VillageJoinService;
import com.gwangmeu.village.application.VillagePermissionService;
import com.gwangmeu.village.application.VillageRoleService;
import com.gwangmeu.village.application.VillageValidationService;
import com.gwangmeu.village.domain.VillageJoinRequest;
import com.gwangmeu.village.domain.VillagePermission;
import com.gwangmeu.village.domain.VillageValidation;
import com.gwangmeu.village.domain.VillageValidationKind;
import com.gwangmeu.village.domain.VillageValidationStatus;
import com.gwangmeu.village.dto.DecideValidationRequest;
import com.gwangmeu.village.dto.GrantRoleRequest;
import com.gwangmeu.village.dto.JoinRequestDto;
import com.gwangmeu.village.dto.JoinResultDto;
import com.gwangmeu.village.dto.MyPermissionsDto;
import com.gwangmeu.village.dto.SubmitValidationRequest;
import com.gwangmeu.village.dto.ValidationDto;
import com.gwangmeu.village.dto.VillageRoleDto;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.EnumSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * Gouvernance de village : roles delegues, adhesions (avec regle AUTO par la genealogie)
 * et validations culturelles/successorales.
 *
 * Tous les endpoints exigent une authentification ; les controles fins de permission
 * sont delegues a {@link VillagePermissionService} et aux services metier.
 */
@RestController
@RequestMapping("/api/v1/villages/{villageId}")
@RequiredArgsConstructor
@PreAuthorize("isAuthenticated()")
@Tag(name = "Village Governance",
        description = "Roles delegues, adhesions (auto/manuelles), validations culturelles et successorales")
public class VillageGovernanceController {

    private final VillageRoleService roleService;
    private final VillageJoinService joinService;
    private final VillageValidationService validationService;
    private final VillagePermissionService permissionService;
    private final UserIdResolver userIdResolver;

    // =====================================================================
    // ROLES DELEGUES
    // =====================================================================

    @GetMapping("/roles")
    @Operation(summary = "Lister les roles delegues d'un village")
    public ResponseEntity<ApiResponse<List<VillageRoleDto>>> listRoles(@PathVariable UUID villageId) {
        List<VillageRoleDto> dtos = roleService.listRoles(villageId)
                .stream().map(VillageRoleDto::from).toList();
        return ResponseEntity.ok(ApiResponse.ok(dtos));
    }

    @PostMapping("/roles")
    @Operation(summary = "Attribuer un role delegue (MANAGE_ROLES requis)")
    public ResponseEntity<ApiResponse<VillageRoleDto>> grantRole(
            @PathVariable UUID villageId,
            @Valid @RequestBody GrantRoleRequest request,
            @CurrentUser Jwt jwt) {
        UUID grantedBy = userIdResolver.resolve(jwt);
        Set<VillagePermission> perms = request.permissions() == null || request.permissions().isEmpty()
                ? EnumSet.noneOf(VillagePermission.class)
                : EnumSet.copyOf(request.permissions());
        VillageRoleDto dto = VillageRoleDto.from(
                roleService.grantRole(villageId, request.userId(), request.title(), perms, grantedBy));
        return ResponseEntity.ok(ApiResponse.ok(dto, "Role delegue enregistre"));
    }

    @DeleteMapping("/roles/{userId}")
    @Operation(summary = "Revoquer un role delegue (MANAGE_ROLES requis)")
    public ResponseEntity<ApiResponse<Void>> revokeRole(
            @PathVariable UUID villageId,
            @PathVariable UUID userId,
            @CurrentUser Jwt jwt) {
        UUID requestedBy = userIdResolver.resolve(jwt);
        roleService.revokeRole(villageId, userId, requestedBy);
        return ResponseEntity.ok(ApiResponse.ok(null, "Role delegue revoque"));
    }

    // =====================================================================
    // ADHESION
    // =====================================================================

    @PostMapping("/membership")
    @Operation(summary = "Demander l'adhesion (MEMBRE) — admission AUTO si un membre de la famille y appartient deja. "
            + "Distinct de POST /join qui gere le simple suivi (FOLLOW).")
    public ResponseEntity<ApiResponse<JoinResultDto>> join(
            @PathVariable UUID villageId,
            @CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        VillageJoinService.JoinResult r = joinService.requestJoin(villageId, userId);
        JoinResultDto dto = new JoinResultDto(r.status(), r.member(), r.autoReason());
        String message = r.member()
                ? "Adhesion validee"
                : "Demande d'adhesion enregistree, en attente de validation";
        return ResponseEntity.ok(ApiResponse.ok(dto, message));
    }

    @GetMapping("/join-requests")
    @Operation(summary = "Lister les demandes d'adhesion PENDING (VALIDATE_MEMBERS requis)")
    public ResponseEntity<ApiResponse<List<JoinRequestDto>>> listJoinRequests(
            @PathVariable UUID villageId,
            @RequestParam(defaultValue = "PENDING") String status,
            @CurrentUser Jwt jwt) {
        UUID requesterId = userIdResolver.resolve(jwt);
        // Seul PENDING est expose ici (workflow de validation). Les autres statuts sont ignores.
        List<VillageJoinRequest> requests = joinService.listPendingJoins(villageId, requesterId);
        List<JoinRequestDto> dtos = requests.stream().map(JoinRequestDto::from).toList();
        return ResponseEntity.ok(ApiResponse.ok(dtos));
    }

    @PostMapping("/join-requests/{id}/approve")
    @Operation(summary = "Approuver une demande d'adhesion (VALIDATE_MEMBERS requis)")
    public ResponseEntity<ApiResponse<JoinResultDto>> approveJoin(
            @PathVariable UUID villageId,
            @PathVariable("id") UUID requestId,
            @CurrentUser Jwt jwt) {
        UUID deciderId = userIdResolver.resolve(jwt);
        VillageJoinService.JoinResult r = joinService.approveJoin(villageId, requestId, deciderId);
        return ResponseEntity.ok(ApiResponse.ok(
                new JoinResultDto(r.status(), r.member(), r.autoReason()), "Adhesion approuvee"));
    }

    @PostMapping("/join-requests/{id}/reject")
    @Operation(summary = "Rejeter une demande d'adhesion (VALIDATE_MEMBERS requis)")
    public ResponseEntity<ApiResponse<JoinResultDto>> rejectJoin(
            @PathVariable UUID villageId,
            @PathVariable("id") UUID requestId,
            @CurrentUser Jwt jwt) {
        UUID deciderId = userIdResolver.resolve(jwt);
        VillageJoinService.JoinResult r = joinService.rejectJoin(villageId, requestId, deciderId);
        return ResponseEntity.ok(ApiResponse.ok(
                new JoinResultDto(r.status(), r.member(), r.autoReason()), "Adhesion rejetee"));
    }

    // =====================================================================
    // VALIDATIONS CULTURELLES / SUCCESSORALES
    // =====================================================================

    @GetMapping("/validations")
    @Operation(summary = "Lister les validations (VALIDATE_CULTURE ou VALIDATE_SUCCESSION selon kind)")
    public ResponseEntity<ApiResponse<List<ValidationDto>>> listValidations(
            @PathVariable UUID villageId,
            @RequestParam(required = false) VillageValidationKind kind,
            @RequestParam(required = false, defaultValue = "PENDING") VillageValidationStatus status,
            @CurrentUser Jwt jwt) {
        UUID requesterId = userIdResolver.resolve(jwt);
        List<VillageValidation> validations =
                validationService.listPending(villageId, kind, status, requesterId);
        List<ValidationDto> dtos = validations.stream().map(ValidationDto::from).toList();
        return ResponseEntity.ok(ApiResponse.ok(dtos));
    }

    @PostMapping("/validations")
    @Operation(summary = "Soumettre un element culturel/successoral a validation (tout membre)")
    public ResponseEntity<ApiResponse<ValidationDto>> submitValidation(
            @PathVariable UUID villageId,
            @Valid @RequestBody SubmitValidationRequest request,
            @CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        ValidationDto dto = ValidationDto.from(
                validationService.submit(villageId, request.kind(), request.title(), request.detail(), userId));
        return ResponseEntity.ok(ApiResponse.ok(dto, "Element soumis a validation"));
    }

    @PostMapping("/validations/{id}/decide")
    @Operation(summary = "Approuver/rejeter une validation (permission selon kind)")
    public ResponseEntity<ApiResponse<ValidationDto>> decideValidation(
            @PathVariable UUID villageId,
            @PathVariable("id") UUID validationId,
            @Valid @RequestBody DecideValidationRequest request,
            @CurrentUser Jwt jwt) {
        UUID deciderId = userIdResolver.resolve(jwt);
        ValidationDto dto = ValidationDto.from(
                validationService.decide(villageId, validationId, request.approve(), deciderId));
        return ResponseEntity.ok(ApiResponse.ok(dto, request.approve() ? "Validation approuvee" : "Validation rejetee"));
    }

    // =====================================================================
    // PERMISSIONS DE L'APPELANT (pour piloter l'IHM)
    // =====================================================================

    @GetMapping("/my-permissions")
    @Operation(summary = "Permissions de l'appelant sur ce village")
    public ResponseEntity<ApiResponse<MyPermissionsDto>> myPermissions(
            @PathVariable UUID villageId,
            @CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        boolean superAdmin = permissionService.isCurrentUserSuperAdmin();
        boolean chief = permissionService.isChief(userId, villageId);
        List<VillagePermission> perms = List.copyOf(
                permissionService.effectivePermissions(userId, villageId));
        MyPermissionsDto dto = new MyPermissionsDto(villageId, userId, chief, superAdmin, perms);
        return ResponseEntity.ok(ApiResponse.ok(dto));
    }
}
