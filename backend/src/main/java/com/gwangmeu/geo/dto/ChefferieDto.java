package com.gwangmeu.geo.dto;

import com.gwangmeu.geo.domain.Chefferie;
import io.swagger.v3.oas.annotations.media.Schema;

/**
 * DTO flat pour une chefferie traditionnelle.
 */
@Schema(description = "Chefferie traditionnelle")
public record ChefferieDto(
        @Schema(description = "Degre de la chefferie", example = "2") Short degre,
        @Schema(description = "Nom de la region") String regionName,
        @Schema(description = "Nom du departement") String departmentName,
        @Schema(description = "Code du departement") String departmentCode,
        @Schema(description = "Numero d'ordre") Integer numero,
        @Schema(description = "Denomination") String denomination
) {
    public static ChefferieDto from(Chefferie c) {
        return new ChefferieDto(
                c.getDegre(), c.getRegionName(), c.getDepartmentName(),
                c.getDepartmentCode(), c.getNumero(), c.getDenomination()
        );
    }
}
