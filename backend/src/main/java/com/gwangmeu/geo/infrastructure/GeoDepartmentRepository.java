package com.gwangmeu.geo.infrastructure;

import com.gwangmeu.geo.domain.GeoDepartment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface GeoDepartmentRepository extends JpaRepository<GeoDepartment, UUID> {

    List<GeoDepartment> findByCountryIso2AndRegionCodeOrderByName(String countryIso2, String regionCode);
}
