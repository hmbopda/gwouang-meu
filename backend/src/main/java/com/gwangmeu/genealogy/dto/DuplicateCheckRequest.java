package com.gwangmeu.genealogy.dto;

import com.gwangmeu.shared.domain.enums.GenderEnum;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DuplicateCheckRequest {
    @NotBlank private String firstName;
    @NotBlank private String lastName;
    @NotNull private GenderEnum gender;
    private LocalDate birthDate;
    private String email;
}
