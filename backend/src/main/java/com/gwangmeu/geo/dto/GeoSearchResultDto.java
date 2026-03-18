package com.gwangmeu.geo.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import java.util.UUID;

/**
 * DTO generique pour les resultats de recherche globale (multi-niveaux).
 * Couvre continents, pays et villages dans un format uniforme.
 * Optimise connexions lentes : pas d'objets imbriques.
 */
@Schema(description = "Resultat de recherche geographique multi-niveaux")
public record GeoSearchResultDto(

        @Schema(description = "ID de l'entite") UUID id,
        @Schema(description = "Type d'entite", example = "VILLAGE",
                allowableValues = {"CONTINENT", "COUNTRY", "VILLAGE"})
        String type,
        @Schema(description = "Nom principal", example = "Bafia") String name,
        @Schema(description = "Code ou code ISO", example = "CMR") String code,
        @Schema(description = "Contexte parent (continent ou pays)", example = "Cameroun") String parentName,
        @Schema(description = "URL image representant l'entite") String imageUrl,
        @Schema(description = "Latitude (villages uniquement)") Double latitude,
        @Schema(description = "Longitude (villages uniquement)") Double longitude
) {
    /** Depuis un continent */
    public static GeoSearchResultDto continent(UUID id, String code, String name, String coverImageUrl) {
        return new GeoSearchResultDto(id, "CONTINENT", name, code, null, coverImageUrl, null, null);
    }

    /** Depuis un pays */
    public static GeoSearchResultDto country(UUID id, String isoCode, String name,
                                             String continentCode, String flagUrl) {
        return new GeoSearchResultDto(id, "COUNTRY", name, isoCode, continentCode, flagUrl, null, null);
    }

    /** Depuis un village */
    public static GeoSearchResultDto village(UUID id, String name, String country,
                                             String coverImageUrl, Double latitude, Double longitude) {
        return new GeoSearchResultDto(id, "VILLAGE", name, null, country, coverImageUrl, latitude, longitude);
    }
}
