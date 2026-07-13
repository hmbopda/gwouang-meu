package com.gwangmeu.village.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Creation / mise a jour d'une entree patrimoniale d'un village.
 */
@Schema(description = "Creation/mise a jour d'une entree patrimoniale")
public record HeritageEntryUpsertRequest(
        @NotBlank @Size(max = 200) @Schema(description = "Titre") String title,
        @Size(max = 200) @Schema(description = "Sous-titre") String subtitle,
        @Schema(description = "Description / recit court") String description,
        @Schema(description = "Detail complementaire") String detail,
        @Schema(description = "Ordre d'affichage") Integer ordinal
) {}
