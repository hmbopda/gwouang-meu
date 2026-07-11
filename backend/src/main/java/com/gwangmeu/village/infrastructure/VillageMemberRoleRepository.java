package com.gwangmeu.village.infrastructure;

import com.gwangmeu.village.domain.VillageMemberRole;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface VillageMemberRoleRepository extends JpaRepository<VillageMemberRole, UUID> {

    List<VillageMemberRole> findByVillageId(UUID villageId);

    Optional<VillageMemberRole> findByVillageIdAndUserId(UUID villageId, UUID userId);

    void deleteByVillageIdAndUserId(UUID villageId, UUID userId);
}
