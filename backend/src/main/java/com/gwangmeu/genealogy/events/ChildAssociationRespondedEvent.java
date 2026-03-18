package com.gwangmeu.genealogy.events;

import java.util.UUID;

/**
 * Publie quand un co-parent accepte ou refuse une demande d'association d'enfant.
 */
public record ChildAssociationRespondedEvent(
        UUID requestId,
        UUID childId,
        UUID requesterId,
        UUID responderId,
        boolean accepted
) {}
