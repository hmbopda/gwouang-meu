package com.gwangmeu.genealogy.events;

import java.util.UUID;

public record AiSuggestionAcceptedEvent(UUID suggestionId, UUID personAId, UUID personBId, String relation) {}
