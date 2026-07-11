package com.gwangmeu.village.dto;

import com.gwangmeu.village.domain.VillageValidationKind;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** Corps de POST /validations : soumet un element culturel/successoral a valider. */
public record SubmitValidationRequest(
        @NotNull VillageValidationKind kind,
        @NotNull @Size(min = 1, max = 160) String title,
        String detail
) {}
