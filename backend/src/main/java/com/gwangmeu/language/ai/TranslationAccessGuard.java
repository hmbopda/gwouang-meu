package com.gwangmeu.language.ai;

import com.gwangmeu.user.UserRepository;
import com.gwangmeu.village.application.VillagePermissionService;
import com.gwangmeu.village.infrastructure.VillageMemberRoleRepository;
import com.gwangmeu.village.infrastructure.VillageRepository;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.UUID;

/**
 * Contrôle d'accès au traducteur.
 *
 * <p>Quota <b>5 traductions / jour</b> pour les utilisateurs non privilégiés.
 * <b>Illimité</b> pour les privilégiés = super-admin OU administrateur d'un
 * village (chef/créateur d'au moins un village, ou porteur d'un rôle délégué).</p>
 *
 * <p>Le comptage passe par Redis, en <b>best-effort fail-open</b> : si Redis est
 * indisponible, on laisse passer plutôt que de bloquer sur un incident d'infra.</p>
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class TranslationAccessGuard {

    private static final int DAILY_LIMIT = 5;
    private static final String KEY_PREFIX = "gw:trlimit:";

    private final UserRepository userRepository;
    private final VillageRepository villageRepository;
    private final VillageMemberRoleRepository memberRoleRepository;
    private final VillagePermissionService permissionService;
    private final RedisConnectionFactory redisConnectionFactory;

    private StringRedisTemplate redis;

    @PostConstruct
    void initRedis() {
        try {
            StringRedisTemplate t = new StringRedisTemplate(redisConnectionFactory);
            t.afterPropertiesSet();
            this.redis = t;
        } catch (Exception e) {
            log.warn("Redis indisponible pour le quota de traduction (fail-open) : {}", e.getMessage());
            this.redis = null;
        }
    }

    /**
     * Autorise ou refuse une traduction. Lève {@link TranslationLimitException}
     * (→ 429) si un utilisateur non privilégié a dépassé son quota du jour.
     */
    public void enforce(Jwt jwt) {
        UUID userId = userRepository.findBySupabaseId(jwt.getSubject())
                .map(u -> u.getId())
                .orElse(null);

        if (isPrivileged(userId)) {
            return; // super-admin / admin de village : illimité
        }
        if (redis == null) {
            return; // fail-open : compteur indisponible
        }

        String subject = userId != null ? userId.toString() : jwt.getSubject();
        String key = KEY_PREFIX + subject + ':' + LocalDate.now(ZoneOffset.UTC);
        try {
            Long count = redis.opsForValue().increment(key);
            if (count != null && count == 1L) {
                redis.expire(key, Duration.ofHours(26));
            }
            if (count != null && count > DAILY_LIMIT) {
                throw new TranslationLimitException(
                        "Limite de " + DAILY_LIMIT + " traductions par jour atteinte. "
                                + "Réessaie demain, ou passe à un accès illimité.");
            }
        } catch (TranslationLimitException e) {
            throw e;
        } catch (Exception e) {
            log.warn("Compteur de quota traduction indisponible (fail-open) : {}", e.getMessage());
            // fail-open : on n'empêche pas la traduction sur incident Redis
        }
    }

    /** Privilégié = super-admin OU chef/créateur d'un village OU rôle délégué de village. */
    private boolean isPrivileged(UUID userId) {
        if (permissionService.isCurrentUserSuperAdmin()) {
            return true;
        }
        if (userId == null) {
            return false;
        }
        return villageRepository.existsByCreatorId(userId)
                || memberRoleRepository.existsByUserId(userId);
    }
}
