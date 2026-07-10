package com.gwangmeu.genealogy.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.gwangmeu.shared.domain.enums.GenderEnum;
import com.gwangmeu.genealogy.domain.enums.PersonStatusEnum;
import com.gwangmeu.genealogy.domain.enums.PrivacyEnum;
import lombok.*;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PersonDTO {
    private UUID id;
    private String firstName;
    private String lastName;
    private String maidenName;
    private GenderEnum gender;
    private LocalDate birthDate;
    private String birthPlace;
    private LocalDate deathDate;
    @JsonProperty("isAlive")
    private boolean isAlive;
    private String clan;
    private String totem;
    private String nativeLanguage;
    private String religion;
    private String profession;
    private String email;
    private String phone;
    private String maritalStatus;
    // ── Origine : ancre de la lignee ──
    /** Village d'origine (texte libre, complete villageIds). */
    private String originVillage;
    /** Ville d'origine. */
    private String originCity;
    /** Region d'origine. */
    private String originRegion;
    /** Pays d'origine, ISO-3166 alpha-2 (ex: CM, FR). */
    private String originCountry;
    // ── Residence : evolution (migration, situation actuelle) ──
    /** Ville de residence actuelle. */
    private String residenceCity;
    /** Pays de residence actuelle, ISO-3166 alpha-2 (ex: CM, FR) — droit applicable des unions. */
    private String residenceCountry;
    /** Regime matrimonial declare (MONOGAMY, POLYGAMY, CUSTOMARY, DE_FACTO, UNKNOWN). */
    private String maritalRegime;
    private String photoUrl;
    private PrivacyEnum privacy;
    private PersonStatusEnum status;
    private UUID userId;
    private List<UUID> villageIds;
    private Instant createdAt;
    private Instant updatedAt;

    // ── Rattachement genealogique (rempli quand la personne est exposee comme enfant) ──
    /** Id de la mere (parent_role MOTHER) — null si inconnu ou non enfant. */
    private String motherId;
    /** Id du pere (parent_role FATHER) — null si inconnu ou non enfant. */
    private String fatherId;
    /** Id de l'union rattachant l'enfant a la bonne co-epouse — null si non derivable. */
    private String unionId;
}
