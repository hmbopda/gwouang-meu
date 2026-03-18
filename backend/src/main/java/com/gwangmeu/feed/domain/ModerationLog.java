package com.gwangmeu.feed.domain;

import com.gwangmeu.shared.audit.AuditEntity;
import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

/**
 * Audit trail immuable de chaque decision de moderation.
 * Consulte par les ambassadeurs via GET /api/v1/moderation/logs.
 */
@Entity
@Table(name = "moderation_logs", indexes = {
        @Index(name = "idx_modlog_post_id",      columnList = "post_id"),
        @Index(name = "idx_modlog_moderator_id", columnList = "moderator_id")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ModerationLog extends AuditEntity {

    @Column(name = "post_id", nullable = false)
    private UUID postId;

    @Column(name = "moderator_id")
    private UUID moderatorId;

    @Enumerated(EnumType.STRING)
    @Column(name = "action", nullable = false, length = 20)
    private ModerationStatus action;

    @Column(columnDefinition = "TEXT")
    private String note;
}
