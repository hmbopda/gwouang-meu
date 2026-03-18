package com.gwangmeu.genealogy.dto;

import com.gwangmeu.shared.domain.enums.GenderEnum;
import com.gwangmeu.genealogy.domain.enums.ParentTypeEnum;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.time.LocalDate;
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
    private String clan;
    private String email;
    private ParentTypeEnum parentType; // default BIOLOGICAL
    private UUID coParentPersonId;     // ID Person du co-parent (optionnel, declenche la demande d'association)
    private UUID existingPersonId;     // ID Person existante si l'utilisateur a confirme un doublon
}
