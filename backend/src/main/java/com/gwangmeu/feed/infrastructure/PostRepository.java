package com.gwangmeu.feed.infrastructure;

import com.gwangmeu.feed.domain.ModerationStatus;
import com.gwangmeu.feed.domain.Post;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface PostRepository extends JpaRepository<Post, UUID> {

    List<Post> findByVillageIdAndModerationStatus(UUID villageId, ModerationStatus status, Pageable pageable);

    List<Post> findByAuthorId(UUID authorId, Pageable pageable);

    List<Post> findByModerationStatus(ModerationStatus status, Pageable pageable);

    List<Post> findByVillageIdAndModerationStatusIn(UUID villageId,
                                                    List<ModerationStatus> statuses,
                                                    Pageable pageable);

    long countByVillageIdAndModerationStatus(UUID villageId, ModerationStatus status);

    /**
     * Fil « communautaire » : publications APPROUVEES qui concernent l'utilisateur —
     * ses propres posts, ceux de ses villages, et ceux des personnes liees (famille,
     * clan, co-membres de village, co-membres de groupes de discussion). Trie les
     * epingles en tete puis par recence. Requete native (CTE hors JPQL, meme logique
     * que UserRepository.findLinkedContacts).
     */
    @Query(value = """
            WITH me_persons AS (
                SELECT id FROM persons WHERE user_id = :me
            ),
            my_clan_ids AS (
                SELECT clan_id FROM person_clans WHERE person_id IN (SELECT id FROM me_persons)
            ),
            my_village_ids AS (
                SELECT village_id FROM village_subscriptions WHERE user_id = :me
            ),
            linked_pids AS (
                SELECT pc.child_id  AS pid FROM parent_child pc WHERE pc.parent_id IN (SELECT id FROM me_persons)
                UNION SELECT pc.parent_id  FROM parent_child pc WHERE pc.child_id  IN (SELECT id FROM me_persons)
                UNION SELECT u.wife_id      FROM unions u WHERE u.husband_id IN (SELECT id FROM me_persons)
                UNION SELECT u.husband_id   FROM unions u WHERE u.wife_id    IN (SELECT id FROM me_persons)
                UNION SELECT s.person_b_id  FROM siblings s WHERE s.person_a_id IN (SELECT id FROM me_persons)
                UNION SELECT s.person_a_id  FROM siblings s WHERE s.person_b_id IN (SELECT id FROM me_persons)
                UNION SELECT pcl.person_id  FROM person_clans pcl WHERE pcl.clan_id IN (SELECT clan_id FROM my_clan_ids)
            ),
            linked_uids AS (
                SELECT DISTINCT p.user_id AS uid FROM persons p
                    WHERE p.id IN (SELECT pid FROM linked_pids) AND p.user_id IS NOT NULL
                UNION
                SELECT DISTINCT s2.user_id FROM village_subscriptions s1
                    JOIN village_subscriptions s2
                      ON s2.village_id = s1.village_id AND s2.user_id <> s1.user_id
                    WHERE s1.user_id = :me
                UNION
                SELECT DISTINCT m2.user_id FROM chat_group_members m1
                    JOIN chat_group_members m2
                      ON m2.group_id = m1.group_id AND m2.user_id <> m1.user_id
                    WHERE m1.user_id = :me
            )
            SELECT p.* FROM posts p
            WHERE p.moderation_status = 'APPROVED'
              AND (
                  p.author_id = :me
                  OR p.village_id IN (SELECT village_id FROM my_village_ids)
                  OR p.author_id IN (SELECT uid FROM linked_uids)
              )
            ORDER BY p.is_pinned DESC, p.created_at DESC
            LIMIT :size OFFSET :offset
            """, nativeQuery = true)
    List<Post> findMembershipFeed(@Param("me") UUID me,
                                  @Param("size") int size,
                                  @Param("offset") int offset);
}
