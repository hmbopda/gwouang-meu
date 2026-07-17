package com.gwangmeu.village.infrastructure;

import com.gwangmeu.village.domain.VillageOfficeHolder;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface VillageOfficeHolderRepository extends JpaRepository<VillageOfficeHolder, UUID> {

    List<VillageOfficeHolder> findByVillageIdOrderByOrdinalAsc(UUID villageId);

    List<VillageOfficeHolder> findByOfficeIdOrderByOrdinalAsc(UUID officeId);

    List<VillageOfficeHolder> findByVillageIdAndCurrentTrue(UUID villageId);
}
