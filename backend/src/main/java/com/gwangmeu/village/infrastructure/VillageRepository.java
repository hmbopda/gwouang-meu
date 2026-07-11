package com.gwangmeu.village.infrastructure;

import com.gwangmeu.geo.infrastructure.NearbyVillageProjection;
import com.gwangmeu.village.domain.Village;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface VillageRepository extends JpaRepository<Village, UUID> {

    /** Communauté déjà matérialisée pour une chefferie du référentiel (dédoublonnage). */
    Optional<Village> findByChefferieId(UUID chefferieId);

    List<Village> findByCountryIgnoreCase(String country);

    List<Village> findByContinentCode(String continentCode);

    List<Village> findByNameContainingIgnoreCase(String name);

    List<Village> findByPrimaryDialectIgnoreCase(String dialect);

    Page<Village> findByCountryId(UUID countryId, Pageable pageable);

    Page<Village> findByContinentCode(String continentCode, Pageable pageable);

    /**
     * Recherche PostGIS de villages dans un rayon donne (ST_DWithin).
     * Utilise la conversion ::geography pour calcul en metres sur ellipsoide WGS84.
     * L'index GiST sur ST_MakePoint(longitude, latitude) accelere la requete.
     *
     * @param lat          Latitude du point de reference
     * @param lng          Longitude du point de reference
     * @param radiusMeters Rayon de recherche en metres
     * @param limit        Nombre maximum de resultats
     */
    @Query(value = """
            SELECT v.id,
                   v.name,
                   v.country,
                   v.region,
                   v.latitude,
                   v.longitude,
                   v.cover_image_url    AS coverImageUrl,
                   v.primary_dialect   AS primaryDialect,
                   v.population_estimate AS populationEstimate,
                   ST_Distance(
                       ST_MakePoint(v.longitude, v.latitude)::geography,
                       ST_MakePoint(:lng, :lat)::geography
                   )                   AS distanceMeters
            FROM villages v
            WHERE v.latitude  IS NOT NULL
              AND v.longitude IS NOT NULL
              AND ST_DWithin(
                      ST_MakePoint(v.longitude, v.latitude)::geography,
                      ST_MakePoint(:lng, :lat)::geography,
                      :radiusMeters
                  )
            ORDER BY distanceMeters ASC
            LIMIT :limit
            """, nativeQuery = true)
    List<NearbyVillageProjection> findNearby(
            @Param("lat") double lat,
            @Param("lng") double lng,
            @Param("radiusMeters") double radiusMeters,
            @Param("limit") int limit
    );
}
