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

    List<ChatGroup> getGroupsByVillage(UUID villageId);

    ChatGroupMember joinGroup(UUID groupId, UUID userId);

    void leaveGroup(UUID groupId, UUID userId);

    List<ChatGroupMember> getGroupMembers(UUID groupId, UUID requesterId);

    long countMembers(UUID groupId);

    ChatMessage sendMessage(UUID groupId, UUID senderId, String content);

    List<ChatMessage> getMessages(UUID groupId, int limit, UUID requesterId);

    List<ChatMessage> getMessagesSince(UUID groupId, Instant since, UUID requesterId);
}
