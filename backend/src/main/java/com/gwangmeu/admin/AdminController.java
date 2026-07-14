package com.gwangmeu.admin;

import com.gwangmeu.shared.api.ApiResponse;
import com.gwangmeu.shared.security.CurrentUser;
import com.gwangmeu.user.UserRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.persistence.EntityNotFoundException;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * Back-office plateforme — RÉSERVÉ AUX SUPER_ADMIN (gate au niveau de la classe).
 * Le rôle est lu depuis la base ({@code users.role}) par SecurityConfig.
 */
@RestController
@RequestMapping("/api/v1/admin")
@PreAuthorize("hasRole('SUPER_ADMIN')")
@RequiredArgsConstructor
@Tag(name = "Admin", description = "Back-office plateforme (super-admin uniquement)")
public class AdminController {

    private final AdminService adminService;
    private final UserRepository userRepository;

    private UUID resolveUserId(Jwt jwt) {
        return userRepository.findBySupabaseId(jwt.getSubject())
                .orElseThrow(() -> new EntityNotFoundException("Utilisateur introuvable"))
                .getId();
    }

    @GetMapping("/users")
    @Operation(summary = "Lister les utilisateurs (super-admin)")
    public ResponseEntity<ApiResponse<List<AdminUserDto>>> listUsers() {
        return ResponseEntity.ok(ApiResponse.ok(adminService.listUsers()));
    }

    @PatchMapping("/users/{id}/role")
    @Operation(summary = "Changer le rôle d'un utilisateur (super-admin)")
    public ResponseEntity<ApiResponse<AdminUserDto>> updateRole(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateRoleRequest req,
            @CurrentUser Jwt jwt) {
        AdminUserDto dto = adminService.updateRole(id, req.role(), resolveUserId(jwt));
        return ResponseEntity.ok(ApiResponse.ok(dto, "Rôle mis à jour"));
    }

    @PatchMapping("/users/{id}/status")
    @Operation(summary = "Activer / désactiver un compte (super-admin)")
    public ResponseEntity<ApiResponse<AdminUserDto>> updateStatus(
            @PathVariable UUID id,
            @RequestBody UpdateStatusRequest req,
            @CurrentUser Jwt jwt) {
        AdminUserDto dto = adminService.updateStatus(id, req.active(), resolveUserId(jwt));
        return ResponseEntity.ok(ApiResponse.ok(dto, "Statut mis à jour"));
    }
}
