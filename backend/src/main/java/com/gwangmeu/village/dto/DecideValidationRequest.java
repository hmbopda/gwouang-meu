package com.gwangmeu.village.dto;

import jakarta.validation.constraints.NotNull;

/** Corps de POST /validations/{id}/decide : approuve (true) ou rejette (false). */
public record DecideValidationRequest(
        @NotNull Boolean approve
) {}
