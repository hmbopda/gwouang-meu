package com.gwangmeu.geo.application;

import com.gwangmeu.geo.domain.*;
import com.gwangmeu.geo.dto.*;
import com.gwangmeu.geo.infrastructure.*;
import com.gwangmeu.village.domain.Village;
import com.gwangmeu.village.infrastructure.VillageRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("GeoServiceImpl — Tests unitaires")
class GeoServiceImplTest {

    @Mock private ContinentRepository continentRepository;
    @Mock private CountryRepository countryRepository;
    @Mock private CulturalLinkRepository culturalLinkRepository;
    @Mock private LanguageRepository languageRepository;
    @Mock private CountryLanguageRepository countryLanguageRepository;
    @Mock private VillageRepository villageRepository;

    @InjectMocks private GeoServiceImpl geoService;

    // ========================================================================
    // getAllContinents
    // ========================================================================

    @Nested
    @DisplayName("getAllContinents — Liste des continents")
    class GetAllContinentsTests {

        @Test
        @DisplayName("Doit retourner tous les continents avec leurs compteurs")
        void shouldReturnAllContinentsWithCounts() {
            Continent africa = Continent.builder()
                    .code("AF").name("Afrique").coverImageUrl("https://img.com/af.jpg").build();
            africa.setId(UUID.randomUUID());

            when(continentRepository.findAll()).thenReturn(List.of(africa));
            when(continentRepository.countCountriesByContinentCode("AF")).thenReturn(54L);
            when(continentRepository.countVillagesByContinentCode("AF")).thenReturn(120L);

            List<ContinentDto> result = geoService.getAllContinents();

            assertThat(result).hasSize(1);
            assertThat(result.get(0).code()).isEqualTo("AF");
            assertThat(result.get(0).countryCount()).isEqualTo(54L);
            assertThat(result.get(0).villageCount()).isEqualTo(120L);
        }

        @Test
        @DisplayName("Doit retourner une liste vide quand aucun continent")
        void shouldReturnEmptyList() {
            when(continentRepository.findAll()).thenReturn(Collections.emptyList());

            assertThat(geoService.getAllContinents()).isEmpty();
        }
    }

    // ========================================================================
    // findContinentByCode
    // ========================================================================

    @Nested
    @DisplayName("findContinentByCode — Recherche par code")
    class FindContinentByCodeTests {

        @Test
        @DisplayName("Doit retourner le continent quand le code existe")
        void shouldReturnWhenExists() {
            Continent africa = Continent.builder()
                    .code("AF").name("Afrique").build();
            africa.setId(UUID.randomUUID());

            when(continentRepository.findByCode("AF")).thenReturn(Optional.of(africa));
            when(continentRepository.countCountriesByContinentCode("AF")).thenReturn(54L);
            when(continentRepository.countVillagesByContinentCode("AF")).thenReturn(120L);

            Optional<ContinentDto> result = geoService.findContinentByCode("af");

            assertThat(result).isPresent();
            assertThat(result.get().code()).isEqualTo("AF");
        }

        @Test
        @DisplayName("Doit convertir le code en majuscules")
        void shouldConvertToUpperCase() {
            when(continentRepository.findByCode("AF")).thenReturn(Optional.empty());

            geoService.findContinentByCode("af");

            verify(continentRepository).findByCode("AF");
        }
    }

    // ========================================================================
    // getAllCountries
    // ========================================================================

    @Nested
    @DisplayName("getAllCountries — Liste des pays")
    class GetAllCountriesTests {

        @Test
        @DisplayName("Doit retourner tous les pays avec compteur de villages")
        void shouldReturnAllCountries() {
            Country cameroun = Country.builder()
                    .isoCode("CMR").name("Cameroun").continentCode("AF").build();
            cameroun.setId(UUID.randomUUID());

            when(countryRepository.findAll()).thenReturn(List.of(cameroun));
            when(countryRepository.countVillagesByCountryId(cameroun.getId())).thenReturn(50L);

            List<CountryDto> result = geoService.getAllCountries();

            assertThat(result).hasSize(1);
            assertThat(result.get(0).isoCode()).isEqualTo("CMR");
        }
    }

    // ========================================================================
    // getCountriesByContinent
    // ========================================================================

    @Nested
    @DisplayName("getCountriesByContinent — Pays par continent")
    class GetCountriesByContinentTests {

        @Test
        @DisplayName("Doit filtrer par code continent en majuscules")
        void shouldFilterByContinentCode() {
            when(countryRepository.findByContinentCode("AF")).thenReturn(Collections.emptyList());

            geoService.getCountriesByContinent("af");

            verify(countryRepository).findByContinentCode("AF");
        }
    }

    // ========================================================================
    // findCountryByIsoCode
    // ========================================================================

    @Nested
    @DisplayName("findCountryByIsoCode — Recherche par code ISO")
    class FindCountryByIsoCodeTests {

        @Test
        @DisplayName("Doit retourner le pays quand le code existe")
        void shouldReturnWhenExists() {
            Country cameroun = Country.builder()
                    .isoCode("CMR").name("Cameroun").continentCode("AF").build();
            cameroun.setId(UUID.randomUUID());

            when(countryRepository.findByIsoCode("CMR")).thenReturn(Optional.of(cameroun));
            when(countryRepository.countVillagesByCountryId(cameroun.getId())).thenReturn(50L);

            Optional<CountryDto> result = geoService.findCountryByIsoCode("cmr");

            assertThat(result).isPresent();
            assertThat(result.get().name()).isEqualTo("Cameroun");
        }
    }

    // ========================================================================
    // findNearbyVillages
    // ========================================================================

    @Nested
    @DisplayName("findNearbyVillages — Villages a proximite (PostGIS)")
    class FindNearbyVillagesTests {

        @Test
        @DisplayName("Doit plafonner la limite a 50")
        void shouldCapLimitAt50() {
            when(villageRepository.findNearby(anyDouble(), anyDouble(), anyDouble(), anyInt()))
                    .thenReturn(Collections.emptyList());

            geoService.findNearbyVillages(4.0, 11.0, 10.0, 200);

            verify(villageRepository).findNearby(4.0, 11.0, 10000.0, 50);
        }

        @Test
        @DisplayName("Doit convertir les km en metres")
        void shouldConvertKmToMeters() {
            when(villageRepository.findNearby(anyDouble(), anyDouble(), anyDouble(), anyInt()))
                    .thenReturn(Collections.emptyList());

            geoService.findNearbyVillages(4.0, 11.0, 25.0, 10);

            verify(villageRepository).findNearby(4.0, 11.0, 25000.0, 10);
        }
    }

    // ========================================================================
    // getCulturalLinks
    // ========================================================================

    @Nested
    @DisplayName("getCulturalLinks — Liens culturels")
    class GetCulturalLinksTests {

        @Test
        @DisplayName("Doit filtrer par linkType quand fourni")
        void shouldFilterByLinkType() {
            UUID villageId = UUID.randomUUID();
            when(culturalLinkRepository.findByVillageIdAndLinkType(villageId, "dialect"))
                    .thenReturn(Collections.emptyList());

            geoService.getCulturalLinks(villageId, "dialect");

            verify(culturalLinkRepository).findByVillageIdAndLinkType(villageId, "dialect");
            verify(culturalLinkRepository, never()).findByVillageId(any());
        }

        @Test
        @DisplayName("Doit retourner tous les liens quand linkType est null")
        void shouldReturnAllWhenLinkTypeNull() {
            UUID villageId = UUID.randomUUID();
            when(culturalLinkRepository.findByVillageId(villageId)).thenReturn(Collections.emptyList());

            geoService.getCulturalLinks(villageId, null);

            verify(culturalLinkRepository).findByVillageId(villageId);
        }
    }

    // ========================================================================
    // getLanguagesByCountry
    // ========================================================================

    @Nested
    @DisplayName("getLanguagesByCountry — Langues par pays")
    class GetLanguagesByCountryTests {

        @Test
        @DisplayName("Doit retourner les langues triees (officielles d'abord)")
        void shouldReturnLanguagesSortedByOfficial() {
            UUID countryId = UUID.randomUUID();
            UUID langId1 = UUID.randomUUID();
            UUID langId2 = UUID.randomUUID();

            CountryLanguage cl1 = CountryLanguage.builder()
                    .countryId(countryId).languageId(langId1).official(false).build();
            CountryLanguage cl2 = CountryLanguage.builder()
                    .countryId(countryId).languageId(langId2).official(true).build();

            Language lang1 = Language.builder().name("Bassa").nameLocal("Bassa").build();
            lang1.setId(langId1);
            Language lang2 = Language.builder().name("Francais").nameLocal("Francais").build();
            lang2.setId(langId2);

            when(countryLanguageRepository.findByCountryIsoCode("CMR")).thenReturn(List.of(cl1, cl2));
            when(languageRepository.findAllByIdIn(List.of(langId1, langId2))).thenReturn(List.of(lang1, lang2));

            List<LanguageDto> result = geoService.getLanguagesByCountry("cmr");

            assertThat(result).hasSize(2);
            assertThat(result.get(0).official()).isTrue();
            assertThat(result.get(0).name()).isEqualTo("Francais");
            assertThat(result.get(1).official()).isFalse();
        }
    }

    // ========================================================================
    // globalSearch
    // ========================================================================

    @Nested
    @DisplayName("globalSearch — Recherche globale multi-niveaux")
    class GlobalSearchTests {

        @Test
        @DisplayName("Doit rechercher dans continents, pays et villages")
        void shouldSearchAcrossAllLevels() {
            Continent africa = Continent.builder().code("AF").name("Afrique").build();
            africa.setId(UUID.randomUUID());

            Country cameroun = Country.builder().isoCode("CMR").name("Cameroun").continentCode("AF").build();
            cameroun.setId(UUID.randomUUID());

            Village bafia = Village.builder().name("Bafia").country("Cameroun").build();
            bafia.setId(UUID.randomUUID());

            when(continentRepository.findAll()).thenReturn(List.of(africa));
            when(countryRepository.findAll()).thenReturn(List.of(cameroun));
            when(villageRepository.findByNameContainingIgnoreCase("a")).thenReturn(List.of(bafia));

            List<GeoSearchResultDto> results = geoService.globalSearch("a");

            assertThat(results).isNotEmpty();
            assertThat(results.stream().map(GeoSearchResultDto::type).toList())
                    .contains("CONTINENT", "COUNTRY", "VILLAGE");
        }

        @Test
        @DisplayName("Doit retourner une liste vide quand aucun resultat")
        void shouldReturnEmptyListWhenNoResults() {
            when(continentRepository.findAll()).thenReturn(Collections.emptyList());
            when(countryRepository.findAll()).thenReturn(Collections.emptyList());
            when(villageRepository.findByNameContainingIgnoreCase("xyz")).thenReturn(Collections.emptyList());

            List<GeoSearchResultDto> results = geoService.globalSearch("xyz");

            assertThat(results).isEmpty();
        }
    }
}
