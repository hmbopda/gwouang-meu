package com.gwangmeu.village.domain;

import com.gwangmeu.shared.audit.AuditEntity;
import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

@Entity
@Table(name = "villages", indexes = {
        @Index(name = "idx_villages_country", columnList = "country"),
        @Index(name = "idx_villages_continent_code", columnList = "continent_code")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Village extends AuditEntity {

    @Column(nullable = false)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(nullable = false)
    private String country;

    private String region;

    @Column(name = "continent_code", length = 10)
    private String continentCode;

    @Column(name = "cover_image_url")
    private String coverImageUrl;

    private Double latitude;
    private Double longitude;

    @Column(name = "founded_year")
    private Integer foundedYear;

    @Column(name = "population_estimate")
    private Integer populationEstimate;

    @Column(name = "primary_dialect")
    private String primaryDialect;

    @Column(name = "creator_id")
    private UUID creatorId;

    @Column(name = "is_verified")
    @Builder.Default
    private boolean verified = false;

    @Column(name = "member_count")
    @Builder.Default
    private int memberCount = 0;

    @Column(name = "historical_summary", columnDefinition = "TEXT")
    private String historicalSummary;

    @Column(name = "country_id")
    private UUID countryId;

    /** Chefferie du référentiel matérialisée en communauté (dédoublonnage). */
    @Column(name = "chefferie_id")
    private UUID chefferieId;

    // ── V61 : snapshot de gouvernance (perf n°1 : chef inline, 0 requête) ──────
    // Maintenu à l'écriture d'un titulaire apex. Toute liste de villages renvoie
    // le chef inline → le N+1 chief() disparaît.

    @Column(name = "gov_authority_model", length = 20)
    private String govAuthorityModel;

    /** Nom du titulaire apex courant (NULL = vacant). */
    @Column(name = "gov_apex_holder", length = 200)
    private String govApexHolder;

    /** Titre résolu en langue primaire ('Fɔ'','Laamiiɗo'). */
    @Column(name = "gov_apex_title", length = 120)
    private String govApexTitle;

    @Column(name = "gov_apex_user_id")
    private UUID govApexUserId;

    @Column(name = "gov_apex_avatar", length = 500)
    private String govApexAvatar;

    @Column(name = "gov_theme_token", length = 40)
    private String govThemeToken;

    @Column(name = "gov_honorific", length = 60)
    private String govHonorific;

    @Column(name = "gov_apex_is_vacant", nullable = false)
    @Builder.Default
    private boolean govApexIsVacant = true;
}
