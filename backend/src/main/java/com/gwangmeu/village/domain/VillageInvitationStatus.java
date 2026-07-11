package com.gwangmeu.village.domain;

/**
 * Statut d'une invitation a rejoindre un village.
 * String-backed : mappe directement sur la colonne status VARCHAR(20).
 */
public enum VillageInvitationStatus {
    PENDING,
    ACCEPTED,
    DECLINED,
    EXPIRED
}
