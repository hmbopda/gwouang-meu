package com.gwangmeu.geo.domain;

import com.gwangmeu.shared.audit.AuditEntity;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Connexion culturelle transversale entre deux villages (cross-pays).
 * Ex: Village Bassa au Cameroun ↔ Village Bassa de la diaspora France.
 * Detectee manuellement ou par Claude AI (created_by_ai = true).
 *
 * Contrainte UNIQUE(village_a_id, village_b_id, link_type).
 */
@Entity
@Table(name = "cultural_links", indexes = {
        @Index(name = "idx_cultural_links_a",    columnList = "village_a_id"),
        @Index(name = "idx_cultural_links_b",    columnList = "village_b_id"),
        @Index(name = "idx_cultural_links_type", columnList = "link_type")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CulturalLink extends AuditEntity {

    @Column(name = "village_a_id", nullable = false)
    private UUID villageAId;

    @Column(name = "village_b_id", nullable = false)
    private UUID villageBId;

    /**
     * Type de lien : dialect, cuisine, rites, history, migration, language
     */
    @Column(name = "link_type", nullable = false, length = 50)
    private String linkType;

    /**
     * Score de similarite entre 0.00 et 1.00.
     * Calcule par Claude AI (ai-module) ou saisi manuellement.
     */
    @Column(name = "similarity_score", precision = 3, scale = 2)
    @Builder.Default
    private BigDecimal similarityScore = BigDecimal.valueOf(0.50);

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "created_by_ai")
    @Builder.Default
    private boolean createdByAi = false;
}
