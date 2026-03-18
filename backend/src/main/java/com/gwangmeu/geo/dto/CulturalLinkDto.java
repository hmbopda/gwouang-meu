package com.gwangmeu.geo.dto;

import com.gwangmeu.geo.domain.CulturalLink;
import io.swagger.v3.oas.annotations.media.Schema;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * DTO pour un lien culturel entre deux villages.
 * Inclut le score de similarite et l'origine (humain ou AI).
 */
@Schema(description = "Lien culturel entre deux villages")
public record CulturalLinkDto(

        @Schema(description = "ID du lien") UUID id,
        @Schema(description = "ID du village A") UUID villageAId,
        @Schema(description = "ID du village B") UUID villageBId,
        @Schema(description = "Type de lien", example = "dialect",
                allowableValues = {"dialect", "cuisine", "rites", "history", "migration", "language"})
        String linkType,
        @Schema(description = "Score de similarite (0.00 a 1.00)", example = "0.85") BigDecimal similarityScore,
        @Schema(description = "Description du lien culturel") String description,
        @Schema(description = "true si detecte par Claude AI") boolean createdByAi
) {
    public static CulturalLinkDto from(CulturalLink link) {
        return new CulturalLinkDto(
                link.getId(),
                link.getVillageAId(),
                link.getVillageBId(),
                link.getLinkType(),
                link.getSimilarityScore(),
                link.getDescription(),
                link.isCreatedByAi()
        );
    }
}
