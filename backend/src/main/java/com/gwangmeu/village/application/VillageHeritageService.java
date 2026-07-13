package com.gwangmeu.village.application;

import com.gwangmeu.village.domain.HeritageKind;
import com.gwangmeu.village.domain.VillageChief;
import com.gwangmeu.village.domain.VillageHeritageEntry;
import com.gwangmeu.village.domain.VillageMilestone;
import com.gwangmeu.village.dto.ChiefUpsertRequest;
import com.gwangmeu.village.dto.HeritageEntryUpsertRequest;
import com.gwangmeu.village.dto.MilestoneUpsertRequest;

import java.util.List;
import java.util.UUID;

/**
 * Patrimoine d'un village : dynastie des chefs (actuel + anciens), temps forts et
 * entrees patrimoniales generiques (traditions, lieux sacres, calendrier).
 * L'autorisation (EDIT_VILLAGE) est verifiee en amont par le controller pour la dynastie
 * et les temps forts ; les entrees generiques la verifient dans le service.
 */
public interface VillageHeritageService {

    // Dynastie
    List<VillageChief> listChiefs(UUID villageId);

    VillageChief addChief(UUID villageId, ChiefUpsertRequest req);

    VillageChief updateChief(UUID villageId, UUID chiefId, ChiefUpsertRequest req);

    void deleteChief(UUID villageId, UUID chiefId);

    // Temps forts
    List<VillageMilestone> listMilestones(UUID villageId);

    VillageMilestone addMilestone(UUID villageId, MilestoneUpsertRequest req);

    VillageMilestone updateMilestone(UUID villageId, UUID milestoneId, MilestoneUpsertRequest req);

    void deleteMilestone(UUID villageId, UUID milestoneId);

    // Entrees patrimoniales generiques (traditions, lieux sacres, calendrier)
    List<VillageHeritageEntry> listEntries(UUID villageId, HeritageKind kind);

    VillageHeritageEntry createEntry(UUID userId, UUID villageId, HeritageKind kind, HeritageEntryUpsertRequest req);

    VillageHeritageEntry updateEntry(UUID userId, UUID villageId, UUID entryId, HeritageEntryUpsertRequest req);

    void deleteEntry(UUID userId, UUID villageId, UUID entryId);
}
