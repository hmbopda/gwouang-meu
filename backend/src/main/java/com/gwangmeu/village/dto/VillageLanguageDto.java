package com.gwangmeu.village.dto;

import io.swagger.v3.oas.annotations.media.Schema;

/**
 * Langue associee a un village, avec le drapeau « principale » et l'ordre d'affichage.
 */
@Schema(description = "Langue d'un village (avec drapeau « principale »)")
public record VillageLanguageDto(
        @Schema(description = "Langue du referentiel") LanguageDto language,
        @Schema(description = "Langue principale (native par defaut)") boolean isPrimary,
        @Schema(description = "Ordre d'affichage") int ordinal
) {}
