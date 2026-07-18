package com.gwangmeu.village.api;

import com.gwangmeu.shared.api.ApiResponse;
import com.gwangmeu.village.application.GovernanceViewService;
import com.gwangmeu.village.dto.GovernanceViewDto;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

/**
 * Vue de gouvernance résolue d'un village (chef, notables par rang, thème piloté
 * par la config). Généralise l'ancien /chief : rend n'importe quelle topologie
 * (monocéphale, conseil acéphale, dyarchie…) sans culture codée en dur.
 */
@RestController
@RequestMapping("/api/v1/villages/{villageId}")
@RequiredArgsConstructor
@PreAuthorize("isAuthenticated()")
@Tag(name = "Village Governance View",
        description = "Vue de gouvernance résolue : sièges, titulaires, thème (data-driven)")
public class GovernanceViewController {

    private final GovernanceViewService governanceViewService;

    @GetMapping("/governance")
    @Operation(summary = "Vue de gouvernance résolue d'un village (data-driven)")
    public ResponseEntity<ApiResponse<GovernanceViewDto>> governance(@PathVariable UUID villageId) {
        return ResponseEntity.ok(ApiResponse.ok(governanceViewService.resolve(villageId)));
    }
}
