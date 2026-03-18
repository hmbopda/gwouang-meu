package com.gwangmeu.genealogy.events;

import java.util.UUID;

public record FamilyLinkSuggestedEvent(
        UUID suggestionId,
        UUID personAId,
        UUID personBId,
        String relationshipType,
        double confidenceScore
) {}
