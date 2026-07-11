package com.gwangmeu.village.infrastructure;

import com.gwangmeu.village.domain.VillageJoinRequest;
import com.gwangmeu.village.domain.VillageJoinStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface VillageJoinRequestRepository extends JpaRepository<VillageJoinRequest, UUID> {

    List<VillageJoinRequest> findByVillageIdAndStatus(UUID villageId, VillageJoinStatus status);

    List<VillageJoinRequest> findByVillageIdAndStatusOrderByCreatedAtDesc(UUID villageId, VillageJoinStatus status);

    Optional<VillageJoinRequest> findByVillageIdAndUserId(UUID villageId, UUID userId);
}
