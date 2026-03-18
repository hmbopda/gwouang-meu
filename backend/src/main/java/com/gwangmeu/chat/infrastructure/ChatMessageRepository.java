package com.gwangmeu.chat.infrastructure;

import com.gwangmeu.chat.domain.ChatMessage;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public interface ChatMessageRepository extends JpaRepository<ChatMessage, UUID> {

    List<ChatMessage> findByGroupIdOrderByCreatedAtDesc(UUID groupId, Pageable pageable);

    List<ChatMessage> findByGroupIdAndCreatedAtAfterOrderByCreatedAtAsc(UUID groupId, Instant since);
}
