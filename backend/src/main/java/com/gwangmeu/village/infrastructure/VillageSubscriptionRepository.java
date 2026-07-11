package com.gwangmeu.village.infrastructure;

import com.gwangmeu.village.domain.VillageSubscription;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface VillageSubscriptionRepository extends JpaRepository<VillageSubscription, UUID> {

    List<VillageSubscription> findByUserId(UUID userId);

    List<VillageSubscription> findByVillageId(UUID villageId);

    boolean existsByUserIdAndVillageId(UUID userId, UUID villageId);

    void deleteByUserIdAndVillageId(UUID userId, UUID villageId);

    Optional<VillageSubscription> findByUserIdAndVillageId(UUID userId, UUID villageId);

    boolean existsByUserIdAndVillageIdAndType(UUID userId, UUID villageId, VillageSubscription.SubscriptionType type);

    /**
     * Abonnements d'un type donne (ex. MEMBER) pour un village, restreints a un ensemble d'utilisateurs.
     * Utilise par l'adhesion AUTO pour detecter un membre de la famille deja MEMBER.
     */
    List<VillageSubscription> findByVillageIdAndTypeAndUserIdIn(
            UUID villageId, VillageSubscription.SubscriptionType type, Collection<UUID> userIds);

    /**
     * Identifiants des villages ou l'un des utilisateurs fournis a une subscription
     * du type donne (ex. MEMBER). Utilise par le calcul des villages herites.
     */
    @Query("SELECT DISTINCT vs.villageId FROM VillageSubscription vs "
            + "WHERE vs.type = :type AND vs.userId IN :userIds")
    List<UUID> findVillageIdsByTypeAndUserIdIn(
            VillageSubscription.SubscriptionType type, Collection<UUID> userIds);
}
