package com.gwangmeu.feed.domain;

/**
 * Machine a etats du post.
 *
 * Transitions valides :
 *   PENDING      → APPROVED       (moderateur approuve, ou auto si auteur confirme)
 *   PENDING      → REJECTED       (moderateur rejette — note obligatoire)
 *   APPROVED     → FLAGGED        (>= 3 signalements d'utilisateurs)
 *   FLAGGED      → SHADOW_BANNED  (moderateur confirme la sanction)
 *   FLAGGED      → APPROVED       (moderateur innocente le post)
 *   REJECTED     → PENDING        (auteur edite et resoumet)
 */
public enum ModerationStatus {
    PENDING,
    APPROVED,
    REJECTED,
    FLAGGED,
    SHADOW_BANNED
}
