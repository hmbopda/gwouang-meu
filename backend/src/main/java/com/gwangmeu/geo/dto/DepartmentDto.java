package com.gwangmeu.geo.dto;

import com.gwangmeu.geo.domain.GeoDepartment;
import io.swagger.v3.oas.annotations.media.Schema;

/**
 * DTO flat pour un departement du referentiel territorial.
 */
@Schema(description = "Departement administratif")
public record DepartmentDto(
        @Schema(description = "Code departement") String code,
        @Schema(description = "Code region parente") String regionCode,
        @Schema(description = "Nom") String name,
        @Schema(description = "Chef-lieu") String chiefTown
) {
    public static DepartmentDto from(GeoDepartment d) {
        return new DepartmentDto(d.getCode(), d.getRegionCode(), d.getName(), d.getChiefTown());
    }
}
