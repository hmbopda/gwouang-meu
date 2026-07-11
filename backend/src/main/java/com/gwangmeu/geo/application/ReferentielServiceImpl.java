package com.gwangmeu.geo.application;

import com.gwangmeu.geo.dto.ArrondissementDto;
import com.gwangmeu.geo.dto.ChefferieDto;
import com.gwangmeu.geo.dto.DepartmentDto;
import com.gwangmeu.geo.dto.RegionDto;
import com.gwangmeu.geo.infrastructure.ChefferieRepository;
import com.gwangmeu.geo.infrastructure.GeoArrondissementRepository;
import com.gwangmeu.geo.infrastructure.GeoDepartmentRepository;
import com.gwangmeu.geo.infrastructure.GeoRegionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Implementation read-only du referentiel territorial camerounais.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ReferentielServiceImpl implements ReferentielService {

    private static final String CM = "CM";

    private final GeoRegionRepository regionRepository;
    private final GeoDepartmentRepository departmentRepository;
    private final GeoArrondissementRepository arrondissementRepository;
    private final ChefferieRepository chefferieRepository;

    @Override
    public List<RegionDto> getRegions() {
        return regionRepository.findByCountryIso2OrderByName(CM).stream()
                .map(RegionDto::from)
                .toList();
    }

    @Override
    public List<DepartmentDto> getDepartmentsByRegion(String regionCode) {
        return departmentRepository.findByCountryIso2AndRegionCodeOrderByName(CM, regionCode).stream()
                .map(DepartmentDto::from)
                .toList();
    }

    @Override
    public List<ArrondissementDto> getArrondissementsByDepartment(String departmentCode) {
        return arrondissementRepository.findByCountryIso2AndDepartmentCodeOrderByName(CM, departmentCode).stream()
                .map(ArrondissementDto::from)
                .toList();
    }

    @Override
    public List<ChefferieDto> getChefferiesByDepartment(String departmentCode, String q, int limit) {
        Pageable pageable = PageRequest.of(0, limit);
        return chefferieRepository.searchByDepartment(CM, departmentCode, pattern(q), pageable).stream()
                .map(ChefferieDto::from)
                .toList();
    }

    @Override
    public List<ChefferieDto> searchChefferiesByRegion(String regionName, String q, int limit) {
        Pageable pageable = PageRequest.of(0, limit);
        return chefferieRepository.searchByRegion(CM, regionName, pattern(q), pageable).stream()
                .map(ChefferieDto::from)
                .toList();
    }

    @Override
    public List<ChefferieDto> searchChefferiesGlobal(String q, int limit) {
        // Une recherche globale exige un terme d'au moins 2 caractères : sinon
        // la similarité floue ramènerait tout le référentiel.
        if (q == null || q.trim().length() < 2) {
            return List.of();
        }
        return chefferieRepository.searchGlobalFuzzy(CM, q.trim(), limit).stream()
                .map(ChefferieDto::from)
                .toList();
    }

    /**
     * Motif SQL LIKE : « % » (tout) si q vide/blanc, sinon « %q% ». Evite un
     * parametre NULL non type cote PostgreSQL et garde le filtre toujours applicable.
     */
    private static String pattern(String q) {
        return (q == null || q.isBlank()) ? "%" : "%" + q.trim() + "%";
    }
}
