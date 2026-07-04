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
        ChatGroup group = chatService.createGroup(
                request.villageId(), request.name(), request.description(),
                request.type(), userId);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.created(toGroupDto(group)));
    }

    @GetMapping("/groups/village/{villageId}")
    @Operation(summary = "Groupes d'un village")
    public ResponseEntity<ApiResponse<List<ChatGroupDto>>> getGroupsByVillage(
            @PathVariable UUID villageId) {
        List<ChatGroupDto> dtos = chatService.getGroupsByVillage(villageId)
                .stream().map(this::toGroupDto).toList();
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
    @Operation(summary = "Membres d'un groupe (réservé aux membres)")
    public ResponseEntity<ApiResponse<List<ChatMemberDto>>> getMembers(
            @PathVariable UUID groupId,
            @CurrentUser Jwt jwt) {
        UUID userId = resolveUserId(jwt);
        List<ChatGroupMember> members = chatService.getGroupMembers(groupId, userId);
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
    @Operation(summary = "Historique des messages (réservé aux membres)")
    public ResponseEntity<ApiResponse<List<ChatMessageDto>>> getMessages(
            @PathVariable UUID groupId,
            @RequestParam(defaultValue = "50") int limit,
            @CurrentUser Jwt jwt) {
        UUID userId = resolveUserId(jwt);
        List<ChatMessage> messages = chatService.getMessages(groupId, limit, userId);
        return ResponseEntity.ok(ApiResponse.ok(enrichMessages(messages)));
    }

    @GetMapping("/groups/{groupId}/messages/poll")
    @Operation(summary = "Polling — nouveaux messages depuis un timestamp (réservé aux membres)")
    public ResponseEntity<ApiResponse<List<ChatMessageDto>>> poll(
            @PathVariable UUID groupId,
            @RequestParam Instant since,
            @CurrentUser Jwt jwt) {
        UUID userId = resolveUserId(jwt);
        List<ChatMessage> messages = chatService.getMessagesSince(groupId, since, userId);
        return ResponseEntity.ok(ApiResponse.ok(enrichMessages(messages)));
    }

    // ── Mapping helpers ──

    private ChatGroupDto toGroupDto(ChatGroup g) {
        int memberCount = (int) chatService.countMembers(g.getId());
        return new ChatGroupDto(
                g.getId(), g.getVillageId(), g.getName(), g.getDescription(),
                g.getType(), memberCount, g.getCreatedBy(), g.getCreatedAt());
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
