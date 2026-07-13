package com.gwangmeu.feed.application;

import com.gwangmeu.feed.domain.Comment;
import com.gwangmeu.feed.domain.ModerationStatus;
import com.gwangmeu.feed.domain.Post;
import com.gwangmeu.feed.domain.PostReaction;
import com.gwangmeu.feed.events.PostCreatedEvent;
import com.gwangmeu.feed.events.PostModeratedEvent;
import com.gwangmeu.feed.events.PostSubmittedEvent;
import com.gwangmeu.feed.infrastructure.CommentRepository;
import com.gwangmeu.feed.infrastructure.PostReactionRepository;
import com.gwangmeu.feed.infrastructure.PostRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
class FeedServiceImpl implements FeedService {

    private final PostRepository postRepository;
    private final CommentRepository commentRepository;
    private final PostReactionRepository reactionRepository;
    private final ApplicationEventPublisher eventPublisher;

    @Override
    public Post createPost(CreatePostCommand command) {
        Post post = Post.builder()
                .authorId(command.authorId())
                .villageId(command.villageId())
                .content(command.content())
                .mediaUrl(command.mediaUrl())
                .moderationStatus(ModerationStatus.PENDING)
                .build();

        Post saved = postRepository.save(post);
        // ai-module ecoute pour moderation automatique Claude
        eventPublisher.publishEvent(new PostCreatedEvent(saved.getId(), saved.getAuthorId(),
                saved.getVillageId(), saved.getContent()));
        // notification-module ecoute pour alerter les moderateurs du village
        eventPublisher.publishEvent(new PostSubmittedEvent(saved.getId(), saved.getVillageId(),
                saved.getAuthorId()));
        log.info("Post created: {} by user {}", saved.getId(), saved.getAuthorId());
        return saved;
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<Post> findPostById(UUID postId) {
        return postRepository.findById(postId);
    }

    @Override
    @Transactional(readOnly = true)
    public List<Post> getVillageFeed(UUID villageId, int page, int size) {
        return postRepository.findByVillageIdAndModerationStatus(villageId, ModerationStatus.APPROVED,
                PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt")));
    }

    @Override
    @Transactional(readOnly = true)
    public List<Post> getUserFeed(UUID userId, int page, int size) {
        return postRepository.findByAuthorId(userId,
                PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt")));
    }

    @Override
    @Transactional(readOnly = true)
    public List<Post> getGlobalFeed(int page, int size) {
        return postRepository.findByModerationStatus(ModerationStatus.APPROVED,
                PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt")));
    }

    @Override
    @Transactional(readOnly = true)
    public List<Post> getMembershipFeed(UUID userId, int page, int size) {
        int safeSize = Math.min(Math.max(size, 1), 50);
        int safePage = Math.max(page, 0);
        return postRepository.findMembershipFeed(userId, safeSize, safePage * safeSize);
    }

    @Override
    public void moderatePost(UUID postId, String status, String reason) {
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new IllegalArgumentException("Post not found: " + postId));

        ModerationStatus newStatus = ModerationStatus.valueOf(status.toUpperCase());
        post.setModerationStatus(newStatus);
        post.setModerationReason(reason);
        postRepository.save(post);

        eventPublisher.publishEvent(new PostModeratedEvent(postId, newStatus.name(), reason));
        log.info("Post {} moderated: {}", postId, newStatus);
    }

    @Override
    public Post pinPost(UUID postId) {
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new IllegalArgumentException("Post not found: " + postId));
        post.setPinned(!post.isPinned());
        return postRepository.save(post);
    }

    @Override
    public Comment addComment(UUID postId, UUID authorId, String content, UUID parentCommentId) {
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new IllegalArgumentException("Post not found: " + postId));

        Comment comment = Comment.builder()
                .postId(postId)
                .authorId(authorId)
                .content(content)
                .parentCommentId(parentCommentId)
                .build();

        Comment saved = commentRepository.save(comment);
        post.setCommentCount(post.getCommentCount() + 1);
        postRepository.save(post);
        return saved;
    }

    @Override
    @Transactional(readOnly = true)
    public List<Comment> getComments(UUID postId) {
        return commentRepository.findByPostIdOrderByCreatedAtAsc(postId);
    }

    @Override
    public PostReaction react(UUID postId, UUID userId, String reactionType) {
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new IllegalArgumentException("Post not found: " + postId));

        PostReaction reaction = reactionRepository.findByPostIdAndUserId(postId, userId)
                .orElse(PostReaction.builder().postId(postId).userId(userId).build());

        reaction.setType(reactionType.toUpperCase());
        PostReaction saved = reactionRepository.save(reaction);
        post.setReactionCount(reactionRepository.countByPostId(postId));
        postRepository.save(post);
        return saved;
    }

    @Override
    public void removeReaction(UUID postId, UUID userId) {
        reactionRepository.deleteByPostIdAndUserId(postId, userId);
        postRepository.findById(postId).ifPresent(post -> {
            post.setReactionCount(reactionRepository.countByPostId(postId));
            postRepository.save(post);
        });
    }

    @Override
    public void deletePost(UUID postId, UUID requesterId) {
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new IllegalArgumentException("Post not found: " + postId));
        if (!post.getAuthorId().equals(requesterId)) {
            throw new IllegalStateException("Only the author can delete their post");
        }
        postRepository.delete(post);
        log.info("Post {} deleted by {}", postId, requesterId);
    }
}
