package com.gwangmeu.genealogy.dto;

import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InvitePersonRequest {
    @NotNull private UUID personId;
    private String email;
    private String phone;
    private String invitationType; // PARENT ou SPOUSE (défaut: PARENT)
}
