package com.gwangmeu.feed.dto;

import com.gwangmeu.feed.domain.ModerationQueue;
import com.gwangmeu.feed.domain.ModerationStatus;
import io.swagger.v3.oas.annotations.media.Schema;

import java.time.Instant;
import java.util.UUID;

@Schema(description = "Entree dans la file de moderation")
public record ModerationQueueDto(

        @Schema(description = "ID de l'entree dans la file") UUID id,
        @Schema(description = "ID du post signale")          UUID postId,
        @Schema(description = "ID du village")               UUID villageId,
        @Schema(description = "Raison du signalement")       String reason,
        @Schema(description = "ID du signaleur")             UUID reporterId,
        @Schema(description = "Statut actuel du post")       ModerationStatus postStatus,
        @Schema(description = "Nombre de signalements")      int flagCount,
        @Schema(description = "Contenu du post")             String postContent,
        @Schema(description = "Auteur du post")              UUID postAuthorId,
        @Schema(description = "Date du signalement")         Instant createdAt
) {
    public static ModerationQueueDto from(ModerationQueue queue,
                                          ModerationStatus postStatus,
                                          int flagCount,
                                          String postContent,
                                          UUID postAuthorId) {
        return new ModerationQueueDto(
                queue.getId(),
                queue.getPostId(),
                queue.getVillageId(),
                queue.getReason(),
                queue.getReporterId(),
                postStatus,
                flagCount,
                postContent,
                postAuthorId,
                queue.getCreatedAt()
        );
    }
}
