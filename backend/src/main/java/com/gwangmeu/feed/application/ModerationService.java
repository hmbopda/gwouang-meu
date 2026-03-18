package com.gwangmeu.feed.application;

import com.gwangmeu.feed.domain.ModerationLog;
import com.gwangmeu.feed.domain.ModerationQueue;
import com.gwangmeu.feed.domain.ModerationStatus;
import com.gwangmeu.feed.dto.ModerationStatsDto;

import java.util.List;
import java.util.UUID;

public interface ModerationService {

    /**
     * Applique une decision de moderation avec validation de la machine a etats.
     * Transitions autorisees :
     *   PENDING → APPROVED | REJECTED
     *   APPROVED → FLAGGED  (normalement via flagPost, mais possible manuellement)
     *   FLAGGED  → SHADOW_BANNED | APPROVED
     *
     * @throws IllegalStateException si la transition est invalide
     * @throws IllegalArgumentException si note manquante pour REJECTED
     */
    void moderatePost(UUID postId, UUID moderatorId, ModerationStatus action, String note);

    /**
     * Signale un post par un utilisateur. Rate limite : 3/heure/user.
     * Auto-transition APPROVED → FLAGGED quand flagCount atteint 3.
     *
     * @throws IllegalStateException si quota depasse ou post deja dans etat final
     */
    void flagPost(UUID postId, UUID reporterId, String reason);

    /**
     * Resoumet un post REJECTED en PENDING (apres edition par l'auteur).
     *
     * @throws IllegalStateException si le post n'est pas en statut REJECTED
     * @throws SecurityException si l'appelant n'est pas l'auteur
     */
    void resubmitPost(UUID postId, UUID authorId);

    /**
     * File des posts PENDING et FLAGGED pour un village, pagines.
     */
    List<ModerationQueue> getQueue(UUID villageId, int page, int size);

    /**
     * Statistiques de moderation pour un village.
     */
    ModerationStatsDto getStats(UUID villageId);

    /**
     * Historique des actions de moderation pour un village.
     */
    List<ModerationLog> getLogs(UUID villageId, int page, int size);
}
