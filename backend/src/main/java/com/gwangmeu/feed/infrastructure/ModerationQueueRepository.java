package com.gwangmeu.feed.infrastructure;

import com.gwangmeu.feed.domain.ModerationQueue;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ModerationQueueRepository extends JpaRepository<ModerationQueue, UUID> {

    List<ModerationQueue> findByVillageIdOrderByCreatedAtDesc(UUID villageId, Pageable pageable);

    Optional<ModerationQueue> findByPostIdAndReporterId(UUID postId, UUID reporterId);

    long countByPostId(UUID postId);

    void deleteByPostId(UUID postId);
}
