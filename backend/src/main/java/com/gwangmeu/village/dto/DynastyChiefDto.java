package com.gwangmeu.village.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import java.util.UUID;

/**
 * Chef d'un village dans la dynastie (chef actuel ou ancien), donnee patrimoniale.
 */
@Schema(description = "Chef d'un village dans la dynastie (actuel ou ancien)")
public record DynastyChiefDto(
        @Schema(description = "Identifiant de l'enregistrement") UUID id,
        @Schema(description = "Nom du chef") String displayName,
        @Schema(description = "Annee de debut de regne") Integer reignStart,
        @Schema(description = "Annee de fin de regne (null = en fonction)") Integer reignEnd,
        @Schema(description = "Chef actuellement en fonction") boolean current,
        @Schema(description = "Ordre d'affichage dans la dynastie") int ordinal,
        @Schema(description = "Recit / note de regne") String note,
        @Schema(description = "URL de l'avatar") String avatarUrl,
        @Schema(description = "Compte utilisateur lie (facultatif)") UUID userId
) {}
