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
        @Schema(description = "Date de creation") Instant createdAt,
        // ── Enrichissement (fil communautaire) ──
        @Schema(description = "Nom affiche de l'auteur") String authorDisplayName,
        @Schema(description = "Avatar de l'auteur") String authorAvatarUrl,
        @Schema(description = "Role de l'auteur") String authorRole,
        @Schema(description = "Nom du village (si post de village)") String villageName,
        @Schema(description = "L'utilisateur courant a-t-il reagi ?") boolean likedByMe
) {}
