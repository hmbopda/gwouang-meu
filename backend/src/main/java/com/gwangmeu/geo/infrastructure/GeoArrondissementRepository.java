package com.gwangmeu.geo.infrastructure;

import com.gwangmeu.geo.domain.GeoArrondissement;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface GeoArrondissementRepository extends JpaRepository<GeoArrondissement, UUID> {

    List<GeoArrondissement> findByCountryIso2AndDepartmentCodeOrderByName(String countryIso2, String departmentCode);
}
