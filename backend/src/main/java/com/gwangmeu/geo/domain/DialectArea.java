package com.gwangmeu.geo.domain;

import com.gwangmeu.shared.audit.AuditEntity;
import jakarta.persistence.*;
import lombok.*;

/**
 * Aire dialectale cross-frontieres.
 * Ex: Aire Bassa (Cameroun + diaspora mondiale) → cours communs, dictionnaire partage.
 */
@Entity
@Table(name = "dialect_areas")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DialectArea extends AuditEntity {

    @Column(nullable = false, unique = true)
    private String name; // "Bassa", "Beti", "Yoruba", "Lingala"...

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "speaker_count_estimate")
    private Integer speakerCountEstimate;

    @Column(name = "language_family")
    private String languageFamily; // "Bantu", "Afro-Asiatique", etc.

    @Column(name = "iso_639_code", length = 10)
    private String iso639Code;
}
