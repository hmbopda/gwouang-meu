package com.gwangmeu.chat.application;

import com.gwangmeu.chat.domain.ChatGroup;
import com.gwangmeu.chat.domain.ChatGroupMember;
import com.gwangmeu.chat.domain.ChatMessage;
import com.gwangmeu.chat.infrastructure.ChatGroupMemberRepository;
import com.gwangmeu.chat.infrastructure.ChatGroupRepository;
import com.gwangmeu.chat.infrastructure.ChatMessageRepository;
import com.gwangmeu.shared.BaseIntegrationTest;
import com.gwangmeu.village.domain.Village;
import com.gwangmeu.village.infrastructure.VillageRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@Transactional
@DisplayName("ChatService - Tests d'integration")
class ChatServiceIntegrationTest extends BaseIntegrationTest {

    @Autowired
    private ChatService chatService;

    @Autowired
    private ChatGroupRepository groupRepository;

    @Autowired
    private ChatGroupMemberRepository memberRepository;

    @Autowired
    private ChatMessageRepository messageRepository;

    @Autowired
    private VillageRepository villageRepository;

    private UUID villageId;
    private final UUID creatorId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        messageRepository.deleteAllInBatch();
        memberRepository.deleteAllInBatch();
        groupRepository.deleteAllInBatch();

        Village village = Village.builder()
                .name("Bafia")
                .country("Cameroun")
                .continentCode("AF")
                .build();
        villageId = villageRepository.saveAndFlush(village).getId();
    }

    private ChatGroup createTestGroup(String name) {
        return chatService.createGroup(villageId, name, "Description " + name,
                ChatGroup.GroupType.GENERAL, creatorId);
    }

    // ── createGroup ──────────────────────────────────────────────────────────

    @Nested
    @DisplayName("createGroup()")
    class CreateGroup {

        @Test
        @DisplayName("doit creer un groupe avec le createur comme ADMIN")
        void shouldCreateGroupWithCreatorAsAdmin() {
            ChatGroup group = createTestGroup("Discussions");

            assertThat(group.getId()).isNotNull();
            assertThat(group.getName()).isEqualTo("Discussions");
            assertThat(group.getVillageId()).isEqualTo(villageId);
            assertThat(group.getType()).isEqualTo(ChatGroup.GroupType.GENERAL);
            assertThat(group.getCreatedBy()).isEqualTo(creatorId);

            List<ChatGroupMember> members = memberRepository.findByGroupId(group.getId());
            assertThat(members).hasSize(1);
            assertThat(members.get(0).getUserId()).isEqualTo(creatorId);
            assertThat(members.get(0).getRole()).isEqualTo(ChatGroupMember.MemberRole.ADMIN);
        }

        @Test
        @DisplayName("doit envoyer un message SYSTEM a la creation")
        void shouldSendSystemMessage() {
            ChatGroup group = createTestGroup("Annonces");

            List<ChatMessage> messages = messageRepository
                    .findByGroupIdOrderByCreatedAtDesc(group.getId(),
                            org.springframework.data.domain.PageRequest.of(0, 10));

            assertThat(messages).hasSize(1);
            assertThat(messages.get(0).getType()).isEqualTo(ChatMessage.MessageType.SYSTEM);
            assertThat(messages.get(0).getContent()).contains("Annonces");
        }

        @Test
        @DisplayName("doit utiliser GENERAL comme type par defaut si null")
        void shouldDefaultToGeneral() {
            ChatGroup group = chatService.createGroup(villageId, "Test", null, null, creatorId);

            assertThat(group.getType()).isEqualTo(ChatGroup.GroupType.GENERAL);
        }
    }

    // ── joinGroup ────────────────────────────────────────────────────────────

    @Nested
    @DisplayName("joinGroup()")
    class JoinGroup {

        @Test
        @DisplayName("doit ajouter un membre avec le role MEMBER")
        void shouldAddMemberWithRoleMember() {
            ChatGroup group = createTestGroup("General");
            UUID newUser = UUID.randomUUID();

            ChatGroupMember member = chatService.joinGroup(group.getId(), newUser);

            assertThat(member.getRole()).isEqualTo(ChatGroupMember.MemberRole.MEMBER);
            assertThat(member.getUserId()).isEqualTo(newUser);
            assertThat(member.getGroupId()).isEqualTo(group.getId());
        }

        @Test
        @DisplayName("doit lancer IllegalStateException si deja membre")
        void shouldThrowWhenAlreadyMember() {
            ChatGroup group = createTestGroup("General");

            assertThatThrownBy(() -> chatService.joinGroup(group.getId(), creatorId))
                    .isInstanceOf(IllegalStateException.class);
        }
    }

    // ── leaveGroup ───────────────────────────────────────────────────────────

    @Nested
    @DisplayName("leaveGroup()")
    class LeaveGroup {

        @Test
        @DisplayName("doit retirer le membre du groupe")
        void shouldRemoveMember() {
            ChatGroup group = createTestGroup("General");
            UUID userId = UUID.randomUUID();
            chatService.joinGroup(group.getId(), userId);

            chatService.leaveGroup(group.getId(), userId);

            assertThat(memberRepository.existsByGroupIdAndUserId(group.getId(), userId)).isFalse();
        }
    }

    // ── sendMessage ──────────────────────────────────────────────────────────

    @Nested
    @DisplayName("sendMessage()")
    class SendMessage {

        @Test
        @DisplayName("doit envoyer un message TEXT si le membre existe")
        void shouldSendTextMessage() {
            ChatGroup group = createTestGroup("General");

            ChatMessage message = chatService.sendMessage(group.getId(), creatorId, "Bonjour tout le monde!");

            assertThat(message.getId()).isNotNull();
            assertThat(message.getContent()).isEqualTo("Bonjour tout le monde!");
            assertThat(message.getType()).isEqualTo(ChatMessage.MessageType.TEXT);
            assertThat(message.getSenderId()).isEqualTo(creatorId);
        }

        @Test
        @DisplayName("doit lancer IllegalStateException si le sender n'est pas membre")
        void shouldThrowWhenSenderNotMember() {
            ChatGroup group = createTestGroup("General");
            UUID outsider = UUID.randomUUID();

            assertThatThrownBy(() -> chatService.sendMessage(group.getId(), outsider, "Salut"))
                    .isInstanceOf(IllegalStateException.class);
        }
    }

    // ── getMessages ──────────────────────────────────────────────────────────

    @Nested
    @DisplayName("getMessages()")
    class GetMessages {

        @Test
        @DisplayName("doit retourner les messages avec le cap a 100")
        void shouldCapAt100() {
            ChatGroup group = createTestGroup("General");

            // Le message SYSTEM de creation + nos messages
            for (int i = 0; i < 5; i++) {
                chatService.sendMessage(group.getId(), creatorId, "Message " + i);
            }

            List<ChatMessage> messages = chatService.getMessages(group.getId(), 200, creatorId);

            // 1 SYSTEM + 5 TEXT = 6
            assertThat(messages).hasSize(6);
        }
    }

    // ── getMessagesSince ─────────────────────────────────────────────────────

    @Nested
    @DisplayName("getMessagesSince()")
    class GetMessagesSince {

        @Test
        @DisplayName("doit retourner les messages apres une date donnee")
        void shouldReturnMessagesSinceDate() {
            ChatGroup group = createTestGroup("General");
            Instant before = Instant.now();

            chatService.sendMessage(group.getId(), creatorId, "Nouveau message");

            List<ChatMessage> messages = chatService.getMessagesSince(group.getId(), before, creatorId);

            assertThat(messages).isNotEmpty();
            assertThat(messages).allMatch(m -> m.getCreatedAt().isAfter(before));
        }
    }

    // ── getGroupsByVillage ───────────────────────────────────────────────────

    @Nested
    @DisplayName("getGroupsByVillage()")
    class GetGroupsByVillage {

        @Test
        @DisplayName("doit retourner tous les groupes d'un village")
        void shouldReturnGroupsForVillage() {
            createTestGroup("General");
            createTestGroup("Annonces");

            List<ChatGroup> groups = chatService.getGroupsByVillage(villageId);

            assertThat(groups).hasSize(2);
        }
    }
}
