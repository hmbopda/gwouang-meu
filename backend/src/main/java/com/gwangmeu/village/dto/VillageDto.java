package com.gwangmeu.village.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import java.time.Instant;
import java.util.UUID;

@Schema(description = "Informations d'un village")
public record VillageDto(
        @Schema(description = "Identifiant unique") UUID id,
        @Schema(description = "Nom du village") String name,
        @Schema(description = "Description") String description,
        @Schema(description = "Pays (ISO 3166-1 alpha-3)") String country,
        @Schema(description = "Region ou province") String region,
        @Schema(description = "Code continent (AF-CENTRAL, AF-WEST...)") String continentCode,
        @Schema(description = "URL image de couverture") String coverImageUrl,
        @Schema(description = "Latitude") Double latitude,
        @Schema(description = "Longitude") Double longitude,
        @Schema(description = "Annee de fondation") Integer foundedYear,
        @Schema(description = "Population estimee") Integer populationEstimate,
        @Schema(description = "Dialecte principal") String primaryDialect,
        @Schema(description = "Nombre de membres") int memberCount,
        @Schema(description = "Village verifie par un moderateur") boolean verified,
        @Schema(description = "Resume historique") String historicalSummary,
        @Schema(description = "Identifiant du createur/chef du village") UUID creatorId,
        @Schema(description = "Date de creation") Instant createdAt
) {}
