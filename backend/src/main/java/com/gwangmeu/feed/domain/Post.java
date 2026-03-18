package com.gwangmeu.feed.domain;

import com.gwangmeu.shared.audit.AuditEntity;
import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "posts", indexes = {
        @Index(name = "idx_posts_author_id", columnList = "author_id"),
        @Index(name = "idx_posts_village_id", columnList = "village_id"),
        @Index(name = "idx_posts_moderation_status", columnList = "moderation_status")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Post extends AuditEntity {

    @Column(name = "author_id", nullable = false)
    private UUID authorId;

    @Column(name = "village_id")
    private UUID villageId;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String content;

    @Column(name = "media_url")
    private String mediaUrl;

    @Enumerated(EnumType.STRING)
    @Column(name = "moderation_status", nullable = false)
    @Builder.Default
    private ModerationStatus moderationStatus = ModerationStatus.PENDING;

    @Column(name = "moderation_reason")
    private String moderationReason;

    @Column(name = "moderation_score")
    private Double moderationScore;

    @Column(name = "is_pinned")
    @Builder.Default
    private boolean pinned = false;

    @Column(name = "reaction_count")
    @Builder.Default
    private int reactionCount = 0;

    @Column(name = "comment_count")
    @Builder.Default
    private int commentCount = 0;

    @Column(name = "flag_count")
    @Builder.Default
    private int flagCount = 0;

    @Column(name = "moderation_note")
    private String moderationNote;

    @Column(name = "moderated_by")
    private UUID moderatedBy;

    @Column(name = "moderated_at")
    private Instant moderatedAt;
}
