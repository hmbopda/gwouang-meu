package com.gwangmeu.village.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

@Schema(description = "Requete de creation d'un village")
public record CreateVillageRequest(
        @NotBlank @Size(min = 2, max = 100)
        @Schema(description = "Nom du village", example = "Bafia") String name,

        @Size(max = 2000)
        @Schema(description = "Description") String description,

        @NotBlank @Size(min = 2, max = 3)
        @Schema(description = "Code pays ISO 3166-1 alpha-3", example = "CMR") String country,

        @Size(max = 100)
        @Schema(description = "Region ou province", example = "Centre") String region,

        @Size(max = 20)
        @Schema(description = "Code continent", example = "AF-CENTRAL") String continentCode,

        @Schema(description = "Latitude GPS") Double latitude,
        @Schema(description = "Longitude GPS") Double longitude,

        @Size(max = 50)
        @Schema(description = "Dialecte principal", example = "Beti") String primaryDialect
) {}
