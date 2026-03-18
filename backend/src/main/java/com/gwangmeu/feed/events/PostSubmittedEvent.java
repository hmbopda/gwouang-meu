package com.gwangmeu.feed.events;

import com.gwangmeu.shared.events.DomainEvent;

import java.util.UUID;

/**
 * Publie quand un post est soumis et entre en file de moderation.
 * Consomme par : notification-module (notifie les moderateurs du village).
 */
public class PostSubmittedEvent extends DomainEvent {

    private final UUID postId;
    private final UUID villageId;
    private final UUID authorId;

    public PostSubmittedEvent(UUID postId, UUID villageId, UUID authorId) {
        super("feed.post_submitted");
        this.postId = postId;
        this.villageId = villageId;
        this.authorId = authorId;
    }

    public UUID getPostId()   { return postId; }
    public UUID getVillageId(){ return villageId; }
    public UUID getAuthorId() { return authorId; }
}
