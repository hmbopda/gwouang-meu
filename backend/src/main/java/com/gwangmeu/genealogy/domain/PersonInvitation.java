package com.gwangmeu.genealogy.domain;

import com.gwangmeu.genealogy.domain.enums.InvitationStatusEnum;
import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "person_invitations")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PersonInvitation {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "person_id", nullable = false)
    private UUID personId;

    @Column(length = 255)
    private String email;

    @Column(length = 30)
    private String phone;

    @Column(unique = true, nullable = false, length = 100)
    private String token;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private InvitationStatusEnum status = InvitationStatusEnum.PENDING;

    @Column(name = "invited_by", nullable = false)
    private UUID invitedBy;

    @Column(name = "invitation_type", nullable = false, length = 20)
    @Builder.Default
    private String invitationType = "PARENT";

    @Column(name = "knows_inviter")
    private Boolean knowsInviter;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private Instant createdAt = Instant.now();

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;

    @Column(name = "accepted_at")
    private Instant acceptedAt;
}
