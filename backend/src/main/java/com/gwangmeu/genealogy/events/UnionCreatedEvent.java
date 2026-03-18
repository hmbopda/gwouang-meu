package com.gwangmeu.genealogy.events;

import java.util.UUID;

public record UnionCreatedEvent(UUID husbandId, UUID wifeId, UUID unionId, boolean isDotPaid) {}
