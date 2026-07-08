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

    /** Groupes de FAMILLE rattachés à un clan (insensible à la casse). */
    List<ChatGroup> findByFamilyClanIgnoreCaseOrderByCreatedAtAsc(String familyClan);

    /**
     * Trouve un groupe DIRECT entre deux utilisateurs dans un village.
     * Cherche dans les deux sens : créé par userId1 ou userId2,
     * avec l'autre utilisateur comme membre.
     */
    @Query("""
            SELECT g FROM ChatGroup g
            WHERE g.villageId = :villageId
              AND g.type = :type
              AND (g.createdBy = :userId1 OR g.createdBy = :userId2)
              AND EXISTS (
                SELECT m FROM ChatGroupMember m WHERE m.groupId = g.id AND m.userId = :userId1
              )
              AND EXISTS (
                SELECT m FROM ChatGroupMember m WHERE m.groupId = g.id AND m.userId = :userId2
              )
            """)
    Optional<ChatGroup> findDirectGroup(
            @Param("villageId") UUID villageId,
            @Param("userId1") UUID userId1,
            @Param("userId2") UUID userId2,
            @Param("type") ChatGroup.GroupType type
    );

    /**
     * Trouve un groupe DIRECT créé par un utilisateur donné dans un village,
     * indépendamment des membres (pour récupération après échec partiel).
     */
    List<ChatGroup> findByVillageIdAndTypeAndCreatedBy(
            UUID villageId, ChatGroup.GroupType type, UUID createdBy
    );
}
