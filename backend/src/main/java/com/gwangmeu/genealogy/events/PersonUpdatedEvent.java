package com.gwangmeu.genealogy.events;

import java.util.List;
import java.util.UUID;

public record PersonUpdatedEvent(UUID personId, List<UUID> villageIds) {}
