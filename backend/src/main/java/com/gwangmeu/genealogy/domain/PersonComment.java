package com.gwangmeu.genealogy.domain;

import com.gwangmeu.shared.audit.AuditEntity;
import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

@Entity
@Table(name = "person_comments", indexes = {
        @Index(name = "idx_person_comments_person_id", columnList = "person_id"),
        @Index(name = "idx_person_comments_author_id", columnList = "author_id")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PersonComment extends AuditEntity {

    @Column(name = "person_id", nullable = false)
    private UUID personId;

    @Column(name = "author_id", nullable = false)
    private UUID authorId;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String content;

    @Column(name = "parent_comment_id")
    private UUID parentCommentId;
}
