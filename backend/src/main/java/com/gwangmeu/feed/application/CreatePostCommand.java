package com.gwangmeu.feed.application;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record CreatePostCommand(
        UUID authorId,
        UUID villageId,
        @NotBlank @Size(max = 5000) String content,
        String mediaUrl
) {}
