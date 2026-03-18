package com.gwangmeu.village.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Size;

@Schema(description = "Requete de mise a jour d'un village")
public record UpdateVillageRequest(
        @Size(max = 2000) @Schema(description = "Description") String description,
        @Schema(description = "URL image de couverture") String coverImageUrl,
        @Schema(description = "Annee de fondation") Integer foundedYear,
        @Schema(description = "Population estimee") Integer populationEstimate,
        @Size(max = 5000) @Schema(description = "Resume historique") String historicalSummary
) {}
