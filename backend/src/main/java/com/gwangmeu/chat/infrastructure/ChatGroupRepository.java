package com.gwangmeu.chat.infrastructure;

import com.gwangmeu.chat.domain.ChatGroup;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface ChatGroupRepository extends JpaRepository<ChatGroup, UUID> {

    List<ChatGroup> findByVillageIdOrderByCreatedAtAsc(UUID villageId);
}
