/**
 * feed-module — Publications, reactions, commentaires, fil personnalise, moderation.
 * Dependances : Workflow Review, Pinned posts.
 *
 * Expose : FeedService.
 * Evenements publies : PostCreatedEvent, PostModeratedEvent.
 * Evenements consommes : UserJoinedVillageEvent (flux d'activite).
 */
@org.springframework.modulith.ApplicationModule(displayName = "Feed Module")
package com.gwangmeu.feed;
