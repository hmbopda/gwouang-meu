package com.gwangmeu.village.application;

import com.gwangmeu.geo.domain.Language;
import com.gwangmeu.geo.infrastructure.LanguageRepository;
import com.gwangmeu.village.domain.VillageLanguage;
import com.gwangmeu.village.domain.VillagePermission;
import com.gwangmeu.village.dto.VillageLanguagesRequest;
import com.gwangmeu.village.infrastructure.VillageLanguageRepository;
import com.gwangmeu.village.infrastructure.VillageRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Service
@Transactional
@RequiredArgsConstructor
class LanguageServiceImpl implements LanguageService {

    private final LanguageRepository languageRepository;
    private final VillageLanguageRepository villageLanguageRepository;
    private final VillageRepository villageRepository;
    private final VillagePermissionService villagePermissionService;

    @Override
    @Transactional(readOnly = true)
    public List<Language> listActive() {
        return languageRepository.findByActiveTrueOrderByFrenchNameAsc();
    }

    @Override
    @Transactional(readOnly = true)
    public List<VillageLanguage> villageLanguages(UUID villageId) {
        return villageLanguageRepository.findByVillageId(villageId);
    }

    @Override
    public List<VillageLanguage> setVillageLanguages(UUID userId, UUID villageId, VillageLanguagesRequest req) {
        requireVillage(villageId);
        villagePermissionService.requireCan(userId, villageId, VillagePermission.EDIT_VILLAGE);

        List<VillageLanguagesRequest.Item> items =
                (req == null || req.languages() == null) ? List.of() : req.languages();

        // Remplacement complet : on vide puis on reinsere l'ensemble transmis.
        villageLanguageRepository.deleteByVillageId(villageId);
        villageLanguageRepository.flush();

        Set<UUID> seen = new HashSet<>();
        boolean primaryTaken = false;
        List<VillageLanguage> toSave = new ArrayList<>();
        for (VillageLanguagesRequest.Item item : items) {
            UUID languageId = item.languageId();
            if (languageId == null || !languageRepository.existsById(languageId)) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Langue introuvable : " + languageId);
            }
            if (!seen.add(languageId)) {
                continue; // ignore les doublons (cle composite unique)
            }
            // Au plus une langue principale : on garde la premiere marquee.
            boolean isPrimary = item.isPrimary() && !primaryTaken;
            if (isPrimary) {
                primaryTaken = true;
            }
            toSave.add(VillageLanguage.builder()
                    .villageId(villageId)
                    .languageId(languageId)
                    .primary(isPrimary)
                    .ordinal(item.ordinal() != null ? item.ordinal() : 0)
                    .build());
        }
        return villageLanguageRepository.saveAll(toSave);
    }

    private void requireVillage(UUID villageId) {
        if (!villageRepository.existsById(villageId)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Village introuvable : " + villageId);
        }
    }
}
