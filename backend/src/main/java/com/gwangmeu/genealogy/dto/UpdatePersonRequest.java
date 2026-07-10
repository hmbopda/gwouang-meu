package com.gwangmeu.genealogy.dto;

import com.gwangmeu.genealogy.domain.enums.PrivacyEnum;
import lombok.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdatePersonRequest {
    private String firstName;
    private String lastName;
    private String maidenName;
    private LocalDate birthDate;
    private String birthPlace;
    private LocalDate deathDate;
    private String clan;
    private String totem;
    private String nativeLanguage;
    private String religion;
    private String profession;
    private String biography;
    private String photoUrl;
    private PrivacyEnum privacy;
    private List<UUID> villageIds;
    // ── Origine : ancre de la lignee ──
    private String originVillage;
    private String originCity;
    private String originRegion;
    /** Pays d'origine, ISO-3166 alpha-2. */
    private String originCountry;
    // ── Residence : evolution (migration, situation actuelle) ──
    private String residenceCity;
    /** Pays de residence actuelle, ISO-3166 alpha-2 — droit applicable des unions. */
    private String residenceCountry;
}
