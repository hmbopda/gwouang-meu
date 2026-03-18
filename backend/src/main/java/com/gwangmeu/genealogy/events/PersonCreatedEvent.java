package com.gwangmeu.genealogy.events;

import java.util.List;
import java.util.UUID;

public record PersonCreatedEvent(UUID personId, List<UUID> villageIds, UUID createdBy) {}
