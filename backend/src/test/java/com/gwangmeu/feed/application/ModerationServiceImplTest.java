package com.gwangmeu.feed.application;

import com.gwangmeu.feed.domain.ModerationLog;
import com.gwangmeu.feed.domain.ModerationQueue;
import com.gwangmeu.feed.domain.ModerationStatus;
import com.gwangmeu.feed.domain.Post;
import com.gwangmeu.feed.dto.ModerationStatsDto;
import com.gwangmeu.feed.events.PostApprovedEvent;
import com.gwangmeu.feed.events.PostFlaggedEvent;
import com.gwangmeu.feed.events.PostRejectedEvent;
import com.gwangmeu.feed.infrastructure.ModerationLogRepository;
import com.gwangmeu.feed.infrastructure.ModerationQueueRepository;
import com.gwangmeu.feed.infrastructure.PostRepository;
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

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("ModerationServiceImpl — Tests unitaires")
class ModerationServiceImplTest {

    @Mock private PostRepository postRepository;
    @Mock private ModerationQueueRepository queueRepository;
    @Mock private ModerationLogRepository logRepository;
    @Mock private FlagRateLimiter rateLimiter;
    @Mock private ApplicationEventPublisher eventPublisher;

    @InjectMocks private ModerationServiceImpl moderationService;

    @Captor private ArgumentCaptor<Post> postCaptor;
    @Captor private ArgumentCaptor<ModerationLog> logCaptor;
    @Captor private ArgumentCaptor<Object> eventCaptor;

    private final UUID postId = UUID.randomUUID();
    private final UUID moderatorId = UUID.randomUUID();
    private final UUID authorId = UUID.randomUUID();
    private final UUID reporterId = UUID.randomUUID();
    private final UUID villageId = UUID.randomUUID();

    private Post buildPost(ModerationStatus status, int flagCount) {
        Post post = Post.builder()
                .authorId(authorId).villageId(villageId)
                .content("Contenu test").moderationStatus(status)
                .flagCount(flagCount).build();
        post.setId(postId);
        return post;
    }

    // =========================================================================
    // moderatePost
    // =========================================================================

    @Nested
    @DisplayName("moderatePost — Decision de moderation")
    class ModeratePostTests {

        @Test
        @DisplayName("PENDING -> APPROVED : doit approuver, logger, publier PostApprovedEvent et nettoyer la queue")
        void shouldApprovePendingPost() {
            Post post = buildPost(ModerationStatus.PENDING, 0);
            when(postRepository.findById(postId)).thenReturn(Optional.of(post));

            moderationService.moderatePost(postId, moderatorId, ModerationStatus.APPROVED, "OK");

            assertThat(post.getModerationStatus()).isEqualTo(ModerationStatus.APPROVED);
            assertThat(post.getModerationNote()).isEqualTo("OK");
            assertThat(post.getModeratedBy()).isEqualTo(moderatorId);
            verify(postRepository).save(post);
            verify(logRepository).save(any(ModerationLog.class));
            verify(queueRepository).deleteByPostId(postId);
            verify(eventPublisher).publishEvent(any(PostApprovedEvent.class));
        }

        @Test
        @DisplayName("PENDING -> REJECTED : doit rejeter avec note obligatoire et publier PostRejectedEvent")
        void shouldRejectPendingPostWithNote() {
            Post post = buildPost(ModerationStatus.PENDING, 0);
            when(postRepository.findById(postId)).thenReturn(Optional.of(post));

            moderationService.moderatePost(postId, moderatorId, ModerationStatus.REJECTED, "Contenu haineux");

            assertThat(post.getModerationStatus()).isEqualTo(ModerationStatus.REJECTED);
            verify(eventPublisher).publishEvent(any(PostRejectedEvent.class));
        }

        @Test
        @DisplayName("PENDING -> REJECTED sans note : doit lever IllegalArgumentException")
        void shouldThrowWhenRejectingWithoutNote() {
            Post post = buildPost(ModerationStatus.PENDING, 0);
            when(postRepository.findById(postId)).thenReturn(Optional.of(post));

            assertThatThrownBy(() ->
                    moderationService.moderatePost(postId, moderatorId, ModerationStatus.REJECTED, null))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("note");
        }

        @Test
        @DisplayName("FLAGGED -> SHADOW_BANNED : doit bannir et nettoyer la queue")
        void shouldShadowBanFlaggedPost() {
            Post post = buildPost(ModerationStatus.FLAGGED, 5);
            when(postRepository.findById(postId)).thenReturn(Optional.of(post));

            moderationService.moderatePost(postId, moderatorId, ModerationStatus.SHADOW_BANNED, "Contenu haineux");

            assertThat(post.getModerationStatus()).isEqualTo(ModerationStatus.SHADOW_BANNED);
            verify(queueRepository).deleteByPostId(postId);
        }

        @Test
        @DisplayName("FLAGGED -> APPROVED : doit re-approuver un post signale")
        void shouldReApproveFlaggedPost() {
            Post post = buildPost(ModerationStatus.FLAGGED, 3);
            when(postRepository.findById(postId)).thenReturn(Optional.of(post));

            moderationService.moderatePost(postId, moderatorId, ModerationStatus.APPROVED, "Fausse alerte");

            assertThat(post.getModerationStatus()).isEqualTo(ModerationStatus.APPROVED);
            verify(queueRepository).deleteByPostId(postId);
        }

        @Test
        @DisplayName("Transition invalide PENDING -> FLAGGED : doit lever IllegalStateException")
        void shouldThrowOnInvalidTransition() {
            Post post = buildPost(ModerationStatus.PENDING, 0);
            when(postRepository.findById(postId)).thenReturn(Optional.of(post));

            assertThatThrownBy(() ->
                    moderationService.moderatePost(postId, moderatorId, ModerationStatus.FLAGGED, "Invalid"))
                    .isInstanceOf(IllegalStateException.class)
                    .hasMessageContaining("Transition de moderation invalide");
        }

        @Test
        @DisplayName("Transition invalide REJECTED -> APPROVED : doit lever IllegalStateException")
        void shouldThrowOnRejectedToApproved() {
            Post post = buildPost(ModerationStatus.REJECTED, 0);
            when(postRepository.findById(postId)).thenReturn(Optional.of(post));

            assertThatThrownBy(() ->
                    moderationService.moderatePost(postId, moderatorId, ModerationStatus.APPROVED, "OK"))
                    .isInstanceOf(IllegalStateException.class);
        }

        @Test
        @DisplayName("Post introuvable : doit lever IllegalArgumentException")
        void shouldThrowWhenPostNotFound() {
            when(postRepository.findById(postId)).thenReturn(Optional.empty());

            assertThatThrownBy(() ->
                    moderationService.moderatePost(postId, moderatorId, ModerationStatus.APPROVED, "OK"))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("Post introuvable");
        }
    }

    // =========================================================================
    // flagPost
    // =========================================================================

    @Nested
    @DisplayName("flagPost — Signalement d'un post")
    class FlagPostTests {

        @Test
        @DisplayName("Doit lever IllegalStateException quand le rate limiter bloque")
        void shouldThrowWhenRateLimited() {
            when(rateLimiter.tryConsume(reporterId)).thenReturn(false);

            assertThatThrownBy(() -> moderationService.flagPost(postId, reporterId, "Spam"))
                    .isInstanceOf(IllegalStateException.class)
                    .hasMessageContaining("Quota");

            verifyNoInteractions(postRepository);
        }

        @Test
        @DisplayName("Doit creer une entree en queue et incrementer le flagCount")
        void shouldCreateQueueEntryAndIncrementFlag() {
            when(rateLimiter.tryConsume(reporterId)).thenReturn(true);
            Post post = buildPost(ModerationStatus.APPROVED, 0);
            when(postRepository.findById(postId)).thenReturn(Optional.of(post));
            when(queueRepository.findByPostIdAndReporterId(postId, reporterId)).thenReturn(Optional.empty());

            moderationService.flagPost(postId, reporterId, "Spam");

            verify(queueRepository).save(any(ModerationQueue.class));
            verify(postRepository).save(postCaptor.capture());
            assertThat(postCaptor.getValue().getFlagCount()).isEqualTo(1);
            verify(eventPublisher).publishEvent(any(PostFlaggedEvent.class));
        }

        @Test
        @DisplayName("Doit lever IllegalStateException si deja signale par le meme utilisateur")
        void shouldThrowWhenAlreadyFlagged() {
            when(rateLimiter.tryConsume(reporterId)).thenReturn(true);
            Post post = buildPost(ModerationStatus.APPROVED, 1);
            when(postRepository.findById(postId)).thenReturn(Optional.of(post));
            when(queueRepository.findByPostIdAndReporterId(postId, reporterId))
                    .thenReturn(Optional.of(ModerationQueue.builder().build()));

            assertThatThrownBy(() -> moderationService.flagPost(postId, reporterId, "Spam"))
                    .isInstanceOf(IllegalStateException.class)
                    .hasMessageContaining("deja signale");
        }

        @Test
        @DisplayName("Doit lever IllegalStateException si le post est REJECTED ou SHADOW_BANNED")
        void shouldThrowWhenPostIsRejectedOrBanned() {
            when(rateLimiter.tryConsume(reporterId)).thenReturn(true);
            Post post = buildPost(ModerationStatus.REJECTED, 0);
            when(postRepository.findById(postId)).thenReturn(Optional.of(post));

            assertThatThrownBy(() -> moderationService.flagPost(postId, reporterId, "Spam"))
                    .isInstanceOf(IllegalStateException.class)
                    .hasMessageContaining("ne peut plus etre signale");
        }

        @Nested
        @DisplayName("Auto-transition APPROVED -> FLAGGED au seuil de 3")
        class AutoTransitionTests {

            @Test
            @DisplayName("Doit passer en FLAGGED quand flagCount atteint 3 et statut est APPROVED")
            void shouldAutoTransitionToFlaggedAtThreshold() {
                when(rateLimiter.tryConsume(reporterId)).thenReturn(true);
                Post post = buildPost(ModerationStatus.APPROVED, 2);
                when(postRepository.findById(postId)).thenReturn(Optional.of(post));
                when(queueRepository.findByPostIdAndReporterId(postId, reporterId)).thenReturn(Optional.empty());

                moderationService.flagPost(postId, reporterId, "3eme signalement");

                verify(postRepository).save(postCaptor.capture());
                Post saved = postCaptor.getValue();
                assertThat(saved.getModerationStatus()).isEqualTo(ModerationStatus.FLAGGED);
                assertThat(saved.getFlagCount()).isEqualTo(3);
                verify(logRepository).save(logCaptor.capture());
                assertThat(logCaptor.getValue().getModeratorId()).isNull();
            }

            @Test
            @DisplayName("Ne doit PAS changer le statut si flagCount < 3")
            void shouldNotAutoTransitionBelowThreshold() {
                when(rateLimiter.tryConsume(reporterId)).thenReturn(true);
                Post post = buildPost(ModerationStatus.APPROVED, 0);
                when(postRepository.findById(postId)).thenReturn(Optional.of(post));
                when(queueRepository.findByPostIdAndReporterId(postId, reporterId)).thenReturn(Optional.empty());

                moderationService.flagPost(postId, reporterId, "Premier signalement");

                verify(postRepository).save(postCaptor.capture());
                assertThat(postCaptor.getValue().getModerationStatus()).isEqualTo(ModerationStatus.APPROVED);
                verify(logRepository, never()).save(any());
            }

            @Test
            @DisplayName("Ne doit PAS auto-transitionner si le statut est PENDING meme au seuil")
            void shouldNotAutoTransitionFromPending() {
                when(rateLimiter.tryConsume(reporterId)).thenReturn(true);
                Post post = buildPost(ModerationStatus.PENDING, 2);
                when(postRepository.findById(postId)).thenReturn(Optional.of(post));
                when(queueRepository.findByPostIdAndReporterId(postId, reporterId)).thenReturn(Optional.empty());

                moderationService.flagPost(postId, reporterId, "Signalement en PENDING");

                verify(postRepository).save(postCaptor.capture());
                assertThat(postCaptor.getValue().getModerationStatus()).isEqualTo(ModerationStatus.PENDING);
                verify(logRepository, never()).save(any());
            }
        }
    }

    // =========================================================================
    // resubmitPost
    // =========================================================================

    @Nested
    @DisplayName("resubmitPost — Resoumission d'un post rejete")
    class ResubmitPostTests {

        @Test
        @DisplayName("Doit remettre en PENDING et effacer les champs de moderation")
        void shouldResetToPending() {
            Post post = buildPost(ModerationStatus.REJECTED, 0);
            post.setModerationNote("Raison du rejet");
            post.setModeratedBy(moderatorId);
            when(postRepository.findById(postId)).thenReturn(Optional.of(post));

            moderationService.resubmitPost(postId, authorId);

            verify(postRepository).save(postCaptor.capture());
            Post saved = postCaptor.getValue();
            assertThat(saved.getModerationStatus()).isEqualTo(ModerationStatus.PENDING);
            assertThat(saved.getModerationNote()).isNull();
            assertThat(saved.getModeratedBy()).isNull();
            assertThat(saved.getModeratedAt()).isNull();
        }

        @Test
        @DisplayName("Doit lever SecurityException quand l'appelant n'est pas l'auteur")
        void shouldThrowWhenNotAuthor() {
            Post post = buildPost(ModerationStatus.REJECTED, 0);
            when(postRepository.findById(postId)).thenReturn(Optional.of(post));

            assertThatThrownBy(() -> moderationService.resubmitPost(postId, UUID.randomUUID()))
                    .isInstanceOf(SecurityException.class)
                    .hasMessageContaining("auteur");
        }

        @Test
        @DisplayName("Doit lever IllegalStateException quand le post n'est pas REJECTED")
        void shouldThrowWhenNotRejected() {
            Post post = buildPost(ModerationStatus.APPROVED, 0);
            when(postRepository.findById(postId)).thenReturn(Optional.of(post));

            assertThatThrownBy(() -> moderationService.resubmitPost(postId, authorId))
                    .isInstanceOf(IllegalStateException.class)
                    .hasMessageContaining("REJECTED");
        }
    }

    // =========================================================================
    // getStats
    // =========================================================================

    @Nested
    @DisplayName("getStats — Statistiques de moderation")
    class GetStatsTests {

        @Test
        @DisplayName("Doit retourner les compteurs pour chaque statut")
        void shouldReturnCountsForEachStatus() {
            when(postRepository.countByVillageIdAndModerationStatus(villageId, ModerationStatus.PENDING)).thenReturn(5L);
            when(postRepository.countByVillageIdAndModerationStatus(villageId, ModerationStatus.FLAGGED)).thenReturn(2L);
            when(postRepository.countByVillageIdAndModerationStatus(villageId, ModerationStatus.APPROVED)).thenReturn(100L);
            when(postRepository.countByVillageIdAndModerationStatus(villageId, ModerationStatus.REJECTED)).thenReturn(3L);
            when(postRepository.countByVillageIdAndModerationStatus(villageId, ModerationStatus.SHADOW_BANNED)).thenReturn(1L);

            ModerationStatsDto stats = moderationService.getStats(villageId);

            assertThat(stats.pendingCount()).isEqualTo(5L);
            assertThat(stats.flaggedCount()).isEqualTo(2L);
            assertThat(stats.approvedCount()).isEqualTo(100L);
            assertThat(stats.rejectedCount()).isEqualTo(3L);
            assertThat(stats.shadowBannedCount()).isEqualTo(1L);
        }
    }
}
