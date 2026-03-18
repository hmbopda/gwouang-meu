package com.gwangmeu.feed;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.gwangmeu.feed.domain.ModerationStatus;
import com.gwangmeu.feed.domain.Post;
import com.gwangmeu.feed.infrastructure.ModerationQueueRepository;
import com.gwangmeu.feed.infrastructure.PostRepository;
import com.gwangmeu.shared.BaseIntegrationTest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@DisplayName("Moderation Workflow Tests")
class ModerationControllerTest extends BaseIntegrationTest {

    @Autowired MockMvc       mockMvc;
    @Autowired ObjectMapper  objectMapper;
    @Autowired PostRepository          postRepository;
    @Autowired ModerationQueueRepository queueRepository;

    private UUID villageId;
    private UUID authorId;
    private UUID moderatorId;

    @BeforeEach
    void setUp() {
        queueRepository.deleteAll();
        postRepository.deleteAll();
        villageId   = UUID.randomUUID();
        authorId    = UUID.randomUUID();
        moderatorId = UUID.randomUUID();
    }

    // -------------------------------------------------------------------------
    // Helper
    // -------------------------------------------------------------------------

    private Post createPost(ModerationStatus status) {
        return postRepository.save(Post.builder()
                .authorId(authorId)
                .villageId(villageId)
                .content("Contenu de test pour la moderation")
                .moderationStatus(status)
                .build());
    }

    // =========================================================================
    // 1. PENDING → APPROVED
    // =========================================================================

    @Nested
    @DisplayName("Transition PENDING → APPROVED")
    class ApprovePendingPost {

        @Test
        @WithMockUser(roles = "MODERATEUR")
        @DisplayName("Should approve a PENDING post")
        void approvePost_success() throws Exception {
            Post post = createPost(ModerationStatus.PENDING);

            mockMvc.perform(put("/api/v1/posts/{id}/moderate", post.getId())
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(Map.of(
                            "action", "APPROVED"
                    ))))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true));

            Post updated = postRepository.findById(post.getId()).orElseThrow();
            assertThat(updated.getModerationStatus()).isEqualTo(ModerationStatus.APPROVED);
            assertThat(updated.getModeratedAt()).isNotNull();
        }

        @Test
        @WithMockUser(roles = "MEMBRE")
        @DisplayName("Should deny approval for MEMBRE role")
        void approvePost_forbiddenForMembre() throws Exception {
            Post post = createPost(ModerationStatus.PENDING);

            mockMvc.perform(put("/api/v1/posts/{id}/moderate", post.getId())
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(Map.of("action", "APPROVED"))))
                    .andExpect(status().isForbidden());
        }
    }

    // =========================================================================
    // 2. PENDING → REJECTED (note obligatoire)
    // =========================================================================

    @Nested
    @DisplayName("Transition PENDING → REJECTED")
    class RejectPendingPost {

        @Test
        @WithMockUser(roles = "MODERATEUR")
        @DisplayName("Should reject a PENDING post with note")
        void rejectPost_withNote_success() throws Exception {
            Post post = createPost(ModerationStatus.PENDING);

            mockMvc.perform(put("/api/v1/posts/{id}/moderate", post.getId())
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(Map.of(
                            "action", "REJECTED",
                            "note", "Contenu offensant envers les coutumes du village."
                    ))))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true));

            Post updated = postRepository.findById(post.getId()).orElseThrow();
            assertThat(updated.getModerationStatus()).isEqualTo(ModerationStatus.REJECTED);
            assertThat(updated.getModerationNote()).isNotBlank();
        }

        @Test
        @WithMockUser(roles = "MODERATEUR")
        @DisplayName("Should fail rejection without note")
        void rejectPost_withoutNote_fails() throws Exception {
            Post post = createPost(ModerationStatus.PENDING);

            mockMvc.perform(put("/api/v1/posts/{id}/moderate", post.getId())
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(Map.of("action", "REJECTED"))))
                    .andExpect(status().isBadRequest());
        }
    }

    // =========================================================================
    // 3. APPROVED → FLAGGED (auto via 3 signalements)
    // =========================================================================

    @Nested
    @DisplayName("Transition APPROVED → FLAGGED (auto via signalements)")
    class FlagApprovedPost {

        @Test
        @WithMockUser(roles = "MEMBRE")
        @DisplayName("Should flag post and auto-transition to FLAGGED at threshold 3")
        void flagPost_autoTransitionAtThreshold() throws Exception {
            Post post = createPost(ModerationStatus.APPROVED);

            // 1er signalement
            flagAs(UUID.randomUUID(), post.getId(), "Raison signalement 1");
            assertThat(postRepository.findById(post.getId()).orElseThrow().getModerationStatus())
                    .isEqualTo(ModerationStatus.APPROVED);

            // 2eme signalement
            flagAs(UUID.randomUUID(), post.getId(), "Raison signalement 2");
            assertThat(postRepository.findById(post.getId()).orElseThrow().getModerationStatus())
                    .isEqualTo(ModerationStatus.APPROVED);

            // 3eme signalement → auto FLAGGED
            flagAs(UUID.randomUUID(), post.getId(), "Raison signalement 3");
            Post updated = postRepository.findById(post.getId()).orElseThrow();
            assertThat(updated.getModerationStatus()).isEqualTo(ModerationStatus.FLAGGED);
            assertThat(updated.getFlagCount()).isEqualTo(3);
        }

        @Test
        @WithMockUser(roles = "MEMBRE")
        @DisplayName("Should prevent duplicate flag from same user")
        void flagPost_duplicateFlag_fails() throws Exception {
            Post post = createPost(ModerationStatus.APPROVED);
            UUID reporterId = UUID.randomUUID();

            flagAs(reporterId, post.getId(), "Premier signalement");

            // Le meme user signale une 2eme fois → erreur
            mockMvc.perform(post("/api/v1/posts/{id}/flag", post.getId())
                    .header("X-Reporter-Id", reporterId)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(Map.of("reason", "Doublon"))))
                    .andExpect(status().isBadRequest());
        }

        private void flagAs(UUID userId, UUID postId, String reason) throws Exception {
            mockMvc.perform(post("/api/v1/posts/{id}/flag", postId)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(Map.of("reason", reason))))
                    .andExpect(status().isOk());
        }
    }

    // =========================================================================
    // 4. FLAGGED → SHADOW_BANNED
    // =========================================================================

    @Nested
    @DisplayName("Transition FLAGGED → SHADOW_BANNED")
    class ShadowBanFlaggedPost {

        @Test
        @WithMockUser(roles = "MODERATEUR")
        @DisplayName("Should shadow-ban a FLAGGED post with note")
        void shadowBan_success() throws Exception {
            Post post = createPost(ModerationStatus.FLAGGED);

            mockMvc.perform(put("/api/v1/posts/{id}/moderate", post.getId())
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(Map.of(
                            "action", "SHADOW_BANNED",
                            "note", "Contenu grave, sanction permanente."
                    ))))
                    .andExpect(status().isOk());

            assertThat(postRepository.findById(post.getId()).orElseThrow().getModerationStatus())
                    .isEqualTo(ModerationStatus.SHADOW_BANNED);
        }
    }

    // =========================================================================
    // 5. REJECTED → PENDING (resoumission)
    // =========================================================================

    @Nested
    @DisplayName("Transition REJECTED → PENDING (resoumission auteur)")
    class ResubmitRejectedPost {

        @Test
        @WithMockUser
        @DisplayName("Should resubmit a REJECTED post to PENDING")
        void resubmit_success() throws Exception {
            Post post = createPost(ModerationStatus.REJECTED);

            mockMvc.perform(post("/api/v1/posts/{id}/resubmit", post.getId()))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true));

            assertThat(postRepository.findById(post.getId()).orElseThrow().getModerationStatus())
                    .isEqualTo(ModerationStatus.PENDING);
        }

        @Test
        @WithMockUser
        @DisplayName("Should fail resubmit on PENDING post")
        void resubmit_notRejected_fails() throws Exception {
            Post post = createPost(ModerationStatus.PENDING);

            mockMvc.perform(post("/api/v1/posts/{id}/resubmit", post.getId()))
                    .andExpect(status().isBadRequest());
        }
    }

    // =========================================================================
    // 6. Transitions invalides
    // =========================================================================

    @Nested
    @DisplayName("Transitions invalides")
    class InvalidTransitions {

        @Test
        @WithMockUser(roles = "MODERATEUR")
        @DisplayName("Should reject SHADOW_BANNED → APPROVED transition")
        void transition_shadowBannedToApproved_fails() throws Exception {
            Post post = createPost(ModerationStatus.SHADOW_BANNED);

            mockMvc.perform(put("/api/v1/posts/{id}/moderate", post.getId())
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(Map.of("action", "APPROVED"))))
                    .andExpect(status().isBadRequest());
        }

        @Test
        @WithMockUser(roles = "MODERATEUR")
        @DisplayName("Should reject PENDING → SHADOW_BANNED direct transition")
        void transition_pendingToShadowBanned_fails() throws Exception {
            Post post = createPost(ModerationStatus.PENDING);

            mockMvc.perform(put("/api/v1/posts/{id}/moderate", post.getId())
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(Map.of(
                            "action", "SHADOW_BANNED",
                            "note", "Tentative de bypass."
                    ))))
                    .andExpect(status().isBadRequest());
        }
    }

    // =========================================================================
    // 7. Dashboard moderation
    // =========================================================================

    @Nested
    @DisplayName("Dashboard moderateur")
    class ModerationDashboard {

        @Test
        @WithMockUser(roles = "MODERATEUR")
        @DisplayName("Should return moderation queue for village")
        void getQueue_returnsEntries() throws Exception {
            createPost(ModerationStatus.PENDING);
            createPost(ModerationStatus.PENDING);
            createPost(ModerationStatus.APPROVED);

            mockMvc.perform(get("/api/v1/moderation/queue")
                    .param("villageId", villageId.toString()))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true));
        }

        @Test
        @WithMockUser(roles = "MODERATEUR")
        @DisplayName("Should return moderation stats for village")
        void getStats_returnsAggregates() throws Exception {
            createPost(ModerationStatus.PENDING);
            createPost(ModerationStatus.APPROVED);
            createPost(ModerationStatus.REJECTED);

            mockMvc.perform(get("/api/v1/moderation/stats")
                    .param("villageId", villageId.toString()))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.data.pendingCount").value(1))
                    .andExpect(jsonPath("$.data.approvedCount").value(1))
                    .andExpect(jsonPath("$.data.rejectedCount").value(1));
        }

        @Test
        @WithMockUser(roles = "AMBASSADEUR")
        @DisplayName("Should return moderation logs for village")
        void getLogs_returnsHistory() throws Exception {
            mockMvc.perform(get("/api/v1/moderation/logs")
                    .param("villageId", villageId.toString()))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true));
        }

        @Test
        @WithMockUser(roles = "MEMBRE")
        @DisplayName("Should deny queue access for MEMBRE role")
        void getQueue_forbiddenForMembre() throws Exception {
            mockMvc.perform(get("/api/v1/moderation/queue")
                    .param("villageId", villageId.toString()))
                    .andExpect(status().isForbidden());
        }
    }
}
