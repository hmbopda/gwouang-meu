package com.gwangmeu.genealogy.dto;

import com.gwangmeu.shared.domain.enums.GenderEnum;
import com.gwangmeu.genealogy.domain.enums.PrivacyEnum;
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
public class CreatePersonRequest {
    @NotBlank private String firstName;
    @NotBlank private String lastName;
    private String maidenName;
    @NotNull private GenderEnum gender;
    private LocalDate birthDate;
    private String birthPlace;
    private String clan;
    private String totem;
    private String nativeLanguage;
    private String email;
    private String phone;
    private String religion;
    private String profession;
    private LocalDate deathDate;
    private String biography;
    private List<UUID> villageIds;
    private PrivacyEnum privacy;
}
