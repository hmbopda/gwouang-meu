package com.gwangmeu.village.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import java.util.List;
import java.util.UUID;

/**
 * Vue de gouvernance RÉSOLUE d'un village : la config (instance village_governance
 * ou, à défaut, le template de la chefferie liée) rendue en sièges + titulaires +
 * thème. C'est ce que consomme le composant générique {@code GovernanceView} côté
 * Flutter — aucune culture n'est codée en dur : la topologie (authorityModel)
 * choisit le layout, le registre (themeToken/honorificStyle) choisit le thème.
 *
 * Généralise l'ancien /chief : n'invente JAMAIS un chef (le créateur n'apparaît pas
 * ici) ; un apex vacant est un état de première classe.
 */
@Schema(description = "Vue de gouvernance résolue d'un village")
public record GovernanceViewDto(
        UUID villageId,
        @Schema(description = "MONOCEPHALIC | DYARCHIC | COLLEGIAL | ROTATING | ACEPHALOUS")
        String authorityModel,
        @Schema(description = "gov.royal | gov.religious | gov.stool | gov.respect | gov.neutral")
        String themeToken,
        @Schema(description = "NONE | RESPECT | ROYAL | RELIGIOUS | IMPERIAL")
        String honorificStyle,
        @Schema(description = "Langue primaire des titres (BCP-47)") String localePrimary,
        @Schema(description = "ABSENT | DOCUMENTED | VERIFIED") String state,
        @Schema(description = "Vrai : aucun titulaire apex courant (siège vacant)") boolean apexVacant,
        @Schema(description = "Titulaire apex courant, ou null si vacant") Holder apex,
        @Schema(description = "Tous les sièges (apex + notables + charges spécifiques), triés") List<Seat> seats,
        @Schema(description = "Institution reconnue (référentiel chefferie), ou null") Institution institution
) {
    /** Un siège de gouvernance + ses titulaires (courant + historiques). */
    @Schema(description = "Siège de gouvernance et ses titulaires")
    public record Seat(
            UUID officeId,
            String officeKey,
            String titleLabel,
            String honorific,
            int tier,
            int rank,
            boolean isApex,
            boolean vacant,
            List<Holder> holders
    ) {}

    /** Un titulaire de siège (courant ou historique). */
    @Schema(description = "Titulaire d'un siège")
    public record Holder(
            String displayName,
            String titleLabel,
            Integer ordinal,
            Integer termStart,
            Integer termEnd,
            boolean current,
            String avatarUrl,
            UUID userId
    ) {}

    /** Institution reconnue par le référentiel (jamais fabriquée). */
    @Schema(description = "Institution reconnue : degré, acte, titre structuré")
    public record Institution(
            Short degre,
            String acte,
            String apexTitleCode,
            String modelCode,
            String properName
    ) {}
}
