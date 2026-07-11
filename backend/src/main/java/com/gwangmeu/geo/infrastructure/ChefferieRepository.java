package com.gwangmeu.geo.infrastructure;

import com.gwangmeu.geo.domain.Chefferie;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface ChefferieRepository extends JpaRepository<Chefferie, UUID> {

    /**
     * Chefferies d'un departement (obligatoire) avec filtre sur la denomination.
     * Tri par numero, pagine (limit via Pageable). Le service passe un motif
     * SQL deja pret (q = "%" pour tout, "%texte%" sinon) : evite un parametre
     * NULL non type (PostgreSQL « could not determine data type of parameter »).
     */
    @Query("""
            SELECT c FROM Chefferie c
            WHERE c.countryIso2 = :countryIso2
              AND c.departmentCode = :departmentCode
              AND LOWER(c.denomination) LIKE LOWER(:pattern)
            ORDER BY c.numero
            """)
    List<Chefferie> searchByDepartment(
            @Param("countryIso2") String countryIso2,
            @Param("departmentCode") String departmentCode,
            @Param("pattern") String pattern,
            Pageable pageable);

    /**
     * Recherche large : chefferies d'une region (region_name obligatoire) avec
     * filtre sur la denomination. Meme convention de motif que searchByDepartment.
     */
    @Query("""
            SELECT c FROM Chefferie c
            WHERE c.countryIso2 = :countryIso2
              AND c.regionName = :regionName
              AND LOWER(c.denomination) LIKE LOWER(:pattern)
            ORDER BY c.numero
            """)
    List<Chefferie> searchByRegion(
            @Param("countryIso2") String countryIso2,
            @Param("regionName") String regionName,
            @Param("pattern") String pattern,
            Pageable pageable);
}
