package com.gwangmeu.geo.dto;

import java.util.UUID;

public record LanguageDto(
        UUID id,
        String name,
        String nameLocal,
        boolean official
) {}
