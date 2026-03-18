package com.gwangmeu.genealogy.events;

import java.util.UUID;

public record UnionEndedEvent(UUID unionId, UUID husbandId, UUID wifeId) {}
