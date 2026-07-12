package com.gwangmeu.village.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Creation / mise a jour d'un temps fort d'un village.
 */
@Schema(description = "Creation/mise a jour d'un temps fort")
public record MilestoneUpsertRequest(
        @Schema(description = "Annee de l'evenement") Integer year,
        @Size(max = 120) @Schema(description = "Libelle de date libre") String dateLabel,
        @NotBlank @Size(max = 200) @Schema(description = "Titre") String title,
        @Size(max = 4000) @Schema(description = "Description / recit") String description,
        @Schema(description = "Ordre d'affichage") Integer ordinal
) {}
