package com.gwangmeu.feed.events;

import com.gwangmeu.shared.events.DomainEvent;

import java.util.UUID;

/**
 * Publie quand un post est approuve par un moderateur.
 * Consomme par :
 *   - notification-module : notifie l'auteur que son post est publie
 *   - user-module         : incremente le score de confiance de l'auteur
 */
public class PostApprovedEvent extends DomainEvent {

    private final UUID postId;
    private final UUID moderatorId;

    public PostApprovedEvent(UUID postId, UUID moderatorId) {
        super("feed.post_approved");
        this.postId = postId;
        this.moderatorId = moderatorId;
    }

    public UUID getPostId()     { return postId; }
    public UUID getModeratorId(){ return moderatorId; }
}
