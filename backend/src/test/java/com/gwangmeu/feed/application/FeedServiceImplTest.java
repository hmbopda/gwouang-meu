package com.gwangmeu.feed.application;

import com.gwangmeu.feed.domain.Comment;
import com.gwangmeu.feed.domain.ModerationStatus;
import com.gwangmeu.feed.domain.Post;
import com.gwangmeu.feed.domain.PostReaction;
import com.gwangmeu.feed.events.PostCreatedEvent;
import com.gwangmeu.feed.events.PostSubmittedEvent;
import com.gwangmeu.feed.infrastructure.CommentRepository;
import com.gwangmeu.feed.infrastructure.PostReactionRepository;
import com.gwangmeu.feed.infrastructure.PostRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;

import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("FeedServiceImpl — Tests unitaires")
class FeedServiceImplTest {

    @Mock private PostRepository postRepository;
    @Mock private CommentRepository commentRepository;
    @Mock private PostReactionRepository reactionRepository;
    @Mock private ApplicationEventPublisher eventPublisher;

    @InjectMocks private FeedServiceImpl feedService;

    @Captor private ArgumentCaptor<Post> postCaptor;
    @Captor private ArgumentCaptor<Comment> commentCaptor;

    private final UUID authorId = UUID.randomUUID();
    private final UUID villageId = UUID.randomUUID();
    private final UUID postId = UUID.randomUUID();
    private final UUID userId = UUID.randomUUID();

    // ========================================================================
    // createPost
    // ========================================================================

    @Nested
    @DisplayName("createPost — Creation d'un post")
    class CreatePostTests {

        @Test
        @DisplayName("Doit creer un post en PENDING et publier deux evenements")
        void shouldCreatePostInPendingAndPublishEvents() {
            CreatePostCommand command = new CreatePostCommand(authorId, villageId, "Contenu test", null);
            Post savedPost = Post.builder()
                    .authorId(authorId).villageId(villageId)
                    .content("Contenu test").moderationStatus(ModerationStatus.PENDING)
                    .build();
            savedPost.setId(postId);

            when(postRepository.save(any(Post.class))).thenReturn(savedPost);

            Post result = feedService.createPost(command);

            assertThat(result.getId()).isEqualTo(postId);
            assertThat(result.getModerationStatus()).isEqualTo(ModerationStatus.PENDING);

            verify(postRepository).save(postCaptor.capture());
            Post captured = postCaptor.getValue();
            assertThat(captured.getAuthorId()).isEqualTo(authorId);
            assertThat(captured.getVillageId()).isEqualTo(villageId);
            assertThat(captured.getContent()).isEqualTo("Contenu test");

            verify(eventPublisher, times(2)).publishEvent(any(Object.class));
        }

        @Test
        @DisplayName("Doit inclure le mediaUrl dans le post cree")
        void shouldIncludeMediaUrl() {
            CreatePostCommand command = new CreatePostCommand(authorId, villageId, "Post avec media", "https://cdn.gwangmeu.com/img.jpg");
            Post savedPost = Post.builder()
                    .authorId(authorId).villageId(villageId)
                    .content("Post avec media").mediaUrl("https://cdn.gwangmeu.com/img.jpg")
                    .moderationStatus(ModerationStatus.PENDING).build();
            savedPost.setId(postId);

            when(postRepository.save(any(Post.class))).thenReturn(savedPost);

            feedService.createPost(command);

            verify(postRepository).save(postCaptor.capture());
            assertThat(postCaptor.getValue().getMediaUrl()).isEqualTo("https://cdn.gwangmeu.com/img.jpg");
        }
    }

    // ========================================================================
    // findPostById
    // ========================================================================

    @Nested
    @DisplayName("findPostById — Recherche par ID")
    class FindPostByIdTests {

        @Test
        @DisplayName("Doit retourner le post quand il existe")
        void shouldReturnPostWhenExists() {
            Post post = Post.builder().authorId(authorId).content("Test").build();
            post.setId(postId);
            when(postRepository.findById(postId)).thenReturn(Optional.of(post));

            Optional<Post> result = feedService.findPostById(postId);

            assertThat(result).isPresent();
            assertThat(result.get().getId()).isEqualTo(postId);
        }

        @Test
        @DisplayName("Doit retourner empty quand le post n'existe pas")
        void shouldReturnEmptyWhenNotExists() {
            when(postRepository.findById(postId)).thenReturn(Optional.empty());

            Optional<Post> result = feedService.findPostById(postId);

            assertThat(result).isEmpty();
        }
    }

    // ========================================================================
    // moderatePost
    // ========================================================================

    @Nested
    @DisplayName("moderatePost — Moderation d'un post")
    class ModeratePostTests {

        @Test
        @DisplayName("Doit changer le statut et publier un PostModeratedEvent")
        void shouldChangeStatusAndPublishEvent() {
            Post post = Post.builder().authorId(authorId).villageId(villageId)
                    .content("Contenu").moderationStatus(ModerationStatus.PENDING).build();
            post.setId(postId);

            when(postRepository.findById(postId)).thenReturn(Optional.of(post));
            when(postRepository.save(any(Post.class))).thenReturn(post);

            feedService.moderatePost(postId, "APPROVED", "Contenu OK");

            assertThat(post.getModerationStatus()).isEqualTo(ModerationStatus.APPROVED);
            assertThat(post.getModerationReason()).isEqualTo("Contenu OK");
            verify(eventPublisher).publishEvent(any(Object.class));
        }

        @Test
        @DisplayName("Doit lever IllegalArgumentException quand le post n'existe pas")
        void shouldThrowWhenPostNotFound() {
            when(postRepository.findById(postId)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> feedService.moderatePost(postId, "APPROVED", "OK"))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("Post not found");
        }
    }

    // ========================================================================
    // pinPost
    // ========================================================================

    @Nested
    @DisplayName("pinPost — Epinglage d'un post")
    class PinPostTests {

        @Test
        @DisplayName("Doit basculer l'etat pinned de false a true")
        void shouldTogglePinFromFalseToTrue() {
            Post post = Post.builder().authorId(authorId).content("Test").pinned(false).build();
            post.setId(postId);

            when(postRepository.findById(postId)).thenReturn(Optional.of(post));
            when(postRepository.save(any(Post.class))).thenAnswer(inv -> inv.getArgument(0));

            Post result = feedService.pinPost(postId);

            assertThat(result.isPinned()).isTrue();
        }

        @Test
        @DisplayName("Doit basculer l'etat pinned de true a false")
        void shouldTogglePinFromTrueToFalse() {
            Post post = Post.builder().authorId(authorId).content("Test").pinned(true).build();
            post.setId(postId);

            when(postRepository.findById(postId)).thenReturn(Optional.of(post));
            when(postRepository.save(any(Post.class))).thenAnswer(inv -> inv.getArgument(0));

            Post result = feedService.pinPost(postId);

            assertThat(result.isPinned()).isFalse();
        }

        @Test
        @DisplayName("Doit lever IllegalArgumentException quand le post n'existe pas")
        void shouldThrowWhenPostNotFound() {
            when(postRepository.findById(postId)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> feedService.pinPost(postId))
                    .isInstanceOf(IllegalArgumentException.class);
        }
    }

    // ========================================================================
    // addComment
    // ========================================================================

    @Nested
    @DisplayName("addComment — Ajout d'un commentaire")
    class AddCommentTests {

        @Test
        @DisplayName("Doit creer un commentaire et incrementer le compteur")
        void shouldCreateCommentAndIncrementCount() {
            Post post = Post.builder().authorId(authorId).content("Post")
                    .moderationStatus(ModerationStatus.APPROVED).commentCount(0).build();
            post.setId(postId);

            Comment savedComment = Comment.builder()
                    .postId(postId).authorId(userId).content("Super!").build();
            savedComment.setId(UUID.randomUUID());

            when(postRepository.findById(postId)).thenReturn(Optional.of(post));
            when(commentRepository.save(any(Comment.class))).thenReturn(savedComment);
            when(postRepository.save(any(Post.class))).thenReturn(post);

            Comment result = feedService.addComment(postId, userId, "Super!", null);

            assertThat(result.getPostId()).isEqualTo(postId);
            assertThat(result.getContent()).isEqualTo("Super!");

            verify(postRepository).save(postCaptor.capture());
            assertThat(postCaptor.getValue().getCommentCount()).isEqualTo(1);
        }

        @Test
        @DisplayName("Doit supporter un parentCommentId pour les reponses")
        void shouldSupportParentCommentId() {
            Post post = Post.builder().authorId(authorId).content("Post").commentCount(0).build();
            post.setId(postId);
            UUID parentId = UUID.randomUUID();

            Comment savedComment = Comment.builder()
                    .postId(postId).authorId(userId).content("Reponse").parentCommentId(parentId).build();
            savedComment.setId(UUID.randomUUID());

            when(postRepository.findById(postId)).thenReturn(Optional.of(post));
            when(commentRepository.save(any(Comment.class))).thenReturn(savedComment);
            when(postRepository.save(any(Post.class))).thenReturn(post);

            Comment result = feedService.addComment(postId, userId, "Reponse", parentId);

            assertThat(result.getParentCommentId()).isEqualTo(parentId);
        }
    }

    // ========================================================================
    // getComments
    // ========================================================================

    @Nested
    @DisplayName("getComments — Recuperation des commentaires")
    class GetCommentsTests {

        @Test
        @DisplayName("Doit retourner les commentaires tries par date ascendante")
        void shouldReturnCommentsSortedAsc() {
            Comment c1 = Comment.builder().postId(postId).content("Premier").build();
            Comment c2 = Comment.builder().postId(postId).content("Deuxieme").build();

            when(commentRepository.findByPostIdOrderByCreatedAtAsc(postId)).thenReturn(List.of(c1, c2));

            List<Comment> result = feedService.getComments(postId);

            assertThat(result).hasSize(2);
        }

        @Test
        @DisplayName("Doit retourner une liste vide quand pas de commentaires")
        void shouldReturnEmptyList() {
            when(commentRepository.findByPostIdOrderByCreatedAtAsc(postId)).thenReturn(Collections.emptyList());

            assertThat(feedService.getComments(postId)).isEmpty();
        }
    }

    // ========================================================================
    // react
    // ========================================================================

    @Nested
    @DisplayName("react — Reaction a un post")
    class ReactTests {

        @Test
        @DisplayName("Doit creer une nouvelle reaction et mettre a jour le compteur")
        void shouldCreateNewReaction() {
            Post post = Post.builder().authorId(authorId).content("Post").reactionCount(0).build();
            post.setId(postId);

            PostReaction savedReaction = PostReaction.builder()
                    .postId(postId).userId(userId).type("LIKE").build();
            savedReaction.setId(UUID.randomUUID());

            when(postRepository.findById(postId)).thenReturn(Optional.of(post));
            when(reactionRepository.findByPostIdAndUserId(postId, userId)).thenReturn(Optional.empty());
            when(reactionRepository.save(any(PostReaction.class))).thenReturn(savedReaction);
            when(reactionRepository.countByPostId(postId)).thenReturn(1);
            when(postRepository.save(any(Post.class))).thenReturn(post);

            PostReaction result = feedService.react(postId, userId, "like");

            assertThat(result.getType()).isEqualTo("LIKE");
            verify(postRepository).save(postCaptor.capture());
            assertThat(postCaptor.getValue().getReactionCount()).isEqualTo(1);
        }

        @Test
        @DisplayName("Doit convertir le type de reaction en majuscules")
        void shouldConvertToUpperCase() {
            Post post = Post.builder().authorId(authorId).content("Post").reactionCount(0).build();
            post.setId(postId);

            when(postRepository.findById(postId)).thenReturn(Optional.of(post));
            when(reactionRepository.findByPostIdAndUserId(postId, userId)).thenReturn(Optional.empty());
            when(reactionRepository.save(any(PostReaction.class))).thenAnswer(inv -> inv.getArgument(0));
            when(reactionRepository.countByPostId(postId)).thenReturn(1);
            when(postRepository.save(any(Post.class))).thenReturn(post);

            feedService.react(postId, userId, "culture");

            verify(reactionRepository).save(argThat(r -> "CULTURE".equals(r.getType())));
        }
    }

    // ========================================================================
    // removeReaction
    // ========================================================================

    @Nested
    @DisplayName("removeReaction — Suppression d'une reaction")
    class RemoveReactionTests {

        @Test
        @DisplayName("Doit supprimer la reaction et mettre a jour le compteur")
        void shouldRemoveAndUpdateCount() {
            Post post = Post.builder().authorId(authorId).content("Post").reactionCount(3).build();
            post.setId(postId);

            when(postRepository.findById(postId)).thenReturn(Optional.of(post));
            when(reactionRepository.countByPostId(postId)).thenReturn(2);
            when(postRepository.save(any(Post.class))).thenReturn(post);

            feedService.removeReaction(postId, userId);

            verify(reactionRepository).deleteByPostIdAndUserId(postId, userId);
            verify(postRepository).save(postCaptor.capture());
            assertThat(postCaptor.getValue().getReactionCount()).isEqualTo(2);
        }
    }

    // ========================================================================
    // deletePost
    // ========================================================================

    @Nested
    @DisplayName("deletePost — Suppression d'un post")
    class DeletePostTests {

        @Test
        @DisplayName("Doit supprimer le post quand le demandeur est l'auteur")
        void shouldDeleteWhenRequesterIsAuthor() {
            Post post = Post.builder().authorId(authorId).content("A supprimer").build();
            post.setId(postId);

            when(postRepository.findById(postId)).thenReturn(Optional.of(post));

            feedService.deletePost(postId, authorId);

            verify(postRepository).delete(post);
        }

        @Test
        @DisplayName("Doit lever IllegalStateException quand le demandeur n'est pas l'auteur")
        void shouldThrowWhenNotAuthor() {
            UUID otherUserId = UUID.randomUUID();
            Post post = Post.builder().authorId(authorId).content("Post d'un autre").build();
            post.setId(postId);

            when(postRepository.findById(postId)).thenReturn(Optional.of(post));

            assertThatThrownBy(() -> feedService.deletePost(postId, otherUserId))
                    .isInstanceOf(IllegalStateException.class)
                    .hasMessage("Only the author can delete their post");

            verify(postRepository, never()).delete(any(Post.class));
        }

        @Test
        @DisplayName("Doit lever IllegalArgumentException quand le post n'existe pas")
        void shouldThrowWhenPostNotFound() {
            when(postRepository.findById(postId)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> feedService.deletePost(postId, authorId))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("Post not found");
        }
    }
}
