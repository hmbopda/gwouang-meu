package com.gwangmeu.feed.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

@Schema(description = "Requete de moderation d'un post")
public record ModeratePostRequest(
        @NotBlank @Pattern(regexp = "APPROVED|REJECTED|FLAGGED")
        @Schema(description = "Nouveau statut de moderation", allowableValues = {"APPROVED", "REJECTED", "FLAGGED"})
        String status,

        @Schema(description = "Raison de la decision (obligatoire si REJECTED)")
        String reason
) {}
