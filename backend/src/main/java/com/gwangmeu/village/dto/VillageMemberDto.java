package com.gwangmeu.village.dto;

import com.gwangmeu.village.domain.VillageSubscription;

import java.time.Instant;
import java.util.UUID;

public record VillageMemberDto(
        UUID userId,
        String displayName,
        String avatarUrl,
        VillageSubscription.SubscriptionType type,
        Instant joinedAt
) {}
