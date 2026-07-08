package com.gwangmeu.chat.application;

import com.gwangmeu.chat.domain.ChatGroup;
import com.gwangmeu.chat.domain.ChatGroupMember;
import com.gwangmeu.chat.domain.ChatMessage;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public interface ChatService {

    ChatGroup createGroup(UUID villageId, String name, String description,
                          ChatGroup.GroupType type, UUID creatorId);

    /** Crée ou retourne un groupe DIRECT existant entre deux utilisateurs. */
    ChatGroup createOrGetDirectGroup(UUID villageId, String name, UUID creatorId, UUID targetUserId);

    List<ChatGroup> getGroupsByVillage(UUID villageId);

    /**
     * Groupes de FAMILLE d'un clan. En crée un par défaut (« Famille {clan} »)
     * s'il n'en existe aucun, et s'assure que l'utilisateur en est membre.
     */
    List<ChatGroup> getOrCreateFamilyGroups(String clan, UUID userId);

    ChatGroupMember joinGroup(UUID groupId, UUID userId);

    void leaveGroup(UUID groupId, UUID userId);

    List<ChatGroupMember> getGroupMembers(UUID groupId);

    ChatMessage sendMessage(UUID groupId, UUID senderId, String content);

    List<ChatMessage> getMessages(UUID groupId, int limit);

    List<ChatMessage> getMessagesSince(UUID groupId, Instant since);
}
