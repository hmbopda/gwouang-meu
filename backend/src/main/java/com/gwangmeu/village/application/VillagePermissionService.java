package com.gwangmeu.village.application;

import com.gwangmeu.village.domain.Village;
import com.gwangmeu.village.domain.VillageMemberRole;
import com.gwangmeu.village.domain.VillagePermission;
import com.gwangmeu.village.infrastructure.VillageMemberRoleRepository;
import com.gwangmeu.village.infrastructure.VillageRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

import java.util.EnumSet;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * Autorisation fine au niveau d'un village.
 *
 * Regle {@link #can(UUID, UUID, VillagePermission)} : TRUE si
 * <ul>
 *   <li>l'utilisateur est SUPER_ADMIN (autorite globale {@code ROLE_SUPER_ADMIN} du JWT), OU</li>
 *   <li>il est le {@code creatorId} du village (= CHEF / proprietaire, toutes permissions), OU</li>
 *   <li>il possede un {@link VillageMemberRole} sur ce village dont les permissions contiennent {@code perm}.</li>
 * </ul>
 */
@Service
@RequiredArgsConstructor
public class VillagePermissionService {

    private static final String ROLE_SUPER_ADMIN = "ROLE_SUPER_ADMIN";

    private final VillageRepository villageRepository;
    private final VillageMemberRoleRepository memberRoleRepository;

    /** Variante lisant l'autorite SUPER_ADMIN depuis le SecurityContext courant. */
    @Transactional(readOnly = true)
    public boolean can(UUID userId, UUID villageId, VillagePermission perm) {
        return can(userId, villageId, perm, isCurrentUserSuperAdmin());
    }

    /**
     * Variante explicite : le super-admin est passe par l'appelant (utile hors contexte web / tests).
     */
    @Transactional(readOnly = true)
    public boolean can(UUID userId, UUID villageId, VillagePermission perm, boolean isSuperAdmin) {
        if (userId == null || villageId == null || perm == null) {
            return false;
        }
        if (isSuperAdmin) {
            return true;
        }
        // Chef / createur du village : toutes les permissions.
        if (isChief(userId, villageId)) {
            return true;
        }
        // Role delegue portant la permission demandee.
        return effectivePermissions(userId, villageId).contains(perm);
    }

    /** Leve 403 FORBIDDEN si l'utilisateur ne dispose pas de la permission. */
    @Transactional(readOnly = true)
    public void requireCan(UUID userId, UUID villageId, VillagePermission perm) {
        if (!can(userId, villageId, perm)) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Permission requise sur ce village : " + perm.name());
        }
    }

    @Transactional(readOnly = true)
    public void requireCan(UUID userId, UUID villageId, VillagePermission perm, boolean isSuperAdmin) {
        if (!can(userId, villageId, perm, isSuperAdmin)) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Permission requise sur ce village : " + perm.name());
        }
    }

    /** true si {@code userId} est le createur (chef) du village. */
    @Transactional(readOnly = true)
    public boolean isChief(UUID userId, UUID villageId) {
        if (userId == null || villageId == null) {
            return false;
        }
        return villageRepository.findById(villageId)
                .map(Village::getCreatorId)
                .filter(userId::equals)
                .isPresent();
    }

    /**
     * Ensemble effectif des permissions de l'utilisateur sur le village.
     * Chef ou super-admin => toutes les permissions ; sinon celles du role delegue.
     */
    @Transactional(readOnly = true)
    public Set<VillagePermission> effectivePermissions(UUID userId, UUID villageId) {
        if (userId == null || villageId == null) {
            return EnumSet.noneOf(VillagePermission.class);
        }
        if (isCurrentUserSuperAdmin() || isChief(userId, villageId)) {
            return EnumSet.allOf(VillagePermission.class);
        }
        Optional<VillageMemberRole> role = memberRoleRepository.findByVillageIdAndUserId(villageId, userId);
        return role.map(VillageMemberRole::getPermissionSet)
                .orElseGet(() -> EnumSet.noneOf(VillagePermission.class));
    }

    /** Lit l'autorite globale {@code ROLE_SUPER_ADMIN} depuis le SecurityContext. */
    public boolean isCurrentUserSuperAdmin() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()) {
            return false;
        }
        for (GrantedAuthority ga : auth.getAuthorities()) {
            if (ROLE_SUPER_ADMIN.equals(ga.getAuthority())) {
                return true;
            }
        }
        return false;
    }
}
