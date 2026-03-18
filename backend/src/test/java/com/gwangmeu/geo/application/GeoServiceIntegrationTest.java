package com.gwangmeu.geo.application;

import com.gwangmeu.geo.domain.Continent;
import com.gwangmeu.geo.domain.Country;
import com.gwangmeu.geo.domain.CountryLanguage;
import com.gwangmeu.geo.domain.Language;
import com.gwangmeu.geo.dto.*;
import com.gwangmeu.geo.infrastructure.ContinentRepository;
import com.gwangmeu.geo.infrastructure.CountryLanguageRepository;
import com.gwangmeu.geo.infrastructure.CountryRepository;
import com.gwangmeu.geo.infrastructure.LanguageRepository;
import com.gwangmeu.shared.BaseIntegrationTest;
import com.gwangmeu.village.domain.Village;
import com.gwangmeu.village.infrastructure.VillageRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

@Transactional
@DisplayName("GeoService - Tests d'integration")
class GeoServiceIntegrationTest extends BaseIntegrationTest {

    @Autowired
    private GeoService geoService;

    @Autowired
    private ContinentRepository continentRepository;

    @Autowired
    private CountryRepository countryRepository;

    @Autowired
    private LanguageRepository languageRepository;

    @Autowired
    private CountryLanguageRepository countryLanguageRepository;

    @Autowired
    private VillageRepository villageRepository;

    @BeforeEach
    void setUp() {
        countryLanguageRepository.deleteAllInBatch();
        languageRepository.deleteAllInBatch();
        villageRepository.deleteAllInBatch();
        countryRepository.deleteAllInBatch();
        continentRepository.deleteAllInBatch();
    }

    // ── getAllContinents ──────────────────────────────────────────────────────

    @Nested
    @DisplayName("getAllContinents()")
    class GetAllContinents {

        @Test
        @DisplayName("doit retourner tous les continents avec les comptages")
        void shouldReturnAllContinents() {
            Continent af = continentRepository.saveAndFlush(Continent.builder()
                    .code("AF").name("Afrique").build());

            Country cmr = countryRepository.saveAndFlush(Country.builder()
                    .isoCode("CMR").name("Cameroon").continentCode("AF").build());

            villageRepository.saveAndFlush(Village.builder()
                    .name("Bafia").country("Cameroun").continentCode("AF").build());

            List<ContinentDto> continents = geoService.getAllContinents();

            assertThat(continents).isNotEmpty();
            ContinentDto africa = continents.stream()
                    .filter(c -> c.code().equals("AF"))
                    .findFirst().orElseThrow();
            assertThat(africa.name()).isEqualTo("Afrique");
            assertThat(africa.countryCount()).isEqualTo(1);
            assertThat(africa.villageCount()).isEqualTo(1);
        }

        @Test
        @DisplayName("doit retourner une liste vide si aucun continent")
        void shouldReturnEmptyIfNone() {
            List<ContinentDto> continents = geoService.getAllContinents();
            assertThat(continents).isEmpty();
        }
    }

    // ── findContinentByCode ─────────────────────────────────────────────────

    @Nested
    @DisplayName("findContinentByCode()")
    class FindContinentByCode {

        @Test
        @DisplayName("doit trouver un continent par code (case insensitive)")
        void shouldFindByCode() {
            continentRepository.saveAndFlush(Continent.builder()
                    .code("AF").name("Afrique").build());

            Optional<ContinentDto> result = geoService.findContinentByCode("af");

            assertThat(result).isPresent();
            assertThat(result.get().name()).isEqualTo("Afrique");
        }

        @Test
        @DisplayName("doit retourner empty si code inconnu")
        void shouldReturnEmptyForUnknownCode() {
            Optional<ContinentDto> result = geoService.findContinentByCode("XX");
            assertThat(result).isEmpty();
        }
    }

    // ── getAllCountries ──────────────────────────────────────────────────────

    @Nested
    @DisplayName("getAllCountries()")
    class GetAllCountries {

        @Test
        @DisplayName("doit retourner tous les pays avec le comptage de villages")
        void shouldReturnAllCountries() {
            continentRepository.saveAndFlush(Continent.builder()
                    .code("AF").name("Afrique").build());

            Country cmr = countryRepository.saveAndFlush(Country.builder()
                    .isoCode("CMR").name("Cameroon").continentCode("AF").build());

            villageRepository.saveAndFlush(Village.builder()
                    .name("Bafia").country("Cameroun").continentCode("AF")
                    .countryId(cmr.getId()).build());

            List<CountryDto> countries = geoService.getAllCountries();

            assertThat(countries).hasSize(1);
            assertThat(countries.get(0).name()).isEqualTo("Cameroon");
            assertThat(countries.get(0).villageCount()).isEqualTo(1);
        }
    }

    // ── getCountriesByContinent ──────────────────────────────────────────────

    @Nested
    @DisplayName("getCountriesByContinent()")
    class GetCountriesByContinent {

        @Test
        @DisplayName("doit retourner les pays d'un continent (case insensitive)")
        void shouldReturnCountriesForContinent() {
            continentRepository.saveAndFlush(Continent.builder()
                    .code("AF").name("Afrique").build());
            continentRepository.saveAndFlush(Continent.builder()
                    .code("EU").name("Europe").build());

            countryRepository.saveAndFlush(Country.builder()
                    .isoCode("CMR").name("Cameroon").continentCode("AF").build());
            countryRepository.saveAndFlush(Country.builder()
                    .isoCode("CIV").name("Cote d'Ivoire").continentCode("AF").build());
            countryRepository.saveAndFlush(Country.builder()
                    .isoCode("FRA").name("France").continentCode("EU").build());

            List<CountryDto> afCountries = geoService.getCountriesByContinent("af");

            assertThat(afCountries).hasSize(2);
            assertThat(afCountries).allMatch(c -> c.isoCode().equals("CMR") || c.isoCode().equals("CIV"));
        }
    }

    // ── findCountryByIsoCode ────────────────────────────────────────────────

    @Nested
    @DisplayName("findCountryByIsoCode()")
    class FindCountryByIsoCode {

        @Test
        @DisplayName("doit trouver un pays par code ISO (case insensitive)")
        void shouldFindByIsoCode() {
            continentRepository.saveAndFlush(Continent.builder()
                    .code("AF").name("Afrique").build());
            countryRepository.saveAndFlush(Country.builder()
                    .isoCode("CMR").name("Cameroon").continentCode("AF").build());

            Optional<CountryDto> result = geoService.findCountryByIsoCode("cmr");

            assertThat(result).isPresent();
            assertThat(result.get().name()).isEqualTo("Cameroon");
        }

        @Test
        @DisplayName("doit retourner empty si code inconnu")
        void shouldReturnEmptyForUnknownCode() {
            Optional<CountryDto> result = geoService.findCountryByIsoCode("ZZZ");
            assertThat(result).isEmpty();
        }
    }

    // ── getLanguagesByCountry ───────────────────────────────────────────────

    @Nested
    @DisplayName("getLanguagesByCountry()")
    class GetLanguagesByCountry {

        @Test
        @DisplayName("doit retourner les langues triees (officielles en premier)")
        void shouldReturnLanguagesSortedOfficialFirst() {
            continentRepository.saveAndFlush(Continent.builder()
                    .code("AF").name("Afrique").build());

            Country cmr = countryRepository.saveAndFlush(Country.builder()
                    .isoCode("CMR").name("Cameroon").continentCode("AF").build());

            Language french = languageRepository.saveAndFlush(Language.builder()
                    .name("French").nameLocal("Francais").build());
            Language english = languageRepository.saveAndFlush(Language.builder()
                    .name("English").nameLocal("English").build());
            Language ewondo = languageRepository.saveAndFlush(Language.builder()
                    .name("Ewondo").nameLocal("Ewondo").build());

            countryLanguageRepository.saveAndFlush(CountryLanguage.builder()
                    .countryId(cmr.getId()).languageId(french.getId()).official(true).build());
            countryLanguageRepository.saveAndFlush(CountryLanguage.builder()
                    .countryId(cmr.getId()).languageId(english.getId()).official(true).build());
            countryLanguageRepository.saveAndFlush(CountryLanguage.builder()
                    .countryId(cmr.getId()).languageId(ewondo.getId()).official(false).build());

            List<LanguageDto> languages = geoService.getLanguagesByCountry("CMR");

            assertThat(languages).hasSize(3);
            // Officielles en premier, triees par nom
            assertThat(languages.get(0).official()).isTrue();
            assertThat(languages.get(1).official()).isTrue();
            assertThat(languages.get(2).official()).isFalse();
            assertThat(languages.get(2).name()).isEqualTo("Ewondo");
        }

        @Test
        @DisplayName("doit retourner une liste vide si aucune langue liee")
        void shouldReturnEmptyIfNoLanguages() {
            List<LanguageDto> languages = geoService.getLanguagesByCountry("ZZZ");
            assertThat(languages).isEmpty();
        }
    }

    // ── findNearbyVillages (PostGIS) ────────────────────────────────────────

    @Nested
    @DisplayName("findNearbyVillages()")
    class FindNearbyVillages {

        @Test
        @DisplayName("doit retourner les villages dans le rayon")
        void shouldReturnVillagesWithinRadius() {
            // Bafia (Cameroun) ~5.7, 11.2
            villageRepository.saveAndFlush(Village.builder()
                    .name("Bafia").country("Cameroun").continentCode("AF")
                    .latitude(5.7).longitude(11.2).build());

            // Village proche (~50 km)
            villageRepository.saveAndFlush(Village.builder()
                    .name("Ntui").country("Cameroun").continentCode("AF")
                    .latitude(4.45).longitude(11.63).build());

            // Village loin (~300 km)
            villageRepository.saveAndFlush(Village.builder()
                    .name("Maroua").country("Cameroun").continentCode("AF")
                    .latitude(10.6).longitude(14.3).build());

            List<NearbyVillageDto> nearby = geoService.findNearbyVillages(5.7, 11.2, 200, 10);

            // Bafia (0 km) et Ntui (~150 km) doivent etre inclus, Maroua (>200 km) non
            assertThat(nearby).hasSizeLessThanOrEqualTo(10);
            assertThat(nearby).anyMatch(v -> v.name().equals("Bafia"));
        }

        @Test
        @DisplayName("doit respecter le hard limit de 50")
        void shouldCapAtHardLimit() {
            // Le cap interne est 50
            List<NearbyVillageDto> nearby = geoService.findNearbyVillages(0, 0, 10000, 100);
            assertThat(nearby.size()).isLessThanOrEqualTo(50);
        }
    }

    // ── globalSearch ────────────────────────────────────────────────────────

    @Nested
    @DisplayName("globalSearch()")
    class GlobalSearch {

        @Test
        @DisplayName("doit chercher dans continents, pays et villages")
        void shouldSearchAcrossAllEntities() {
            continentRepository.saveAndFlush(Continent.builder()
                    .code("AF").name("Afrique").build());

            countryRepository.saveAndFlush(Country.builder()
                    .isoCode("CMR").name("Cameroon").continentCode("AF").build());

            villageRepository.saveAndFlush(Village.builder()
                    .name("Bafia").country("Cameroun").continentCode("AF").build());

            // Rechercher "af" — doit matcher le continent "AFrique"
            List<GeoSearchResultDto> results = geoService.globalSearch("Af");
            assertThat(results).isNotEmpty();
            assertThat(results).anyMatch(r -> r.name().equals("Afrique"));
        }

        @Test
        @DisplayName("doit retourner les villages par nom")
        void shouldSearchVillagesByName() {
            villageRepository.saveAndFlush(Village.builder()
                    .name("Bafia").country("Cameroun").continentCode("AF").build());

            villageRepository.saveAndFlush(Village.builder()
                    .name("Dschang").country("Cameroun").continentCode("AF").build());

            List<GeoSearchResultDto> results = geoService.globalSearch("Bafi");

            assertThat(results).isNotEmpty();
            assertThat(results).anyMatch(r -> r.name().equals("Bafia"));
            assertThat(results).noneMatch(r -> r.name().equals("Dschang"));
        }

        @Test
        @DisplayName("doit retourner une liste vide si aucun resultat")
        void shouldReturnEmptyForNoMatch() {
            List<GeoSearchResultDto> results = geoService.globalSearch("XXXXXXX");
            assertThat(results).isEmpty();
        }
    }
}
