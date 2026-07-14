package com.gwangmeu.admin;

import java.util.UUID;

/** Vue admin d'un utilisateur (back-office super-admin). */
public record AdminUserDto(
        UUID id,
        String email,
        String displayName,
        String role,
        boolean active
) {}
