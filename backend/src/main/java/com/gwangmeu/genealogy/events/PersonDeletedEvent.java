package com.gwangmeu.genealogy.events;

import java.util.UUID;

public record PersonDeletedEvent(UUID personId) {}
