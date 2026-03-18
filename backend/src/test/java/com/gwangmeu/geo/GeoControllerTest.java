package com.gwangmeu.geo;

import com.gwangmeu.geo.domain.Continent;
import com.gwangmeu.geo.domain.Country;
import com.gwangmeu.geo.domain.CulturalLink;
import com.gwangmeu.geo.infrastructure.ContinentRepository;
import com.gwangmeu.geo.infrastructure.CountryRepository;
import com.gwangmeu.geo.infrastructure.CulturalLinkRepository;
import com.gwangmeu.shared.BaseIntegrationTest;
import com.gwangmeu.village.domain.Village;
import com.gwangmeu.village.infrastructure.VillageRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@DisplayName("GeoController — Integration Tests")
class GeoControllerTest extends BaseIntegrationTest {

    @Autowired MockMvc mockMvc;

    @Autowired ContinentRepository continentRepository;
    @Autowired CountryRepository   countryRepository;
    @Autowired VillageRepository   villageRepository;
    @Autowired CulturalLinkRepository culturalLinkRepository;

    private Continent savedContinent;
    private Country   savedCountry;
    private Village   savedVillage;

    @BeforeEach
    void setUp() {
        culturalLinkRepository.deleteAll();
        villageRepository.deleteAll();
        countryRepository.deleteAll();
        continentRepository.deleteAll();

        savedContinent = continentRepository.save(Continent.builder()
                .code("AF-CENTRAL")
                .name("Central Africa")
                .description("Afrique centrale — Cameroun, Congo, RCA")
                .build());

        savedCountry = countryRepository.save(Country.builder()
                .isoCode("CMR")
                .name("Cameroun")
                .continentCode("AF-CENTRAL")
                .flagEmoji("\uD83C\uDDE8\uD83C\uDDF2")
                .build());

        savedVillage = villageRepository.save(Village.builder()
                .name("Bafia")
                .country("CMR")
                .continentCode("AF-CENTRAL")
                .latitude(4.75)
                .longitude(11.23)
                .countryId(savedCountry.getId())
                .build());
    }

    // ── 1. GET /api/v1/geo/continents ────────────────────────────────────────

    @Test
    @DisplayName("GET /continents — retourne la liste avec stats")
    void getContinents_returnsList() throws Exception {
        mockMvc.perform(get("/api/v1/geo/continents").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data", hasSize(greaterThanOrEqualTo(1))))
                .andExpect(jsonPath("$.data[0].code").value("AF-CENTRAL"))
                .andExpect(jsonPath("$.data[0].countryCount").value(greaterThanOrEqualTo(1)));
    }

    @Test
    @DisplayName("GET /continents/{code} — retourne le bon continent")
    void getContinent_byCode() throws Exception {
        mockMvc.perform(get("/api/v1/geo/continents/AF-CENTRAL").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("Central Africa"));
    }

    @Test
    @DisplayName("GET /continents/{code} — 404 si inconnu")
    void getContinent_notFound() throws Exception {
        mockMvc.perform(get("/api/v1/geo/continents/UNKNOWN").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isNotFound());
    }

    // ── 2. GET /api/v1/geo/continents/{code}/countries ───────────────────────

    @Test
    @DisplayName("GET /continents/{code}/countries — retourne les pays avec emoji")
    void getCountriesByContinent() throws Exception {
        mockMvc.perform(get("/api/v1/geo/continents/AF-CENTRAL/countries").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(greaterThanOrEqualTo(1))))
                .andExpect(jsonPath("$.data[0].isoCode").value("CMR"))
                .andExpect(jsonPath("$.data[0].flagEmoji").isNotEmpty());
    }

    // ── 3. GET /api/v1/geo/countries/{isoCode} ───────────────────────────────

    @Test
    @DisplayName("GET /countries/{isoCode} — retourne le pays avec villageCount")
    void getCountry_byIsoCode() throws Exception {
        mockMvc.perform(get("/api/v1/geo/countries/CMR").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("Cameroun"))
                .andExpect(jsonPath("$.data.villageCount").value(greaterThanOrEqualTo(1)));
    }

    @Test
    @DisplayName("GET /countries/{isoCode} — insensible a la casse")
    void getCountry_caseInsensitive() throws Exception {
        mockMvc.perform(get("/api/v1/geo/countries/cmr").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.isoCode").value("CMR"));
    }

    @Test
    @DisplayName("GET /countries/{isoCode} — 404 si inconnu")
    void getCountry_notFound() throws Exception {
        mockMvc.perform(get("/api/v1/geo/countries/ZZZ").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isNotFound());
    }

    // ── 4. GET /api/v1/geo/villages/nearby ───────────────────────────────────

    @Test
    @DisplayName("GET /villages/nearby — retourne Bafia dans rayon 100km")
    void getNearbyVillages_returnsResult() throws Exception {
        mockMvc.perform(get("/api/v1/geo/villages/nearby")
                        .param("lat", "4.80")
                        .param("lng", "11.20")
                        .param("radiusKm", "100")
                        .param("limit", "10")
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(greaterThanOrEqualTo(1))))
                .andExpect(jsonPath("$.data[0].name").value("Bafia"))
                .andExpect(jsonPath("$.data[0].distanceKm").value(lessThan(100.0)));
    }

    @Test
    @DisplayName("GET /villages/nearby — 0 resultats si rayon trop petit")
    void getNearbyVillages_noResult() throws Exception {
        mockMvc.perform(get("/api/v1/geo/villages/nearby")
                        .param("lat", "0.0")
                        .param("lng", "0.0")
                        .param("radiusKm", "1")
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(0)));
    }

    @Test
    @DisplayName("GET /villages/nearby — 400 si lat invalide")
    void getNearbyVillages_invalidLat() throws Exception {
        mockMvc.perform(get("/api/v1/geo/villages/nearby")
                        .param("lat", "200")
                        .param("lng", "11.0")
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isBadRequest());
    }

    // ── 5. GET /api/v1/geo/villages/{id}/cultural-links ──────────────────────

    @Test
    @DisplayName("GET /villages/{id}/cultural-links — retourne les liens")
    @WithMockUser
    void getCulturalLinks_returnsList() throws Exception {
        Village villageB = villageRepository.save(Village.builder()
                .name("Douala")
                .country("CMR")
                .continentCode("AF-CENTRAL")
                .latitude(4.05)
                .longitude(9.70)
                .build());

        culturalLinkRepository.save(CulturalLink.builder()
                .villageAId(savedVillage.getId())
                .villageBId(villageB.getId())
                .linkType("dialect")
                .similarityScore(BigDecimal.valueOf(0.80))
                .description("Partage du dialecte Bassa")
                .build());

        mockMvc.perform(get("/api/v1/geo/villages/{id}/cultural-links", savedVillage.getId())
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(1)))
                .andExpect(jsonPath("$.data[0].linkType").value("dialect"))
                .andExpect(jsonPath("$.data[0].similarityScore").value(0.80));
    }

    @Test
    @DisplayName("GET /villages/{id}/cultural-links?linkType=cuisine — filtre par type")
    void getCulturalLinks_filterByType() throws Exception {
        mockMvc.perform(get("/api/v1/geo/villages/{id}/cultural-links", savedVillage.getId())
                        .param("linkType", "cuisine")
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(0)));
    }

    // ── 6. GET /api/v1/geo/search ─────────────────────────────────────────────

    @Test
    @DisplayName("GET /search?q=Baf — retourne Bafia dans les resultats")
    void globalSearch_findsVillage() throws Exception {
        mockMvc.perform(get("/api/v1/geo/search")
                        .param("q", "Baf")
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.name == 'Bafia')]").exists())
                .andExpect(jsonPath("$.data[?(@.type == 'VILLAGE')]").exists());
    }

    @Test
    @DisplayName("GET /search?q=CMR — retourne le pays Cameroun")
    void globalSearch_findsCountry() throws Exception {
        mockMvc.perform(get("/api/v1/geo/search")
                        .param("q", "CMR")
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.type == 'COUNTRY')]").exists());
    }

    @Test
    @DisplayName("GET /search?q=x — 400 si moins de 2 caracteres")
    void globalSearch_tooShort() throws Exception {
        mockMvc.perform(get("/api/v1/geo/search")
                        .param("q", "x")
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isBadRequest());
    }
}
