package com.gwangmeu.geo.application;

import com.gwangmeu.geo.domain.Continent;
import com.gwangmeu.geo.domain.Country;
import com.gwangmeu.geo.domain.CountryLanguage;
import com.gwangmeu.geo.domain.Language;
import com.gwangmeu.geo.dto.*;
import com.gwangmeu.geo.infrastructure.*;
import com.gwangmeu.village.infrastructure.VillageRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
@Transactional(readOnly = true)
@RequiredArgsConstructor
class GeoServiceImpl implements GeoService {

    private static final int NEARBY_HARD_LIMIT = 50;
    private static final int SEARCH_RESULT_LIMIT = 20;

    private final ContinentRepository continentRepository;
    private final CountryRepository   countryRepository;
    private final CulturalLinkRepository culturalLinkRepository;
    private final LanguageRepository  languageRepository;
    private final CountryLanguageRepository countryLanguageRepository;
    private final VillageRepository   villageRepository;

    // ── Continents ──────────────────────────────────────────────────────────

    @Override
    public List<ContinentDto> getAllContinents() {
        return continentRepository.findAll().stream()
                .map(c -> ContinentDto.from(c,
                        continentRepository.countCountriesByContinentCode(c.getCode()),
                        continentRepository.countVillagesByContinentCode(c.getCode())))
                .toList();
    }

    @Override
    public Optional<ContinentDto> findContinentByCode(String code) {
        return continentRepository.findByCode(code.toUpperCase())
                .map(c -> ContinentDto.from(c,
                        continentRepository.countCountriesByContinentCode(c.getCode()),
                        continentRepository.countVillagesByContinentCode(c.getCode())));
    }

    // ── Countries ────────────────────────────────────────────────────────────

    @Override
    public List<CountryDto> getAllCountries() {
        return countryRepository.findAll().stream()
                .map(c -> CountryDto.from(c, countryRepository.countVillagesByCountryId(c.getId())))
                .toList();
    }

    @Override
    public List<CountryDto> getCountriesByContinent(String continentCode) {
        return countryRepository.findByContinentCode(continentCode.toUpperCase()).stream()
                .map(c -> CountryDto.from(c, countryRepository.countVillagesByCountryId(c.getId())))
                .toList();
    }

    @Override
    public Optional<CountryDto> findCountryByIsoCode(String isoCode) {
        return countryRepository.findByIsoCode(isoCode.toUpperCase())
                .map(c -> CountryDto.from(c, countryRepository.countVillagesByCountryId(c.getId())));
    }

    // ── Nearby (PostGIS) ─────────────────────────────────────────────────────

    @Override
    public List<NearbyVillageDto> findNearbyVillages(double lat, double lng, double radiusKm, int limit) {
        int cappedLimit = Math.min(limit, NEARBY_HARD_LIMIT);
        double radiusMeters = radiusKm * 1000.0;
        return villageRepository.findNearby(lat, lng, radiusMeters, cappedLimit).stream()
                .map(NearbyVillageDto::from)
                .toList();
    }

    // ── Cultural links ────────────────────────────────────────────────────────

    @Override
    public List<CulturalLinkDto> getCulturalLinks(UUID villageId, String linkType) {
        var links = (linkType != null && !linkType.isBlank())
                ? culturalLinkRepository.findByVillageIdAndLinkType(villageId, linkType)
                : culturalLinkRepository.findByVillageId(villageId);
        return links.stream().map(CulturalLinkDto::from).toList();
    }

    // ── Languages ───────────────────────────────────────────────────────────────

    @Override
    public List<LanguageDto> getLanguagesByCountry(String isoCode) {
        List<CountryLanguage> links = countryLanguageRepository.findByCountryIsoCode(isoCode.toUpperCase());
        List<UUID> languageIds = links.stream().map(CountryLanguage::getLanguageId).toList();
        Map<UUID, Language> languageMap = languageRepository.findAllByIdIn(languageIds).stream()
                .collect(Collectors.toMap(Language::getId, l -> l));

        return links.stream()
                .filter(cl -> languageMap.containsKey(cl.getLanguageId()))
                .map(cl -> {
                    Language l = languageMap.get(cl.getLanguageId());
                    return new LanguageDto(l.getId(), l.getName(), l.getNameLocal(), cl.isOfficial());
                })
                .sorted((a, b) -> {
                    if (a.official() != b.official()) return a.official() ? -1 : 1;
                    return a.name().compareToIgnoreCase(b.name());
                })
                .toList();
    }

    // ── Global search ─────────────────────────────────────────────────────────

    @Override
    public List<GeoSearchResultDto> globalSearch(String query) {
        String q = query.trim();
        List<GeoSearchResultDto> results = new ArrayList<>();

        // Continents
        continentRepository.findAll().stream()
                .filter(c -> containsIgnoreCase(c.getName(), q) || containsIgnoreCase(c.getCode(), q))
                .limit(5)
                .map(c -> GeoSearchResultDto.continent(c.getId(), c.getCode(), c.getName(), c.getCoverImageUrl()))
                .forEach(results::add);

        // Countries
        countryRepository.findAll().stream()
                .filter(c -> containsIgnoreCase(c.getName(), q) || containsIgnoreCase(c.getIsoCode(), q))
                .limit(10)
                .map(c -> GeoSearchResultDto.country(c.getId(), c.getIsoCode(), c.getName(),
                        c.getContinentCode(), c.getFlagUrl()))
                .forEach(results::add);

        // Villages (name search)
        villageRepository.findByNameContainingIgnoreCase(q).stream()
                .limit(SEARCH_RESULT_LIMIT - results.size())
                .map(v -> GeoSearchResultDto.village(v.getId(), v.getName(), v.getCountry(),
                        v.getCoverImageUrl(), v.getLatitude(), v.getLongitude()))
                .forEach(results::add);

        return results;
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private boolean containsIgnoreCase(String text, String query) {
        return text != null && text.toLowerCase().contains(query.toLowerCase());
    }
}
