package com.gwangmeu.feed.dto;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "Statistiques de moderation pour un village")
public record ModerationStatsDto(

        @Schema(description = "Posts en attente de moderation")       long pendingCount,
        @Schema(description = "Posts signales (3+ flags)")            long flaggedCount,
        @Schema(description = "Posts approuves")                      long approvedCount,
        @Schema(description = "Posts rejetes")                        long rejectedCount,
        @Schema(description = "Posts shadow-bannes")                  long shadowBannedCount
) {}
