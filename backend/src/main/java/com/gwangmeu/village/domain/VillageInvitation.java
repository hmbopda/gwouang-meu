package com.gwangmeu.village.domain;

import com.gwangmeu.shared.audit.AuditEntity;
import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

/**
 * Invitation a rejoindre un village. Emise par un notable/chef (invitedBy) vers
 * un utilisateur existant (invitedUserId) ou une adresse email (invitedEmail).
 * L'un des deux ciblages est renseigne. Statut : PENDING/ACCEPTED/DECLINED/EXPIRED.
 */
@Entity
@Table(name = "village_invitations",
        uniqueConstraints = @UniqueConstraint(
                name = "uq_vinv_village_user", columnNames = {"village_id", "invited_user_id"}),
        indexes = {
                @Index(name = "idx_vinv_user_status", columnList = "invited_user_id, status"),
                @Index(name = "idx_vinv_village_status", columnList = "village_id, status")
        })
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VillageInvitation extends AuditEntity {

    @Column(name = "village_id", nullable = false)
    private UUID villageId;

    /** Utilisateur cible (NULL si invitation par email). */
    @Column(name = "invited_user_id")
    private UUID invitedUserId;

    /** Email cible (utilise quand invitedUserId est NULL). */
    @Column(name = "invited_email", length = 200)
    private String invitedEmail;

    @Column(name = "invited_by", nullable = false)
    private UUID invitedBy;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private VillageInvitationStatus status;

    /** Message d'accompagnement facultatif. */
    @Column(length = 300)
    private String message;

    @Column(name = "decided_at")
    private Instant decidedAt;
}
