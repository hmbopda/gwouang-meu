package com.gwangmeu.village.domain;

import com.gwangmeu.shared.audit.AuditEntity;
import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

/**
 * Titulaire d'un siège de gouvernance (généralise village_chiefs : le chef courant
 * = titulaire du siège apex, mais aussi reine-mère, notables, porte-parole…).
 * `user_id` facultatif : les titulaires historiques sont saisis au nom libre.
 * Au plus un titulaire courant par siège. Table village_office_holders (V61).
 */
@Entity
@Table(name = "village_office_holders")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VillageOfficeHolder extends AuditEntity {

    @Column(name = "office_id", nullable = false)
    private UUID officeId;

    /** Dénormalisé pour une requête directe par village (snapshot, listes). */
    @Column(name = "village_id", nullable = false)
    private UUID villageId;

    /** Compte utilisateur lié (facultatif) — NULL = titulaire historique sans compte. */
    @Column(name = "user_id")
    private UUID userId;

    @Column(name = "display_name", nullable = false, length = 200)
    private String displayName;

    /** Snapshot du libellé résolu au moment de la saisie → historique stable. */
    @Column(name = "title_label", length = 120)
    private String titleLabel;

    @Column(length = 12)
    private String gender;

    /** Règne OU mandat (ex-reign_start). */
    @Column(name = "term_start")
    private Integer termStart;

    @Column(name = "term_end")
    private Integer termEnd;

    @Column(name = "is_current", nullable = false)
    @Builder.Default
    private boolean current = false;

    /** « 12ᵉ du nom ». */
    @Column(nullable = false)
    @Builder.Default
    private Integer ordinal = 0;

    @Column(name = "avatar_url", length = 500)
    private String avatarUrl;

    @Column(name = "note", columnDefinition = "TEXT")
    private String note;

    /** HERITAGE_CURATED | COMMUNITY_DECLARED | COLONIAL_APPOINTED. */
    @Column(nullable = false, length = 20)
    @Builder.Default
    private String source = "HERITAGE_CURATED";
}
