package com.gwangmeu.feed.infrastructure;

import com.gwangmeu.feed.domain.CommentReaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface CommentReactionRepository extends JpaRepository<CommentReaction, UUID> {

    Optional<CommentReaction> findByCommentIdAndUserId(UUID commentId, UUID userId);

    void deleteByCommentIdAndUserId(UUID commentId, UUID userId);

    /** Mes réactions parmi un lot de commentaires — pour « aimé par moi ». */
    List<CommentReaction> findByUserIdAndCommentIdIn(UUID userId, Collection<UUID> commentIds);

    /** Nombre de réactions par commentaire, pour un lot (évite le N+1). */
    @Query("SELECT r.commentId, COUNT(r) FROM CommentReaction r WHERE r.commentId IN :ids GROUP BY r.commentId")
    List<Object[]> countByCommentIds(@Param("ids") Collection<UUID> ids);
}
