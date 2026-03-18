package com.gwangmeu.geo.dto;

import com.gwangmeu.geo.domain.Continent;
import io.swagger.v3.oas.annotations.media.Schema;

import java.util.UUID;

/**
 * DTO flat (low-bandwidth) pour la liste des continents.
 * Pas d'objets imbriques — optimise pour connexions lentes.
 */
@Schema(description = "Continent africain avec statistiques")
public record ContinentDto(

        @Schema(description = "ID du continent") UUID id,
        @Schema(description = "Code court", example = "AF-CENTRAL") String code,
        @Schema(description = "Nom anglais", example = "Central Africa") String name,
        @Schema(description = "Nom francais", example = "Afrique Centrale") String nameFr,
        @Schema(description = "Description") String description,
        @Schema(description = "URL image de couverture") String coverImageUrl,
        @Schema(description = "Nombre de pays references") long countryCount,
        @Schema(description = "Nombre de villages enregistres") long villageCount
) {
    public static ContinentDto from(Continent c, long countryCount, long villageCount) {
        return new ContinentDto(
                c.getId(), c.getCode(), c.getName(), null,
                c.getDescription(), c.getCoverImageUrl(),
                countryCount, villageCount
        );
    }
}
