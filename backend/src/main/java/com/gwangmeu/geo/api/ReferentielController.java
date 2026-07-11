package com.gwangmeu.geo.api;

import com.gwangmeu.geo.application.ReferentielService;
import com.gwangmeu.geo.dto.ArrondissementDto;
import com.gwangmeu.geo.dto.ChefferieDto;
import com.gwangmeu.geo.dto.DepartmentDto;
import com.gwangmeu.geo.dto.RegionDto;
import com.gwangmeu.shared.api.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * API publique read-only du referentiel territorial camerounais (country_iso2='CM').
 * Regions > departements > arrondissements + chefferies traditionnelles.
 * Toutes les routes /api/v1/geo/** sont permitAll en GET (SecurityConfig).
 */
@RestController
@RequestMapping("/api/v1/geo/cm")
@RequiredArgsConstructor
@Validated
@Tag(name = "Referentiel CM", description = "Referentiel territorial camerounais : regions, departements, arrondissements, chefferies")
public class ReferentielController {

    private final ReferentielService referentielService;

    @GetMapping("/regions")
    @Operation(summary = "Liste des regions", description = "Regions du Cameroun triees par nom. Acces public.")
    public ResponseEntity<ApiResponse<List<RegionDto>>> getRegions() {
        return ResponseEntity.ok(ApiResponse.ok(referentielService.getRegions()));
    }

    @GetMapping("/departments")
    @Operation(summary = "Departements d'une region", description = "Departements filtres par code region, tries par nom. Acces public.")
    public ResponseEntity<ApiResponse<List<DepartmentDto>>> getDepartments(
            @Parameter(description = "Code de la region", example = "OU")
            @RequestParam("region") String region) {
        return ResponseEntity.ok(ApiResponse.ok(referentielService.getDepartmentsByRegion(region)));
    }

    @GetMapping("/arrondissements")
    @Operation(summary = "Arrondissements d'un departement", description = "Arrondissements filtres par code departement, tries par nom. Acces public.")
    public ResponseEntity<ApiResponse<List<ArrondissementDto>>> getArrondissements(
            @Parameter(description = "Code du departement")
            @RequestParam("department") String department) {
        return ResponseEntity.ok(ApiResponse.ok(referentielService.getArrondissementsByDepartment(department)));
    }

    @GetMapping("/chefferies")
    @Operation(summary = "Chefferies d'un departement", description = "Chefferies d'un departement, filtre optionnel par denomination (q), triees par numero. Acces public.")
    public ResponseEntity<ApiResponse<List<ChefferieDto>>> getChefferies(
            @Parameter(description = "Code du departement")
            @RequestParam("department") String department,
            @Parameter(description = "Filtre texte optionnel sur la denomination", example = "Bandjoun")
            @RequestParam(value = "q", required = false) String q,
            @Parameter(description = "Nombre max de resultats (1 a 200)", example = "50")
            @RequestParam(value = "limit", defaultValue = "50") @Min(1) @Max(200) int limit) {
        return ResponseEntity.ok(ApiResponse.ok(
                referentielService.getChefferiesByDepartment(department, q, limit)));
    }

    @GetMapping("/chefferies/search")
    @Operation(summary = "Recherche large de chefferies", description = "Chefferies d'une region (region_name) filtrees par denomination (q), triees par numero. Acces public.")
    public ResponseEntity<ApiResponse<List<ChefferieDto>>> searchChefferies(
            @Parameter(description = "Nom de la region", example = "Ouest")
            @RequestParam("region") String region,
            @Parameter(description = "Terme de recherche sur la denomination")
            @RequestParam(value = "q", required = false) String q,
            @Parameter(description = "Nombre max de resultats (1 a 200)", example = "50")
            @RequestParam(value = "limit", defaultValue = "50") @Min(1) @Max(200) int limit) {
        return ResponseEntity.ok(ApiResponse.ok(
                referentielService.searchChefferiesByRegion(region, q, limit)));
    }

    @GetMapping("/chefferies/lookup")
    @Operation(summary = "Recherche globale et floue de chefferies",
            description = "Recherche une chefferie par nom sur TOUT le referentiel (sans deroulement de la cascade), " +
                    "accent-insensible et tolerante aux fautes de frappe (« Bandenkop » comme « Badenkop »). Acces public.")
    public ResponseEntity<ApiResponse<List<ChefferieDto>>> lookupChefferies(
            @Parameter(description = "Terme de recherche (min. 2 caracteres)", example = "Bandenkop")
            @RequestParam("q") String q,
            @Parameter(description = "Nombre max de resultats (1 a 200)", example = "30")
            @RequestParam(value = "limit", defaultValue = "30") @Min(1) @Max(200) int limit) {
        return ResponseEntity.ok(ApiResponse.ok(
                referentielService.searchChefferiesGlobal(q, limit)));
    }
}
