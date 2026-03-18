package com.gwangmeu.user.application;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateUserCommand(
        @Email @NotBlank String email,
        @NotBlank @Size(min = 3, max = 30) String username,
        String displayName,
        String preferredLanguage,
        @NotBlank String supabaseUid
) {}
