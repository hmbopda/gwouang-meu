package com.gwangmeu.village.application;

import com.gwangmeu.village.domain.VillageChief;
import com.gwangmeu.village.domain.VillageMilestone;
import com.gwangmeu.village.dto.ChiefUpsertRequest;
import com.gwangmeu.village.dto.MilestoneUpsertRequest;

import java.util.List;
import java.util.UUID;

/**
 * Patrimoine d'un village : dynastie des chefs (actuel + anciens) et temps forts.
 * L'autorisation (EDIT_VILLAGE) est verifiee en amont par le controller.
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
}
