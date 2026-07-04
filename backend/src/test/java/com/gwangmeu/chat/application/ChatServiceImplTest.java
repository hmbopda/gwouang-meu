package com.gwangmeu.chat.application;

import com.gwangmeu.chat.domain.ChatGroup;
import com.gwangmeu.chat.domain.ChatGroupMember;
import com.gwangmeu.chat.domain.ChatMessage;
import com.gwangmeu.chat.infrastructure.ChatGroupMemberRepository;
import com.gwangmeu.chat.infrastructure.ChatGroupRepository;
import com.gwangmeu.chat.infrastructure.ChatMessageRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Pageable;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("ChatServiceImpl — Tests unitaires")
class ChatServiceImplTest {

    @Mock private ChatGroupRepository groupRepository;
    @Mock private ChatGroupMemberRepository memberRepository;
    @Mock private ChatMessageRepository messageRepository;

    @InjectMocks private ChatServiceImpl chatService;

    @Captor private ArgumentCaptor<ChatGroup> groupCaptor;
    @Captor private ArgumentCaptor<ChatGroupMember> memberCaptor;
    @Captor private ArgumentCaptor<ChatMessage> messageCaptor;

    // ========================================================================
    // createGroup
    // ========================================================================

    @Nested
    @DisplayName("createGroup — Creation d'un groupe de chat")
    class CreateGroupTests {

        @Test
        @DisplayName("Doit creer le groupe, ajouter le createur comme ADMIN et envoyer un message systeme")
        void shouldCreateGroupWithAdminAndSystemMessage() {
            UUID villageId = UUID.randomUUID();
            UUID creatorId = UUID.randomUUID();

            ChatGroup savedGroup = ChatGroup.builder()
                    .villageId(villageId).name("Assemblee").description("Groupe principal")
                    .type(ChatGroup.GroupType.GENERAL).createdBy(creatorId).build();
            savedGroup.setId(UUID.randomUUID());

            when(groupRepository.save(any(ChatGroup.class))).thenReturn(savedGroup);
            when(memberRepository.save(any(ChatGroupMember.class))).thenAnswer(inv -> inv.getArgument(0));
            when(messageRepository.save(any(ChatMessage.class))).thenAnswer(inv -> inv.getArgument(0));

            ChatGroup result = chatService.createGroup(villageId, "Assemblee", "Groupe principal",
                    ChatGroup.GroupType.GENERAL, creatorId);

            assertThat(result.getName()).isEqualTo("Assemblee");
            assertThat(result.getVillageId()).isEqualTo(villageId);

            verify(memberRepository).save(memberCaptor.capture());
            assertThat(memberCaptor.getValue().getRole()).isEqualTo(ChatGroupMember.MemberRole.ADMIN);
            assertThat(memberCaptor.getValue().getUserId()).isEqualTo(creatorId);

            verify(messageRepository).save(messageCaptor.capture());
            assertThat(messageCaptor.getValue().getType()).isEqualTo(ChatMessage.MessageType.SYSTEM);
            assertThat(messageCaptor.getValue().getContent()).contains("Assemblee");
        }

        @Test
        @DisplayName("Doit utiliser GENERAL comme type par defaut quand type est null")
        void shouldDefaultToGeneralType() {
            UUID villageId = UUID.randomUUID();
            UUID creatorId = UUID.randomUUID();

            ChatGroup savedGroup = ChatGroup.builder()
                    .villageId(villageId).name("Test").type(ChatGroup.GroupType.GENERAL)
                    .createdBy(creatorId).build();
            savedGroup.setId(UUID.randomUUID());

            when(groupRepository.save(any(ChatGroup.class))).thenReturn(savedGroup);
            when(memberRepository.save(any(ChatGroupMember.class))).thenAnswer(inv -> inv.getArgument(0));
            when(messageRepository.save(any(ChatMessage.class))).thenAnswer(inv -> inv.getArgument(0));

            chatService.createGroup(villageId, "Test", null, null, creatorId);

            verify(groupRepository).save(groupCaptor.capture());
            assertThat(groupCaptor.getValue().getType()).isEqualTo(ChatGroup.GroupType.GENERAL);
        }
    }

    // ========================================================================
    // joinGroup
    // ========================================================================

    @Nested
    @DisplayName("joinGroup — Rejoindre un groupe")
    class JoinGroupTests {

        @Test
        @DisplayName("Doit ajouter l'utilisateur comme MEMBER")
        void shouldAddAsMember() {
            UUID groupId = UUID.randomUUID();
            UUID userId = UUID.randomUUID();

            when(memberRepository.existsByGroupIdAndUserId(groupId, userId)).thenReturn(false);
            when(memberRepository.save(any(ChatGroupMember.class))).thenAnswer(inv -> inv.getArgument(0));

            ChatGroupMember result = chatService.joinGroup(groupId, userId);

            assertThat(result.getRole()).isEqualTo(ChatGroupMember.MemberRole.MEMBER);
            verify(memberRepository).save(memberCaptor.capture());
            assertThat(memberCaptor.getValue().getGroupId()).isEqualTo(groupId);
            assertThat(memberCaptor.getValue().getUserId()).isEqualTo(userId);
        }

        @Test
        @DisplayName("Doit lever IllegalStateException si deja membre")
        void shouldThrowWhenAlreadyMember() {
            UUID groupId = UUID.randomUUID();
            UUID userId = UUID.randomUUID();

            when(memberRepository.existsByGroupIdAndUserId(groupId, userId)).thenReturn(true);

            assertThatThrownBy(() -> chatService.joinGroup(groupId, userId))
                    .isInstanceOf(IllegalStateException.class);

            verify(memberRepository, never()).save(any());
        }
    }

    // ========================================================================
    // leaveGroup
    // ========================================================================

    @Nested
    @DisplayName("leaveGroup — Quitter un groupe")
    class LeaveGroupTests {

        @Test
        @DisplayName("Doit deleguer la suppression au memberRepository")
        void shouldDeleteMembership() {
            UUID groupId = UUID.randomUUID();
            UUID userId = UUID.randomUUID();

            chatService.leaveGroup(groupId, userId);

            verify(memberRepository).deleteByGroupIdAndUserId(groupId, userId);
        }
    }

    // ========================================================================
    // sendMessage
    // ========================================================================

    @Nested
    @DisplayName("sendMessage — Envoi d'un message")
    class SendMessageTests {

        @Test
        @DisplayName("Doit sauvegarder un message TEXT quand l'expediteur est membre")
        void shouldSaveTextMessage() {
            UUID groupId = UUID.randomUUID();
            UUID senderId = UUID.randomUUID();

            when(memberRepository.existsByGroupIdAndUserId(groupId, senderId)).thenReturn(true);
            when(messageRepository.save(any(ChatMessage.class))).thenAnswer(inv -> inv.getArgument(0));

            ChatMessage result = chatService.sendMessage(groupId, senderId, "Bonjour!");

            assertThat(result.getContent()).isEqualTo("Bonjour!");
            assertThat(result.getType()).isEqualTo(ChatMessage.MessageType.TEXT);

            verify(messageRepository).save(messageCaptor.capture());
            assertThat(messageCaptor.getValue().getGroupId()).isEqualTo(groupId);
            assertThat(messageCaptor.getValue().getSenderId()).isEqualTo(senderId);
        }

        @Test
        @DisplayName("Doit lever IllegalStateException si l'expediteur n'est pas membre")
        void shouldThrowWhenNotMember() {
            UUID groupId = UUID.randomUUID();
            UUID senderId = UUID.randomUUID();

            when(memberRepository.existsByGroupIdAndUserId(groupId, senderId)).thenReturn(false);

            assertThatThrownBy(() -> chatService.sendMessage(groupId, senderId, "Message"))
                    .isInstanceOf(IllegalStateException.class);

            verify(messageRepository, never()).save(any());
        }
    }

    // ========================================================================
    // getMessages
    // ========================================================================

    @Nested
    @DisplayName("getMessages — Recuperation des messages")
    class GetMessagesTests {

        @Test
        @DisplayName("Doit plafonner la limite a 100")
        void shouldCapLimitAt100() {
            UUID groupId = UUID.randomUUID();
            UUID requesterId = UUID.randomUUID();

            when(memberRepository.existsByGroupIdAndUserId(groupId, requesterId)).thenReturn(true);
            when(messageRepository.findByGroupIdOrderByCreatedAtDesc(eq(groupId), any(Pageable.class)))
                    .thenReturn(List.of());

            chatService.getMessages(groupId, 500, requesterId);

            @SuppressWarnings("unchecked")
            ArgumentCaptor<Pageable> pageableCaptor = ArgumentCaptor.forClass(Pageable.class);
            verify(messageRepository).findByGroupIdOrderByCreatedAtDesc(eq(groupId), pageableCaptor.capture());
            assertThat(pageableCaptor.getValue().getPageSize()).isEqualTo(100);
        }

        @Test
        @DisplayName("Doit utiliser la limite telle quelle quand elle est <= 100")
        void shouldUseLimitAsIs() {
            UUID groupId = UUID.randomUUID();
            UUID requesterId = UUID.randomUUID();

            when(memberRepository.existsByGroupIdAndUserId(groupId, requesterId)).thenReturn(true);
            when(messageRepository.findByGroupIdOrderByCreatedAtDesc(eq(groupId), any(Pageable.class)))
                    .thenReturn(List.of());

            chatService.getMessages(groupId, 50, requesterId);

            @SuppressWarnings("unchecked")
            ArgumentCaptor<Pageable> pageableCaptor = ArgumentCaptor.forClass(Pageable.class);
            verify(messageRepository).findByGroupIdOrderByCreatedAtDesc(eq(groupId), pageableCaptor.capture());
            assertThat(pageableCaptor.getValue().getPageSize()).isEqualTo(50);
        }

        @Test
        @DisplayName("Doit lever IllegalStateException si le demandeur n'est pas membre")
        void shouldThrowWhenRequesterNotMember() {
            UUID groupId = UUID.randomUUID();
            UUID requesterId = UUID.randomUUID();

            when(memberRepository.existsByGroupIdAndUserId(groupId, requesterId)).thenReturn(false);

            assertThatThrownBy(() -> chatService.getMessages(groupId, 50, requesterId))
                    .isInstanceOf(IllegalStateException.class);

            verify(messageRepository, never()).findByGroupIdOrderByCreatedAtDesc(any(), any());
        }
    }

    // ========================================================================
    // getMessagesSince
    // ========================================================================

    @Nested
    @DisplayName("getMessagesSince — Messages depuis un instant")
    class GetMessagesSinceTests {

        @Test
        @DisplayName("Doit deleguer au repository avec les bons parametres")
        void shouldDelegateToRepository() {
            UUID groupId = UUID.randomUUID();
            UUID requesterId = UUID.randomUUID();
            Instant since = Instant.parse("2025-01-15T10:30:00Z");

            when(memberRepository.existsByGroupIdAndUserId(groupId, requesterId)).thenReturn(true);
            when(messageRepository.findByGroupIdAndCreatedAtAfterOrderByCreatedAtAsc(groupId, since))
                    .thenReturn(List.of());

            List<ChatMessage> result = chatService.getMessagesSince(groupId, since, requesterId);

            assertThat(result).isEmpty();
            verify(messageRepository).findByGroupIdAndCreatedAtAfterOrderByCreatedAtAsc(groupId, since);
        }

        @Test
        @DisplayName("Doit lever IllegalStateException si le demandeur n'est pas membre")
        void shouldThrowWhenRequesterNotMember() {
            UUID groupId = UUID.randomUUID();
            UUID requesterId = UUID.randomUUID();
            Instant since = Instant.parse("2025-01-15T10:30:00Z");

            when(memberRepository.existsByGroupIdAndUserId(groupId, requesterId)).thenReturn(false);

            assertThatThrownBy(() -> chatService.getMessagesSince(groupId, since, requesterId))
                    .isInstanceOf(IllegalStateException.class);

            verify(messageRepository, never()).findByGroupIdAndCreatedAtAfterOrderByCreatedAtAsc(any(), any());
        }
    }

    // ========================================================================
    // getGroupsByVillage & getGroupMembers
    // ========================================================================

    @Nested
    @DisplayName("Requetes de lecture")
    class ReadTests {

        @Test
        @DisplayName("getGroupsByVillage doit deleguer au groupRepository")
        void shouldReturnGroupsByVillage() {
            UUID villageId = UUID.randomUUID();
            when(groupRepository.findByVillageIdOrderByCreatedAtAsc(villageId)).thenReturn(List.of());

            assertThat(chatService.getGroupsByVillage(villageId)).isEmpty();
        }

        @Test
        @DisplayName("getGroupMembers doit deleguer au memberRepository quand le demandeur est membre")
        void shouldReturnGroupMembers() {
            UUID groupId = UUID.randomUUID();
            UUID requesterId = UUID.randomUUID();
            when(memberRepository.existsByGroupIdAndUserId(groupId, requesterId)).thenReturn(true);
            when(memberRepository.findByGroupId(groupId)).thenReturn(List.of());

            assertThat(chatService.getGroupMembers(groupId, requesterId)).isEmpty();
        }

        @Test
        @DisplayName("getGroupMembers doit lever IllegalStateException si le demandeur n'est pas membre")
        void shouldThrowWhenMemberListRequestedByNonMember() {
            UUID groupId = UUID.randomUUID();
            UUID requesterId = UUID.randomUUID();
            when(memberRepository.existsByGroupIdAndUserId(groupId, requesterId)).thenReturn(false);

            assertThatThrownBy(() -> chatService.getGroupMembers(groupId, requesterId))
                    .isInstanceOf(IllegalStateException.class);

            verify(memberRepository, never()).findByGroupId(any());
        }

        @Test
        @DisplayName("countMembers doit deleguer au memberRepository")
        void shouldCountMembers() {
            UUID groupId = UUID.randomUUID();
            when(memberRepository.countByGroupId(groupId)).thenReturn(3L);

            assertThat(chatService.countMembers(groupId)).isEqualTo(3L);
        }
    }
}
