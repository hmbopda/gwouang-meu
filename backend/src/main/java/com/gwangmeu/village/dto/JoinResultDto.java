package com.gwangmeu.village.dto;

import com.gwangmeu.village.domain.VillageJoinStatus;

/** Resultat immediat d'une demande d'adhesion (statut + statut de membre). */
public record JoinResultDto(
        VillageJoinStatus status,
        boolean member,
        String autoReason
) {}
