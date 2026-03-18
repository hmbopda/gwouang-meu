package com.gwangmeu.chat.dto;

import com.gwangmeu.chat.domain.ChatGroup;

import java.time.Instant;
import java.util.UUID;

public record ChatGroupDto(
        UUID id,
        UUID villageId,
        String name,
        String description,
        ChatGroup.GroupType type,
        int memberCount,
        UUID createdBy,
        Instant createdAt
) {}
