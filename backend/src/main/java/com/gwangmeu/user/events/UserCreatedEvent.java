package com.gwangmeu.user.events;

import com.gwangmeu.shared.domain.enums.GenderEnum;
import com.gwangmeu.shared.events.DomainEvent;

import java.util.UUID;

/**
 * Publie quand un nouvel utilisateur s'inscrit.
 * Consomme par : notification-module (email de bienvenue).
 */
public class UserCreatedEvent extends DomainEvent {

    private final UUID userId;
    private final String email;
    private final String username;
    private final GenderEnum gender;

    public UserCreatedEvent(UUID userId, String email, String username, GenderEnum gender) {
        super("user.created");
        this.userId = userId;
        this.email = email;
        this.username = username;
        this.gender = gender;
    }

    public UUID getUserId() { return userId; }
    public String getEmail() { return email; }
    public String getUsername() { return username; }
    public GenderEnum getGender() { return gender; }
}
