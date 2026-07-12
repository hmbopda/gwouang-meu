package com.gwangmeu.village.infrastructure;

import com.gwangmeu.village.domain.VillageChief;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface VillageChiefRepository extends JpaRepository<VillageChief, UUID> {

    /** Dynastie d'un village, ordonnee (ordinal puis debut de regne). */
    List<VillageChief> findByVillageIdOrderByOrdinalAscReignStartAsc(UUID villageId);

    /** Chef(s) marque(s) actuel(s) pour un village (invariant : au plus un). */
    List<VillageChief> findByVillageIdAndCurrentTrue(UUID villageId);
}
