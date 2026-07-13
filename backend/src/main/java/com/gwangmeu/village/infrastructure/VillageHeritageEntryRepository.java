package com.gwangmeu.village.infrastructure;

import com.gwangmeu.village.domain.HeritageKind;
import com.gwangmeu.village.domain.VillageHeritageEntry;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface VillageHeritageEntryRepository extends JpaRepository<VillageHeritageEntry, UUID> {

    /** Entrees patrimoniales d'un village pour une rubrique donnee, ordonnees (ordinal puis creation). */
    List<VillageHeritageEntry> findByVillageIdAndKindOrderByOrdinalAscCreatedAtAsc(UUID villageId, HeritageKind kind);
}
