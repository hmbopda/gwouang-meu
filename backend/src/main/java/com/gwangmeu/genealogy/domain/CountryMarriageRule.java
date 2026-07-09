package com.gwangmeu.genealogy.domain;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;

/**
 * Referentiel des regles de mariage par pays (lecture seule cote appli).
 * Sert a evaluer la conformite au droit civil du pays de residence/
 * celebration d'une union. Les pays absents sont traites UNKNOWN.
 */
@Entity
@Table(name = "country_marriage_rules")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CountryMarriageRule {

    /** Code pays ISO-3166 alpha-2 (ex: CM, FR). */
    @Id
    @Column(name = "iso2", length = 2)
    private String iso2;

    /** Code pays ISO-3166 alpha-3 (ex: CMR, FRA) — aligne sur la table countries. */
    @Column(name = "iso3", length = 3)
    private String iso3;

    @Column(name = "country_name", length = 100)
    private String countryName;

    /** ALLOWED | CONDITIONAL | FORBIDDEN */
    @Column(name = "polygamy", nullable = false, length = 20)
    private String polygamy;

    /** Liste CSV des regimes admis (ex: MONOGAMY,POLYGAMY,CUSTOMARY). */
    @Column(name = "regimes", columnDefinition = "TEXT")
    private String regimes;

    @Column(name = "legal_basis", columnDefinition = "TEXT")
    private String legalBasis;

    @Column(name = "source_url", columnDefinition = "TEXT")
    private String sourceUrl;

    @Column(name = "is_advisory")
    @Builder.Default
    private boolean isAdvisory = true;

    @Column(name = "updated_at")
    private Instant updatedAt;
}
