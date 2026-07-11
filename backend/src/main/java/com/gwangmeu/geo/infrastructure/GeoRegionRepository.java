package com.gwangmeu.geo.infrastructure;

import com.gwangmeu.geo.domain.GeoRegion;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface GeoRegionRepository extends JpaRepository<GeoRegion, UUID> {

    List<GeoRegion> findByCountryIso2OrderByName(String countryIso2);
}
