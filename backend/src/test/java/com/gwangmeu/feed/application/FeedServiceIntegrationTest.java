package com.gwangmeu.feed.application;

import com.gwangmeu.feed.domain.Comment;
import com.gwangmeu.feed.domain.ModerationStatus;
import com.gwangmeu.feed.domain.Post;
import com.gwangmeu.feed.domain.PostReaction;
import com.gwangmeu.feed.infrastructure.CommentRepository;
import com.gwangmeu.feed.infrastructure.PostReactionRepository;
import com.gwangmeu.feed.infrastructure.PostRepository;
import com.gwangmeu.shared.BaseIntegrationTest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@Transactional
@DisplayName("FeedService - Tests d'integration")
class FeedServiceIntegrationTest extends BaseIntegrationTest {

    @Autowired
    private FeedService feedService;

    @Autowired
    private PostRepository postRepository;

    @Autowired
    private CommentRepository commentRepository;

    @Autowired
    private PostReactionRepository reactionRepository;

    private final UUID authorId = UUID.randomUUID();
    private final UUID villageId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        reactionRepository.deleteAllInBatch();
        commentRepository.deleteAllInBatch();
        postRepository.deleteAllInBatch();
    }

    private Post insertPost(ModerationStatus status) {
        Post post = Post.builder()
                .authorId(authorId)
                .villageId(villageId)
                .content("Contenu de test " + UUID.randomUUID())
                .moderationStatus(status)
                .build();
        return postRepository.saveAndFlush(post);
    }

    // ── createPost ───────────────────────────────────────────────────────────

    @Nested
    @DisplayName("createPost()")
    class CreatePost {

        @Test
        @DisplayName("doit creer un post avec le statut PENDING")
        void shouldCreatePostInPending() {
            CreatePostCommand command = new CreatePostCommand(authorId, villageId, "Mon premier post", null);

            Post result = feedService.createPost(command);

            assertThat(result).isNotNull();
            assertThat(result.getId()).isNotNull();
            assertThat(result.getAuthorId()).isEqualTo(authorId);
            assertThat(result.getVillageId()).isEqualTo(villageId);
            assertThat(result.getContent()).isEqualTo("Mon premier post");
            assertThat(result.getModerationStatus()).isEqualTo(ModerationStatus.PENDING);
            assertThat(result.getCreatedAt()).isNotNull();

            Optional<Post> persisted = postRepository.findById(result.getId());
            assertThat(persisted).isPresent();
        }

        @Test
        @DisplayName("doit inclure le mediaUrl dans le post")
        void shouldIncludeMediaUrl() {
            CreatePostCommand command = new CreatePostCommand(
                    authorId, villageId, "Post avec media", "https://cdn.gwangmeu.com/img.jpg");

            Post result = feedService.createPost(command);

            assertThat(result.getMediaUrl()).isEqualTo("https://cdn.gwangmeu.com/img.jpg");
        }
    }

    // ── findPostById ─────────────────────────────────────────────────────────

    @Nested
    @DisplayName("findPostById()")
    class FindPostById {

        @Test
        @DisplayName("doit retourner le post quand il existe")
        void shouldReturnPostWhenExists() {
            Post post = insertPost(ModerationStatus.PENDING);

            Optional<Post> result = feedService.findPostById(post.getId());

            assertThat(result).isPresent();
            assertThat(result.get().getId()).isEqualTo(post.getId());
        }

        @Test
        @DisplayName("doit retourner Optional.empty quand le post n'existe pas")
        void shouldReturnEmptyWhenNotFound() {
            assertThat(feedService.findPostById(UUID.randomUUID())).isEmpty();
        }
    }

    // ── getVillageFeed ───────────────────────────────────────────────────────

    @Nested
    @DisplayName("getVillageFeed()")
    class GetVillageFeed {

        @Test
        @DisplayName("doit retourner uniquement les posts APPROVED du village")
        void shouldReturnOnlyApprovedPosts() {
            insertPost(ModerationStatus.APPROVED);
            insertPost(ModerationStatus.APPROVED);
            insertPost(ModerationStatus.PENDING);
            insertPost(ModerationStatus.REJECTED);

            List<Post> feed = feedService.getVillageFeed(villageId, 0, 10);

            assertThat(feed).hasSize(2);
            assertThat(feed).allMatch(p -> p.getModerationStatus() == ModerationStatus.APPROVED);
        }
    }

    // ── moderatePost ─────────────────────────────────────────────────────────

    @Nested
    @DisplayName("moderatePost()")
    class ModeratePost {

        @Test
        @DisplayName("doit changer le statut d'un post")
        void shouldChangeStatus() {
            Post post = insertPost(ModerationStatus.PENDING);

            feedService.moderatePost(post.getId(), "APPROVED", "Contenu OK");

            Post updated = postRepository.findById(post.getId()).orElseThrow();
            assertThat(updated.getModerationStatus()).isEqualTo(ModerationStatus.APPROVED);
            assertThat(updated.getModerationReason()).isEqualTo("Contenu OK");
        }

        @Test
        @DisplayName("doit lancer IllegalArgumentException quand le post n'existe pas")
        void shouldThrowWhenPostNotFound() {
            assertThatThrownBy(() -> feedService.moderatePost(UUID.randomUUID(), "APPROVED", "OK"))
                    .isInstanceOf(IllegalArgumentException.class);
        }
    }

    // ── pinPost ──────────────────────────────────────────────────────────────

    @Nested
    @DisplayName("pinPost()")
    class PinPost {

        @Test
        @DisplayName("doit basculer le statut pinned du post")
        void shouldTogglePinned() {
            Post post = insertPost(ModerationStatus.APPROVED);
            assertThat(post.isPinned()).isFalse();

            Post pinned = feedService.pinPost(post.getId());
            assertThat(pinned.isPinned()).isTrue();

            Post unpinned = feedService.pinPost(post.getId());
            assertThat(unpinned.isPinned()).isFalse();
        }
    }

    // ── addComment ───────────────────────────────────────────────────────────

    @Nested
    @DisplayName("addComment()")
    class AddComment {

        @Test
        @DisplayName("doit ajouter un commentaire et incrementer le compteur")
        void shouldAddCommentAndIncrementCount() {
            Post post = insertPost(ModerationStatus.APPROVED);

            Comment comment = feedService.addComment(post.getId(), authorId, "Super post!", null);

            assertThat(comment).isNotNull();
            assertThat(comment.getContent()).isEqualTo("Super post!");
            assertThat(comment.getAuthorId()).isEqualTo(authorId);
            assertThat(comment.getPostId()).isEqualTo(post.getId());

            Post updated = postRepository.findById(post.getId()).orElseThrow();
            assertThat(updated.getCommentCount()).isEqualTo(1);
        }

        @Test
        @DisplayName("doit supporter les commentaires imbriques")
        void shouldSupportNestedComments() {
            Post post = insertPost(ModerationStatus.APPROVED);
            Comment parent = feedService.addComment(post.getId(), authorId, "Commentaire parent", null);

            Comment reply = feedService.addComment(post.getId(), UUID.randomUUID(), "Reponse", parent.getId());

            assertThat(reply.getParentCommentId()).isEqualTo(parent.getId());

            Post updated = postRepository.findById(post.getId()).orElseThrow();
            assertThat(updated.getCommentCount()).isEqualTo(2);
        }
    }

    // ── getComments ──────────────────────────────────────────────────────────

    @Nested
    @DisplayName("getComments()")
    class GetComments {

        @Test
        @DisplayName("doit retourner les commentaires tries par date croissante")
        void shouldReturnCommentsSortedByDate() {
            Post post = insertPost(ModerationStatus.APPROVED);
            feedService.addComment(post.getId(), authorId, "Premier", null);
            feedService.addComment(post.getId(), authorId, "Deuxieme", null);

            List<Comment> comments = feedService.getComments(post.getId());

            assertThat(comments).hasSize(2);
            assertThat(comments.get(0).getContent()).isEqualTo("Premier");
            assertThat(comments.get(1).getContent()).isEqualTo("Deuxieme");
        }
    }

    // ── react / removeReaction ───────────────────────────────────────────────

    @Nested
    @DisplayName("react() / removeReaction()")
    class Reactions {

        @Test
        @DisplayName("doit ajouter une reaction et mettre a jour le compteur")
        void shouldAddReactionAndUpdateCount() {
            Post post = insertPost(ModerationStatus.APPROVED);
            UUID userId = UUID.randomUUID();

            PostReaction reaction = feedService.react(post.getId(), userId, "like");

            assertThat(reaction.getType()).isEqualTo("LIKE");
            Post updated = postRepository.findById(post.getId()).orElseThrow();
            assertThat(updated.getReactionCount()).isEqualTo(1);
        }

        @Test
        @DisplayName("doit mettre a jour le type de reaction si l'utilisateur reagit a nouveau")
        void shouldUpdateReactionType() {
            Post post = insertPost(ModerationStatus.APPROVED);
            UUID userId = UUID.randomUUID();

            feedService.react(post.getId(), userId, "like");
            PostReaction updated = feedService.react(post.getId(), userId, "love");

            assertThat(updated.getType()).isEqualTo("LOVE");
            Post postUpdated = postRepository.findById(post.getId()).orElseThrow();
            assertThat(postUpdated.getReactionCount()).isEqualTo(1);
        }

        @Test
        @DisplayName("doit supprimer la reaction et mettre a jour le compteur")
        void shouldRemoveReactionAndUpdateCount() {
            Post post = insertPost(ModerationStatus.APPROVED);
            UUID userId = UUID.randomUUID();
            feedService.react(post.getId(), userId, "like");

            feedService.removeReaction(post.getId(), userId);

            Post updated = postRepository.findById(post.getId()).orElseThrow();
            assertThat(updated.getReactionCount()).isEqualTo(0);
        }
    }

    // ── deletePost ───────────────────────────────────────────────────────────

    @Nested
    @DisplayName("deletePost()")
    class DeletePost {

        @Test
        @DisplayName("doit supprimer le post si le demandeur est l'auteur")
        void shouldDeleteWhenRequesterIsAuthor() {
            Post post = insertPost(ModerationStatus.APPROVED);

            feedService.deletePost(post.getId(), authorId);

            assertThat(postRepository.findById(post.getId())).isEmpty();
        }

        @Test
        @DisplayName("doit lancer IllegalStateException si le demandeur n'est pas l'auteur")
        void shouldThrowWhenRequesterIsNotAuthor() {
            Post post = insertPost(ModerationStatus.APPROVED);
            UUID otherUser = UUID.randomUUID();

            assertThatThrownBy(() -> feedService.deletePost(post.getId(), otherUser))
                    .isInstanceOf(IllegalStateException.class)
                    .hasMessageContaining("author");
        }
    }
}
