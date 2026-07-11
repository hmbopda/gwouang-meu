package com.gwangmeu.village.dto;

import com.gwangmeu.village.domain.VillagePermission;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;
import java.util.UUID;

/** Corps de POST /roles : attribue un role delegue a un utilisateur. */
public record GrantRoleRequest(
        @NotNull UUID userId,
        @NotNull @Size(min = 1, max = 80) String title,
        List<VillagePermission> permissions
) {}
