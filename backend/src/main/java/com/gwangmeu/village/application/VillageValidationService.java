package com.gwangmeu.village.application;

import com.gwangmeu.village.domain.VillagePermission;
import com.gwangmeu.village.domain.VillageValidation;
import com.gwangmeu.village.domain.VillageValidationKind;
import com.gwangmeu.village.domain.VillageValidationStatus;
import com.gwangmeu.village.infrastructure.VillageRepository;
import com.gwangmeu.village.infrastructure.VillageValidationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Soumission et validation d'elements culturels / successoraux d'un village
 * (clan, chefferie, ligne de chefs, succession).
 *
 * <p>Permission de decision selon la nature :
 * SUCCESSION -> {@link VillagePermission#VALIDATE_SUCCESSION},
 * sinon -> {@link VillagePermission#VALIDATE_CULTURE}.</p>
 */
@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
public class VillageValidationService {

    private final VillageValidationRepository validationRepository;
    private final VillageRepository villageRepository;
    private final VillagePermissionService permissionService;

    /** Tout membre peut soumettre un element a valider. */
    public VillageValidation submit(UUID villageId, VillageValidationKind kind,
                                    String title, String detail, UUID userId) {
        if (!villageRepository.existsById(villageId)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Village introuvable : " + villageId);
        }
        if (kind == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "La nature (kind) est obligatoire.");
        }
        if (title == null || title.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Le titre est obligatoire.");
        }

        VillageValidation validation = VillageValidation.builder()
                .villageId(villageId)
                .kind(kind)
                .title(title.trim())
                .detail(detail)
                .submittedBy(userId)
                .status(VillageValidationStatus.PENDING)
                .build();

        VillageValidation saved = validationRepository.save(validation);
        log.info("Validation soumise village={} kind={} par={} id={}",
                villageId, kind, userId, saved.getId());
        return saved;
    }

    /**
     * Liste les validations d'un village, filtrees eventuellement par nature et/ou statut.
     * La lecture requiert la permission de decision correspondant a la nature filtree ;
     * sans filtre de nature, VALIDATE_CULTURE suffit.
     */
    @Transactional(readOnly = true)
    public List<VillageValidation> listPending(UUID villageId, VillageValidationKind kind,
                                               VillageValidationStatus status, UUID requesterId) {
        VillagePermission required = kind != null
                ? permissionForKind(kind)
                : VillagePermission.VALIDATE_CULTURE;
        permissionService.requireCan(requesterId, villageId, required);

        if (kind != null && status != null) {
            return validationRepository.findByVillageIdAndKindAndStatusOrderByCreatedAtDesc(villageId, kind, status);
        }
        if (kind != null) {
            return validationRepository.findByVillageIdAndKindOrderByCreatedAtDesc(villageId, kind);
        }
        if (status != null) {
            return validationRepository.findByVillageIdAndStatusOrderByCreatedAtDesc(villageId, status);
        }
        return validationRepository.findByVillageIdOrderByCreatedAtDesc(villageId);
    }

    /** Approuve (true) ou rejette (false) une validation. Permission selon la nature. */
    public VillageValidation decide(UUID villageId, UUID validationId, boolean approve, UUID deciderId) {
        VillageValidation validation = validationRepository.findById(validationId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Validation introuvable : " + validationId));
        if (!villageId.equals(validation.getVillageId())) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND,
                    "Validation introuvable pour ce village.");
        }

        permissionService.requireCan(deciderId, villageId, permissionForKind(validation.getKind()));

        validation.setStatus(approve ? VillageValidationStatus.APPROVED : VillageValidationStatus.REJECTED);
        validation.setDecidedBy(deciderId);
        validation.setDecidedAt(Instant.now());
        VillageValidation saved = validationRepository.save(validation);
        log.info("Validation {} village={} id={} par={}",
                saved.getStatus(), villageId, validationId, deciderId);
        return saved;
    }

    /** SUCCESSION -> VALIDATE_SUCCESSION ; CLAN/CHEFFERIE/CHIEF_LINE -> VALIDATE_CULTURE. */
    static VillagePermission permissionForKind(VillageValidationKind kind) {
        return kind == VillageValidationKind.SUCCESSION
                ? VillagePermission.VALIDATE_SUCCESSION
                : VillagePermission.VALIDATE_CULTURE;
    }
}
