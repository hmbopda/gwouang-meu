package com.gwangmeu.feed.dto;

import com.gwangmeu.feed.domain.ModerationLog;
import com.gwangmeu.feed.domain.ModerationStatus;
import io.swagger.v3.oas.annotations.media.Schema;

import java.time.Instant;
import java.util.UUID;

@Schema(description = "Entree du journal de moderation")
public record ModerationLogDto(

        @Schema(description = "ID du log")           UUID id,
        @Schema(description = "ID du post")          UUID postId,
        @Schema(description = "ID du moderateur")    UUID moderatorId,
        @Schema(description = "Action effectuee")    ModerationStatus action,
        @Schema(description = "Note du moderateur")  String note,
        @Schema(description = "Date de l'action")    Instant createdAt
) {
    public static ModerationLogDto from(ModerationLog log) {
        return new ModerationLogDto(
                log.getId(),
                log.getPostId(),
                log.getModeratorId(),
                log.getAction(),
                log.getNote(),
                log.getCreatedAt()
        );
    }
}
