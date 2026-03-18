package com.gwangmeu.feed.infrastructure;

import com.gwangmeu.feed.domain.ModerationStatus;
import com.gwangmeu.feed.domain.Post;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface PostRepository extends JpaRepository<Post, UUID> {

    List<Post> findByVillageIdAndModerationStatus(UUID villageId, ModerationStatus status, Pageable pageable);

    List<Post> findByAuthorId(UUID authorId, Pageable pageable);

    List<Post> findByModerationStatus(ModerationStatus status, Pageable pageable);

    List<Post> findByVillageIdAndModerationStatusIn(UUID villageId,
                                                    List<ModerationStatus> statuses,
                                                    Pageable pageable);

    long countByVillageIdAndModerationStatus(UUID villageId, ModerationStatus status);
}
