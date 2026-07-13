package com.gwangmeu.feed.domain;

import com.gwangmeu.shared.audit.AuditEntity;
import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

/** Réaction (« bénédiction ») d'un utilisateur sur un commentaire — une seule par (comment, user). */
@Entity
@Table(name = "comment_reactions", indexes = {
        @Index(name = "idx_comment_reactions_comment", columnList = "comment_id"),
        @Index(name = "idx_comment_reactions_user", columnList = "user_id")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CommentReaction extends AuditEntity {

    @Column(name = "comment_id", nullable = false)
    private UUID commentId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;
}
