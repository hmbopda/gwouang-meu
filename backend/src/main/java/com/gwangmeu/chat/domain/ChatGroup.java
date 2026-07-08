package com.gwangmeu.chat.domain;

import com.gwangmeu.shared.audit.AuditEntity;
import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

@Entity
@Table(name = "chat_groups",
        indexes = {
                @Index(name = "idx_chat_group_village", columnList = "village_id"),
                @Index(name = "idx_chat_group_family_clan", columnList = "family_clan")
        })
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ChatGroup extends AuditEntity {

    /**
     * Village de rattachement — null pour un groupe à portée famille
     * (voir {@link #familyClan}).
     */
    @Column(name = "village_id")
    private UUID villageId;

    /**
     * Clan / lignée de rattachement pour les discussions de FAMILLE
     * (null pour les groupes de village).
     */
    @Column(name = "family_clan", length = 100)
    private String familyClan;

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
        DIRECT,
        FAMILY
    }
}
