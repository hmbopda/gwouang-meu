package com.gwangmeu.chat.infrastructure;

import com.gwangmeu.chat.domain.ChatMessage;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.UUID;

public interface ChatMessageRepository extends JpaRepository<ChatMessage, UUID> {

    List<ChatMessage> findByGroupIdOrderByCreatedAtDesc(UUID groupId, Pageable pageable);

    List<ChatMessage> findByGroupIdAndCreatedAtAfterOrderByCreatedAtAsc(UUID groupId, Instant since);

    /**
     * Dernier message de CHAQUE groupe donné, en UNE seule requête (anti N+1).
     * La sous-requête corrélée retourne, par groupe, le message dont la date de
     * création est maximale ; l'index (group_id, created_at DESC) la rend rapide.
     * En cas d'égalité stricte de {@code created_at} au sein d'un même groupe
     * (très improbable), plusieurs lignes peuvent remonter — l'appelant
     * déduplique par {@code groupId}.
     */
    @Query("""
            SELECT m FROM ChatMessage m
            WHERE m.groupId IN :groupIds
              AND m.createdAt = (
                    SELECT MAX(m2.createdAt) FROM ChatMessage m2
                    WHERE m2.groupId = m.groupId
              )
            """)
    List<ChatMessage> findLatestPerGroup(@Param("groupIds") Collection<UUID> groupIds);
}
