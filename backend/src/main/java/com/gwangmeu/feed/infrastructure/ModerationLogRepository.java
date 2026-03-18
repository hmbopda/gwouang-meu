package com.gwangmeu.feed.infrastructure;

import com.gwangmeu.feed.domain.ModerationLog;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface ModerationLogRepository extends JpaRepository<ModerationLog, UUID> {

    List<ModerationLog> findByPostIdOrderByCreatedAtDesc(UUID postId);

    /**
     * Historique des logs pour un village — joint avec posts pour filtrer par village_id.
     */
    @Query("SELECT ml FROM ModerationLog ml " +
           "JOIN Post p ON ml.postId = p.id " +
           "WHERE p.villageId = :villageId " +
           "ORDER BY ml.createdAt DESC")
    List<ModerationLog> findByVillageId(@Param("villageId") UUID villageId, Pageable pageable);
}
