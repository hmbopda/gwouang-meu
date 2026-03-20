package com.gwangmeu.chat.domain;

import com.gwangmeu.shared.audit.AuditEntity;
import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

@Entity
@Table(name = "chat_groups",
        indexes = @Index(name = "idx_chat_group_village", columnList = "village_id"))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ChatGroup extends AuditEntity {

    @Column(name = "village_id", nullable = false)
    private UUID villageId;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private GroupType type = GroupType.GENERAL;

    @Column(name = "created_by", nullable = false)
    private UUID createdBy;

    public enum GroupType {
        GENERAL,
        COMMISSION,
        DIRECT
    }
}
