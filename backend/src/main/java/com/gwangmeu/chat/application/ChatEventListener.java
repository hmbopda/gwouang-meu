package com.gwangmeu.chat.application;

import com.gwangmeu.chat.domain.ChatGroup;
import com.gwangmeu.chat.domain.ChatGroupMember;
import com.gwangmeu.chat.infrastructure.ChatGroupMemberRepository;
import com.gwangmeu.chat.infrastructure.ChatGroupRepository;
import com.gwangmeu.village.events.UserJoinedVillageEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * Écoute les événements village et gère les groupes de chat automatiquement.
 * - Quand un utilisateur rejoint un village → auto-join dans le groupe Général (créé si inexistant).
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ChatEventListener {

    private final ChatGroupRepository groupRepository;
    private final ChatGroupMemberRepository memberRepository;

    @EventListener
    @Transactional
    public void onUserJoinedVillage(UserJoinedVillageEvent event) {
        UUID villageId = event.getVillageId();
        UUID userId = event.getUserId();

        // Trouver ou créer le groupe Général du village
        List<ChatGroup> groups = groupRepository.findByVillageIdOrderByCreatedAtAsc(villageId);
        ChatGroup general = groups.stream()
                .filter(g -> g.getType() == ChatGroup.GroupType.GENERAL)
                .findFirst()
                .orElseGet(() -> {
                    log.info("Création auto du groupe Général pour village {}", villageId);
                    return groupRepository.save(ChatGroup.builder()
                            .villageId(villageId)
                            .name("Général")
                            .description("Discussion générale du village")
                            .type(ChatGroup.GroupType.GENERAL)
                            .createdBy(userId)
                            .build());
                });

        // Auto-join si pas déjà membre
        if (!memberRepository.existsByGroupIdAndUserId(general.getId(), userId)) {
            memberRepository.save(ChatGroupMember.builder()
                    .groupId(general.getId())
                    .userId(userId)
                    .role(ChatGroupMember.MemberRole.MEMBER)
                    .build());
            log.info("User {} auto-joined Général group for village {}", userId, villageId);
        }
    }
}
