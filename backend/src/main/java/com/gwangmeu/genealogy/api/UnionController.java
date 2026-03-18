package com.gwangmeu.genealogy.api;

import com.gwangmeu.genealogy.application.GenealogyService;
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
@RequestMapping("/api/v1/unions")
@RequiredArgsConstructor
public class UnionController {

    private final GenealogyService genealogyService;
    private final UserIdResolver userIdResolver;

    @PostMapping
    @Operation(summary = "Create a new union (marriage/dot)")
    public ResponseEntity<ApiResponse<UnionDTO>> createUnion(
            @Valid @RequestBody CreateUnionRequest req,
            @CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        UnionDTO union = genealogyService.createUnion(req, userId);
        return ResponseEntity.status(201).body(ApiResponse.created(union));
    }

    @PostMapping("/{id}/confirm")
    @Operation(summary = "Confirm a pending union (by the spouse)")
    public ResponseEntity<ApiResponse<UnionDTO>> confirmUnion(
            @PathVariable UUID id,
            @CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        UnionDTO union = genealogyService.confirmUnion(id, userId);
        return ResponseEntity.ok(ApiResponse.ok(union));
    }

    @PostMapping("/{id}/contest")
    @Operation(summary = "Contest/reject a pending union")
    public ResponseEntity<ApiResponse<UnionDTO>> contestUnion(
            @PathVariable UUID id,
            @RequestBody(required = false) ContestRequest req,
            @CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        String reason = req != null ? req.reason() : null;
        UnionDTO union = genealogyService.contestUnion(id, userId, reason);
        return ResponseEntity.ok(ApiResponse.ok(union));
    }

    record ContestRequest(String reason) {}

    @PutMapping("/{id}/dot")
    @Operation(summary = "Update dot (bride price) status")
    public ResponseEntity<ApiResponse<UnionDTO>> updateDotStatus(
            @PathVariable UUID id,
            @RequestBody UpdateDotRequest req,
            @CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        return ResponseEntity.ok(ApiResponse.ok(genealogyService.updateDotStatus(id, req, userId)));
    }

    @PutMapping("/{id}/end")
    @Operation(summary = "End a union (divorce, death, etc.)")
    public ResponseEntity<ApiResponse<Void>> endUnion(
            @PathVariable UUID id,
            @Valid @RequestBody EndUnionRequest req,
            @CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        genealogyService.endUnion(id, req, userId);
        return ResponseEntity.ok(ApiResponse.noContent());
    }

    @GetMapping("/person/{personId}")
    @Operation(summary = "Get all unions for a person")
    public ResponseEntity<ApiResponse<List<UnionDTO>>> getUnionsByPerson(@PathVariable UUID personId) {
        return ResponseEntity.ok(ApiResponse.ok(genealogyService.getUnionsByPerson(personId)));
    }
}
