package com.gwangmeu.village.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import java.util.UUID;

/** Notable = siège non-apex + son titulaire courant. */
@Schema(description = "Notable (siège + titulaire courant)")
public record NotableDto(
        UUID officeId,
        String displayName,
        String title,
        int rank,
        Integer termStart,
        UUID userId
) {}
