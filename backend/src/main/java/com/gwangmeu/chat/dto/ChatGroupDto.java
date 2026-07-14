package com.gwangmeu.chat.dto;

import com.gwangmeu.chat.domain.ChatGroup;

import java.time.Instant;
import java.util.UUID;

public record ChatGroupDto(
        UUID id,
        UUID villageId,
        String familyClan,
        String name,
        String description,
        ChatGroup.GroupType type,
        int memberCount,
        UUID createdBy,
        Instant createdAt,
        /** Extrait tronqué du dernier message de la conversation (null si aucun message). */
        String lastMessagePreview,
        /** Date du dernier message, pour trier par activité récente (null si aucun message). */
        Instant lastMessageAt
) {}
