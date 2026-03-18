package com.gwangmeu.village.application;

import jakarta.validation.constraints.NotBlank;

import java.util.UUID;

public record CreateVillageCommand(
        @NotBlank String name,
        String description,
        @NotBlank String country,
        String region,
        String continentCode,
        Double latitude,
        Double longitude,
        String primaryDialect,
        UUID creatorId
) {}
