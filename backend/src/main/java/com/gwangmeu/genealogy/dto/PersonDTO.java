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
    private String photoUrl;
    private PrivacyEnum privacy;
    private PersonStatusEnum status;
    private UUID userId;
    private List<UUID> villageIds;
    private Instant createdAt;
    private Instant updatedAt;
}
