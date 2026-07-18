package com.gwangmeu.village.application;

import com.gwangmeu.village.domain.VillageOffice;
import com.gwangmeu.village.domain.VillageOfficeHolder;
import com.gwangmeu.village.domain.VillagePermission;
import com.gwangmeu.village.dto.NotableDto;
import com.gwangmeu.village.dto.NotableUpsertRequest;
import com.gwangmeu.village.infrastructure.VillageOfficeHolderRepository;
import com.gwangmeu.village.infrastructure.VillageOfficeRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Gestion des NOTABLES d'un village = sièges NON-apex de {@code village_offices}
 * + leur titulaire courant ({@code village_office_holders}). Le CHEF (apex) se
 * gère via la dynastie (VillageHeritageController /chiefs, source canonique).
 * Écritures gatées {@code EDIT_VILLAGE} (chef, délégué, super-admin).
 */
@Service
@RequiredArgsConstructor
public class GovernanceAdminService {

    private final VillageOfficeRepository officeRepository;
    private final VillageOfficeHolderRepository holderRepository;
    private final VillagePermissionService permissionService;

    @Transactional
    public NotableDto addNotable(UUID villageId, UUID actorId, NotableUpsertRequest req) {
        permissionService.requireCan(actorId, villageId, VillagePermission.EDIT_VILLAGE);
        VillageOffice office = officeRepository.save(VillageOffice.builder()
                .villageId(villageId)
                .officeKey("notable")
                .labelOverride(blankToNull(req.title()))
                .tier(2)
                .rank(req.rank() != null ? req.rank() : 100)
                .apex(false)
                .cardMin(0)
                .cardMax(1)
                .permBundle("")
                .build());
        holderRepository.save(VillageOfficeHolder.builder()
                .officeId(office.getId())
                .villageId(villageId)
                .userId(req.userId())
                .displayName(req.displayName().trim())
                .titleLabel(blankToNull(req.title()))
                .termStart(req.termStart())
                .current(true)
                .ordinal(0)
                .source("COMMUNITY_DECLARED")
                .build());
        return toDto(office, req);
    }

    @Transactional
    public NotableDto updateNotable(UUID villageId, UUID actorId, UUID officeId,
                                    NotableUpsertRequest req) {
        permissionService.requireCan(actorId, villageId, VillagePermission.EDIT_VILLAGE);
        VillageOffice office = requireNotable(villageId, officeId);
        office.setLabelOverride(blankToNull(req.title()));
        if (req.rank() != null) office.setRank(req.rank());
        officeRepository.save(office);

        VillageOfficeHolder holder = holderRepository.findByOfficeIdOrderByOrdinalAsc(officeId)
                .stream().filter(VillageOfficeHolder::isCurrent).findFirst()
                .orElseGet(() -> VillageOfficeHolder.builder()
                        .officeId(officeId).villageId(villageId).current(true)
                        .ordinal(0).source("COMMUNITY_DECLARED").build());
        holder.setDisplayName(req.displayName().trim());
        holder.setTitleLabel(blankToNull(req.title()));
        holder.setUserId(req.userId());
        holder.setTermStart(req.termStart());
        holderRepository.save(holder);
        return toDto(office, req);
    }

    @Transactional
    public void deleteNotable(UUID villageId, UUID actorId, UUID officeId) {
        permissionService.requireCan(actorId, villageId, VillagePermission.EDIT_VILLAGE);
        // FK village_office_holders.office_id ON DELETE CASCADE → titulaires supprimés.
        officeRepository.delete(requireNotable(villageId, officeId));
    }

    private VillageOffice requireNotable(UUID villageId, UUID officeId) {
        return officeRepository.findById(officeId)
                .filter(o -> o.getVillageId().equals(villageId) && !o.isApex())
                .orElseThrow(() -> new EntityNotFoundException("Notable introuvable : " + officeId));
    }

    private static NotableDto toDto(VillageOffice office, NotableUpsertRequest req) {
        return new NotableDto(office.getId(), req.displayName().trim(),
                blankToNull(req.title()), office.getRank(), req.termStart(), req.userId());
    }

    private static String blankToNull(String s) {
        return (s == null || s.isBlank()) ? null : s.trim();
    }
}
