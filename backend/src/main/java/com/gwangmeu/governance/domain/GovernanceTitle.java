package com.gwangmeu.governance.domain;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/**
 * Une CHARGE dans la structure de leadership d'un template (le chef, la reine-mère,
 * la société régulatrice, un rang de notables, un porte-parole…). « Chef ou pas »,
 * rangs, cardinalité, succession, médiation d'accès = des colonnes, jamais des if.
 */
@Entity
@Table(name = "governance_titles")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GovernanceTitle {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "model_id", nullable = false)
    private UUID modelId;

    @Column(nullable = false, length = 60)
    private String code;

    /** FK vers role_kinds.code (soft-ref par code, pas de relation JPA). */
    @Column(name = "role_kind", nullable = false, length = 40)
    private String roleKind;

    @Column(nullable = false)
    @Builder.Default
    private Integer tier = 0;

    @Column(nullable = false)
    @Builder.Default
    private Integer rank = 100;

    @Column(name = "is_apex", nullable = false)
    @Builder.Default
    private boolean apex = false;

    @Column(name = "card_min", nullable = false)
    @Builder.Default
    private Integer cardMin = 0;

    /** NULL = illimité (classe de notables) ; 1 = siège unique. */
    @Column(name = "card_max")
    private Integer cardMax;

    @Column(name = "gender_rule", nullable = false, length = 10)
    @Builder.Default
    private String genderRule = "ANY";

    @Column(name = "mediates_head", nullable = false)
    @Builder.Default
    private boolean mediatesHead = false;

    @Column(length = 24)
    private String succession;

    @Column(name = "designating_title_code", length = 60)
    private String designatingTitleCode;

    @Column(name = "regalia_key", length = 40)
    private String regaliaKey;

    @Column(name = "perm_bundle", nullable = false, length = 300)
    @Builder.Default
    private String permBundle = "";

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb", nullable = false)
    @Builder.Default
    private Map<String, Object> config = new HashMap<>();

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    @Builder.Default
    private Instant updatedAt = Instant.now();
}
