package com.gwangmeu.feed.dto;

import com.gwangmeu.feed.domain.ModerationStatus;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;

@Schema(description = "Requete de moderation — action et note optionnelle (obligatoire si REJECTED)")
public record ModerateActionRequest(

        @NotNull(message = "L'action de moderation est obligatoire")
        @Schema(description = "Nouvelle action de moderation",
                allowableValues = {"APPROVED", "REJECTED", "SHADOW_BANNED"},
                example = "APPROVED")
        ModerationStatus action,

        @Schema(description = "Note explicative (obligatoire pour REJECTED et SHADOW_BANNED)",
                example = "Contenu irrespectueux envers les traditions du village.")
        String note
) {}
