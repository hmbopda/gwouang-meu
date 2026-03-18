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
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
class ModerationServiceImpl implements ModerationService {

    private static final int FLAG_THRESHOLD = 3;

    private final PostRepository             postRepository;
    private final ModerationQueueRepository  queueRepository;
    private final ModerationLogRepository    logRepository;
    private final FlagRateLimiter            rateLimiter;
    private final ApplicationEventPublisher  eventPublisher;

    // -------------------------------------------------------------------------
    // Moderation decision
    // -------------------------------------------------------------------------

    @Override
    public void moderatePost(UUID postId, UUID moderatorId, ModerationStatus action, String note) {
        Post post = requirePost(postId);

        if (action == ModerationStatus.REJECTED && (note == null || note.isBlank())) {
            throw new IllegalArgumentException("La note est obligatoire pour rejeter un post.");
        }

        validateTransition(post.getModerationStatus(), action);

        post.setModerationStatus(action);
        post.setModerationNote(note);
        post.setModeratedBy(moderatorId);
        post.setModeratedAt(Instant.now());
        postRepository.save(post);

        logRepository.save(ModerationLog.builder()
                .postId(postId)
                .moderatorId(moderatorId)
                .action(action)
                .note(note)
                .build());

        // Nettoyer la file si approuve ou banni (plus besoin de review)
        if (action == ModerationStatus.APPROVED || action == ModerationStatus.SHADOW_BANNED) {
            queueRepository.deleteByPostId(postId);
        }

        // Publier l'evenement specifique — notification-module et user-module ecoutent
        switch (action) {
            case APPROVED      -> eventPublisher.publishEvent(new PostApprovedEvent(postId, moderatorId));
            case REJECTED      -> eventPublisher.publishEvent(new PostRejectedEvent(postId, moderatorId, note));
            case SHADOW_BANNED -> eventPublisher.publishEvent(new PostRejectedEvent(postId, moderatorId, "SHADOW_BANNED"));
            default            -> { /* FLAGGED manuel : pas d'event separe */ }
        }

        log.info("Post {} moderate: {} par {}", postId, action, moderatorId);
    }

    // -------------------------------------------------------------------------
    // Flag (signalement)
    // -------------------------------------------------------------------------

    @Override
    public void flagPost(UUID postId, UUID reporterId, String reason) {
        if (!rateLimiter.tryConsume(reporterId)) {
            throw new IllegalStateException("Quota de signalements atteint (max 3/heure). Reessayez plus tard.");
        }

        Post post = requirePost(postId);

        if (post.getModerationStatus() == ModerationStatus.REJECTED
                || post.getModerationStatus() == ModerationStatus.SHADOW_BANNED) {
            throw new IllegalStateException("Ce post ne peut plus etre signale (statut : " + post.getModerationStatus() + ").");
        }

        // Eviter les doublons : un utilisateur ne peut signaler qu'une fois le meme post
        if (queueRepository.findByPostIdAndReporterId(postId, reporterId).isPresent()) {
            throw new IllegalStateException("Vous avez deja signale ce post.");
        }

        queueRepository.save(ModerationQueue.builder()
                .postId(postId)
                .villageId(post.getVillageId())
                .reason(reason)
                .reporterId(reporterId)
                .build());

        int newFlagCount = post.getFlagCount() + 1;
        post.setFlagCount(newFlagCount);

        // Auto-transition APPROVED → FLAGGED quand seuil atteint
        if (newFlagCount >= FLAG_THRESHOLD && post.getModerationStatus() == ModerationStatus.APPROVED) {
            post.setModerationStatus(ModerationStatus.FLAGGED);
            logRepository.save(ModerationLog.builder()
                    .postId(postId)
                    .moderatorId(null) // transition automatique, pas de moderateur
                    .action(ModerationStatus.FLAGGED)
                    .note("Seuil de " + FLAG_THRESHOLD + " signalements atteint — transition automatique.")
                    .build());
            log.info("Post {} passe automatiquement en FLAGGED ({} signalements)", postId, newFlagCount);
        }

        postRepository.save(post);
        eventPublisher.publishEvent(new PostFlaggedEvent(postId, reporterId, reason, newFlagCount));
        log.info("Post {} signale par {} (flag #{}) : {}", postId, reporterId, newFlagCount, reason);
    }

    // -------------------------------------------------------------------------
    // Resoumission apres edition
    // -------------------------------------------------------------------------

    @Override
    public void resubmitPost(UUID postId, UUID authorId) {
        Post post = requirePost(postId);

        if (!post.getAuthorId().equals(authorId)) {
            throw new SecurityException("Seul l'auteur peut resoumettre son post.");
        }
        if (post.getModerationStatus() != ModerationStatus.REJECTED) {
            throw new IllegalStateException("Seul un post REJECTED peut etre ressoumis (statut actuel : "
                    + post.getModerationStatus() + ").");
        }

        post.setModerationStatus(ModerationStatus.PENDING);
        post.setModerationNote(null);
        post.setModeratedBy(null);
        post.setModeratedAt(null);
        postRepository.save(post);

        log.info("Post {} ressoumis en PENDING par l'auteur {}", postId, authorId);
    }

    // -------------------------------------------------------------------------
    // Lecture (dashboard moderateur)
    // -------------------------------------------------------------------------

    @Override
    @Transactional(readOnly = true)
    public List<ModerationQueue> getQueue(UUID villageId, int page, int size) {
        return queueRepository.findByVillageIdOrderByCreatedAtDesc(
                villageId,
                PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"))
        );
    }

    @Override
    @Transactional(readOnly = true)
    public ModerationStatsDto getStats(UUID villageId) {
        return new ModerationStatsDto(
                postRepository.countByVillageIdAndModerationStatus(villageId, ModerationStatus.PENDING),
                postRepository.countByVillageIdAndModerationStatus(villageId, ModerationStatus.FLAGGED),
                postRepository.countByVillageIdAndModerationStatus(villageId, ModerationStatus.APPROVED),
                postRepository.countByVillageIdAndModerationStatus(villageId, ModerationStatus.REJECTED),
                postRepository.countByVillageIdAndModerationStatus(villageId, ModerationStatus.SHADOW_BANNED)
        );
    }

    @Override
    @Transactional(readOnly = true)
    public List<ModerationLog> getLogs(UUID villageId, int page, int size) {
        return logRepository.findByVillageId(
                villageId,
                PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"))
        );
    }

    // -------------------------------------------------------------------------
    // Machine a etats — transitions valides
    // -------------------------------------------------------------------------

    private void validateTransition(ModerationStatus current, ModerationStatus next) {
        boolean valid = switch (current) {
            case PENDING      -> next == ModerationStatus.APPROVED || next == ModerationStatus.REJECTED;
            case APPROVED     -> next == ModerationStatus.FLAGGED;
            case FLAGGED      -> next == ModerationStatus.SHADOW_BANNED || next == ModerationStatus.APPROVED;
            case REJECTED     -> false; // resoumission via resubmitPost, pas via moderatePost
            case SHADOW_BANNED -> false;
        };
        if (!valid) {
            throw new IllegalStateException(
                    "Transition de moderation invalide : " + current + " → " + next);
        }
    }

    private Post requirePost(UUID postId) {
        return postRepository.findById(postId)
                .orElseThrow(() -> new IllegalArgumentException("Post introuvable : " + postId));
    }
}
