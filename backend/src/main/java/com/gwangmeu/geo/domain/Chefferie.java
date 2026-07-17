package com.gwangmeu.geo.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/**
 * Chefferie traditionnelle (read-only). Table chefferies (migrations V44 + V60).
 * Pas de colonnes created_at/updated_at → n'etend PAS AuditEntity.
 *
 * V60 : `degre` devient nullable (déblocage multi-pays — le MINAT camerounais
 * n'est plus le seul modèle). Colonnes de gouvernance ajoutées (template lié,
 * titre structuré, nom propre, niveau générique, classification nationale brute).
 * La provenance MINAT (degre, acte, region_name) reste conservée.
 */
@Entity
@Table(name = "chefferies")
@Getter
@NoArgsConstructor
public class Chefferie {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "country_iso2", nullable = false, length = 2)
    private String countryIso2;

    /** Degré MINAT (Cameroun) — nullable depuis V60 (autres pays sans ce concept). */
    @Column(name = "degre")
    private Short degre;

    @Column(name = "region_name", nullable = false, length = 150)
    private String regionName;

    @Column(name = "department_name", length = 150)
    private String departmentName;

    @Column(name = "department_code", length = 20)
    private String departmentCode;

    @Column(name = "numero")
    private Integer numero;

    @Column(name = "denomination", nullable = false, length = 250)
    private String denomination;

    @Column(name = "acte", length = 500)
    private String acte;

    // ── V60 : gouvernance + décomposition structurée ──────────────────────────

    /** Template de gouvernance rattaché (governance_models.id) ; NULL = non déduit. */
    @Column(name = "governance_model_id")
    private UUID governanceModelId;

    /** Titre de tête structuré ('fon','lamido','sultan'…) — remplace la regex runtime. */
    @Column(name = "apex_title_code", length = 60)
    private String apexTitleCode;

    /** Dénomination sans le préfixe administratif ('Bandenkop'). */
    @Column(name = "proper_name", length = 250)
    private String properName;

    /** Rang administratif générique multi-pays (remplace le concept 'degre'). */
    @Column(name = "admin_level")
    private Integer adminLevel;

    /** Classification nationale brute (ex. { minat: { degre, acte, region } }). */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "classification", columnDefinition = "jsonb", nullable = false)
    private Map<String, Object> classification = new HashMap<>();

    @Column(name = "department_id")
    private UUID departmentId;

    @Column(name = "region_id")
    private UUID regionId;

    @Column(name = "source", length = 32)
    private String source;

    @Column(name = "source_ref", length = 120)
    private String sourceRef;

    /** IMPORTED | INFERRED | MANUAL — provenance du titre déduit. */
    @Column(name = "title_source", length = 16)
    private String titleSource;
}
