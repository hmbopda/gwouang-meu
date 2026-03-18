package com.gwangmeu.geo.infrastructure;

import com.gwangmeu.geo.domain.Country;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface CountryRepository extends JpaRepository<Country, UUID> {

    Optional<Country> findByIsoCode(String isoCode);

    List<Country> findByContinentCode(String continentCode);

    /** Nombre de villages enregistres pour un pays donne (par country_id FK). */
    @Query("SELECT COUNT(v) FROM Village v WHERE v.countryId = :countryId")
    long countVillagesByCountryId(UUID countryId);
}
