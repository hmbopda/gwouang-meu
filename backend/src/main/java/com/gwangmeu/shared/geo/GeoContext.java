package com.gwangmeu.shared.geo;

/**
 * Contexte geographique immutable partage entre modules.
 * Represente la position dans la hierarchie : Continent → Pays → Region → Village.
 */
public record GeoContext(
        String continent,
        String country,
        String region,
        String village,
        Double latitude,
        Double longitude) {

    public static GeoContext ofVillage(String country, String village) {
        return new GeoContext(null, country, null, village, null, null);
    }

    public static GeoContext ofCountry(String country) {
        return new GeoContext(null, country, null, null, null, null);
    }

    public static GeoContext withCoordinates(String country, String village, double lat, double lng) {
        return new GeoContext(null, country, null, village, lat, lng);
    }

    public boolean hasCoordinates() {
        return latitude != null && longitude != null;
    }

    public boolean hasVillage() {
        return village != null && !village.isBlank();
    }
}
