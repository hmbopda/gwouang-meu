package com.gwangmeu.user.application;

import java.util.UUID;

public record UpdateProfileCommand(
        String displayName,
        String bio,
        String avatarUrl,
        String preferredLanguage,
        UUID originVillageId
) {}
