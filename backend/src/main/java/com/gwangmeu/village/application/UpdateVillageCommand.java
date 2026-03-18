package com.gwangmeu.village.application;

public record UpdateVillageCommand(
        String description,
        String coverImageUrl,
        Integer foundedYear,
        Integer populationEstimate,
        String historicalSummary
) {}
