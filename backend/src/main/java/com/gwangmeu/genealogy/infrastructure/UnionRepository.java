package com.gwangmeu.genealogy.infrastructure;

import com.gwangmeu.genealogy.domain.GenealogyUnion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface UnionRepository extends JpaRepository<GenealogyUnion, UUID> {

    List<GenealogyUnion> findByHusbandId(UUID husbandId);

    List<GenealogyUnion> findByWifeId(UUID wifeId);

    @Query("SELECT u FROM GenealogyUnion u WHERE u.husbandId = :husbandId AND u.status IN ('ACTIVE', 'PENDING_APPROVAL', 'DIVORCE_PENDING', 'DEATH_PENDING', 'DISPUTE')")
    List<GenealogyUnion> findActiveUnionsByHusband(UUID husbandId);

    @Query("SELECT u FROM GenealogyUnion u WHERE u.wifeId = :wifeId AND u.status IN ('ACTIVE', 'PENDING_APPROVAL', 'DIVORCE_PENDING', 'DEATH_PENDING', 'DISPUTE')")
    List<GenealogyUnion> findActiveUnionsByWife(UUID wifeId);

    @Query("SELECT COUNT(u) FROM GenealogyUnion u WHERE u.husbandId = :husbandId AND u.status IN ('ACTIVE', 'PENDING_APPROVAL', 'DIVORCE_PENDING', 'DEATH_PENDING', 'DISPUTE')")
    long countActiveWivesByHusband(UUID husbandId);

    @Query("SELECT u FROM GenealogyUnion u WHERE u.husbandId = :personId OR u.wifeId = :personId")
    List<GenealogyUnion> findByPersonId(UUID personId);

    @Query("SELECT u FROM GenealogyUnion u WHERE (u.husbandId = :personId OR u.wifeId = :personId) AND u.status IN ('ACTIVE', 'PENDING_APPROVAL', 'DIVORCE_PENDING', 'DEATH_PENDING', 'DISPUTE')")
    List<GenealogyUnion> findActiveUnionsByPerson(UUID personId);

    @Query("SELECT COALESCE(MAX(u.unionOrder), 0) FROM GenealogyUnion u WHERE u.husbandId = :husbandId")
    int findMaxUnionOrderByHusband(UUID husbandId);
}
