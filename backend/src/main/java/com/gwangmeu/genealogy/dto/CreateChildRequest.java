package com.gwangmeu.genealogy.dto;

import com.gwangmeu.shared.domain.enums.GenderEnum;
import com.gwangmeu.genealogy.domain.enums.ParentTypeEnum;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateChildRequest {
    @NotBlank private String firstName;
    @NotBlank private String lastName;
    @NotNull private GenderEnum gender;
    private LocalDate birthDate;
    private String birthPlace;
    private String clan;
    private String totem;
    private String nativeLanguage;
    private String email;
    private List<UUID> villageIds;     // villages rattaches (person_villages)

    // Origine — ancre de la lignee (village, ville, region, pays d'origine).
    private String originVillage;
    private String originCity;
    private String originRegion;
    /** Pays d'origine, ISO-3166 alpha-2 (ex: CM). */
    private String originCountry;

    // Residence — evolution (situation actuelle, droit applicable des unions).
    private String residenceCity;
    /** Pays de residence, ISO-3166 alpha-2 (ex: CM, FR). */
    private String residenceCountry;

    private ParentTypeEnum parentType; // default BIOLOGICAL
    private UUID coParentPersonId;     // ID Person du co-parent (optionnel, declenche la demande d'association)
    private UUID existingPersonId;     // ID Person existante si l'utilisateur a confirme un doublon
}
