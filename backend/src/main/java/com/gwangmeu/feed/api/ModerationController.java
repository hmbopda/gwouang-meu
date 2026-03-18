package com.gwangmeu.feed.api;

import com.gwangmeu.feed.application.ModerationService;
import com.gwangmeu.feed.domain.ModerationLog;
import com.gwangmeu.feed.domain.ModerationQueue;
import com.gwangmeu.feed.domain.Post;
import com.gwangmeu.feed.dto.FlagPostRequest;
import com.gwangmeu.feed.dto.ModerateActionRequest;
import com.gwangmeu.feed.dto.ModerationLogDto;
import com.gwangmeu.feed.dto.ModerationQueueDto;
import com.gwangmeu.feed.dto.ModerationStatsDto;
import com.gwangmeu.feed.infrastructure.PostRepository;
import com.gwangmeu.shared.api.ApiResponse;
import com.gwangmeu.shared.security.CurrentUser;
import com.gwangmeu.shared.security.UserIdResolver;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequiredArgsConstructor
@Tag(name = "Moderation", description = "Workflow de moderation — file d'attente, decisions, signalements, dashboard")
public class ModerationController {

    private final ModerationService moderationService;
    private final PostRepository    postRepository;
    private final UserIdResolver    userIdResolver;

    // -------------------------------------------------------------------------
    // GET /api/v1/moderation/queue — File d'attente (MODERATEUR)
    // -------------------------------------------------------------------------

    @GetMapping("/api/v1/moderation/queue")
    @PreAuthorize("hasRole('MODERATEUR') or hasRole('SUPER_ADMIN')")
    @Operation(
        summary = "File de moderation",
        description = "Retourne les posts PENDING et FLAGGED du village, du plus recent au plus ancien."
    )
    @ApiResponses({
        @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "File retournee"),
        @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "Non authentifie"),
        @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", description = "Role insuffisant")
    })
    public ResponseEntity<ApiResponse<List<ModerationQueueDto>>> getQueue(
            @RequestParam UUID villageId,
            @RequestParam(defaultValue = "0")  int page,
            @RequestParam(defaultValue = "20") int size) {

        List<ModerationQueue> queue = moderationService.getQueue(villageId, page, size);
        List<ModerationQueueDto> dtos = queue.stream().map(entry -> {
            Post post = postRepository.findById(entry.getPostId()).orElse(null);
            return ModerationQueueDto.from(
                    entry,
                    post != null ? post.getModerationStatus() : null,
                    post != null ? post.getFlagCount() : 0,
                    post != null ? post.getContent() : null,
                    post != null ? post.getAuthorId() : null
            );
        }).toList();

        return ResponseEntity.ok(ApiResponse.ok(dtos));
    }

    // -------------------------------------------------------------------------
    // PUT /api/v1/posts/{id}/moderate — Decision de moderation (MODERATEUR)
    // -------------------------------------------------------------------------

    @PutMapping("/api/v1/posts/{postId}/moderate")
    @PreAuthorize("hasRole('MODERATEUR') or hasRole('SUPER_ADMIN')")
    @Operation(
        summary = "Moderer un post",
        description = "Applique une decision de moderation avec validation de la machine a etats. " +
                      "La note est obligatoire pour REJECTED et SHADOW_BANNED."
    )
    @ApiResponses({
        @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Decision appliquee"),
        @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "Transition invalide ou note manquante"),
        @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "Non authentifie"),
        @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", description = "Role insuffisant"),
        @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Post introuvable")
    })
    public ResponseEntity<ApiResponse<Void>> moderate(
            @PathVariable UUID postId,
            @Valid @RequestBody ModerateActionRequest request,
            @CurrentUser Jwt jwt) {

        UUID moderatorId = userIdResolver.resolve(jwt);
        moderationService.moderatePost(postId, moderatorId, request.action(), request.note());
        return ResponseEntity.ok(ApiResponse.ok(null, "Decision de moderation appliquee : " + request.action()));
    }

    // -------------------------------------------------------------------------
    // POST /api/v1/posts/{id}/flag — Signaler un post (MEMBRE)
    // -------------------------------------------------------------------------

    @PostMapping("/api/v1/posts/{postId}/flag")
    @PreAuthorize("hasRole('MEMBRE') or hasRole('AMBASSADEUR') or hasRole('MODERATEUR') or hasRole('SUPER_ADMIN')")
    @Operation(
        summary = "Signaler un post",
        description = "Signale un post comme inapproprie. Limite : 3 signalements par heure par utilisateur. " +
                      "A partir de 3 signalements, le post passe automatiquement en FLAGGED."
    )
    @ApiResponses({
        @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Signalement enregistre"),
        @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "Post deja signale ou etat incompatible"),
        @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "Non authentifie"),
        @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "429", description = "Quota de signalements depasse (3/heure)")
    })
    public ResponseEntity<ApiResponse<Void>> flagPost(
            @PathVariable UUID postId,
            @Valid @RequestBody FlagPostRequest request,
            @CurrentUser Jwt jwt) {

        UUID reporterId = userIdResolver.resolve(jwt);
        moderationService.flagPost(postId, reporterId, request.reason());
        return ResponseEntity.ok(ApiResponse.ok(null, "Signalement enregistre."));
    }

    // -------------------------------------------------------------------------
    // POST /api/v1/posts/{id}/resubmit — Resoumettre apres edition (auteur)
    // -------------------------------------------------------------------------

    @PostMapping("/api/v1/posts/{postId}/resubmit")
    @PreAuthorize("isAuthenticated()")
    @Operation(
        summary = "Resoumettre un post rejete",
        description = "Permet a l'auteur de resoumettre son post apres edition. Le post doit etre en statut REJECTED."
    )
    @ApiResponses({
        @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Post ressoumis en PENDING"),
        @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "Post non rejete ou acces refuse"),
        @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "Non authentifie")
    })
    public ResponseEntity<ApiResponse<Void>> resubmit(
            @PathVariable UUID postId,
            @CurrentUser Jwt jwt) {

        UUID authorId = userIdResolver.resolve(jwt);
        moderationService.resubmitPost(postId, authorId);
        return ResponseEntity.ok(ApiResponse.ok(null, "Post ressoumis en moderation."));
    }

    // -------------------------------------------------------------------------
    // GET /api/v1/moderation/stats — Tableau de bord (MODERATEUR)
    // -------------------------------------------------------------------------

    @GetMapping("/api/v1/moderation/stats")
    @PreAuthorize("hasRole('MODERATEUR') or hasRole('AMBASSADEUR') or hasRole('SUPER_ADMIN')")
    @Operation(
        summary = "Statistiques de moderation",
        description = "Retourne le nombre de posts par statut pour un village."
    )
    @ApiResponses({
        @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Stats retournees"),
        @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "Non authentifie"),
        @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", description = "Role insuffisant")
    })
    public ResponseEntity<ApiResponse<ModerationStatsDto>> getStats(@RequestParam UUID villageId) {
        return ResponseEntity.ok(ApiResponse.ok(moderationService.getStats(villageId)));
    }

    // -------------------------------------------------------------------------
    // GET /api/v1/moderation/logs — Historique (AMBASSADEUR)
    // -------------------------------------------------------------------------

    @GetMapping("/api/v1/moderation/logs")
    @PreAuthorize("hasRole('AMBASSADEUR') or hasRole('MODERATEUR') or hasRole('SUPER_ADMIN')")
    @Operation(
        summary = "Historique de moderation",
        description = "Retourne le journal des decisions de moderation pour un village."
    )
    @ApiResponses({
        @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Logs retournes"),
        @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "Non authentifie"),
        @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", description = "Role insuffisant")
    })
    public ResponseEntity<ApiResponse<List<ModerationLogDto>>> getLogs(
            @RequestParam UUID villageId,
            @RequestParam(defaultValue = "0")  int page,
            @RequestParam(defaultValue = "50") int size) {

        List<ModerationLogDto> dtos = moderationService.getLogs(villageId, page, size)
                .stream().map(ModerationLogDto::from).toList();
        return ResponseEntity.ok(ApiResponse.ok(dtos));
    }
}
