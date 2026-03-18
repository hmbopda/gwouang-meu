package com.gwangmeu.geo.application;

import com.gwangmeu.geo.dto.*;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface GeoService {

    // ── Continents ──────────────────────────────────────────────────────────

    List<ContinentDto> getAllContinents();

    Optional<ContinentDto> findContinentByCode(String code);

    // ── Countries ────────────────────────────────────────────────────────────

    List<CountryDto> getAllCountries();

    List<CountryDto> getCountriesByContinent(String continentCode);

    Optional<CountryDto> findCountryByIsoCode(String isoCode);

    // ── Nearby (PostGIS) ─────────────────────────────────────────────────────

    /**
     * Villages dans un rayon donne autour d'un point GPS.
     *
     * @param lat          Latitude du point de reference
     * @param lng          Longitude du point de reference
     * @param radiusKm     Rayon en kilometres (converti en metres en interne)
     * @param limit        Nombre max de resultats (cap a 50)
     */
    List<NearbyVillageDto> findNearbyVillages(double lat, double lng, double radiusKm, int limit);

    // ── Cultural links ────────────────────────────────────────────────────────

    List<CulturalLinkDto> getCulturalLinks(UUID villageId, String linkType);

    // ── Languages ─────────────────────────────────────────────────────────────

    List<LanguageDto> getLanguagesByCountry(String isoCode);

    // ── Global search ─────────────────────────────────────────────────────────

    /**
     * Recherche globale multi-niveaux (continents + pays + villages).
     * Limite a 20 resultats pour economiser la bande passante.
     */
    List<GeoSearchResultDto> globalSearch(String query);
}
