package com.gwangmeu.village.domain;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

/**
 * En-tête de gouvernance d'un village (surcharge locale du template adopté).
 * PK = village_id (une gouvernance par village). Créé quand un village adopte
 * un modèle (copy-on-adopt) ; `gov_version` est bumpé à chaque écriture → clé de
 * cache. Table village_governance (migration V61).
 */
@Entity
@Table(name = "village_governance")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VillageGovernance {

    @Id
    @Column(name = "village_id")
    private UUID villageId;

    /** Template de gouvernance adopté (governance_models.id) ; NULL = sur-mesure. */
    @Column(name = "model_id")
    private UUID modelId;

    @Column(name = "authority_model", nullable = false, length = 20)
    @Builder.Default
    private String authorityModel = "MONOCEPHALIC";

    /** Langue des titres de CETTE chefferie. */
    @Column(name = "locale_primary", nullable = false, length = 20)
    @Builder.Default
    private String localePrimary = "fr";

    @Column(name = "honorific_style", nullable = false, length = 20)
    @Builder.Default
    private String honorificStyle = "RESPECT";

    @Column(name = "theme_token", nullable = false, length = 40)
    @Builder.Default
    private String themeToken = "gov.neutral";

    @Column(name = "gov_version", nullable = false)
    @Builder.Default
    private Integer govVersion = 1;

    @Column(name = "is_published", nullable = false)
    @Builder.Default
    private boolean published = false;

    @Column(name = "updated_by")
    private UUID updatedBy;

    @Column(name = "updated_at", nullable = false)
    @Builder.Default
    private Instant updatedAt = Instant.now();
}
