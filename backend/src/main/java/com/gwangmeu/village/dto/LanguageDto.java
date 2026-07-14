package com.gwangmeu.village.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import java.util.UUID;

/**
 * Langue du referentiel ({@code languages}).
 */
@Schema(description = "Langue du referentiel")
public record LanguageDto(
        @Schema(description = "Identifiant de la langue") UUID id,
        @Schema(description = "Slug stable (ex. « basaa »)") String code,
        @Schema(description = "Nom de la langue") String name,
        @Schema(description = "Nom francais (ex. « Bassa »)") String frenchName,
        @Schema(description = "Code ISO 639-3 (ex. « bas »)") String iso6393,
        @Schema(description = "Region / aire linguistique") String region
) {}
