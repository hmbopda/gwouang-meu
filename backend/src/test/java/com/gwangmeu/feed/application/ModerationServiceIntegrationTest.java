package com.gwangmeu.feed.application;

import com.gwangmeu.feed.domain.ModerationLog;
import com.gwangmeu.feed.domain.ModerationQueue;
import com.gwangmeu.feed.domain.ModerationStatus;
import com.gwangmeu.feed.domain.Post;
import com.gwangmeu.feed.dto.ModerationStatsDto;
import com.gwangmeu.feed.infrastructure.ModerationLogRepository;
import com.gwangmeu.feed.infrastructure.ModerationQueueRepository;
import com.gwangmeu.feed.infrastructure.PostRepository;
import com.gwangmeu.shared.BaseIntegrationTest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@Transactional
@DisplayName("ModerationService - Tests d'integration")
class ModerationServiceIntegrationTest extends BaseIntegrationTest {

    @Autowired
    private ModerationService moderationService;

    @Autowired
    private PostRepository postRepository;

    @Autowired
    private ModerationQueueRepository queueRepository;

    @Autowired
    private ModerationLogRepository logRepository;

    private UUID villageId;
    private UUID authorId;
    private UUID moderatorId;

    @BeforeEach
    void setUp() {
        logRepository.deleteAllInBatch();
        queueRepository.deleteAllInBatch();
        postRepository.deleteAllInBatch();

        villageId = UUID.randomUUID();
        authorId = UUID.randomUUID();
        moderatorId = UUID.randomUUID();
    }

    private Post createPost(ModerationStatus status) {
        Post post = Post.builder()
                .authorId(authorId)
                .villageId(villageId)
                .content("Contenu de test")
                .moderationStatus(status)
                .build();
        return postRepository.saveAndFlush(post);
    }

    // ── moderatePost ─────────────────────────────────────────────────────────

    @Nested
    @DisplayName("moderatePost()")
    class ModeratePost {

        @Test
        @DisplayName("PENDING -> APPROVED doit mettre a jour le statut et creer un log")
        void shouldApprovePendingPost() {
            Post post = createPost(ModerationStatus.PENDING);

            moderationService.moderatePost(post.getId(), moderatorId, ModerationStatus.APPROVED, "Bon contenu");

            Post updated = postRepository.findById(post.getId()).orElseThrow();
            assertThat(updated.getModerationStatus()).isEqualTo(ModerationStatus.APPROVED);
            assertThat(updated.getModeratedBy()).isEqualTo(moderatorId);
            assertThat(updated.getModeratedAt()).isNotNull();
            assertThat(updated.getModerationNote()).isEqualTo("Bon contenu");

            List<ModerationLog> logs = logRepository.findByPostIdOrderByCreatedAtDesc(post.getId());
            assertThat(logs).hasSize(1);
            assertThat(logs.get(0).getAction()).isEqualTo(ModerationStatus.APPROVED);
            assertThat(logs.get(0).getModeratorId()).isEqualTo(moderatorId);
        }

        @Test
        @DisplayName("PENDING -> REJECTED doit exiger une note")
        void shouldRequireNoteForRejection() {
            Post post = createPost(ModerationStatus.PENDING);

            assertThatThrownBy(() ->
                    moderationService.moderatePost(post.getId(), moderatorId, ModerationStatus.REJECTED, null))
                    .isInstanceOf(IllegalArgumentException.class);

            assertThatThrownBy(() ->
                    moderationService.moderatePost(post.getId(), moderatorId, ModerationStatus.REJECTED, "  "))
                    .isInstanceOf(IllegalArgumentException.class);
        }

        @Test
        @DisplayName("PENDING -> REJECTED avec note doit fonctionner")
        void shouldRejectPendingWithNote() {
            Post post = createPost(ModerationStatus.PENDING);

            moderationService.moderatePost(post.getId(), moderatorId, ModerationStatus.REJECTED, "Contenu inapproprie");

            Post updated = postRepository.findById(post.getId()).orElseThrow();
            assertThat(updated.getModerationStatus()).isEqualTo(ModerationStatus.REJECTED);
            assertThat(updated.getModerationNote()).isEqualTo("Contenu inapproprie");
        }

        @Test
        @DisplayName("FLAGGED -> SHADOW_BANNED doit supprimer les entrees de queue")
        void shouldShadowBanFlaggedPost() {
            Post post = createPost(ModerationStatus.FLAGGED);
            // Ajouter des entrees dans la queue de moderation
            queueRepository.saveAndFlush(ModerationQueue.builder()
                    .postId(post.getId())
                    .villageId(villageId)
                    .reason("Spam")
                    .reporterId(UUID.randomUUID())
                    .build());

            moderationService.moderatePost(post.getId(), moderatorId, ModerationStatus.SHADOW_BANNED, "Spam confirme");

            Post updated = postRepository.findById(post.getId()).orElseThrow();
            assertThat(updated.getModerationStatus()).isEqualTo(ModerationStatus.SHADOW_BANNED);
            assertThat(queueRepository.countByPostId(post.getId())).isZero();
        }

        @Test
        @DisplayName("FLAGGED -> APPROVED doit supprimer les entrees de queue")
        void shouldApproveFlaggedPost() {
            Post post = createPost(ModerationStatus.FLAGGED);
            queueRepository.saveAndFlush(ModerationQueue.builder()
                    .postId(post.getId())
                    .villageId(villageId)
                    .reason("Signalement non justifie")
                    .reporterId(UUID.randomUUID())
                    .build());

            moderationService.moderatePost(post.getId(), moderatorId, ModerationStatus.APPROVED, "Contenu OK apres examen");

            Post updated = postRepository.findById(post.getId()).orElseThrow();
            assertThat(updated.getModerationStatus()).isEqualTo(ModerationStatus.APPROVED);
            assertThat(queueRepository.countByPostId(post.getId())).isZero();
        }

        @Test
        @DisplayName("Transitions invalides doivent echouer")
        void shouldRejectInvalidTransitions() {
            // REJECTED -> APPROVED (invalide, doit passer par resubmit)
            Post rejected = createPost(ModerationStatus.REJECTED);
            assertThatThrownBy(() ->
                    moderationService.moderatePost(rejected.getId(), moderatorId, ModerationStatus.APPROVED, null))
                    .isInstanceOf(IllegalStateException.class);

            // SHADOW_BANNED -> APPROVED (invalide)
            Post banned = createPost(ModerationStatus.SHADOW_BANNED);
            assertThatThrownBy(() ->
                    moderationService.moderatePost(banned.getId(), moderatorId, ModerationStatus.APPROVED, null))
                    .isInstanceOf(IllegalStateException.class);

            // PENDING -> SHADOW_BANNED (invalide)
            Post pending = createPost(ModerationStatus.PENDING);
            assertThatThrownBy(() ->
                    moderationService.moderatePost(pending.getId(), moderatorId, ModerationStatus.SHADOW_BANNED, null))
                    .isInstanceOf(IllegalStateException.class);
        }

        @Test
        @DisplayName("Post introuvable doit lancer IllegalArgumentException")
        void shouldThrowForUnknownPost() {
            assertThatThrownBy(() ->
                    moderationService.moderatePost(UUID.randomUUID(), moderatorId, ModerationStatus.APPROVED, null))
                    .isInstanceOf(IllegalArgumentException.class);
        }
    }

    // ── flagPost ──────────────────────────────────────────────────────────────

    @Nested
    @DisplayName("flagPost()")
    class FlagPost {

        @Test
        @DisplayName("doit creer une entree dans la queue et incrementer le flagCount")
        void shouldCreateQueueEntryAndIncrementFlag() {
            Post post = createPost(ModerationStatus.APPROVED);
            UUID reporterId = UUID.randomUUID();

            moderationService.flagPost(post.getId(), reporterId, "Contenu offensant");

            Post updated = postRepository.findById(post.getId()).orElseThrow();
            assertThat(updated.getFlagCount()).isEqualTo(1);

            assertThat(queueRepository.findByPostIdAndReporterId(post.getId(), reporterId)).isPresent();
        }

        @Test
        @DisplayName("doit empêcher le doublon de signalement par le meme utilisateur")
        void shouldPreventDuplicateFlag() {
            Post post = createPost(ModerationStatus.APPROVED);
            UUID reporterId = UUID.randomUUID();

            moderationService.flagPost(post.getId(), reporterId, "Premier signalement");

            assertThatThrownBy(() ->
                    moderationService.flagPost(post.getId(), reporterId, "Deuxieme signalement"))
                    .isInstanceOf(IllegalStateException.class);
        }

        @Test
        @DisplayName("doit auto-transitionner APPROVED -> FLAGGED au seuil de 3")
        void shouldAutoTransitionToFlaggedAtThreshold() {
            Post post = createPost(ModerationStatus.APPROVED);

            // 3 signalements differents
            moderationService.flagPost(post.getId(), UUID.randomUUID(), "Raison 1");
            moderationService.flagPost(post.getId(), UUID.randomUUID(), "Raison 2");
            moderationService.flagPost(post.getId(), UUID.randomUUID(), "Raison 3");

            Post updated = postRepository.findById(post.getId()).orElseThrow();
            assertThat(updated.getModerationStatus()).isEqualTo(ModerationStatus.FLAGGED);
            assertThat(updated.getFlagCount()).isEqualTo(3);

            // Un log automatique doit etre cree
            List<ModerationLog> logs = logRepository.findByPostIdOrderByCreatedAtDesc(post.getId());
            assertThat(logs).isNotEmpty();
            assertThat(logs.get(0).getAction()).isEqualTo(ModerationStatus.FLAGGED);
            assertThat(logs.get(0).getModeratorId()).isNull(); // transition automatique
        }

        @Test
        @DisplayName("ne doit pas transitionner si flagCount < 3")
        void shouldNotTransitionBelowThreshold() {
            Post post = createPost(ModerationStatus.APPROVED);

            moderationService.flagPost(post.getId(), UUID.randomUUID(), "Raison 1");
            moderationService.flagPost(post.getId(), UUID.randomUUID(), "Raison 2");

            Post updated = postRepository.findById(post.getId()).orElseThrow();
            assertThat(updated.getModerationStatus()).isEqualTo(ModerationStatus.APPROVED);
            assertThat(updated.getFlagCount()).isEqualTo(2);
        }

        @Test
        @DisplayName("ne doit pas permettre de signaler un post REJECTED")
        void shouldNotAllowFlaggingRejectedPost() {
            Post post = createPost(ModerationStatus.REJECTED);

            assertThatThrownBy(() ->
                    moderationService.flagPost(post.getId(), UUID.randomUUID(), "Raison"))
                    .isInstanceOf(IllegalStateException.class);
        }

        @Test
        @DisplayName("ne doit pas permettre de signaler un post SHADOW_BANNED")
        void shouldNotAllowFlaggingShadowBannedPost() {
            Post post = createPost(ModerationStatus.SHADOW_BANNED);

            assertThatThrownBy(() ->
                    moderationService.flagPost(post.getId(), UUID.randomUUID(), "Raison"))
                    .isInstanceOf(IllegalStateException.class);
        }
    }

    // ── resubmitPost ──────────────────────────────────────────────────────────

    @Nested
    @DisplayName("resubmitPost()")
    class ResubmitPost {

        @Test
        @DisplayName("doit resoumettre un post REJECTED en PENDING")
        void shouldResubmitRejectedPost() {
            Post post = createPost(ModerationStatus.REJECTED);
            post.setModerationNote("Raison du rejet");
            post.setModeratedBy(moderatorId);
            postRepository.saveAndFlush(post);

            moderationService.resubmitPost(post.getId(), authorId);

            Post updated = postRepository.findById(post.getId()).orElseThrow();
            assertThat(updated.getModerationStatus()).isEqualTo(ModerationStatus.PENDING);
            assertThat(updated.getModerationNote()).isNull();
            assertThat(updated.getModeratedBy()).isNull();
            assertThat(updated.getModeratedAt()).isNull();
        }

        @Test
        @DisplayName("doit echouer si l'appelant n'est pas l'auteur")
        void shouldThrowIfNotAuthor() {
            Post post = createPost(ModerationStatus.REJECTED);

            assertThatThrownBy(() ->
                    moderationService.resubmitPost(post.getId(), UUID.randomUUID()))
                    .isInstanceOf(SecurityException.class);
        }

        @Test
        @DisplayName("doit echouer si le post n'est pas REJECTED")
        void shouldThrowIfNotRejected() {
            Post post = createPost(ModerationStatus.APPROVED);

            assertThatThrownBy(() ->
                    moderationService.resubmitPost(post.getId(), authorId))
                    .isInstanceOf(IllegalStateException.class);
        }
    }

    // ── getStats ──────────────────────────────────────────────────────────────

    @Nested
    @DisplayName("getStats()")
    class GetStats {

        @Test
        @DisplayName("doit retourner les statistiques correctes par statut")
        void shouldReturnCorrectStats() {
            createPost(ModerationStatus.PENDING);
            createPost(ModerationStatus.PENDING);
            createPost(ModerationStatus.APPROVED);
            createPost(ModerationStatus.FLAGGED);
            createPost(ModerationStatus.REJECTED);

            ModerationStatsDto stats = moderationService.getStats(villageId);

            assertThat(stats.pendingCount()).isEqualTo(2);
            assertThat(stats.approvedCount()).isEqualTo(1);
            assertThat(stats.flaggedCount()).isEqualTo(1);
            assertThat(stats.rejectedCount()).isEqualTo(1);
            assertThat(stats.shadowBannedCount()).isZero();
        }

        @Test
        @DisplayName("doit retourner des zeros pour un village sans posts")
        void shouldReturnZerosForEmptyVillage() {
            ModerationStatsDto stats = moderationService.getStats(UUID.randomUUID());

            assertThat(stats.pendingCount()).isZero();
            assertThat(stats.approvedCount()).isZero();
            assertThat(stats.flaggedCount()).isZero();
            assertThat(stats.rejectedCount()).isZero();
            assertThat(stats.shadowBannedCount()).isZero();
        }
    }

    // ── getQueue ──────────────────────────────────────────────────────────────

    @Nested
    @DisplayName("getQueue()")
    class GetQueue {

        @Test
        @DisplayName("doit retourner les entrees de moderation pour un village")
        void shouldReturnQueueForVillage() {
            Post post = createPost(ModerationStatus.APPROVED);

            queueRepository.saveAndFlush(ModerationQueue.builder()
                    .postId(post.getId())
                    .villageId(villageId)
                    .reason("Spam")
                    .reporterId(UUID.randomUUID())
                    .build());

            queueRepository.saveAndFlush(ModerationQueue.builder()
                    .postId(post.getId())
                    .villageId(villageId)
                    .reason("Offensant")
                    .reporterId(UUID.randomUUID())
                    .build());

            List<ModerationQueue> queue = moderationService.getQueue(villageId, 0, 10);

            assertThat(queue).hasSize(2);
        }
    }

    // ── getLogs ────────────────────────────────────────────────────────────────

    @Nested
    @DisplayName("getLogs()")
    class GetLogs {

        @Test
        @DisplayName("doit retourner les logs de moderation pour un village")
        void shouldReturnLogsForVillage() {
            Post post = createPost(ModerationStatus.PENDING);

            // Approuver le post pour generer un log
            moderationService.moderatePost(post.getId(), moderatorId, ModerationStatus.APPROVED, "OK");

            List<ModerationLog> logs = moderationService.getLogs(villageId, 0, 10);

            assertThat(logs).hasSize(1);
            assertThat(logs.get(0).getAction()).isEqualTo(ModerationStatus.APPROVED);
        }
    }
}
