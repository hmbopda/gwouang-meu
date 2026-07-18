package com.gwangmeu.village.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;

import java.util.UUID;

/** Création / mise à jour d'un notable (siège non-apex + titulaire courant). */
@Schema(description = "Création/mise à jour d'un notable")
public record NotableUpsertRequest(
        @NotBlank
        @Schema(description = "Nom affiché du notable") String displayName,
        @Schema(description = "Titre / libellé (ex. « Nji », « Méfé »)") String title,
        @Schema(description = "Rang de préséance (petit = plus haut)") Integer rank,
        @Schema(description = "Année de début de charge (facultatif)") Integer termStart,
        @Schema(description = "Compte utilisateur lié (facultatif)") UUID userId
) {}
