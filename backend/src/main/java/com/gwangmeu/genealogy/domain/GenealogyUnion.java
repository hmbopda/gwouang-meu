package com.gwangmeu.genealogy.domain;

import com.gwangmeu.genealogy.domain.enums.EndReasonEnum;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "unions")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GenealogyUnion {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "husband_id", nullable = false)
    private UUID husbandId;

    @Column(name = "wife_id", nullable = false)
    private UUID wifeId;

    @Column(name = "union_types", nullable = false, columnDefinition = "text[]")
    @Builder.Default
    private String[] unionTypes = new String[0];

    @Column(name = "union_order", nullable = false)
    @Builder.Default
    private int unionOrder = 1;

    @Column(name = "start_date")
    private LocalDate startDate;

    @Column(name = "end_date")
    private LocalDate endDate;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    @Column(name = "end_reason")
    private EndReasonEnum endReason;

    @Column(name = "is_dot_paid", nullable = false)
    @Builder.Default
    private boolean isDotPaid = false;

    @Column(name = "dot_date")
    private LocalDate dotDate;

    @Column(name = "dot_paid_by")
    private UUID dotPaidBy;

    @Column(name = "dot_description", columnDefinition = "TEXT")
    private String dotDescription;

    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "dot_witnesses", columnDefinition = "uuid[]")
    private UUID[] dotWitnesses;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private Instant createdAt = Instant.now();

    @Column(name = "created_by", nullable = false)
    private UUID createdBy;

    // ── Dissolution (divorce / décès) ──

    @Column(name = "status", nullable = false, length = 30)
    @Builder.Default
    private String status = "ACTIVE";

    @Column(name = "dissolution_type", length = 20)
    private String dissolutionType; // DIVORCE ou DEATH

    @Column(name = "dissolution_doc_url", length = 500)
    private String dissolutionDocUrl;

    @Column(name = "dissolution_requested_by")
    private UUID dissolutionRequestedBy;

    @Column(name = "dissolution_requested_at")
    private Instant dissolutionRequestedAt;

    @Column(name = "dissolution_confirmed_at")
    private Instant dissolutionConfirmedAt;

    @Column(name = "dispute_reason", columnDefinition = "TEXT")
    private String disputeReason;

    @Transient
    public boolean isActive() {
        return this.endDate == null && "ACTIVE".equals(this.status);
    }
}
