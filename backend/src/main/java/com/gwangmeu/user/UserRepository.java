package com.gwangmeu.user;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserRepository extends JpaRepository<User, UUID> {

    Optional<User> findBySupabaseId(String supabaseId);

    Optional<User> findByEmail(String email);

    boolean existsByEmail(String email);

    boolean existsBySupabaseId(String supabaseId);

    /**
     * Utilisateurs LIÉS à {@code me} — ceux à qui il peut écrire directement :
     * co-membres de ses villages, famille (parents/enfants/conjoints/frères-sœurs),
     * et même clan (résolus via persons.user_id). Filtré par nom ({@code q} vide =
     * tous). Exclut {@code me}. Requête native (unaccent + CTE hors JPQL).
     */
    @Query(value = """
            WITH me_persons AS (
                SELECT id FROM persons WHERE user_id = :me
            ),
            linked_pids AS (
                SELECT pc.child_id AS pid FROM parent_child pc WHERE pc.parent_id IN (SELECT id FROM me_persons)
                UNION SELECT pc.parent_id FROM parent_child pc WHERE pc.child_id IN (SELECT id FROM me_persons)
                UNION SELECT u.wife_id FROM unions u WHERE u.husband_id IN (SELECT id FROM me_persons)
                UNION SELECT u.husband_id FROM unions u WHERE u.wife_id IN (SELECT id FROM me_persons)
                UNION SELECT s.person_b_id FROM siblings s WHERE s.person_a_id IN (SELECT id FROM me_persons)
                UNION SELECT s.person_a_id FROM siblings s WHERE s.person_b_id IN (SELECT id FROM me_persons)
                UNION SELECT pcl.person_id FROM person_clans pcl
                      WHERE pcl.clan_id IN (SELECT clan_id FROM person_clans
                                            WHERE person_id IN (SELECT id FROM me_persons))
            ),
            linked_uids AS (
                SELECT DISTINCT p.user_id AS uid FROM persons p
                    WHERE p.id IN (SELECT pid FROM linked_pids) AND p.user_id IS NOT NULL
                UNION
                SELECT DISTINCT s2.user_id FROM village_subscriptions s1
                    JOIN village_subscriptions s2
                      ON s2.village_id = s1.village_id AND s2.user_id <> s1.user_id
                    WHERE s1.user_id = :me
            )
            SELECT u.* FROM users u
            JOIN linked_uids l ON l.uid = u.id
            WHERE u.id <> :me
              AND (:q = '' OR unaccent(lower(u.display_name)) LIKE unaccent(lower('%' || :q || '%')))
            ORDER BY u.display_name
            LIMIT 30
            """, nativeQuery = true)
    List<User> findLinkedContacts(@Param("me") UUID me, @Param("q") String q);
}
