package com.gwangmeu.genealogy.api;

import com.gwangmeu.genealogy.application.DissolutionService;
import com.gwangmeu.genealogy.domain.GenealogyUnion;
import com.gwangmeu.genealogy.infrastructure.PersonRepository;
import com.gwangmeu.shared.api.ApiResponse;
import com.gwangmeu.shared.security.CurrentUser;
import com.gwangmeu.shared.security.UserIdResolver;
import io.swagger.v3.oas.annotations.Operation;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/dissolutions")
@RequiredArgsConstructor
public class DissolutionController {

    private final DissolutionService dissolutionService;
    private final UserIdResolver userIdResolver;
    private final PersonRepository personRepository;

    // ── DIVORCE ─────────────────────────────────────────────

    @PostMapping("/unions/{unionId}/divorce")
    @Operation(summary = "Demander le divorce pour une union")
    public ResponseEntity<ApiResponse<Map<String, String>>> requestDivorce(
            @PathVariable UUID unionId,
            @RequestBody DissolutionRequest req,
            @CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        // On a besoin du personId du demandeur, pas du userId
        UUID personId = resolvePersonId(userId);

        GenealogyUnion union = dissolutionService.requestDivorce(unionId, personId, req.docUrl());
        return ResponseEntity.ok(ApiResponse.ok(Map.of(
                "unionId", union.getId().toString(),
                "status", union.getStatus()
        )));
    }

    @PostMapping("/unions/{unionId}/divorce/confirm")
    @Operation(summary = "Confirmer le divorce (par le conjoint)")
    public ResponseEntity<ApiResponse<Map<String, String>>> confirmDivorce(
            @PathVariable UUID unionId,
            @CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        UUID personId = resolvePersonId(userId);

        GenealogyUnion union = dissolutionService.confirmDivorce(unionId, personId);
        return ResponseEntity.ok(ApiResponse.ok(Map.of(
                "unionId", union.getId().toString(),
                "status", union.getStatus()
        )));
    }

    @PostMapping("/unions/{unionId}/divorce/contest")
    @Operation(summary = "Contester le divorce")
    public ResponseEntity<ApiResponse<Map<String, String>>> contestDivorce(
            @PathVariable UUID unionId,
            @RequestBody ContestRequest req,
            @CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        UUID personId = resolvePersonId(userId);

        GenealogyUnion union = dissolutionService.contestDivorce(unionId, personId, req.reason());
        return ResponseEntity.ok(ApiResponse.ok(Map.of(
                "unionId", union.getId().toString(),
                "status", union.getStatus()
        )));
    }

    // ── DECES ───────────────────────────────────────────────

    @PostMapping("/unions/{unionId}/death")
    @Operation(summary = "Declarer le deces du conjoint")
    public ResponseEntity<ApiResponse<Map<String, String>>> declareDeath(
            @PathVariable UUID unionId,
            @RequestBody DissolutionRequest req,
            @CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        UUID personId = resolvePersonId(userId);

        GenealogyUnion union = dissolutionService.declareDeath(unionId, personId, req.docUrl());
        return ResponseEntity.ok(ApiResponse.ok(Map.of(
                "unionId", union.getId().toString(),
                "status", union.getStatus()
        )));
    }

    @PostMapping("/unions/{unionId}/death/contest")
    @Operation(summary = "Contester la declaration de deces")
    public ResponseEntity<ApiResponse<Map<String, String>>> contestDeath(
            @PathVariable UUID unionId,
            @RequestBody ContestRequest req,
            @CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        UUID personId = resolvePersonId(userId);

        GenealogyUnion union = dissolutionService.contestDeath(unionId, personId, req.reason());
        return ResponseEntity.ok(ApiResponse.ok(Map.of(
                "unionId", union.getId().toString(),
                "status", union.getStatus()
        )));
    }

    // ── ADMIN ───────────────────────────────────────────────

    @PostMapping("/unions/{unionId}/death/admin-validate")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('MODERATEUR')")
    @Operation(summary = "Validation admin du deces (jamais auto-valide)")
    public ResponseEntity<ApiResponse<Map<String, String>>> adminValidateDeath(
            @PathVariable UUID unionId,
            @RequestParam boolean approved) {
        GenealogyUnion union = dissolutionService.adminValidateDeath(unionId, approved);
        return ResponseEntity.ok(ApiResponse.ok(Map.of(
                "unionId", union.getId().toString(),
                "status", union.getStatus()
        )));
    }

    @PostMapping("/unions/{unionId}/divorce/admin-resolve")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('MODERATEUR')")
    @Operation(summary = "Resolution admin d'un litige divorce")
    public ResponseEntity<ApiResponse<Map<String, String>>> adminResolveDivorceDispute(
            @PathVariable UUID unionId,
            @RequestParam boolean approved) {
        GenealogyUnion union = dissolutionService.adminResolveDivorceDispute(unionId, approved);
        return ResponseEntity.ok(ApiResponse.ok(Map.of(
                "unionId", union.getId().toString(),
                "status", union.getStatus()
        )));
    }

    // ── HELPERS ─────────────────────────────────────────────

    private UUID resolvePersonId(UUID userId) {
        return personRepository.findByUserId(userId)
                .orElseThrow(() -> new IllegalStateException(
                        "Aucune personne liee a ce compte utilisateur"))
                .getId();
    }

    // ── DTOs ────────────────────────────────────────────────

    public record DissolutionRequest(String docUrl) {}
    public record ContestRequest(String reason) {}
}
