package com.gwangmeu.feed.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.UUID;

@Schema(description = "Requete de creation d'un post")
public record CreatePostRequest(
        @Schema(description = "Village auquel le post est rattache") UUID villageId,

        @NotBlank @Size(min = 1, max = 5000)
        @Schema(description = "Contenu du post", example = "Vive notre village!") String content,

        @Schema(description = "URL du media joint (image ou video)") String mediaUrl
) {}
