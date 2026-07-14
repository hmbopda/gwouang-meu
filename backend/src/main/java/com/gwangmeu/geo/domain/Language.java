package com.gwangmeu.geo.domain;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "languages")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Language {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, unique = true, length = 100)
    private String name;

    @Column(name = "name_local", length = 100)
    private String nameLocal;

    /** Slug stable (ex. « basaa »), unique lorsqu'il est renseigne. Ajoute en V57. */
    @Column(name = "code", length = 30)
    private String code;

    /** Nom francais de la langue (ex. « Bassa »). Ajoute en V57. */
    @Column(name = "french_name", length = 100)
    private String frenchName;

    /** Code ISO 639-3 (ex. « bas »), nullable. Ajoute en V57. */
    @Column(name = "iso639_3", length = 3)
    private String iso6393;

    /** Region / aire linguistique indicative. Ajoute en V57. */
    @Column(name = "region", length = 120)
    private String region;

    /** Langue active dans le referentiel. Ajoute en V57. */
    @Column(name = "active", nullable = false)
    @Builder.Default
    private boolean active = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @PrePersist
    void prePersist() {
        if (createdAt == null) createdAt = Instant.now();
    }
}
