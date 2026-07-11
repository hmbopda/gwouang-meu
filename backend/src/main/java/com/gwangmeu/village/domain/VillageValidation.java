package com.gwangmeu.village.domain;

import com.gwangmeu.shared.audit.AuditEntity;
import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

/**
 * Element culturel ou successoral soumis a validation pour un village
 * (clan, chefferie, ligne de chefs, succession).
 */
@Entity
@Table(name = "village_validations",
        indexes = @Index(name = "idx_vval_village_status", columnList = "village_id, status"))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VillageValidation extends AuditEntity {

    @Column(name = "village_id", nullable = false)
    private UUID villageId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private VillageValidationKind kind;

    @Column(nullable = false, length = 160)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String detail;

    @Column(name = "submitted_by", nullable = false)
    private UUID submittedBy;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private VillageValidationStatus status = VillageValidationStatus.PENDING;

    @Column(name = "decided_by")
    private UUID decidedBy;

    @Column(name = "decided_at")
    private Instant decidedAt;
}
