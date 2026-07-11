package com.gwangmeu.geo.application;

import com.gwangmeu.geo.dto.ArrondissementDto;
import com.gwangmeu.geo.dto.ChefferieDto;
import com.gwangmeu.geo.dto.DepartmentDto;
import com.gwangmeu.geo.dto.RegionDto;

import java.util.List;

/**
 * Referentiel territorial camerounais (read-only) : regions, departements,
 * arrondissements, chefferies. country_iso2 = 'CM'.
 */
public interface ReferentielService {

    List<RegionDto> getRegions();

    List<DepartmentDto> getDepartmentsByRegion(String regionCode);

    List<ArrondissementDto> getArrondissementsByDepartment(String departmentCode);

    List<ChefferieDto> getChefferiesByDepartment(String departmentCode, String q, int limit);

    List<ChefferieDto> searchChefferiesByRegion(String regionName, String q, int limit);

    /**
     * Recherche globale et floue d'une chefferie par nom, sans dérouler la
     * cascade. Accent-insensible + tolérante aux fautes de frappe.
     */
    List<ChefferieDto> searchChefferiesGlobal(String q, int limit);
}
