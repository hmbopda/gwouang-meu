package com.gwangmeu.feed.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

@Schema(description = "Requete de signalement d'un post")
public record FlagPostRequest(

        @NotBlank(message = "La raison du signalement est obligatoire")
        @Size(min = 5, max = 500, message = "La raison doit contenir entre 5 et 500 caracteres")
        @Schema(description = "Raison du signalement", example = "Contenu offensant envers la culture du village")
        String reason
) {}
