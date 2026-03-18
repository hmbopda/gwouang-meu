package com.gwangmeu.genealogy.events;

import java.util.UUID;

public record ParentChildUnlinkedEvent(UUID parentId, UUID childId) {}
