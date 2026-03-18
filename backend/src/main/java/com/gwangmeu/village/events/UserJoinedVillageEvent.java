package com.gwangmeu.village.events;

import com.gwangmeu.shared.events.DomainEvent;

import java.util.UUID;

/**
 * Publie quand un utilisateur rejoint un village.
 * Consomme par : notification-module, feed-module (flux d'activite).
 */
public class UserJoinedVillageEvent extends DomainEvent {

    private final UUID userId;
    private final UUID villageId;
    private final String subscriptionType;

    public UserJoinedVillageEvent(UUID userId, UUID villageId, String subscriptionType) {
        super("village.user_joined");
        this.userId = userId;
        this.villageId = villageId;
        this.subscriptionType = subscriptionType;
    }

    public UUID getUserId() { return userId; }
    public UUID getVillageId() { return villageId; }
    public String getSubscriptionType() { return subscriptionType; }
}
