package com.gwangmeu.village.application;

import com.gwangmeu.geo.domain.Chefferie;
import com.gwangmeu.geo.infrastructure.ChefferieRepository;
import com.gwangmeu.governance.domain.GovernanceModel;
import com.gwangmeu.governance.domain.GovernanceTitleLabel;
import com.gwangmeu.governance.infrastructure.GovernanceModelRepository;
import com.gwangmeu.governance.infrastructure.GovernanceTitleLabelRepository;
import com.gwangmeu.village.domain.Village;
import com.gwangmeu.village.domain.VillageGovernance;
import com.gwangmeu.village.domain.VillageOffice;
import com.gwangmeu.village.domain.VillageOfficeHolder;
import com.gwangmeu.village.dto.GovernanceViewDto;
import com.gwangmeu.village.dto.GovernanceViewDto.Holder;
import com.gwangmeu.village.dto.GovernanceViewDto.Institution;
import com.gwangmeu.village.dto.GovernanceViewDto.Seat;
import com.gwangmeu.village.infrastructure.VillageGovernanceRepository;
import com.gwangmeu.village.infrastructure.VillageOfficeHolderRepository;
import com.gwangmeu.village.infrastructure.VillageOfficeRepository;
import com.gwangmeu.village.infrastructure.VillageRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Résout la VUE de gouvernance d'un village en agrégeant : l'instance locale
 * ({@code village_governance} + sièges + titulaires), à défaut le template de la
 * chefferie liée (governance_models/titles), et l'institution du référentiel.
 *
 * Règle d'or (n'invente rien) : l'apex n'est peuplé QUE s'il existe un titulaire
 * courant du siège apex ; le créateur du village n'apparaît jamais comme chef.
 * Défaut sûr = conseil acéphale, thème neutre.
 */
@Service
@RequiredArgsConstructor
public class GovernanceViewService {

    private final VillageRepository villageRepository;
    private final VillageGovernanceRepository governanceRepository;
    private final VillageOfficeRepository officeRepository;
    private final VillageOfficeHolderRepository holderRepository;
    private final GovernanceModelRepository modelRepository;
    private final GovernanceTitleLabelRepository titleLabelRepository;
    private final ChefferieRepository chefferieRepository;

    @Transactional(readOnly = true)
    public GovernanceViewDto resolve(UUID villageId) {
        Village village = villageRepository.findById(villageId)
                .orElseThrow(() -> new EntityNotFoundException("Village introuvable : " + villageId));

        Chefferie chefferie = village.getChefferieId() != null
                ? chefferieRepository.findById(village.getChefferieId()).orElse(null)
                : null;

        Optional<VillageGovernance> govOpt = governanceRepository.findById(villageId);

        // Modèle : instance adoptée en priorité, sinon celui de la chefferie liée.
        UUID modelId = govOpt.map(VillageGovernance::getModelId).orElse(null);
        if (modelId == null && chefferie != null) {
            modelId = chefferie.getGovernanceModelId();
        }
        GovernanceModel model = modelId != null
                ? modelRepository.findById(modelId).orElse(null)
                : null;

        String authorityModel = govOpt.map(VillageGovernance::getAuthorityModel)
                .orElseGet(() -> model != null ? model.getAuthorityModel() : "ACEPHALOUS");
        String themeToken = govOpt.map(VillageGovernance::getThemeToken)
                .orElseGet(() -> model != null ? model.getThemeToken() : "gov.neutral");
        String honorificStyle = govOpt.map(VillageGovernance::getHonorificStyle)
                .orElseGet(() -> model != null ? model.getHonorificStyle() : "RESPECT");
        String localePrimary = govOpt.map(VillageGovernance::getLocalePrimary).orElse("fr");

        List<VillageOffice> offices = officeRepository.findByVillageIdOrderByTierAscRankAsc(villageId);
        Map<UUID, List<VillageOfficeHolder>> holdersByOffice = holderRepository
                .findByVillageIdOrderByOrdinalAsc(villageId).stream()
                .collect(Collectors.groupingBy(VillageOfficeHolder::getOfficeId));

        List<Seat> seats = new ArrayList<>();
        Holder apex = null;
        for (VillageOffice o : offices) {
            String label = resolveLabel(o, localePrimary);
            String honorific = resolveHonorific(o, localePrimary, honorificStyle);
            List<VillageOfficeHolder> hs = holdersByOffice.getOrDefault(o.getId(), List.of());
            List<Holder> holders = hs.stream().map(h -> toHolder(h, label)).toList();
            boolean vacant = hs.stream().noneMatch(VillageOfficeHolder::isCurrent);
            seats.add(new Seat(o.getOfficeKey(), label, honorific, o.getTier(), o.getRank(),
                    o.isApex(), vacant, holders));
            if (o.isApex() && apex == null) {
                apex = hs.stream().filter(VillageOfficeHolder::isCurrent).findFirst()
                        .map(h -> toHolder(h, label)).orElse(null);
            }
        }

        boolean apexVacant = apex == null;
        // ABSENT : aucun apex courant. DOCUMENTED : un titulaire renseigné. VERIFIED
        // (ancrage vérifié) reste réservé à une évolution ultérieure.
        String state = apexVacant ? "ABSENT" : "DOCUMENTED";

        Institution institution = chefferie != null
                ? new Institution(chefferie.getDegre(), chefferie.getActe(),
                        chefferie.getApexTitleCode(),
                        model != null ? model.getCode() : null,
                        chefferie.getProperName())
                : null;

        return new GovernanceViewDto(villageId, authorityModel, themeToken, honorificStyle,
                localePrimary, state, apexVacant, apex, seats, institution);
    }

    private Holder toHolder(VillageOfficeHolder h, String seatLabel) {
        String titleLabel = (h.getTitleLabel() != null && !h.getTitleLabel().isBlank())
                ? h.getTitleLabel() : seatLabel;
        return new Holder(h.getDisplayName(), titleLabel, h.getOrdinal(),
                h.getTermStart(), h.getTermEnd(), h.isCurrent(), h.getAvatarUrl(), h.getUserId());
    }

    /** Libellé du siège : surcharge locale > libellé i18n du titre catalogue > humanisation. */
    private String resolveLabel(VillageOffice o, String locale) {
        if (o.getLabelOverride() != null && !o.getLabelOverride().isBlank()) {
            return o.getLabelOverride();
        }
        if (o.getTitleId() != null) {
            String l = pickTitleLabel(o.getTitleId(), locale, false);
            if (l != null) return l;
        }
        return humanize(o.getOfficeKey());
    }

    private String resolveHonorific(VillageOffice o, String locale, String honorificStyle) {
        if (o.getTitleId() != null) {
            String h = pickTitleLabel(o.getTitleId(), locale, true);
            if (h != null) return h;
        }
        // Défaut dérivé du registre honorifique, réservé aux registres royaux/impériaux.
        return switch (honorificStyle) {
            case "ROYAL", "IMPERIAL" -> o.isApex() ? "Sa Majesté" : null;
            default -> null;
        };
    }

    private String pickTitleLabel(UUID titleId, String locale, boolean honorific) {
        List<GovernanceTitleLabel> labels = titleLabelRepository.findByTitleId(titleId);
        if (labels.isEmpty()) return null;
        GovernanceTitleLabel chosen = labels.stream()
                .filter(l -> locale.equals(l.getLocale())).findFirst()
                .or(() -> labels.stream().filter(l -> "fr".equals(l.getLocale())).findFirst())
                .orElse(labels.get(0));
        return honorific ? chosen.getHonorific() : chosen.getLabel();
    }

    /** Libellé générique quand le siège n'est pas relié au catalogue de titres. */
    private String humanize(String officeKey) {
        return switch (officeKey) {
            case "head" -> "Chef";
            case "queen_mother" -> "Reine-mère";
            case "notable" -> "Notable";
            case "elder" -> "Aîné du conseil";
            case "spokesperson" -> "Porte-parole";
            case "kingmaker" -> "Faiseur de roi";
            case "women_leader" -> "Cheffe des femmes";
            case "kwifon", "regulatory" -> "Société régulatrice";
            default -> officeKey;
        };
    }
}
