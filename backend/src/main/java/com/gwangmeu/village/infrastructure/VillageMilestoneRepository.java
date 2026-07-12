package com.gwangmeu.village.infrastructure;

import com.gwangmeu.village.domain.VillageMilestone;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface VillageMilestoneRepository extends JpaRepository<VillageMilestone, UUID> {

    /** Temps forts d'un village, ordonnes (ordinal puis annee). */
    List<VillageMilestone> findByVillageIdOrderByOrdinalAscYearAsc(UUID villageId);
}
