package com.gwangmeu.village.api;

import com.gwangmeu.geo.domain.Language;
import com.gwangmeu.geo.infrastructure.LanguageRepository;
import com.gwangmeu.shared.api.ApiResponse;
import com.gwangmeu.shared.security.CurrentUser;
import com.gwangmeu.user.UserRepository;
import com.gwangmeu.village.application.LanguageService;
import com.gwangmeu.village.domain.VillageLanguage;
import com.gwangmeu.village.dto.LanguageDto;
import com.gwangmeu.village.dto.VillageLanguageDto;
import com.gwangmeu.village.dto.VillageLanguagesRequest;
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
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Referentiel des langues et langues d'un village.
 *
 * <p>Lectures publiques (GET). L'ecriture des langues d'un village (PUT) exige
 * EDIT_VILLAGE — verifie dans {@link LanguageService#setVillageLanguages} (chef,
 * delegue portant la permission ou super-admin).</p>
 */
@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
@Tag(name = "Langues", description = "Referentiel des langues et langues d'un village")
public class LanguageController {

    private final LanguageService languageService;
    private final LanguageRepository languageRepository;
    private final UserRepository userRepository;

    private UUID resolveUserId(Jwt jwt) {
        return userRepository.findBySupabaseId(jwt.getSubject())
                .orElseThrow(() -> new EntityNotFoundException("Utilisateur introuvable"))
                .getId();
    }

    // ── Referentiel des langues ──────────────────────────────────

    @GetMapping("/languages")
    @Operation(summary = "Referentiel des langues",
            description = "Liste des langues actives, triees par nom francais. Acces public.")
    public ResponseEntity<ApiResponse<List<LanguageDto>>> listLanguages() {
        List<LanguageDto> dtos = languageService.listActive().stream()
                .map(LanguageController::toDto).toList();
        return ResponseEntity.ok(ApiResponse.ok(dtos));
    }

    // ── Langues d'un village ─────────────────────────────────────

    @GetMapping("/villages/{villageId}/languages")
    @Operation(summary = "Langues d'un village",
            description = "Liste des langues du village (dont la langue principale). Acces public.")
    public ResponseEntity<ApiResponse<List<VillageLanguageDto>>> listVillageLanguages(
            @PathVariable UUID villageId) {
        List<VillageLanguageDto> dtos = toDtos(languageService.villageLanguages(villageId));
        return ResponseEntity.ok(ApiResponse.ok(dtos));
    }

    @PutMapping("/villages/{villageId}/languages")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Definir les langues d'un village",
            description = "Remplace la liste des langues. Requiert EDIT_VILLAGE.")
    public ResponseEntity<ApiResponse<List<VillageLanguageDto>>> setVillageLanguages(
            @PathVariable UUID villageId,
            @Valid @RequestBody VillageLanguagesRequest req,
            @CurrentUser Jwt jwt) {
        List<VillageLanguage> saved =
                languageService.setVillageLanguages(resolveUserId(jwt), villageId, req);
        return ResponseEntity.ok(ApiResponse.ok(toDtos(saved), "Langues mises a jour"));
    }

    // ── Mapping entite → DTO ─────────────────────────────────────

    private List<VillageLanguageDto> toDtos(List<VillageLanguage> links) {
        if (links.isEmpty()) {
            return List.of();
        }
        List<UUID> ids = links.stream().map(VillageLanguage::getLanguageId).distinct().toList();
        Map<UUID, Language> byId = languageRepository.findAllByIdIn(ids).stream()
                .collect(Collectors.toMap(Language::getId, l -> l));
        return links.stream()
                .filter(vl -> byId.containsKey(vl.getLanguageId()))
                .map(vl -> new VillageLanguageDto(toDto(byId.get(vl.getLanguageId())),
                        vl.isPrimary(), vl.getOrdinal()))
                .toList();
    }

    private static LanguageDto toDto(Language l) {
        return new LanguageDto(l.getId(), l.getCode(), l.getName(),
                l.getFrenchName(), l.getIso6393(), l.getRegion());
    }
}
