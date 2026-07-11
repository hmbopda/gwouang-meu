package com.gwangmeu.village.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

/**
 * Corps de requete pour inviter un utilisateur a rejoindre un village.
 */
@Schema(description = "Demande d'invitation a un village")
public record InviteToVillageRequest(
        @Schema(description = "Identifiant de l'utilisateur invite", requiredMode = Schema.RequiredMode.REQUIRED)
        @NotNull UUID invitedUserId,

        @Schema(description = "Message d'accompagnement facultatif")
        @Size(max = 300) String message
) {}
