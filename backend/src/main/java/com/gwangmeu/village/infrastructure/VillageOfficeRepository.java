package com.gwangmeu.village.infrastructure;

import com.gwangmeu.village.domain.VillageOffice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface VillageOfficeRepository extends JpaRepository<VillageOffice, UUID> {

    List<VillageOffice> findByVillageIdOrderByTierAscRankAsc(UUID villageId);

    Optional<VillageOffice> findByVillageIdAndApexTrue(UUID villageId);
}
