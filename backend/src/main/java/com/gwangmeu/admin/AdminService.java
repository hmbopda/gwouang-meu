package com.gwangmeu.admin;

import com.gwangmeu.shared.security.UserRole;
import com.gwangmeu.user.User;
import com.gwangmeu.user.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.Comparator;
import java.util.List;
import java.util.UUID;

/**
 * Back-office plateforme — gestion des utilisateurs (réservé SUPER_ADMIN, gate
 * au niveau du controller). Le rôle en base (users.role) est la source de vérité
 * lue par {@code SecurityConfig} (effet en ≤ 60 s, sans re-login).
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AdminService {

    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public List<AdminUserDto> listUsers() {
        return userRepository.findAll().stream()
                .sorted(Comparator.comparing(u -> u.getEmail() == null ? "" : u.getEmail().toLowerCase()))
                .map(AdminService::toDto)
                .toList();
    }

    @Transactional
    public AdminUserDto updateRole(UUID targetUserId, String roleName, UUID actingUserId) {
        UserRole role;
        try {
            role = UserRole.valueOf(roleName.trim().toUpperCase());
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Rôle invalide : " + roleName);
        }
        User target = userRepository.findById(targetUserId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Utilisateur introuvable"));

        // Garde-fou anti-lockout : un super-admin ne peut pas retirer son propre rôle.
        if (target.getId().equals(actingUserId) && role != UserRole.SUPER_ADMIN) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Vous ne pouvez pas retirer votre propre rôle super-admin (demandez à un autre super-admin).");
        }
        UserRole previous = target.getRole();
        target.setRole(role);
        userRepository.save(target);
        log.info("[ADMIN] {} a changé le rôle de {} : {} -> {}", actingUserId, target.getEmail(), previous, role);
        return toDto(target);
    }

    @Transactional
    public AdminUserDto updateStatus(UUID targetUserId, boolean active, UUID actingUserId) {
        User target = userRepository.findById(targetUserId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Utilisateur introuvable"));

        // Garde-fou : on ne désactive pas son propre compte.
        if (target.getId().equals(actingUserId) && !active) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Vous ne pouvez pas désactiver votre propre compte.");
        }
        target.setActive(active);
        userRepository.save(target);
        log.info("[ADMIN] {} a {} le compte {}", actingUserId, active ? "réactivé" : "désactivé", target.getEmail());
        return toDto(target);
    }

    private static AdminUserDto toDto(User u) {
        return new AdminUserDto(
                u.getId(),
                u.getEmail(),
                u.getDisplayName(),
                u.getRole() != null ? u.getRole().name() : UserRole.MEMBRE.name(),
                u.isActive());
    }
}
