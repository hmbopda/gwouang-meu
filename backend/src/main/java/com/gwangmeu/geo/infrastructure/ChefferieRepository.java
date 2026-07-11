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
     * Chefferies d'un departement (obligatoire) avec filtre optionnel sur la
     * denomination (ILIKE %q%). Tri par numero, pagine (limit via Pageable).
     * Quand q est null/vide, aucun filtre denomination n'est applique.
     */
    @Query("""
            SELECT c FROM Chefferie c
            WHERE c.countryIso2 = :countryIso2
              AND c.departmentCode = :departmentCode
              AND (:q IS NULL OR LOWER(c.denomination) LIKE LOWER(CONCAT('%', :q, '%')))
            ORDER BY c.numero
            """)
    List<Chefferie> searchByDepartment(
            @Param("countryIso2") String countryIso2,
            @Param("departmentCode") String departmentCode,
            @Param("q") String q,
            Pageable pageable);

    /**
     * Recherche large : chefferies d'une region (region_name obligatoire) avec
     * filtre optionnel sur la denomination (ILIKE %q%). Tri par numero, pagine.
     */
    @Query("""
            SELECT c FROM Chefferie c
            WHERE c.countryIso2 = :countryIso2
              AND c.regionName = :regionName
              AND (:q IS NULL OR LOWER(c.denomination) LIKE LOWER(CONCAT('%', :q, '%')))
            ORDER BY c.numero
            """)
    List<Chefferie> searchByRegion(
            @Param("countryIso2") String countryIso2,
            @Param("regionName") String regionName,
            @Param("q") String q,
            Pageable pageable);
}
