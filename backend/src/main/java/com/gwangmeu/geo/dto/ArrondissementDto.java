package com.gwangmeu.geo.dto;

import com.gwangmeu.geo.domain.GeoArrondissement;
import io.swagger.v3.oas.annotations.media.Schema;

/**
 * DTO flat pour un arrondissement / commune du referentiel territorial.
 */
@Schema(description = "Arrondissement / commune")
public record ArrondissementDto(
        @Schema(description = "Code arrondissement") String code,
        @Schema(description = "Code departement parent") String departmentCode,
        @Schema(description = "Nom") String name
) {
    public static ArrondissementDto from(GeoArrondissement a) {
        return new ArrondissementDto(a.getCode(), a.getDepartmentCode(), a.getName());
    }
}
