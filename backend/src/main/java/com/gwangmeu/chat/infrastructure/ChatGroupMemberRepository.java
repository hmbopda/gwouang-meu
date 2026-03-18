package com.gwangmeu.chat.infrastructure;

import com.gwangmeu.chat.domain.ChatGroupMember;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface ChatGroupMemberRepository extends JpaRepository<ChatGroupMember, UUID> {

    List<ChatGroupMember> findByGroupId(UUID groupId);

    List<ChatGroupMember> findByUserId(UUID userId);

    boolean existsByGroupIdAndUserId(UUID groupId, UUID userId);

    void deleteByGroupIdAndUserId(UUID groupId, UUID userId);
}
