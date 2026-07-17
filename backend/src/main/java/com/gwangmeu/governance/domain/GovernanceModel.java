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
 * TEMPLATE de gouvernance partagé par aire culturelle (grassfields_fondom,
 * fulani_lamidat, yoruba_obaship, akan_stool, igbo_council, generic_council…).
 * La structure est O(templates), jamais O(chefferies) : chaque chefferie ne
 * porte qu'une FK vers ce modèle. Attributs de comportement uniquement — aucun
 * nom de culture ni titre codé en dur.
 */
@Entity
@Table(name = "governance_models")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GovernanceModel {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, length = 80)
    private String code;

    @Column(name = "model_version", nullable = false)
    @Builder.Default
    private Integer modelVersion = 1;

    @Column(name = "scope_type", nullable = false, length = 20)
    @Builder.Default
    private String scopeType = "GLOBAL";

    @Column(name = "scope_key", length = 80)
    private String scopeKey;

    @Column(name = "country_iso2", length = 2)
    private String countryIso2;

    @Column(name = "authority_model", nullable = false, length = 20)
    @Builder.Default
    private String authorityModel = "MONOCEPHALIC";

    @Column(name = "head_cardinality", nullable = false)
    @Builder.Default
    private Integer headCardinality = 1;

    @Column(nullable = false, length = 20)
    @Builder.Default
    private String sacrality = "RESPECT";

    @Column(name = "honorific_style", nullable = false, length = 20)
    @Builder.Default
    private String honorificStyle = "RESPECT";

    @Column(nullable = false, length = 20)
    @Builder.Default
    private String lineality = "PATRILINEAL";

    @Column(nullable = false)
    @Builder.Default
    private boolean revocable = false;

    @Column(name = "access_mediated", nullable = false)
    @Builder.Default
    private boolean accessMediated = false;

    @Column(name = "regalia_key", nullable = false, length = 40)
    @Builder.Default
    private String regaliaKey = "none";

    @Column(name = "theme_token", nullable = false, length = 40)
    @Builder.Default
    private String themeToken = "gov.neutral";

    @Column(name = "rotation_years")
    private Integer rotationYears;

    @Column(nullable = false, length = 16)
    @Builder.Default
    private String status = "PUBLISHED";

    @Column(name = "is_default", nullable = false)
    @Builder.Default
    private boolean defaultModel = false;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb", nullable = false)
    @Builder.Default
    private Map<String, Object> config = new HashMap<>();

    @Column(nullable = false, length = 64)
    @Builder.Default
    private String checksum = "";

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    @Builder.Default
    private Instant updatedAt = Instant.now();
}
