package com.gwangmeu.genealogy.events;

import java.util.UUID;

public record UnionDotPaidEvent(UUID unionId, UUID husbandId, UUID wifeId, UUID paidBy) {}
