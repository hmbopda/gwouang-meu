package com.gwangmeu.feed.events;

import com.gwangmeu.shared.events.DomainEvent;

import java.util.UUID;

/**
 * Publie quand un post est cree.
 * Consomme par : ai-module (moderation automatique Claude),
 *                search-module (indexation Meilisearch),
 *                notification-module (notif aux membres du village).
 */
public class PostCreatedEvent extends DomainEvent {

    private final UUID postId;
    private final UUID authorId;
    private final UUID villageId;
    private final String content;

    public PostCreatedEvent(UUID postId, UUID authorId, UUID villageId, String content) {
        super("feed.post_created");
        this.postId = postId;
        this.authorId = authorId;
        this.villageId = villageId;
        this.content = content;
    }

    public UUID getPostId() { return postId; }
    public UUID getAuthorId() { return authorId; }
    public UUID getVillageId() { return villageId; }
    public String getContent() { return content; }
}
