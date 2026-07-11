package com.gwangmeu.village.domain;

import com.gwangmeu.shared.audit.AuditEntity;
import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

/**
 * Demande d'adhesion a un village. Peut etre auto-approuvee via la genealogie
 * (ex. « parent deja membre ») ou validee manuellement par un notable.
 * Une seule demande par (village, utilisateur) : contrainte unique.
 */
@Entity
@Table(name = "village_join_requests",
        uniqueConstraints = @UniqueConstraint(
                name = "uq_vjr_village_user", columnNames = {"village_id", "user_id"}),
        indexes = @Index(name = "idx_vjr_village_status", columnList = "village_id, status"))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VillageJoinRequest extends AuditEntity {

    @Column(name = "village_id", nullable = false)
    private UUID villageId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private VillageJoinStatus status;

    /** Motif fourni par le demandeur. */
    @Column(length = 300)
    private String reason;

    /** Motif d'auto-approbation (ex. « parent deja membre »). */
    @Column(name = "auto_reason", length = 200)
    private String autoReason;

    @Column(name = "decided_by")
    private UUID decidedBy;

    @Column(name = "decided_at")
    private Instant decidedAt;
}
