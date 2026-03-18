package com.gwangmeu.genealogy.infrastructure;

import com.gwangmeu.genealogy.domain.PersonModificationRequest;
import com.gwangmeu.genealogy.domain.enums.AssociationRequestStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface PersonModificationRequestRepository extends JpaRepository<PersonModificationRequest, UUID> {

    List<PersonModificationRequest> findByPersonIdAndStatus(UUID personId, AssociationRequestStatus status);

    List<PersonModificationRequest> findByRequesterId(UUID requesterId);
}
