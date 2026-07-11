package com.gwangmeu.geo.dto;

import com.gwangmeu.geo.domain.GeoRegion;
import io.swagger.v3.oas.annotations.media.Schema;

/**
 * DTO flat pour une region du referentiel territorial.
 */
@Schema(description = "Region administrative")
public record RegionDto(
        @Schema(description = "Code region", example = "OU") String code,
        @Schema(description = "Nom", example = "Ouest") String name,
        @Schema(description = "Chef-lieu", example = "Bafoussam") String chiefTown
) {
    public static RegionDto from(GeoRegion r) {
        return new RegionDto(r.getCode(), r.getName(), r.getChiefTown());
    }
}
