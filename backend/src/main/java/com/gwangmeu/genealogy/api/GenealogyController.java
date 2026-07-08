package com.gwangmeu.genealogy.api;

import com.gwangmeu.genealogy.application.GenealogyService;
import com.gwangmeu.genealogy.application.Neo4jSyncService;
import com.gwangmeu.genealogy.domain.enums.ParentRoleEnum;
import com.gwangmeu.genealogy.domain.enums.ParentTypeEnum;
import com.gwangmeu.genealogy.dto.*;
import com.gwangmeu.shared.api.ApiResponse;
import com.gwangmeu.shared.security.CurrentUser;
import com.gwangmeu.shared.security.UserIdResolver;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/v1/genealogy")
@RequiredArgsConstructor
public class GenealogyController {

    private final GenealogyService genealogyService;
    private final Neo4jSyncService neo4jSyncService;
    private final UserIdResolver userIdResolver;

    @GetMapping("/tree/{personId}")
    @Operation(summary = "Get full family tree for Flutter display")
    public ResponseEntity<ApiResponse<FamilyTreeDTO>> getFullTree(@PathVariable UUID personId) {
        return ResponseEntity.ok(ApiResponse.ok(genealogyService.getFullTree(personId)));
    }

    @PostMapping("/link/parent-child")
    @Operation(summary = "Link a parent to a child")
    public ResponseEntity<ApiResponse<ParentChildDTO>> linkParentChild(
            @Valid @RequestBody LinkParentChildRequest req,
            @CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        ParentTypeEnum type = req.getType() != null ? req.getType() : ParentTypeEnum.BIOLOGICAL;
        ParentChildDTO result = genealogyService.linkParentChild(
                req.getParentId(), req.getChildId(), req.getRole(), type, userId);
        return ResponseEntity.status(201).body(ApiResponse.created(result));
    }

    @DeleteMapping("/link/parent-child")
    @Operation(summary = "Unlink a parent from a child")
    public ResponseEntity<ApiResponse<Void>> unlinkParentChild(
            @RequestParam UUID parentId,
            @RequestParam UUID childId,
            @CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        genealogyService.unlinkParentChild(parentId, childId, userId);
        return ResponseEntity.ok(ApiResponse.noContent());
    }

    @GetMapping("/{personId}/parents")
    @Operation(summary = "Get parents of a person")
    public ResponseEntity<ApiResponse<List<PersonDTO>>> getParents(@PathVariable UUID personId) {
        return ResponseEntity.ok(ApiResponse.ok(genealogyService.getParents(personId)));
    }

    @GetMapping("/{personId}/children")
    @Operation(summary = "Get children of a person")
    public ResponseEntity<ApiResponse<List<PersonDTO>>> getChildren(@PathVariable UUID personId) {
        return ResponseEntity.ok(ApiResponse.ok(genealogyService.getChildren(personId)));
    }

    @GetMapping("/{personId}/siblings")
    @Operation(summary = "Get siblings of a person")
    public ResponseEntity<ApiResponse<List<PersonDTO>>> getSiblings(@PathVariable UUID personId) {
        return ResponseEntity.ok(ApiResponse.ok(genealogyService.getSiblings(personId)));
    }

    @GetMapping("/{personId}/grandparents")
    @Operation(summary = "Get grandparents of a person")
    public ResponseEntity<ApiResponse<List<PersonDTO>>> getGrandparents(@PathVariable UUID personId) {
        return ResponseEntity.ok(ApiResponse.ok(genealogyService.getGrandparents(personId)));
    }

    @GetMapping("/{personId}/cousins")
    @Operation(summary = "Get first cousins of a person")
    public ResponseEntity<ApiResponse<List<PersonDTO>>> getFirstCousins(@PathVariable UUID personId) {
        return ResponseEntity.ok(ApiResponse.ok(genealogyService.getFirstCousins(personId)));
    }

    @GetMapping("/{personId}/spouses")
    @Operation(summary = "Get active spouses of a person")
    public ResponseEntity<ApiResponse<List<UnionDTO>>> getActiveSpouses(@PathVariable UUID personId) {
        return ResponseEntity.ok(ApiResponse.ok(genealogyService.getActiveSpouses(personId)));
    }

    @GetMapping("/{personId}/ancestors")
    @Operation(summary = "Get ancestors up to N generations (uses Neo4j graph traversal)")
    public ResponseEntity<ApiResponse<List<PersonDTO>>> getAncestors(
            @PathVariable UUID personId,
            @RequestParam(defaultValue = "5") int depth) {
        return ResponseEntity.ok(ApiResponse.ok(genealogyService.getAncestors(personId, Math.min(depth, 20))));
    }

    @GetMapping("/{personId}/descendants")
    @Operation(summary = "Get descendants up to N generations (uses Neo4j graph traversal)")
    public ResponseEntity<ApiResponse<List<PersonDTO>>> getDescendants(
            @PathVariable UUID personId,
            @RequestParam(defaultValue = "5") int depth) {
        return ResponseEntity.ok(ApiResponse.ok(genealogyService.getDescendants(personId, Math.min(depth, 20))));
    }

    // ── REFERENTIEL PAYS (regles de mariage) ─────────

    @GetMapping("/marriage-rules/{iso2}")
    @Operation(summary = "Get marriage/polygamy rule for a country (public read). Absent country -> UNKNOWN.")
    public ResponseEntity<ApiResponse<CountryMarriageRuleDTO>> getMarriageRule(@PathVariable String iso2) {
        return ResponseEntity.ok(ApiResponse.ok(genealogyService.getMarriageRule(iso2)));
    }

    // ── CHILD ASSOCIATION REQUESTS ─────────────────

    @PostMapping("/child-associations/{requestId}/accept")
    @Operation(summary = "Accept a child association request (co-parent validates filiation)")
    public ResponseEntity<ApiResponse<Void>> acceptChildAssociation(
            @PathVariable UUID requestId,
            @CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        genealogyService.acceptChildAssociation(requestId, userId);
        return ResponseEntity.ok(ApiResponse.noContent());
    }

    @PostMapping("/child-associations/{requestId}/reject")
    @Operation(summary = "Reject a child association request")
    public ResponseEntity<ApiResponse<Void>> rejectChildAssociation(
            @PathVariable UUID requestId,
            @CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        genealogyService.rejectChildAssociation(requestId, userId);
        return ResponseEntity.ok(ApiResponse.noContent());
    }

    // ── PERSON MODIFICATION REQUESTS (enfant < 4 ans) ─────

    @PostMapping("/persons/{personId}/modification-request")
    @Operation(summary = "Request modification of a child's info (child must be < 4 years old)")
    public ResponseEntity<ApiResponse<Void>> requestChildModification(
            @PathVariable UUID personId,
            @RequestBody java.util.Map<String, Object> changes,
            @CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        genealogyService.requestChildModification(personId, changes, userId);
        return ResponseEntity.status(201).body(ApiResponse.noContent());
    }

    @PostMapping("/modification-requests/{requestId}/accept")
    @Operation(summary = "Accept a child modification request (co-parent validates)")
    public ResponseEntity<ApiResponse<Void>> acceptModificationRequest(
            @PathVariable UUID requestId,
            @CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        genealogyService.acceptModificationRequest(requestId, userId);
        return ResponseEntity.ok(ApiResponse.noContent());
    }

    @PostMapping("/modification-requests/{requestId}/reject")
    @Operation(summary = "Reject a child modification request")
    public ResponseEntity<ApiResponse<Void>> rejectModificationRequest(
            @PathVariable UUID requestId,
            @CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        genealogyService.rejectModificationRequest(requestId, userId);
        return ResponseEntity.ok(ApiResponse.noContent());
    }

    @PostMapping("/admin/neo4j/sync-all")
    @Operation(summary = "Re-synchronise toutes les donnees PostgreSQL vers Neo4j")
    public ResponseEntity<ApiResponse<String>> syncAllToNeo4j() {
        String result = neo4jSyncService.fullSyncAll();
        return ResponseEntity.ok(ApiResponse.ok(result));
    }
}
