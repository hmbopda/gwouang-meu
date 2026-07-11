package com.gwangmeu.village.application;

import com.gwangmeu.village.domain.VillageMemberRole;
import com.gwangmeu.village.domain.VillagePermission;
import com.gwangmeu.village.infrastructure.VillageMemberRoleRepository;
import com.gwangmeu.village.infrastructure.VillageRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * Gestion des roles delegues d'un village (attribution / revocation / lecture).
 * Seul un utilisateur disposant de {@link VillagePermission#MANAGE_ROLES}
 * (chef/createur ou super-admin) peut modifier les roles.
 */
@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
public class VillageRoleService {

    private final VillageMemberRoleRepository memberRoleRepository;
    private final VillageRepository villageRepository;
    private final VillagePermissionService permissionService;

    /**
     * Cree ou met a jour le role delegue de {@code targetUserId} sur le village.
     * @param grantedBy auteur de l'action, doit disposer de MANAGE_ROLES.
     */
    public VillageMemberRole grantRole(UUID villageId, UUID targetUserId, String title,
                                       Set<VillagePermission> permissions, UUID grantedBy) {
        if (!villageRepository.existsById(villageId)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Village introuvable : " + villageId);
        }
        permissionService.requireCan(grantedBy, villageId, VillagePermission.MANAGE_ROLES);

        if (title == null || title.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Le titre du role est obligatoire.");
        }

        VillageMemberRole role = memberRoleRepository.findByVillageIdAndUserId(villageId, targetUserId)
                .orElseGet(() -> VillageMemberRole.builder()
                        .villageId(villageId)
                        .userId(targetUserId)
                        .build());

        role.setTitle(title.trim());
        role.setGrantedBy(grantedBy);
        role.setPermissionSet(permissions == null ? Set.of() : permissions);

        VillageMemberRole saved = memberRoleRepository.save(role);
        log.info("Role delegue upsert village={} user={} title='{}' perms={} par={}",
                villageId, targetUserId, saved.getTitle(), saved.getPermissions(), grantedBy);
        return saved;
    }

    /**
     * Revoque le role delegue de {@code targetUserId}.
     * @param requestedBy auteur de l'action, doit disposer de MANAGE_ROLES.
     */
    public void revokeRole(UUID villageId, UUID targetUserId, UUID requestedBy) {
        permissionService.requireCan(requestedBy, villageId, VillagePermission.MANAGE_ROLES);
        memberRoleRepository.deleteByVillageIdAndUserId(villageId, targetUserId);
        log.info("Role delegue revoque village={} user={} par={}", villageId, targetUserId, requestedBy);
    }

    @Transactional(readOnly = true)
    public List<VillageMemberRole> listRoles(UUID villageId) {
        return memberRoleRepository.findByVillageId(villageId);
    }
}
