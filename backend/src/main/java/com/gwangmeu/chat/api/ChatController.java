package com.gwangmeu.chat.api;

import com.gwangmeu.chat.application.ChatService;
import com.gwangmeu.chat.domain.ChatGroup;
import com.gwangmeu.chat.domain.ChatGroupMember;
import com.gwangmeu.chat.domain.ChatMessage;
import com.gwangmeu.chat.dto.*;
import com.gwangmeu.shared.api.ApiResponse;
import com.gwangmeu.shared.security.CurrentUser;
import com.gwangmeu.user.User;
import com.gwangmeu.user.UserRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.persistence.EntityNotFoundException;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/chat")
@RequiredArgsConstructor
@Tag(name = "Chat", description = "Groupes de discussion par village")
public class ChatController {

    private final ChatService chatService;
    private final UserRepository userRepository;

    private UUID resolveUserId(Jwt jwt) {
        return userRepository.findBySupabaseId(jwt.getSubject())
                .orElseThrow(() -> new EntityNotFoundException("Utilisateur introuvable"))
                .getId();
    }

    // ── Groupes ──

    @PostMapping("/groups")
    @Operation(summary = "Créer un groupe de chat")
    public ResponseEntity<ApiResponse<ChatGroupDto>> createGroup(
            @Valid @RequestBody CreateChatGroupRequest request,
            @CurrentUser Jwt jwt) {
        UUID userId = resolveUserId(jwt);
        ChatGroup group;
        if (request.type() == ChatGroup.GroupType.DIRECT) {
            if (request.targetUserId() == null) {
                throw new org.springframework.web.server.ResponseStatusException(
                        org.springframework.http.HttpStatus.BAD_REQUEST,
                        "targetUserId requis pour un groupe DIRECT");
            }
            group = chatService.createOrGetDirectGroup(
                    request.villageId(), request.name(), userId, request.targetUserId());
        } else {
            group = chatService.createGroup(
                    request.villageId(), request.name(), request.description(),
                    request.type(), userId);
        }
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.created(toGroupDto(group)));
    }

    @PostMapping("/direct")
    @Operation(summary = "Ouvrir une conversation directe avec un utilisateur (sans village)")
    public ResponseEntity<ApiResponse<ChatGroupDto>> openDirect(
            @RequestBody Map<String, String> body,
            @CurrentUser Jwt jwt) {
        UUID userId = resolveUserId(jwt);
        String raw = body.get("targetUserId");
        if (raw == null || raw.isBlank()) {
            throw new org.springframework.web.server.ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "targetUserId requis");
        }
        UUID targetUserId = UUID.fromString(raw);
        User target = userRepository.findById(targetUserId)
                .orElseThrow(() -> new EntityNotFoundException("Utilisateur introuvable"));
        ChatGroup group = chatService.createOrGetDirectByUsers(
                userId, targetUserId, target.getDisplayName());
        return ResponseEntity.ok(ApiResponse.ok(toGroupDto(group), "Conversation ouverte"));
    }

    @GetMapping("/contacts")
    @Operation(summary = "Contacts avec qui je peux discuter (famille, mariage, clan, village)")
    public ResponseEntity<ApiResponse<List<ChatMemberDto>>> contacts(
            @RequestParam(defaultValue = "") String q,
            @CurrentUser Jwt jwt) {
        UUID userId = resolveUserId(jwt);
        List<ChatMemberDto> dtos = userRepository
                .findLinkedContacts(userId, q == null ? "" : q.trim())
                .stream()
                .map(u -> new ChatMemberDto(
                        u.getId(), u.getDisplayName(), u.getAvatarUrl(), null, null))
                .toList();
        return ResponseEntity.ok(ApiResponse.ok(dtos));
    }

    @GetMapping("/my-groups")
    @Operation(summary = "Toutes mes conversations (village, famille, directes)")
    public ResponseEntity<ApiResponse<List<ChatGroupDto>>> myGroups(@CurrentUser Jwt jwt) {
        UUID userId = resolveUserId(jwt);
        List<ChatGroupDto> dtos = toGroupDtos(chatService.getGroupsForUser(userId));
        return ResponseEntity.ok(ApiResponse.ok(dtos));
    }

    @GetMapping("/groups/village/{villageId}")
    @Operation(summary = "Groupes d'un village")
    public ResponseEntity<ApiResponse<List<ChatGroupDto>>> getGroupsByVillage(
            @PathVariable UUID villageId) {
        List<ChatGroupDto> dtos = toGroupDtos(chatService.getGroupsByVillage(villageId));
        return ResponseEntity.ok(ApiResponse.ok(dtos));
    }

    @GetMapping("/groups/family/{clan}")
    @Operation(summary = "Discussions de famille d'un clan (créées à la demande)")
    public ResponseEntity<ApiResponse<List<ChatGroupDto>>> getFamilyGroups(
            @PathVariable String clan,
            @CurrentUser Jwt jwt) {
        UUID userId = resolveUserId(jwt);
        List<ChatGroupDto> dtos = toGroupDtos(chatService.getOrCreateFamilyGroups(clan, userId));
        return ResponseEntity.ok(ApiResponse.ok(dtos));
    }

    @PostMapping("/groups/{groupId}/join")
    @Operation(summary = "Rejoindre un groupe")
    public ResponseEntity<ApiResponse<Void>> joinGroup(
            @PathVariable UUID groupId,
            @CurrentUser Jwt jwt) {
        UUID userId = resolveUserId(jwt);
        chatService.joinGroup(groupId, userId);
        return ResponseEntity.ok(ApiResponse.ok(null, "Groupe rejoint"));
    }

    @DeleteMapping("/groups/{groupId}/leave")
    @Operation(summary = "Quitter un groupe")
    public ResponseEntity<Void> leaveGroup(
            @PathVariable UUID groupId,
            @CurrentUser Jwt jwt) {
        UUID userId = resolveUserId(jwt);
        chatService.leaveGroup(groupId, userId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/groups/{groupId}/members")
    @Operation(summary = "Membres d'un groupe")
    public ResponseEntity<ApiResponse<List<ChatMemberDto>>> getMembers(
            @PathVariable UUID groupId) {
        List<ChatGroupMember> members = chatService.getGroupMembers(groupId);
        List<UUID> userIds = members.stream().map(ChatGroupMember::getUserId).toList();
        Map<UUID, User> usersMap = userRepository.findAllById(userIds)
                .stream().collect(Collectors.toMap(User::getId, u -> u));

        List<ChatMemberDto> dtos = members.stream().map(m -> {
            User u = usersMap.get(m.getUserId());
            return new ChatMemberDto(
                    m.getUserId(),
                    u != null ? u.getDisplayName() : "Inconnu",
                    u != null ? u.getAvatarUrl() : null,
                    m.getRole(),
                    m.getCreatedAt()
            );
        }).toList();

        return ResponseEntity.ok(ApiResponse.ok(dtos));
    }

    // ── Messages ──

    @PostMapping("/groups/{groupId}/messages")
    @Operation(summary = "Envoyer un message")
    public ResponseEntity<ApiResponse<ChatMessageDto>> sendMessage(
            @PathVariable UUID groupId,
            @Valid @RequestBody SendMessageRequest request,
            @CurrentUser Jwt jwt) {
        UUID userId = resolveUserId(jwt);
        ChatMessage msg = chatService.sendMessage(groupId, userId, request.content());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.created(toMessageDto(msg, userId)));
    }

    @GetMapping("/groups/{groupId}/messages")
    @Operation(summary = "Historique des messages")
    public ResponseEntity<ApiResponse<List<ChatMessageDto>>> getMessages(
            @PathVariable UUID groupId,
            @RequestParam(defaultValue = "50") int limit) {
        List<ChatMessage> messages = chatService.getMessages(groupId, limit);
        return ResponseEntity.ok(ApiResponse.ok(enrichMessages(messages)));
    }

    @GetMapping("/groups/{groupId}/messages/poll")
    @Operation(summary = "Polling — nouveaux messages depuis un timestamp")
    public ResponseEntity<ApiResponse<List<ChatMessageDto>>> poll(
            @PathVariable UUID groupId,
            @RequestParam Instant since) {
        List<ChatMessage> messages = chatService.getMessagesSince(groupId, since);
        return ResponseEntity.ok(ApiResponse.ok(enrichMessages(messages)));
    }

    // ── Mapping helpers ──

    /** Longueur max de l'aperçu du dernier message (troncature douce). */
    private static final int PREVIEW_MAX_LENGTH = 80;

    /** Mappe une liste de groupes en récupérant le dernier message de TOUS en UNE requête (anti N+1). */
    private List<ChatGroupDto> toGroupDtos(List<ChatGroup> groups) {
        if (groups.isEmpty()) {
            return List.of();
        }
        List<UUID> groupIds = groups.stream().map(ChatGroup::getId).toList();
        Map<UUID, ChatMessage> lastByGroup = chatService.getLatestMessagesPerGroup(groupIds);
        return groups.stream()
                .map(g -> toGroupDto(g, lastByGroup.get(g.getId())))
                .toList();
    }

    private ChatGroupDto toGroupDto(ChatGroup g) {
        ChatMessage last = chatService.getLatestMessagesPerGroup(List.of(g.getId())).get(g.getId());
        return toGroupDto(g, last);
    }

    private ChatGroupDto toGroupDto(ChatGroup g, ChatMessage last) {
        int memberCount = chatService.getGroupMembers(g.getId()).size();
        return new ChatGroupDto(
                g.getId(), g.getVillageId(), g.getFamilyClan(), g.getName(),
                g.getDescription(), g.getType(), memberCount, g.getCreatedBy(),
                g.getCreatedAt(),
                last != null ? buildPreview(last) : null,
                last != null ? last.getCreatedAt() : null);
    }

    /**
     * Aperçu court du dernier message : « 📷 Photo » pour une image, «  » pour
     * un contenu vide, sinon le texte normalisé (espaces compactés) tronqué à
     * {@link #PREVIEW_MAX_LENGTH} caractères avec une ellipse.
     */
    private String buildPreview(ChatMessage m) {
        if (m.getType() == ChatMessage.MessageType.IMAGE) {
            return "📷 Photo";
        }
        String content = m.getContent();
        if (content == null || content.isBlank()) {
            return "";
        }
        String normalized = content.strip().replaceAll("\\s+", " ");
        if (normalized.length() <= PREVIEW_MAX_LENGTH) {
            return normalized;
        }
        return normalized.substring(0, PREVIEW_MAX_LENGTH).stripTrailing() + "…";
    }

    private List<ChatMessageDto> enrichMessages(List<ChatMessage> messages) {
        List<UUID> senderIds = messages.stream().map(ChatMessage::getSenderId).distinct().toList();
        Map<UUID, User> usersMap = userRepository.findAllById(senderIds)
                .stream().collect(Collectors.toMap(User::getId, u -> u));

        return messages.stream().map(m -> {
            User u = usersMap.get(m.getSenderId());
            return new ChatMessageDto(
                    m.getId(), m.getGroupId(), m.getSenderId(),
                    u != null ? u.getDisplayName() : "Inconnu",
                    u != null ? u.getAvatarUrl() : null,
                    m.getContent(), m.getType(), m.getCreatedAt());
        }).toList();
    }

    private ChatMessageDto toMessageDto(ChatMessage m, UUID senderId) {
        User u = userRepository.findById(senderId).orElse(null);
        return new ChatMessageDto(
                m.getId(), m.getGroupId(), m.getSenderId(),
                u != null ? u.getDisplayName() : "Inconnu",
                u != null ? u.getAvatarUrl() : null,
                m.getContent(), m.getType(), m.getCreatedAt());
    }
}
