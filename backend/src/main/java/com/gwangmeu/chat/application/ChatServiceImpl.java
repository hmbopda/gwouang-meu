package com.gwangmeu.chat.application;

import com.gwangmeu.chat.domain.ChatGroup;
import com.gwangmeu.chat.domain.ChatGroupMember;
import com.gwangmeu.chat.domain.ChatMessage;
import com.gwangmeu.chat.infrastructure.ChatGroupMemberRepository;
import com.gwangmeu.chat.infrastructure.ChatGroupRepository;
import com.gwangmeu.chat.infrastructure.ChatMessageRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
class ChatServiceImpl implements ChatService {

    private final ChatGroupRepository groupRepository;
    private final ChatGroupMemberRepository memberRepository;
    private final ChatMessageRepository messageRepository;

    @Override
    public ChatGroup createGroup(UUID villageId, String name, String description,
                                 ChatGroup.GroupType type, UUID creatorId) {
        ChatGroup group = ChatGroup.builder()
                .villageId(villageId)
                .name(name)
                .description(description)
                .type(type != null ? type : ChatGroup.GroupType.GENERAL)
                .createdBy(creatorId)
                .build();

        ChatGroup saved = groupRepository.save(group);

        // Le créateur est automatiquement admin du groupe
        memberRepository.save(ChatGroupMember.builder()
                .groupId(saved.getId())
                .userId(creatorId)
                .role(ChatGroupMember.MemberRole.ADMIN)
                .build());

        // Message système d'accueil
        messageRepository.save(ChatMessage.builder()
                .groupId(saved.getId())
                .senderId(creatorId)
                .content("Groupe \"" + name + "\" créé.")
                .type(ChatMessage.MessageType.SYSTEM)
                .build());

        log.info("Chat group created: {} in village {}", name, villageId);
        return saved;
    }

    @Override
    public ChatGroup createOrGetDirectGroup(UUID villageId, String name, UUID creatorId, UUID targetUserId) {
        // 1. Chercher un groupe DIRECT complet (les deux membres présents)
        Optional<ChatGroup> existing = groupRepository.findDirectGroup(
                villageId, creatorId, targetUserId, ChatGroup.GroupType.DIRECT);
        if (existing.isPresent()) {
            return existing.get();
        }

        // 2. Chercher un groupe DIRECT créé par l'un ou l'autre mais incomplet (ex: échec partiel)
        List<ChatGroup> partials = new ArrayList<>();
        partials.addAll(groupRepository.findByVillageIdAndTypeAndCreatedBy(
                villageId, ChatGroup.GroupType.DIRECT, creatorId));
        partials.addAll(groupRepository.findByVillageIdAndTypeAndCreatedBy(
                villageId, ChatGroup.GroupType.DIRECT, targetUserId));

        if (!partials.isEmpty()) {
            ChatGroup partial = partials.get(0);
            // Compléter les membres manquants
            addMemberIfAbsent(partial.getId(), creatorId);
            addMemberIfAbsent(partial.getId(), targetUserId);
            return partial;
        }

        // 3. Créer le groupe et ses deux membres
        ChatGroup group = ChatGroup.builder()
                .villageId(villageId)
                .name(name)
                .type(ChatGroup.GroupType.DIRECT)
                .createdBy(creatorId)
                .build();
        ChatGroup saved = groupRepository.save(group);
        addMemberIfAbsent(saved.getId(), creatorId);
        addMemberIfAbsent(saved.getId(), targetUserId);

        log.info("Direct chat group created between {} and {} in village {}", creatorId, targetUserId, villageId);
        return saved;
    }

    private void addMemberIfAbsent(UUID groupId, UUID userId) {
        if (!memberRepository.existsByGroupIdAndUserId(groupId, userId)) {
            memberRepository.save(ChatGroupMember.builder()
                    .groupId(groupId)
                    .userId(userId)
                    .role(ChatGroupMember.MemberRole.MEMBER)
                    .build());
        }
    }

    @Override
    public ChatGroup createOrGetDirectByUsers(UUID creatorId, UUID targetUserId, String targetName) {
        List<ChatGroup> existing = groupRepository.findDirectGroupsByMembers(creatorId, targetUserId);
        if (!existing.isEmpty()) {
            return existing.get(0);
        }
        ChatGroup group = ChatGroup.builder()
                .villageId(null)
                .name(targetName != null && !targetName.isBlank() ? targetName : "Conversation")
                .type(ChatGroup.GroupType.DIRECT)
                .createdBy(creatorId)
                .build();
        ChatGroup saved = groupRepository.save(group);
        addMemberIfAbsent(saved.getId(), creatorId);
        addMemberIfAbsent(saved.getId(), targetUserId);
        log.info("Direct chat (global) created between {} and {}", creatorId, targetUserId);
        return saved;
    }

    @Override
    @Transactional(readOnly = true)
    public List<ChatGroup> getGroupsForUser(UUID userId) {
        List<UUID> groupIds = memberRepository.findByUserId(userId)
                .stream().map(ChatGroupMember::getGroupId).toList();
        if (groupIds.isEmpty()) {
            return List.of();
        }
        return groupRepository.findAllById(groupIds);
    }

    @Override
    @Transactional(readOnly = true)
    public List<ChatGroup> getGroupsByVillage(UUID villageId) {
        return groupRepository.findByVillageIdOrderByCreatedAtAsc(villageId);
    }

    @Override
    public List<ChatGroup> getOrCreateFamilyGroups(String clan, UUID userId) {
        String normalized = clan == null ? "" : clan.trim();
        if (normalized.isEmpty()) {
            return List.of();
        }

        List<ChatGroup> groups =
                groupRepository.findByFamilyClanIgnoreCaseOrderByCreatedAtAsc(normalized);

        // Aucune discussion de famille pour ce clan → en créer une par défaut.
        if (groups.isEmpty()) {
            ChatGroup group = ChatGroup.builder()
                    .villageId(null)
                    .familyClan(normalized)
                    .name("Famille " + normalized)
                    .description("Discussion de la famille " + normalized)
                    .type(ChatGroup.GroupType.FAMILY)
                    .createdBy(userId)
                    .build();
            ChatGroup saved = groupRepository.save(group);
            memberRepository.save(ChatGroupMember.builder()
                    .groupId(saved.getId())
                    .userId(userId)
                    .role(ChatGroupMember.MemberRole.ADMIN)
                    .build());
            messageRepository.save(ChatMessage.builder()
                    .groupId(saved.getId())
                    .senderId(userId)
                    .content("Bienvenue dans la discussion de la famille "
                            + normalized + ".")
                    .type(ChatMessage.MessageType.SYSTEM)
                    .build());
            log.info("Family chat group created for clan {}", normalized);
            return List.of(saved);
        }

        // Groupes existants → s'assurer que l'utilisateur en est membre.
        for (ChatGroup g : groups) {
            addMemberIfAbsent(g.getId(), userId);
        }
        return groups;
    }

    @Override
    public ChatGroupMember joinGroup(UUID groupId, UUID userId) {
        if (memberRepository.existsByGroupIdAndUserId(groupId, userId)) {
            throw new IllegalStateException("Utilisateur déjà membre de ce groupe");
        }

        return memberRepository.save(ChatGroupMember.builder()
                .groupId(groupId)
                .userId(userId)
                .role(ChatGroupMember.MemberRole.MEMBER)
                .build());
    }

    @Override
    public void leaveGroup(UUID groupId, UUID userId) {
        memberRepository.deleteByGroupIdAndUserId(groupId, userId);
    }

    @Override
    @Transactional(readOnly = true)
    public List<ChatGroupMember> getGroupMembers(UUID groupId) {
        return memberRepository.findByGroupId(groupId);
    }

    @Override
    public ChatMessage sendMessage(UUID groupId, UUID senderId, String content) {
        if (!memberRepository.existsByGroupIdAndUserId(groupId, senderId)) {
            throw new IllegalStateException("Utilisateur non membre de ce groupe");
        }

        return messageRepository.save(ChatMessage.builder()
                .groupId(groupId)
                .senderId(senderId)
                .content(content)
                .type(ChatMessage.MessageType.TEXT)
                .build());
    }

    @Override
    @Transactional(readOnly = true)
    public List<ChatMessage> getMessages(UUID groupId, int limit) {
        return messageRepository.findByGroupIdOrderByCreatedAtDesc(
                groupId, PageRequest.of(0, Math.min(limit, 100)));
    }

    @Override
    @Transactional(readOnly = true)
    public List<ChatMessage> getMessagesSince(UUID groupId, Instant since) {
        return messageRepository.findByGroupIdAndCreatedAtAfterOrderByCreatedAtAsc(groupId, since);
    }

    @Override
    @Transactional(readOnly = true)
    public Map<UUID, ChatMessage> getLatestMessagesPerGroup(Collection<UUID> groupIds) {
        if (groupIds == null || groupIds.isEmpty()) {
            return Map.of();
        }
        Map<UUID, ChatMessage> latestByGroup = new LinkedHashMap<>();
        for (ChatMessage m : messageRepository.findLatestPerGroup(groupIds)) {
            // Déduplication défensive : en cas d'égalité de created_at dans un même
            // groupe, on conserve le premier rencontré.
            latestByGroup.putIfAbsent(m.getGroupId(), m);
        }
        return latestByGroup;
    }
}
