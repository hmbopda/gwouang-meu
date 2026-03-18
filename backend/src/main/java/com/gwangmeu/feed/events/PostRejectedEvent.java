package com.gwangmeu.feed.events;

import com.gwangmeu.shared.events.DomainEvent;

import java.util.UUID;

/**
 * Publie quand un post est rejete par un moderateur.
 * Consomme par : notification-module (notifie l'auteur avec la note de rejet).
 */
public class PostRejectedEvent extends DomainEvent {

    private final UUID postId;
    private final UUID moderatorId;
    private final String note;

    public PostRejectedEvent(UUID postId, UUID moderatorId, String note) {
        super("feed.post_rejected");
        this.postId = postId;
        this.moderatorId = moderatorId;
        this.note = note;
    }

    public UUID getPostId()     { return postId; }
    public UUID getModeratorId(){ return moderatorId; }
    public String getNote()     { return note; }
}
