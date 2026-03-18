package com.gwangmeu.geo.infrastructure;

import com.gwangmeu.geo.domain.Continent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.Optional;
import java.util.UUID;

public interface ContinentRepository extends JpaRepository<Continent, UUID> {

    Optional<Continent> findByCode(String code);

    /** Nombre de pays references pour un continent donne. */
    @Query("SELECT COUNT(c) FROM Country c WHERE c.continentCode = :continentCode")
    long countCountriesByContinentCode(String continentCode);

    /** Nombre total de villages pour un continent via pays (country string). */
    @Query("""
            SELECT COUNT(v) FROM Village v
            WHERE v.continentCode = :continentCode
            """)
    long countVillagesByContinentCode(String continentCode);
}
