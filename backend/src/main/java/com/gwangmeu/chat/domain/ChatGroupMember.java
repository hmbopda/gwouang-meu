package com.gwangmeu.chat.domain;

import com.gwangmeu.shared.audit.AuditEntity;
import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

@Entity
@Table(name = "chat_group_members",
        uniqueConstraints = @UniqueConstraint(columnNames = {"group_id", "user_id"}),
        indexes = {
                @Index(name = "idx_chat_member_group", columnList = "group_id"),
                @Index(name = "idx_chat_member_user", columnList = "user_id")
        })
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ChatGroupMember extends AuditEntity {

    @Column(name = "group_id", nullable = false)
    private UUID groupId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private MemberRole role = MemberRole.MEMBER;

    public enum MemberRole {
        ADMIN,
        MEMBER
    }
}
