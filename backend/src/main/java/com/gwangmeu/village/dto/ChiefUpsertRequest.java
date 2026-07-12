package com.gwangmeu.village.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.UUID;

/**
 * Creation / mise a jour d'un chef de la dynastie d'un village.
 */
@Schema(description = "Creation/mise a jour d'un chef de la dynastie")
public record ChiefUpsertRequest(
        @NotBlank @Size(max = 200) @Schema(description = "Nom du chef") String displayName,
        @Schema(description = "Annee de debut de regne") Integer reignStart,
        @Schema(description = "Annee de fin de regne (null = en fonction)") Integer reignEnd,
        @Schema(description = "Chef actuellement en fonction") Boolean current,
        @Schema(description = "Ordre d'affichage") Integer ordinal,
        @Size(max = 4000) @Schema(description = "Recit / note de regne") String note,
        @Size(max = 500) @Schema(description = "URL de l'avatar") String avatarUrl,
        @Schema(description = "Compte utilisateur lie (facultatif)") UUID userId
) {}
