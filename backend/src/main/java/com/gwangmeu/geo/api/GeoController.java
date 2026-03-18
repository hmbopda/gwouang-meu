package com.gwangmeu.geo.api;

import com.gwangmeu.geo.application.GeoService;
import com.gwangmeu.geo.dto.*;
import com.gwangmeu.shared.api.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/geo")
@RequiredArgsConstructor
@Validated
@Tag(name = "Geo", description = "Hierarchie geographique africaine : Continent > Pays > Village")
public class GeoController {

    private final GeoService geoService;

    // ── 1. Continents ────────────────────────────────────────────────────────

    @GetMapping("/continents")
    @Operation(
            summary = "Liste des continents/sous-regions",
            description = "Retourne tous les continents avec leur nombre de pays et villages. Acces public."
    )
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Liste retournee")
    })
    public ResponseEntity<ApiResponse<List<ContinentDto>>> getContinents() {
        return ResponseEntity.ok(ApiResponse.ok(geoService.getAllContinents()));
    }

    @GetMapping("/continents/{code}")
    @Operation(
            summary = "Detail d'un continent",
            description = "Retourne un continent par son code (ex: AF-CENTRAL, AF-WEST). Acces public."
    )
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Continent trouve"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Continent introuvable")
    })
    public ResponseEntity<ApiResponse<ContinentDto>> getContinent(
            @Parameter(description = "Code du continent", example = "AF-CENTRAL")
            @PathVariable String code) {
        return geoService.findContinentByCode(code)
                .map(dto -> ResponseEntity.ok(ApiResponse.ok(dto)))
                .orElse(ResponseEntity.notFound().build());
    }

    // ── 2. Countries ─────────────────────────────────────────────────────────

    @GetMapping("/countries")
    @Operation(
            summary = "Liste de tous les pays",
            description = "Retourne tous les pays enregistres avec emoji drapeau et nb de villages. Acces public."
    )
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Liste retournee")
    })
    public ResponseEntity<ApiResponse<List<CountryDto>>> getAllCountries() {
        return ResponseEntity.ok(ApiResponse.ok(geoService.getAllCountries()));
    }

    @GetMapping("/continents/{continentCode}/countries")
    @Operation(
            summary = "Pays d'un continent",
            description = "Retourne tous les pays d'un continent avec emoji drapeau et nb de villages. Acces public."
    )
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Liste retournee")
    })
    public ResponseEntity<ApiResponse<List<CountryDto>>> getCountriesByContinent(
            @Parameter(description = "Code du continent", example = "AF-CENTRAL")
            @PathVariable String continentCode) {
        return ResponseEntity.ok(ApiResponse.ok(geoService.getCountriesByContinent(continentCode)));
    }

    @GetMapping("/countries/{isoCode}")
    @Operation(
            summary = "Detail d'un pays",
            description = "Retourne un pays par son code ISO alpha-3 (ex: CMR, SEN). Acces public."
    )
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Pays trouve"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Pays introuvable")
    })
    public ResponseEntity<ApiResponse<CountryDto>> getCountry(
            @Parameter(description = "Code ISO alpha-3", example = "CMR")
            @PathVariable String isoCode) {
        return geoService.findCountryByIsoCode(isoCode)
                .map(dto -> ResponseEntity.ok(ApiResponse.ok(dto)))
                .orElse(ResponseEntity.notFound().build());
    }

    // ── Languages ───────────────────────────────────────────────────────────────

    @GetMapping("/countries/{isoCode}/languages")
    @Operation(
            summary = "Langues d'un pays",
            description = "Retourne les langues parlees dans un pays (par code ISO alpha-3). Officielles en premier. Acces public."
    )
    public ResponseEntity<ApiResponse<List<LanguageDto>>> getLanguagesByCountry(
            @Parameter(description = "Code ISO alpha-3 du pays", example = "CMR")
            @PathVariable String isoCode) {
        return ResponseEntity.ok(ApiResponse.ok(geoService.getLanguagesByCountry(isoCode)));
    }

    // ── 3. Nearby Villages (PostGIS) ──────────────────────────────────────────

    @GetMapping("/villages/nearby")
    @Operation(
            summary = "Villages proches (GPS)",
            description = """
                    Retourne les villages dans un rayon donne autour d'un point GPS.
                    Utilise PostGIS ST_DWithin sur la geographie WGS84.
                    Rayon max : 500 km. Resultats max : 50. Acces public.
                    """
    )
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Villages proches retournes"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "Coordonnees invalides")
    })
    public ResponseEntity<ApiResponse<List<NearbyVillageDto>>> getNearbyVillages(
            @Parameter(description = "Latitude (-90 a 90)", example = "3.848")
            @RequestParam @DecimalMin("-90.0") @DecimalMax("90.0") double lat,

            @Parameter(description = "Longitude (-180 a 180)", example = "11.502")
            @RequestParam @DecimalMin("-180.0") @DecimalMax("180.0") double lng,

            @Parameter(description = "Rayon en kilometres (1 a 500)", example = "50")
            @RequestParam(defaultValue = "50") @Min(1) @Max(500) double radiusKm,

            @Parameter(description = "Nombre max de resultats (1 a 50)", example = "20")
            @RequestParam(defaultValue = "20") @Min(1) @Max(50) int limit) {

        List<NearbyVillageDto> results = geoService.findNearbyVillages(lat, lng, radiusKm, limit);
        return ResponseEntity.ok(ApiResponse.ok(results));
    }

    // ── 4. Cultural Links ─────────────────────────────────────────────────────

    @GetMapping("/villages/{villageId}/cultural-links")
    @Operation(
            summary = "Liens culturels d'un village",
            description = """
                    Retourne les connexions culturelles entre ce village et d'autres villages africains.
                    Filtre optionnel par type : dialect, cuisine, rites, history, migration, language.
                    Acces public.
                    """
    )
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Liens retournes")
    })
    public ResponseEntity<ApiResponse<List<CulturalLinkDto>>> getCulturalLinks(
            @Parameter(description = "ID du village") @PathVariable UUID villageId,
            @Parameter(description = "Filtrer par type de lien", example = "dialect")
            @RequestParam(required = false) String linkType) {

        return ResponseEntity.ok(ApiResponse.ok(geoService.getCulturalLinks(villageId, linkType)));
    }

    // ── 5. Global search ──────────────────────────────────────────────────────

    @GetMapping("/search")
    @Operation(
            summary = "Recherche geographique globale",
            description = """
                    Recherche multi-niveaux sur les continents, pays et villages.
                    Retourne jusqu'a 20 resultats combines. Acces public.
                    """
    )
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Resultats de recherche"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "Requete trop courte")
    })
    public ResponseEntity<ApiResponse<List<GeoSearchResultDto>>> globalSearch(
            @Parameter(description = "Terme de recherche (min 2 caracteres)", example = "Bafia")
            @RequestParam String q) {

        if (q == null || q.trim().length() < 2) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "La recherche doit contenir au moins 2 caracteres");
        }
        return ResponseEntity.ok(ApiResponse.ok(geoService.globalSearch(q)));
    }
}
