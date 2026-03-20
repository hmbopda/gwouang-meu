package com.gwangmeu.chat.infrastructure;

import com.gwangmeu.chat.domain.ChatGroup;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ChatGroupRepository extends JpaRepository<ChatGroup, UUID> {

    List<ChatGroup> findByVillageIdOrderByCreatedAtAsc(UUID villageId);

    /**
     * Trouve un groupe DIRECT existant entre deux utilisateurs dans un village.
     * Les deux utilisateurs doivent être membres du groupe.
     */
    @Query("""
            SELECT g FROM ChatGroup g
            WHERE g.villageId = :villageId
              AND g.type = :type
              AND EXISTS (
                SELECT m1 FROM ChatGroupMember m1
                WHERE m1.groupId = g.id AND m1.userId = :userId1
              )
              AND EXISTS (
                SELECT m2 FROM ChatGroupMember m2
                WHERE m2.groupId = g.id AND m2.userId = :userId2
              )
            """)
    Optional<ChatGroup> findDirectGroup(
            @Param("villageId") UUID villageId,
            @Param("userId1") UUID userId1,
            @Param("userId2") UUID userId2,
            @Param("type") ChatGroup.GroupType type
    );
}
