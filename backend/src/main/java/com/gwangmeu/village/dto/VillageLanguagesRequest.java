package com.gwangmeu.village.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;

import java.util.List;
import java.util.UUID;

/**
 * Definit (remplace) l'ensemble des langues d'un village.
 * Au plus un {@code isPrimary = true} est conserve (le premier si plusieurs).
 */
@Schema(description = "Definit les langues d'un village (remplace l'existant)")
public record VillageLanguagesRequest(
        @Schema(description = "Langues du village") List<@Valid Item> languages
) {

    @Schema(description = "Langue d'un village avec ses drapeaux")
    public record Item(
            @NotNull @Schema(description = "Identifiant de la langue") UUID languageId,
            @Schema(description = "Langue principale") boolean isPrimary,
            @Schema(description = "Ordre d'affichage") Integer ordinal
    ) {}
}
