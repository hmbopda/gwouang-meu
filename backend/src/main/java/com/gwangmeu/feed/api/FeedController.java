package com.gwangmeu.feed.api;

import com.gwangmeu.feed.FeedMapper;
import com.gwangmeu.feed.application.CreatePostCommand;
import com.gwangmeu.feed.application.FeedService;
import com.gwangmeu.feed.application.ModerationService;
import com.gwangmeu.feed.domain.Comment;
import com.gwangmeu.feed.domain.CommentReaction;
import com.gwangmeu.feed.domain.ModerationStatus;
import com.gwangmeu.feed.domain.Post;
import com.gwangmeu.feed.domain.PostReaction;
import com.gwangmeu.feed.dto.CommentDto;
import com.gwangmeu.feed.dto.CreatePostRequest;
import com.gwangmeu.feed.dto.ModeratePostRequest;
import com.gwangmeu.feed.dto.PostDto;
import com.gwangmeu.feed.infrastructure.CommentReactionRepository;
import com.gwangmeu.feed.infrastructure.PostReactionRepository;
import com.gwangmeu.shared.api.ApiResponse;
import com.gwangmeu.shared.security.CurrentUser;
import com.gwangmeu.shared.security.UserIdResolver;
import com.gwangmeu.user.User;
import com.gwangmeu.user.UserRepository;
import com.gwangmeu.village.domain.Village;
import com.gwangmeu.village.infrastructure.VillageRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.persistence.EntityNotFoundException;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/feed")
@RequiredArgsConstructor
@Tag(name = "Feed", description = "Fil d'actualite — posts, commentaires, reactions")
public class FeedController {

    private final FeedService            feedService;
    private final ModerationService      moderationService;
    private final FeedMapper             feedMapper;
    private final UserIdResolver         userIdResolver;
    private final UserRepository            userRepository;
    private final VillageRepository         villageRepository;
    private final PostReactionRepository    reactionRepository;
    private final CommentReactionRepository commentReactionRepository;

    @GetMapping
    @Operation(summary = "Feed global", description = "Retourne tous les posts approuves, du plus recent au plus ancien.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Feed retourne")
    })
    public ResponseEntity<ApiResponse<List<PostDto>>> getGlobalFeed(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        List<PostDto> dtos = feedService.getGlobalFeed(page, size)
                .stream().map(feedMapper::toDto).toList();
        return ResponseEntity.ok(ApiResponse.ok(dtos));
    }

    @GetMapping("/home")
    @Operation(summary = "Fil communautaire",
               description = "Publications de mes villages, clans, familles et groupes, enrichies (auteur, village, aime par moi), du plus recent au plus ancien.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Fil retourne"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "Non authentifie")
    })
    public ResponseEntity<ApiResponse<List<PostDto>>> getHomeFeed(
            @CurrentUser Jwt jwt,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        UUID userId = userIdResolver.resolve(jwt);
        List<PostDto> dtos = enrichPosts(feedService.getMembershipFeed(userId, page, size), userId);
        return ResponseEntity.ok(ApiResponse.ok(dtos));
    }

    @PostMapping
    @Operation(summary = "Creer un post", description = "Publie un nouveau post. Statut initial : PENDING (moderation IA).")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "201", description = "Post cree"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "Validation echouee"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "Non authentifie")
    })
    public ResponseEntity<ApiResponse<PostDto>> createPost(
            @Valid @RequestBody CreatePostRequest request,
            @CurrentUser Jwt jwt) {
        UUID authorId = userIdResolver.resolve(jwt);
        CreatePostCommand command = new CreatePostCommand(
                authorId, request.villageId(), request.content(), request.mediaUrl()
        );
        PostDto dto = feedMapper.toDto(feedService.createPost(command));
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.created(dto));
    }

    @GetMapping("/{postId}")
    @Operation(summary = "Obtenir un post", description = "Retourne un post par son identifiant.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Post retourne"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Post introuvable")
    })
    public ResponseEntity<ApiResponse<PostDto>> getPost(@PathVariable UUID postId) {
        Post post = feedService.findPostById(postId)
                .orElseThrow(() -> new EntityNotFoundException("Post introuvable : " + postId));
        return ResponseEntity.ok(ApiResponse.ok(feedMapper.toDto(post)));
    }

    @GetMapping("/village/{villageId}")
    @Operation(summary = "Feed d'un village", description = "Retourne les posts approuves d'un village, du plus recent au plus ancien.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Feed retourne")
    })
    public ResponseEntity<ApiResponse<List<PostDto>>> getVillageFeed(
            @PathVariable UUID villageId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        List<PostDto> dtos = feedService.getVillageFeed(villageId, page, size)
                .stream().map(feedMapper::toDto).toList();
        return ResponseEntity.ok(ApiResponse.ok(dtos));
    }

    @GetMapping("/my-feed")
    @Operation(summary = "Mon feed", description = "Retourne les posts de l'utilisateur connecte.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Feed retourne"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "Non authentifie")
    })
    public ResponseEntity<ApiResponse<List<PostDto>>> getMyFeed(
            @CurrentUser Jwt jwt,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        UUID userId = userIdResolver.resolve(jwt);
        List<PostDto> dtos = feedService.getUserFeed(userId, page, size)
                .stream().map(feedMapper::toDto).toList();
        return ResponseEntity.ok(ApiResponse.ok(dtos));
    }

    @PutMapping("/{postId}/moderate")
    @PreAuthorize("hasRole('MODERATEUR') or hasRole('SUPER_ADMIN')")
    @Operation(summary = "Moderer un post", description = "Change le statut de moderation d'un post.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Moderation appliquee"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", description = "Role insuffisant"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Post introuvable")
    })
    public ResponseEntity<ApiResponse<Void>> moderate(
            @PathVariable UUID postId,
            @Valid @RequestBody ModeratePostRequest request,
            @CurrentUser Jwt jwt) {
        UUID moderatorId = userIdResolver.resolve(jwt);
        moderationService.moderatePost(postId, moderatorId,
                ModerationStatus.valueOf(request.status()), request.reason());
        return ResponseEntity.ok(ApiResponse.ok(null, "Moderation appliquee"));
    }

    @PutMapping("/{postId}/pin")
    @PreAuthorize("hasRole('AMBASSADEUR') or hasRole('MODERATEUR') or hasRole('SUPER_ADMIN')")
    @Operation(summary = "Epingler/desepingler un post")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Statut d'epingle mis a jour"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", description = "Role insuffisant")
    })
    public ResponseEntity<ApiResponse<PostDto>> pin(@PathVariable UUID postId) {
        return ResponseEntity.ok(ApiResponse.ok(feedMapper.toDto(feedService.pinPost(postId))));
    }

    @PostMapping("/{postId}/comments")
    @Operation(summary = "Ajouter un commentaire")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "201", description = "Commentaire ajoute"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "Non authentifie")
    })
    public ResponseEntity<ApiResponse<CommentDto>> addComment(
            @PathVariable UUID postId,
            @RequestBody CommentRequest request,
            @CurrentUser Jwt jwt) {
        UUID authorId = userIdResolver.resolve(jwt);
        CommentDto dto = feedMapper.toDto(
                feedService.addComment(postId, authorId, request.content(), request.parentCommentId())
        );
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.created(dto));
    }

    @GetMapping("/{postId}/comments")
    @Operation(summary = "Commentaires d'un post")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Commentaires retournes")
    })
    public ResponseEntity<ApiResponse<List<CommentDto>>> getComments(
            @PathVariable UUID postId, @CurrentUser Jwt jwt) {
        UUID userId = jwt != null ? userIdResolver.resolve(jwt) : null;
        List<CommentDto> dtos = enrichComments(feedService.getComments(postId), userId);
        return ResponseEntity.ok(ApiResponse.ok(dtos));
    }

    @PostMapping("/{postId}/react")
    @Operation(summary = "Reagir a un post", description = "Ajoute ou modifie une reaction (LIKE, LOVE, CULTURE, RESPECT).")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Reaction enregistree"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "Non authentifie")
    })
    public ResponseEntity<ApiResponse<Void>> react(
            @PathVariable UUID postId,
            @RequestParam(defaultValue = "LIKE") String type,
            @CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        feedService.react(postId, userId, type);
        return ResponseEntity.ok(ApiResponse.ok(null, "Reaction enregistree"));
    }

    @DeleteMapping("/{postId}/react")
    @Operation(summary = "Supprimer ma reaction")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "204", description = "Reaction supprimee"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "Non authentifie")
    })
    public ResponseEntity<ApiResponse<Void>> removeReaction(
            @PathVariable UUID postId,
            @CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        feedService.removeReaction(postId, userId);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/comments/{commentId}/react")
    @Operation(summary = "Bénir un commentaire")
    public ResponseEntity<ApiResponse<Void>> reactComment(
            @PathVariable UUID commentId, @CurrentUser Jwt jwt) {
        feedService.reactComment(commentId, userIdResolver.resolve(jwt));
        return ResponseEntity.ok(ApiResponse.ok(null, "Bénédiction enregistrée"));
    }

    @DeleteMapping("/comments/{commentId}/react")
    @Operation(summary = "Retirer ma bénédiction d'un commentaire")
    public ResponseEntity<Void> unreactComment(
            @PathVariable UUID commentId, @CurrentUser Jwt jwt) {
        feedService.unreactComment(commentId, userIdResolver.resolve(jwt));
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/{postId}")
    @Operation(summary = "Supprimer un post", description = "Seul l'auteur peut supprimer son post.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "204", description = "Post supprime"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "Non authentifie"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", description = "Pas l'auteur")
    })
    public ResponseEntity<ApiResponse<Void>> deletePost(
            @PathVariable UUID postId,
            @CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        feedService.deletePost(postId, userId);
        return ResponseEntity.noContent().build();
    }

    // ── Enrichissement des DTO (auteur, village, aime par moi) ──

    /** Batch-charge auteurs, villages et mes reactions pour habiller les posts. */
    private List<PostDto> enrichPosts(List<Post> posts, UUID meId) {
        if (posts.isEmpty()) {
            return List.of();
        }
        List<UUID> authorIds = posts.stream().map(Post::getAuthorId).distinct().toList();
        List<UUID> villageIds = posts.stream().map(Post::getVillageId)
                .filter(Objects::nonNull).distinct().toList();
        List<UUID> postIds = posts.stream().map(Post::getId).toList();

        Map<UUID, User> authors = userRepository.findAllById(authorIds).stream()
                .collect(Collectors.toMap(User::getId, u -> u));
        Map<UUID, String> villageNames = villageIds.isEmpty() ? Map.of()
                : villageRepository.findAllById(villageIds).stream()
                        .collect(Collectors.toMap(Village::getId, Village::getName));
        Set<UUID> likedPostIds = meId == null ? Set.of()
                : reactionRepository.findByUserIdAndPostIdIn(meId, postIds).stream()
                        .map(PostReaction::getPostId).collect(Collectors.toSet());

        return posts.stream().map(p -> {
            User a = authors.get(p.getAuthorId());
            return new PostDto(
                    p.getId(), p.getAuthorId(), p.getVillageId(), p.getContent(), p.getMediaUrl(),
                    p.getModerationStatus(), p.isPinned(), p.getReactionCount(), p.getCommentCount(),
                    p.getCreatedAt(),
                    a != null ? a.getDisplayName() : null,
                    a != null ? a.getAvatarUrl() : null,
                    a != null && a.getRole() != null ? a.getRole().name() : null,
                    p.getVillageId() != null ? villageNames.get(p.getVillageId()) : null,
                    likedPostIds.contains(p.getId())
            );
        }).toList();
    }

    /** Batch-charge auteurs + bénédictions (compteur, aimé par moi) des commentaires. */
    private List<CommentDto> enrichComments(List<Comment> comments, UUID meId) {
        if (comments.isEmpty()) {
            return List.of();
        }
        List<UUID> authorIds = comments.stream().map(Comment::getAuthorId).distinct().toList();
        List<UUID> commentIds = comments.stream().map(Comment::getId).toList();

        Map<UUID, User> authors = userRepository.findAllById(authorIds).stream()
                .collect(Collectors.toMap(User::getId, u -> u));

        Map<UUID, Integer> counts = new java.util.HashMap<>();
        for (Object[] row : commentReactionRepository.countByCommentIds(commentIds)) {
            counts.put((UUID) row[0], ((Long) row[1]).intValue());
        }
        Set<UUID> likedIds = meId == null ? Set.of()
                : commentReactionRepository.findByUserIdAndCommentIdIn(meId, commentIds).stream()
                        .map(CommentReaction::getCommentId).collect(Collectors.toSet());

        return comments.stream().map(c -> {
            User a = authors.get(c.getAuthorId());
            return new CommentDto(
                    c.getId(), c.getPostId(), c.getAuthorId(), c.getContent(), c.getParentCommentId(),
                    c.getCreatedAt(),
                    a != null ? a.getDisplayName() : null,
                    a != null ? a.getAvatarUrl() : null,
                    counts.getOrDefault(c.getId(), 0),
                    likedIds.contains(c.getId())
            );
        }).toList();
    }

    record CommentRequest(String content, UUID parentCommentId) {}
}
