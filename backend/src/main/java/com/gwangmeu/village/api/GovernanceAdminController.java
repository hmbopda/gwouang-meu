package com.gwangmeu.village.api;

import com.gwangmeu.shared.api.ApiResponse;
import com.gwangmeu.shared.security.CurrentUser;
import com.gwangmeu.shared.security.UserIdResolver;
import com.gwangmeu.village.application.GovernanceAdminService;
import com.gwangmeu.village.dto.NotableDto;
import com.gwangmeu.village.dto.NotableUpsertRequest;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

/**
 * Gestion des NOTABLES d'un village (EDIT_VILLAGE). Le chef (apex) se gère via
 * la dynastie (/chiefs). Complète {@link GovernanceViewController} (lecture).
 */
@RestController
@RequestMapping("/api/v1/villages/{villageId}/governance")
@RequiredArgsConstructor
@PreAuthorize("isAuthenticated()")
@Tag(name = "Village Governance Admin", description = "Gestion des notables (EDIT_VILLAGE)")
public class GovernanceAdminController {

    private final GovernanceAdminService adminService;
    private final UserIdResolver userIdResolver;

    @PostMapping("/notables")
    @Operation(summary = "Ajouter un notable (EDIT_VILLAGE)")
    public ResponseEntity<ApiResponse<NotableDto>> addNotable(
            @PathVariable UUID villageId,
            @Valid @RequestBody NotableUpsertRequest req,
            @CurrentUser Jwt jwt) {
        NotableDto dto = adminService.addNotable(villageId, userIdResolver.resolve(jwt), req);
        return ResponseEntity.ok(ApiResponse.ok(dto, "Notable ajouté"));
    }

    @PutMapping("/notables/{officeId}")
    @Operation(summary = "Modifier un notable (EDIT_VILLAGE)")
    public ResponseEntity<ApiResponse<NotableDto>> updateNotable(
            @PathVariable UUID villageId,
            @PathVariable UUID officeId,
            @Valid @RequestBody NotableUpsertRequest req,
            @CurrentUser Jwt jwt) {
        NotableDto dto = adminService.updateNotable(
                villageId, userIdResolver.resolve(jwt), officeId, req);
        return ResponseEntity.ok(ApiResponse.ok(dto, "Notable mis à jour"));
    }

    @DeleteMapping("/notables/{officeId}")
    @Operation(summary = "Supprimer un notable (EDIT_VILLAGE)")
    public ResponseEntity<ApiResponse<Void>> deleteNotable(
            @PathVariable UUID villageId,
            @PathVariable UUID officeId,
            @CurrentUser Jwt jwt) {
        adminService.deleteNotable(villageId, userIdResolver.resolve(jwt), officeId);
        return ResponseEntity.ok(ApiResponse.noContent());
    }
}
