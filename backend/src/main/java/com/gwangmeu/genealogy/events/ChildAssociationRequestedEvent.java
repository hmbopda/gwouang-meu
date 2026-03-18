package com.gwangmeu.genealogy.events;

import java.util.UUID;

/**
 * Publie quand un utilisateur cree un enfant et demande a un co-parent de valider la filiation.
 */
public record ChildAssociationRequestedEvent(
        UUID requestId,
        UUID childId,
        UUID requesterId,
        UUID targetParentId
) {}
