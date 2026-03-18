package com.gwangmeu.feed.events;

import com.gwangmeu.shared.events.DomainEvent;

import java.util.UUID;

/**
 * Publie quand un post est signale par un utilisateur.
 * Publie egalement quand le seuil de 3 signalements est atteint (transition APPROVED → FLAGGED).
 * Consomme par : notification-module (alerte les moderateurs du village).
 */
public class PostFlaggedEvent extends DomainEvent {

    private final UUID postId;
    private final UUID reporterId;
    private final String reason;
    private final int flagCount;

    public PostFlaggedEvent(UUID postId, UUID reporterId, String reason, int flagCount) {
        super("feed.post_flagged");
        this.postId = postId;
        this.reporterId = reporterId;
        this.reason = reason;
        this.flagCount = flagCount;
    }

    public UUID getPostId()    { return postId; }
    public UUID getReporterId(){ return reporterId; }
    public String getReason()  { return reason; }
    public int getFlagCount()  { return flagCount; }
}
