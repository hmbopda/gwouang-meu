package com.gwangmeu.genealogy.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AcceptInvitationRequest {
    @NotBlank private String firstName;
    @NotBlank private String lastName;
    private String maidenName;
    private String clan;
    private String totem;
    private String nativeLanguage;
    private String email;
    private String phone;
    private String maritalStatus;   // SINGLE, MARRIED, WIDOWED, DIVORCED
    private LocalDate birthDate;
    private String birthPlace;
    private String religion;
    private String profession;
    private Boolean knowsInviter;
}
