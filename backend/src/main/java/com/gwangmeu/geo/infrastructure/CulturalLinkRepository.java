package com.gwangmeu.geo.infrastructure;

import com.gwangmeu.geo.domain.CulturalLink;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface CulturalLinkRepository extends JpaRepository<CulturalLink, UUID> {

    /**
     * Tous les liens d'un village (il peut etre cote A ou cote B).
     */
    @Query("SELECT cl FROM CulturalLink cl " +
           "WHERE cl.villageAId = :villageId OR cl.villageBId = :villageId " +
           "ORDER BY cl.similarityScore DESC")
    List<CulturalLink> findByVillageId(@Param("villageId") UUID villageId);

    /**
     * Liens filtres par type (dialect, cuisine, rites, history...).
     */
    @Query("SELECT cl FROM CulturalLink cl " +
           "WHERE (cl.villageAId = :villageId OR cl.villageBId = :villageId) " +
           "AND cl.linkType = :linkType " +
           "ORDER BY cl.similarityScore DESC")
    List<CulturalLink> findByVillageIdAndLinkType(@Param("villageId") UUID villageId,
                                                  @Param("linkType") String linkType);

    /**
     * Meilleurs liens par score (pour le dashboard culturel).
     */
    List<CulturalLink> findTop10ByOrderBySimilarityScoreDesc();
}
