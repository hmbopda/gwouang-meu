package com.gwangmeu.genealogy.infrastructure;

import com.gwangmeu.genealogy.domain.ParentChild;
import com.gwangmeu.genealogy.domain.enums.ParentRoleEnum;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ParentChildRepository extends JpaRepository<ParentChild, UUID> {

    List<ParentChild> findByParentId(UUID parentId);

    List<ParentChild> findByChildId(UUID childId);

    Optional<ParentChild> findByChildIdAndParentRole(UUID childId, ParentRoleEnum role);

    boolean existsByParentIdAndChildId(UUID parentId, UUID childId);
}
