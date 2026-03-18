package com.gwangmeu.feed.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import java.time.Instant;
import java.util.UUID;

@Schema(description = "Commentaire sur un post")
public record CommentDto(
        @Schema(description = "Identifiant unique") UUID id,
        @Schema(description = "Post commente") UUID postId,
        @Schema(description = "Auteur") UUID authorId,
        @Schema(description = "Contenu") String content,
        @Schema(description = "Commentaire parent (pour les reponses)") UUID parentCommentId,
        @Schema(description = "Date de creation") Instant createdAt
) {}
