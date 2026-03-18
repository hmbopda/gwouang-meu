package com.gwangmeu.genealogy.infrastructure;

import com.gwangmeu.genealogy.domain.Person;
import com.gwangmeu.genealogy.domain.enums.PersonStatusEnum;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface PersonRepository extends JpaRepository<Person, UUID> {

    List<Person> findByCreatedBy(UUID userId);

    Optional<Person> findByUserId(UUID userId);

    Optional<Person> findByNeo4jNodeId(String neo4jNodeId);

    @Query("""
        SELECT p FROM Person p
        JOIN PersonVillage pv ON pv.personId = p.id
        WHERE pv.villageId = :villageId
    """)
    List<Person> findByVillageId(UUID villageId);

    @Query("""
        SELECT p FROM Person p
        JOIN PersonVillage pv ON pv.personId = p.id
        WHERE pv.villageId = :villageId AND p.clan = :clan
    """)
    List<Person> findByVillageIdAndClan(UUID villageId, String clan);

    @Query("""
        SELECT p FROM Person p
        JOIN PersonVillage pv ON pv.personId = p.id
        WHERE pv.villageId = :villageId AND p.status = :status
    """)
    Page<Person> findByVillageIdAndStatus(UUID villageId, PersonStatusEnum status, Pageable pageable);

    @Query("""
        SELECT DISTINCT p.clan FROM Person p
        JOIN PersonVillage pv ON pv.personId = p.id
        WHERE pv.villageId = :villageId AND p.clan IS NOT NULL AND p.clan <> ''
        ORDER BY p.clan
    """)
    List<String> findDistinctClansByVillageId(UUID villageId);

    @Query("""
        SELECT p FROM Person p
        WHERE p.clan = :clan
        AND (LOWER(p.firstName) LIKE LOWER(CONCAT('%', :search, '%'))
             OR LOWER(p.lastName) LIKE LOWER(CONCAT('%', :search, '%')))
        ORDER BY p.lastName, p.firstName
    """)
    List<Person> searchByClanAndName(String clan, String search);

    @Query("""
        SELECT p FROM Person p
        WHERE p.clan = :clan
        ORDER BY p.lastName, p.firstName
    """)
    List<Person> findByClan(String clan);

    @Query("""
        SELECT p FROM Person p
        JOIN PersonVillage pv ON pv.personId = p.id
        WHERE pv.villageId = :villageId AND p.gender = :gender
        ORDER BY p.lastName, p.firstName
    """)
    List<Person> findByVillageIdAndGender(UUID villageId, com.gwangmeu.shared.domain.enums.GenderEnum gender);

    @Query("""
        SELECT p FROM Person p
        JOIN PersonClan pc ON pc.personId = p.id
        WHERE pc.clanId = :clanId AND p.gender = :gender
        ORDER BY p.lastName, p.firstName
    """)
    List<Person> findByClanIdAndGender(UUID clanId, com.gwangmeu.shared.domain.enums.GenderEnum gender);

    @Query("""
        SELECT p FROM Person p
        JOIN PersonClan pc ON pc.personId = p.id
        WHERE pc.clanId = :clanId
        ORDER BY p.lastName, p.firstName
    """)
    List<Person> findByClanId(UUID clanId);

    @Query("""
        SELECT DISTINCT p.userId FROM Person p
        WHERE p.userId IS NOT NULL
        AND (p.id IN (SELECT pc.parentId FROM ParentChild pc WHERE pc.childId = :personId)
             OR p.id IN (SELECT pc.childId FROM ParentChild pc WHERE pc.parentId = :personId)
             OR p.id IN (SELECT pc2.childId FROM ParentChild pc1
                         JOIN ParentChild pc2 ON pc2.parentId = pc1.parentId
                         WHERE pc1.childId = :personId AND pc2.childId <> :personId))
    """)
    List<UUID> findFamilyUserIds(UUID personId);

    @Query("""
        SELECT p FROM Person p
        WHERE LOWER(p.firstName) = LOWER(:firstName)
        AND LOWER(p.lastName) = LOWER(:lastName)
        AND p.birthDate = :birthDate
    """)
    List<Person> findByNameAndBirthDate(String firstName, String lastName, LocalDate birthDate);

    @Query("""
        SELECT p FROM Person p
        WHERE LOWER(p.firstName) = LOWER(:firstName)
        AND LOWER(p.lastName) = LOWER(:lastName)
        AND p.birthDate = :birthDate
        AND p.gender = :gender
    """)
    List<Person> findByNameBirthDateAndGender(
            @Param("firstName") String firstName,
            @Param("lastName") String lastName,
            @Param("birthDate") LocalDate birthDate,
            @Param("gender") com.gwangmeu.shared.domain.enums.GenderEnum gender);

    Optional<Person> findByEmailIgnoreCase(String email);

    Optional<Person> findByPhone(String phone);

    @Query(value = """
        SELECT * FROM persons p
        WHERE (LOWER(p.email) = LOWER(CAST(:email AS TEXT)) AND CAST(:email AS TEXT) IS NOT NULL AND CAST(:email AS TEXT) <> '')
           OR (p.phone = CAST(:phone AS TEXT) AND CAST(:phone AS TEXT) IS NOT NULL AND CAST(:phone AS TEXT) <> '')
        ORDER BY p.last_name, p.first_name
    """, nativeQuery = true)
    List<Person> findByEmailOrPhone(@Param("email") String email, @Param("phone") String phone);
}
