package com.gwangmeu.governance.domain;

import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

/**
 * Libellé i18n d'un {@link GovernanceModel} (galerie du wizard, multilingue).
 * Clé naturelle (model_id, locale) portée par une contrainte UNIQUE ; PK technique UUID.
 */
@Entity
@Table(name = "governance_model_labels")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GovernanceModelLabel {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "model_id", nullable = false)
    private UUID modelId;

    @Column(nullable = false, length = 20)
    private String locale;

    @Column(nullable = false, length = 120)
    private String label;

    @Column(length = 500)
    private String description;
}
