package com.gwangmeu.user.events;

import com.gwangmeu.shared.events.DomainEvent;

import java.util.UUID;

/**
 * Publie quand un profil utilisateur est modifie.
 * Consomme par : search-module (re-indexation), notification-module.
 */
public class UserUpdatedEvent extends DomainEvent {

    private final UUID userId;

    public UserUpdatedEvent(UUID userId) {
        super("user.updated");
        this.userId = userId;
    }

    public UUID getUserId() { return userId; }
}
