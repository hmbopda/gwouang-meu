package com.gwangmeu.village.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import java.util.UUID;

/**
 * Temps fort (jalon historique) d'un village.
 */
@Schema(description = "Temps fort (jalon historique) d'un village")
public record VillageMilestoneDto(
        @Schema(description = "Identifiant de l'enregistrement") UUID id,
        @Schema(description = "Annee de l'evenement") Integer year,
        @Schema(description = "Libelle de date libre (ex. « vers 1850 »)") String dateLabel,
        @Schema(description = "Titre du temps fort") String title,
        @Schema(description = "Description / recit") String description,
        @Schema(description = "Ordre d'affichage dans la frise") int ordinal
) {}
