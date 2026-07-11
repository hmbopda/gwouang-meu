package com.gwangmeu.village.infrastructure;

import com.gwangmeu.village.domain.VillageInvitation;
import com.gwangmeu.village.domain.VillageInvitationStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface VillageInvitationRepository extends JpaRepository<VillageInvitation, UUID> {

    List<VillageInvitation> findByInvitedUserIdAndStatus(UUID invitedUserId, VillageInvitationStatus status);

    List<VillageInvitation> findByVillageIdAndStatus(UUID villageId, VillageInvitationStatus status);

    Optional<VillageInvitation> findByVillageIdAndInvitedUserId(UUID villageId, UUID invitedUserId);
}
