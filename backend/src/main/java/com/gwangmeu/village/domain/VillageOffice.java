package com.gwangmeu.village.domain;

import com.gwangmeu.shared.audit.AuditEntity;
import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

/**
 * Siège de gouvernance dans un village (chef, reine-mère, un rang de notables,
 * porte-parole…), matérialisé depuis un template puis éditable localement.
 * Table village_offices (migration V61). Au plus un siège apex par village.
 */
@Entity
@Table(name = "village_offices")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VillageOffice extends AuditEntity {

    @Column(name = "village_id", nullable = false)
    private UUID villageId;

    /** Soft-ref au catalogue (governance_titles.id) ; NULL = siège sur-mesure. */
    @Column(name = "title_id")
    private UUID titleId;

    @Column(name = "office_key", nullable = false, length = 60)
    private String officeKey;

    @Column(name = "label_override", length = 120)
    private String labelOverride;

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

    /** NULL = classe de notables (illimité) ; 1 = trône. */
    @Column(name = "card_max")
    private Integer cardMax;

    @Column(name = "perm_bundle", nullable = false, length = 300)
    @Builder.Default
    private String permBundle = "";

    @Column(length = 24)
    private String succession;
}
