package com.gwangmeu.feed.events;

import com.gwangmeu.shared.events.DomainEvent;

import java.util.UUID;

/**
 * Publie quand un post est modere (approuve ou rejete).
 * Consomme par : notification-module (notif a l'auteur du post).
 */
public class PostModeratedEvent extends DomainEvent {

    private final UUID postId;
    private final String status;
    private final String reason;

    public PostModeratedEvent(UUID postId, String status, String reason) {
        super("feed.post_moderated");
        this.postId = postId;
        this.status = status;
        this.reason = reason;
    }

    public UUID getPostId() { return postId; }
    public String getStatus() { return status; }
    public String getReason() { return reason; }
}
