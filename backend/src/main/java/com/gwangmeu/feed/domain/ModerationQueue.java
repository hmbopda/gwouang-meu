package com.gwangmeu.feed.domain;

import com.gwangmeu.shared.audit.AuditEntity;
import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

/**
 * Entree dans la file d'attente de moderation.
 * Creee lors d'un signalement (flag) par un utilisateur.
 * Consultee par les moderateurs via GET /api/v1/moderation/queue.
 */
@Entity
@Table(name = "moderation_queue", indexes = {
        @Index(name = "idx_modqueue_post_id",    columnList = "post_id"),
        @Index(name = "idx_modqueue_village_id", columnList = "village_id")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ModerationQueue extends AuditEntity {

    @Column(name = "post_id", nullable = false)
    private UUID postId;

    @Column(name = "village_id")
    private UUID villageId;

    @Column(columnDefinition = "TEXT")
    private String reason;

    @Column(name = "reporter_id")
    private UUID reporterId;
}
