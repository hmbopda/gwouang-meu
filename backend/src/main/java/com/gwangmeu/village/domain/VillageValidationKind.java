package com.gwangmeu.village.domain;

/**
 * Nature d'une validation culturelle/successorale soumise pour un village.
 * String-backed : mappe directement sur la colonne kind VARCHAR(20).
 */
public enum VillageValidationKind {
    CLAN,
    CHEFFERIE,
    CHIEF_LINE,
    SUCCESSION
}
