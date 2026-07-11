package com.gwangmeu.village.domain;

/**
 * Statut d'une demande d'adhesion a un village.
 * String-backed : mappe directement sur la colonne status VARCHAR(20).
 */
public enum VillageJoinStatus {
    PENDING,
    AUTO_APPROVED,
    APPROVED,
    REJECTED
}
