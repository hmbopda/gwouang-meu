package com.gwangmeu.village.domain;

import com.gwangmeu.shared.audit.AuditEntity;
import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

@Entity
@Table(name = "village_subscriptions",
        uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "village_id"}),
        indexes = {
                @Index(name = "idx_vsub_user_id", columnList = "user_id"),
                @Index(name = "idx_vsub_village_id", columnList = "village_id")
        })
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VillageSubscription extends AuditEntity {

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "village_id", nullable = false)
    private UUID villageId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private SubscriptionType type;

    public enum SubscriptionType {
        FOLLOW,
        MEMBER,
        AMBASSADOR
    }
}
