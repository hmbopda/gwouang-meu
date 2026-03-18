package com.gwangmeu.genealogy.events;

import java.util.UUID;

/**
 * Publie quand un parent demande la modification des infos d'un enfant < 4 ans.
 * L'autre parent doit valider.
 */
public record PersonModificationRequestedEvent(
        UUID requestId,
        UUID personId,
        UUID requesterId,
        UUID targetParentId
) {}
