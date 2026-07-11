package com.gwangmeu.village.dto;

import com.gwangmeu.village.domain.VillageValidation;
import com.gwangmeu.village.domain.VillageValidationKind;
import com.gwangmeu.village.domain.VillageValidationStatus;

import java.time.Instant;
import java.util.UUID;

/** Element culturel / successoral soumis a validation, expose a l'IHM. */
public record ValidationDto(
        UUID id,
        UUID villageId,
        VillageValidationKind kind,
        String title,
        String detail,
        UUID submittedBy,
        VillageValidationStatus status,
        UUID decidedBy,
        Instant decidedAt,
        Instant createdAt
) {
    public static ValidationDto from(VillageValidation v) {
        return new ValidationDto(
                v.getId(),
                v.getVillageId(),
                v.getKind(),
                v.getTitle(),
                v.getDetail(),
                v.getSubmittedBy(),
                v.getStatus(),
                v.getDecidedBy(),
                v.getDecidedAt(),
                v.getCreatedAt()
        );
    }
}
