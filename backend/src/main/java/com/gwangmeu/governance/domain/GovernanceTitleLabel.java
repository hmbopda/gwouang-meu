package com.gwangmeu.governance.domain;

import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

/**
 * Libellé i18n + forme d'adresse d'un {@link GovernanceTitle} (« Fɔ' »/« Sa Majesté »,
 * « Laamiiɗo », « Okyeame »…). Le libellé résolu selon la langue du lecteur ; jamais
 * le code brut. Index GIN trigram côté DB pour un typeahead multilingue.
 */
@Entity
@Table(name = "governance_title_labels")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GovernanceTitleLabel {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "title_id", nullable = false)
    private UUID titleId;

    @Column(nullable = false, length = 20)
    private String locale;

    @Column(nullable = false, length = 120)
    private String label;

    @Column(length = 120)
    private String honorific;

    @Column(length = 500)
    private String description;
}
