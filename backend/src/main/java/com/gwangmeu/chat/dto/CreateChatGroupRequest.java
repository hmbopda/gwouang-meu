package com.gwangmeu.chat.dto;

import com.gwangmeu.chat.domain.ChatGroup;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record CreateChatGroupRequest(
        @NotNull UUID villageId,
        @NotBlank @Size(min = 2, max = 100) String name,
        @Size(max = 500) String description,
        ChatGroup.GroupType type,
        UUID targetUserId
) {}
