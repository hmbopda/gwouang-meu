package com.gwangmeu.village.dto;

import com.gwangmeu.village.domain.VillageInvitationStatus;
import io.swagger.v3.oas.annotations.media.Schema;

import java.time.Instant;
import java.util.UUID;

/**
 * Invitation a rejoindre un village, enrichie du nom du village et de l'inviteur
 * pour l'affichage cote client.
 */
@Schema(description = "Invitation a rejoindre un village")
public record VillageInvitationDto(
        @Schema(description = "Identifiant de l'invitation") UUID id,
        @Schema(description = "Identifiant du village") UUID villageId,
        @Schema(description = "Nom du village") String villageName,
        @Schema(description = "Nom affiche de l'inviteur") String invitedByName,
        @Schema(description = "Statut de l'invitation") VillageInvitationStatus status,
        @Schema(description = "Message d'accompagnement") String message,
        @Schema(description = "Date de creation") Instant createdAt
) {}
