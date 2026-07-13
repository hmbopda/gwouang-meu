package com.gwangmeu.village.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import java.time.Instant;
import java.util.UUID;

/**
 * Entree patrimoniale d'un village (tradition, lieu sacre ou calendrier traditionnel).
 */
@Schema(description = "Entree patrimoniale d'un village (tradition, lieu sacre, calendrier)")
public record HeritageEntryDto(
        @Schema(description = "Identifiant de l'enregistrement") UUID id,
        @Schema(description = "Identifiant du village") UUID villageId,
        @Schema(description = "Rubrique (TRADITION, SACRED_PLACE, CALENDAR)") String kind,
        @Schema(description = "Titre") String title,
        @Schema(description = "Sous-titre") String subtitle,
        @Schema(description = "Description / recit court") String description,
        @Schema(description = "Detail complementaire") String detail,
        @Schema(description = "Ordre d'affichage") int ordinal,
        @Schema(description = "Date de creation") Instant createdAt
) {}
