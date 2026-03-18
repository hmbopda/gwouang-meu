package com.gwangmeu.feed.infrastructure;

import com.gwangmeu.feed.domain.PostReaction;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface PostReactionRepository extends JpaRepository<PostReaction, UUID> {

    Optional<PostReaction> findByPostIdAndUserId(UUID postId, UUID userId);

    int countByPostId(UUID postId);

    void deleteByPostIdAndUserId(UUID postId, UUID userId);
}
