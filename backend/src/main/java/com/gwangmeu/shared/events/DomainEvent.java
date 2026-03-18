package com.gwangmeu.shared.events;

import java.time.Instant;
import java.util.UUID;

/**
 * Classe de base pour tous les evenements domaine.
 * Publie via ApplicationEventPublisher — jamais d'appel direct entre modules.
 *
 * Convention de nommage : ModuleAction + "Event"
 * Ex: UserCreatedEvent, VillageJoinedEvent, PostModeratedEvent
 */
public abstract class DomainEvent {

    private final UUID eventId = UUID.randomUUID();
    private final Instant occurredAt = Instant.now();
    private final String eventType;

    protected DomainEvent(String eventType) {
        this.eventType = eventType;
    }

    public UUID getEventId() { return eventId; }
    public Instant getOccurredAt() { return occurredAt; }
    public String getEventType() { return eventType; }

    @Override
    public String toString() {
        return "DomainEvent{type='" + eventType + "', id=" + eventId + ", at=" + occurredAt + '}';
    }
}
