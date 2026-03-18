package com.gwangmeu.geo.infrastructure;

import com.gwangmeu.geo.domain.CountryLanguage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.UUID;

public interface CountryLanguageRepository extends JpaRepository<CountryLanguage, UUID> {

    @Query("""
        SELECT cl FROM CountryLanguage cl
        JOIN Country c ON cl.countryId = c.id
        WHERE c.isoCode = :isoCode
        ORDER BY cl.official DESC
    """)
    List<CountryLanguage> findByCountryIsoCode(String isoCode);

    List<CountryLanguage> findByCountryId(UUID countryId);
}
