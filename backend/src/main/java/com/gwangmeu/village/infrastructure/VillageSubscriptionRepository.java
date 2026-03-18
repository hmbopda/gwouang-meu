package com.gwangmeu.village.infrastructure;

import com.gwangmeu.village.domain.VillageSubscription;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface VillageSubscriptionRepository extends JpaRepository<VillageSubscription, UUID> {

    List<VillageSubscription> findByUserId(UUID userId);

    List<VillageSubscription> findByVillageId(UUID villageId);

    boolean existsByUserIdAndVillageId(UUID userId, UUID villageId);

    void deleteByUserIdAndVillageId(UUID userId, UUID villageId);
}
