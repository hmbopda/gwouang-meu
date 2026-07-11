package com.gwangmeu.village.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import java.util.UUID;

/**
 * Chef (createur) d'un village, resolu depuis {@code villages.creator_id}.
 */
@Schema(description = "Chef / createur d'un village")
public record ChiefDto(
        @Schema(description = "Identifiant de l'utilisateur chef") UUID userId,
        @Schema(description = "Nom affiche du chef") String displayName,
        @Schema(description = "URL de l'avatar du chef") String avatarUrl,
        @Schema(description = "Annee depuis laquelle le chef dirige (year de created_at ou foundedYear)") Integer since,
        @Schema(description = "Vrai : le chef est le createur du village") boolean isCreator
) {}
