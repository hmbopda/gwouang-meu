package com.gwangmeu.village.domain;

/**
 * Statut d'une validation culturelle/successorale.
 * String-backed : mappe directement sur la colonne status VARCHAR(20).
 */
public enum VillageValidationStatus {
    PENDING,
    APPROVED,
    REJECTED
}
