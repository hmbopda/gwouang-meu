package com.gwangmeu.feed.application;

import com.gwangmeu.feed.domain.Comment;
import com.gwangmeu.feed.domain.Post;
import com.gwangmeu.feed.domain.PostReaction;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface FeedService {

    Post createPost(CreatePostCommand command);

    Optional<Post> findPostById(UUID postId);

    List<Post> getVillageFeed(UUID villageId, int page, int size);

    List<Post> getUserFeed(UUID userId, int page, int size);

    List<Post> getGlobalFeed(int page, int size);

    /** Fil agrege par appartenance : posts de mes villages, clans, familles et groupes. */
    List<Post> getMembershipFeed(UUID userId, int page, int size);

    void moderatePost(UUID postId, String status, String reason);

    Post pinPost(UUID postId);

    Comment addComment(UUID postId, UUID authorId, String content, UUID parentCommentId);

    List<Comment> getComments(UUID postId);

    PostReaction react(UUID postId, UUID userId, String reactionType);

    void removeReaction(UUID postId, UUID userId);

    void deletePost(UUID postId, UUID requesterId);
}
