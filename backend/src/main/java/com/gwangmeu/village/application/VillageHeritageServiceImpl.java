package com.gwangmeu.village.application;

import com.gwangmeu.village.domain.HeritageKind;
import com.gwangmeu.village.domain.VillageChief;
import com.gwangmeu.village.domain.VillageHeritageEntry;
import com.gwangmeu.village.domain.VillageMilestone;
import com.gwangmeu.village.domain.VillagePermission;
import com.gwangmeu.village.dto.ChiefUpsertRequest;
import com.gwangmeu.village.dto.HeritageEntryUpsertRequest;
import com.gwangmeu.village.dto.MilestoneUpsertRequest;
import com.gwangmeu.village.infrastructure.VillageChiefRepository;
import com.gwangmeu.village.infrastructure.VillageHeritageEntryRepository;
import com.gwangmeu.village.infrastructure.VillageMilestoneRepository;
import com.gwangmeu.village.infrastructure.VillageRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.UUID;

@Service
@Transactional
@RequiredArgsConstructor
class VillageHeritageServiceImpl implements VillageHeritageService {

    private final VillageRepository villageRepository;
    private final VillageChiefRepository chiefRepository;
    private final VillageMilestoneRepository milestoneRepository;
    private final VillageHeritageEntryRepository entryRepository;
    private final VillagePermissionService villagePermissionService;

    private void requireVillage(UUID villageId) {
        if (!villageRepository.existsById(villageId)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Village introuvable : " + villageId);
        }
    }

    // ── Dynastie ────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public List<VillageChief> listChiefs(UUID villageId) {
        return chiefRepository.findByVillageIdOrderByOrdinalAscReignStartAsc(villageId);
    }

    @Override
    public VillageChief addChief(UUID villageId, ChiefUpsertRequest req) {
        requireVillage(villageId);
        boolean makeCurrent = Boolean.TRUE.equals(req.current());
        // Rétrograder AVANT d'insérer le nouveau chef courant : l'index unique
        // partiel ux_vchief_current interdit deux is_current=TRUE simultanés.
        if (makeCurrent) {
            demoteCurrents(villageId, null);
        }
        VillageChief chief = VillageChief.builder()
                .villageId(villageId)
                .displayName(req.displayName().trim())
                .reignStart(req.reignStart())
                .reignEnd(req.reignEnd())
                .current(makeCurrent)
                .ordinal(req.ordinal() != null ? req.ordinal() : 0)
                .note(req.note())
                .avatarUrl(req.avatarUrl())
                .userId(req.userId())
                .build();
        return chiefRepository.save(chief);
    }

    @Override
    public VillageChief updateChief(UUID villageId, UUID chiefId, ChiefUpsertRequest req) {
        VillageChief chief = loadChiefOfVillage(villageId, chiefId);
        boolean makeCurrent = Boolean.TRUE.equals(req.current());
        if (makeCurrent) {
            demoteCurrents(villageId, chiefId);
        }
        chief.setDisplayName(req.displayName().trim());
        chief.setReignStart(req.reignStart());
        chief.setReignEnd(req.reignEnd());
        chief.setCurrent(makeCurrent);
        if (req.ordinal() != null) {
            chief.setOrdinal(req.ordinal());
        }
        chief.setNote(req.note());
        chief.setAvatarUrl(req.avatarUrl());
        chief.setUserId(req.userId());
        return chiefRepository.save(chief);
    }

    @Override
    public void deleteChief(UUID villageId, UUID chiefId) {
        VillageChief chief = loadChiefOfVillage(villageId, chiefId);
        chiefRepository.delete(chief);
    }

    /**
     * Rétrograde les chefs actuellement marqués courants pour ce village
     * (en excluant {@code keepId} s'il est fourni), puis force le flush pour
     * que l'UPDATE is_current=FALSE atteigne la base AVANT la promotion suivante
     * (invariant garanti par l'index unique partiel).
     */
    private void demoteCurrents(UUID villageId, UUID keepId) {
        List<VillageChief> currents = chiefRepository.findByVillageIdAndCurrentTrue(villageId);
        boolean changed = false;
        for (VillageChief c : currents) {
            if (keepId == null || !c.getId().equals(keepId)) {
                c.setCurrent(false);
                changed = true;
            }
        }
        if (changed) {
            chiefRepository.saveAll(currents);
            chiefRepository.flush();
        }
    }

    private VillageChief loadChiefOfVillage(UUID villageId, UUID chiefId) {
        VillageChief chief = chiefRepository.findById(chiefId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Chef introuvable : " + chiefId));
        if (!villageId.equals(chief.getVillageId())) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Chef introuvable dans ce village");
        }
        return chief;
    }

    // ── Temps forts ─────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public List<VillageMilestone> listMilestones(UUID villageId) {
        return milestoneRepository.findByVillageIdOrderByOrdinalAscYearAsc(villageId);
    }

    @Override
    public VillageMilestone addMilestone(UUID villageId, MilestoneUpsertRequest req) {
        requireVillage(villageId);
        VillageMilestone m = VillageMilestone.builder()
                .villageId(villageId)
                .year(req.year())
                .dateLabel(req.dateLabel())
                .title(req.title().trim())
                .description(req.description())
                .ordinal(req.ordinal() != null ? req.ordinal() : 0)
                .build();
        return milestoneRepository.save(m);
    }

    @Override
    public VillageMilestone updateMilestone(UUID villageId, UUID milestoneId, MilestoneUpsertRequest req) {
        VillageMilestone m = loadMilestoneOfVillage(villageId, milestoneId);
        m.setYear(req.year());
        m.setDateLabel(req.dateLabel());
        m.setTitle(req.title().trim());
        m.setDescription(req.description());
        if (req.ordinal() != null) {
            m.setOrdinal(req.ordinal());
        }
        return milestoneRepository.save(m);
    }

    @Override
    public void deleteMilestone(UUID villageId, UUID milestoneId) {
        VillageMilestone m = loadMilestoneOfVillage(villageId, milestoneId);
        milestoneRepository.delete(m);
    }

    private VillageMilestone loadMilestoneOfVillage(UUID villageId, UUID milestoneId) {
        VillageMilestone m = milestoneRepository.findById(milestoneId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Temps fort introuvable : " + milestoneId));
        if (!villageId.equals(m.getVillageId())) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Temps fort introuvable dans ce village");
        }
        return m;
    }

    // ── Entrées patrimoniales génériques (traditions, lieux sacrés, calendrier) ──

    @Override
    @Transactional(readOnly = true)
    public List<VillageHeritageEntry> listEntries(UUID villageId, HeritageKind kind) {
        return entryRepository.findByVillageIdAndKindOrderByOrdinalAscCreatedAtAsc(villageId, kind);
    }

    @Override
    public VillageHeritageEntry createEntry(UUID userId, UUID villageId, HeritageKind kind,
                                            HeritageEntryUpsertRequest req) {
        requireVillage(villageId);
        villagePermissionService.requireCan(userId, villageId, VillagePermission.EDIT_VILLAGE);
        VillageHeritageEntry e = VillageHeritageEntry.builder()
                .villageId(villageId)
                .kind(kind)
                .title(req.title().trim())
                .subtitle(req.subtitle())
                .description(req.description())
                .detail(req.detail())
                .ordinal(req.ordinal() != null ? req.ordinal() : 0)
                .build();
        return entryRepository.save(e);
    }

    @Override
    public VillageHeritageEntry updateEntry(UUID userId, UUID villageId, UUID entryId,
                                            HeritageEntryUpsertRequest req) {
        villagePermissionService.requireCan(userId, villageId, VillagePermission.EDIT_VILLAGE);
        VillageHeritageEntry e = loadEntryOfVillage(villageId, entryId);
        e.setTitle(req.title().trim());
        e.setSubtitle(req.subtitle());
        e.setDescription(req.description());
        e.setDetail(req.detail());
        if (req.ordinal() != null) {
            e.setOrdinal(req.ordinal());
        }
        return entryRepository.save(e);
    }

    @Override
    public void deleteEntry(UUID userId, UUID villageId, UUID entryId) {
        villagePermissionService.requireCan(userId, villageId, VillagePermission.EDIT_VILLAGE);
        VillageHeritageEntry e = loadEntryOfVillage(villageId, entryId);
        entryRepository.delete(e);
    }

    private VillageHeritageEntry loadEntryOfVillage(UUID villageId, UUID entryId) {
        VillageHeritageEntry e = entryRepository.findById(entryId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Entrée introuvable : " + entryId));
        if (!villageId.equals(e.getVillageId())) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Entrée introuvable dans ce village");
        }
        return e;
    }
}
