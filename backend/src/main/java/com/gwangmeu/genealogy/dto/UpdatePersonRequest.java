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
}
