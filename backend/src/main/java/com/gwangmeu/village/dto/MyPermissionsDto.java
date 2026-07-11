package com.gwangmeu.village.dto;

import com.gwangmeu.village.domain.VillagePermission;

import java.util.List;
import java.util.UUID;

/** Permissions de l'appelant sur un village, pour piloter l'affichage IHM. */
public record MyPermissionsDto(
        UUID villageId,
        UUID userId,
        boolean chief,
        boolean superAdmin,
        List<VillagePermission> permissions
) {}
