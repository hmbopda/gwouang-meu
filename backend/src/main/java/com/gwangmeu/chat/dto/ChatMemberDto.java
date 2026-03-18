package com.gwangmeu.chat.dto;

import com.gwangmeu.chat.domain.ChatGroupMember;

import java.time.Instant;
import java.util.UUID;

public record ChatMemberDto(
        UUID userId,
        String displayName,
        String avatarUrl,
        ChatGroupMember.MemberRole role,
        Instant joinedAt
) {}
