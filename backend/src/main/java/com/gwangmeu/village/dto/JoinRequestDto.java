package com.gwangmeu.village.dto;

import com.gwangmeu.village.domain.VillageJoinRequest;
import com.gwangmeu.village.domain.VillageJoinStatus;

import java.time.Instant;
import java.util.UUID;

/** Demande d'adhesion a un village, exposee a l'IHM. */
public record JoinRequestDto(
        UUID id,
        UUID villageId,
        UUID userId,
        VillageJoinStatus status,
        String reason,
        String autoReason,
        UUID decidedBy,
        Instant decidedAt,
        Instant createdAt
) {
    public static JoinRequestDto from(VillageJoinRequest r) {
        return new JoinRequestDto(
                r.getId(),
                r.getVillageId(),
                r.getUserId(),
                r.getStatus(),
                r.getReason(),
                r.getAutoReason(),
                r.getDecidedBy(),
                r.getDecidedAt(),
                r.getCreatedAt()
        );
    }
}
