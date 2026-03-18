package com.gwangmeu.feed.dto;

import com.gwangmeu.feed.domain.ModerationStatus;
import io.swagger.v3.oas.annotations.media.Schema;

import java.time.Instant;
import java.util.UUID;

@Schema(description = "Publication du fil d'actualite")
public record PostDto(
        @Schema(description = "Identifiant unique") UUID id,
        @Schema(description = "Auteur du post") UUID authorId,
        @Schema(description = "Village associe") UUID villageId,
        @Schema(description = "Contenu textuel") String content,
        @Schema(description = "URL du media joint") String mediaUrl,
        @Schema(description = "Statut de moderation") ModerationStatus moderationStatus,
        @Schema(description = "Post epingle") boolean pinned,
        @Schema(description = "Nombre de reactions") int reactionCount,
        @Schema(description = "Nombre de commentaires") int commentCount,
        @Schema(description = "Date de creation") Instant createdAt
) {}
