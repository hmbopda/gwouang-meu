package com.gwangmeu.village.dto;

import com.gwangmeu.village.domain.VillageMemberRole;
import com.gwangmeu.village.domain.VillagePermission;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** Role delegue d'un membre de village, expose a l'IHM. */
public record VillageRoleDto(
        UUID id,
        UUID villageId,
        UUID userId,
        String title,
        List<VillagePermission> permissions,
        UUID grantedBy,
        Instant createdAt,
        Instant updatedAt
) {
    public static VillageRoleDto from(VillageMemberRole role) {
        return new VillageRoleDto(
                role.getId(),
                role.getVillageId(),
                role.getUserId(),
                role.getTitle(),
                List.copyOf(role.getPermissionSet()),
                role.getGrantedBy(),
                role.getCreatedAt(),
                role.getUpdatedAt()
        );
    }
}
