package com.gwangmeu.chat.dto;

import com.gwangmeu.chat.domain.ChatMessage;

import java.time.Instant;
import java.util.UUID;

public record ChatMessageDto(
        UUID id,
        UUID groupId,
        UUID senderId,
        String senderName,
        String senderAvatarUrl,
        String content,
        ChatMessage.MessageType type,
        Instant createdAt
) {}
