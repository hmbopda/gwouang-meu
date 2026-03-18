package com.gwangmeu.genealogy.events;

import java.util.UUID;

/**
 * Publie quand un co-parent accepte ou refuse une demande de modification d'une fiche enfant.
 */
public record PersonModificationRespondedEvent(
        UUID requestId,
        UUID personId,
        UUID requesterId,
        UUID responderId,
        boolean accepted
) {}
