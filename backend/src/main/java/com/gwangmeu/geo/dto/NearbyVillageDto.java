package com.gwangmeu.geo.dto;

import com.gwangmeu.geo.infrastructure.NearbyVillageProjection;
import io.swagger.v3.oas.annotations.media.Schema;

import java.util.UUID;

/**
 * DTO pour les villages proches (PostGIS ST_DWithin).
 * Distance convertie en kilometres pour le client.
 */
@Schema(description = "Village proche avec distance calculee")
public record NearbyVillageDto(

        @Schema(description = "ID du village") UUID id,
        @Schema(description = "Nom du village", example = "Bafia") String name,
        @Schema(description = "Pays (code ISO ou nom)", example = "CMR") String country,
        @Schema(description = "Region", example = "Centre") String region,
        @Schema(description = "Latitude GPS") Double latitude,
        @Schema(description = "Longitude GPS") Double longitude,
        @Schema(description = "URL image de couverture") String coverImageUrl,
        @Schema(description = "Dialecte principal", example = "Yemba") String primaryDialect,
        @Schema(description = "Population estimee", example = "12000") Integer populationEstimate,
        @Schema(description = "Distance depuis le point de reference (km)", example = "23.4") double distanceKm
) {
    public static NearbyVillageDto from(NearbyVillageProjection p) {
        double km = p.getDistanceMeters() != null ? p.getDistanceMeters() / 1000.0 : 0.0;
        return new NearbyVillageDto(
                p.getId(), p.getName(), p.getCountry(), p.getRegion(),
                p.getLatitude(), p.getLongitude(), p.getCoverImageUrl(),
                p.getPrimaryDialect(), p.getPopulationEstimate(),
                Math.round(km * 10.0) / 10.0
        );
    }
}
