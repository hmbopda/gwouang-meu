package com.gwangmeu.genealogy.infrastructure;

import com.gwangmeu.genealogy.domain.ChildAssociationRequest;
import com.gwangmeu.genealogy.domain.enums.AssociationRequestStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ChildAssociationRequestRepository extends JpaRepository<ChildAssociationRequest, UUID> {

    Optional<ChildAssociationRequest> findByChildIdAndTargetParentId(UUID childId, UUID targetParentId);

    List<ChildAssociationRequest> findByTargetParentIdAndStatus(UUID targetParentId, AssociationRequestStatus status);

    List<ChildAssociationRequest> findByRequesterId(UUID requesterId);
}
