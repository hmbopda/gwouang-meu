package com.gwangmeu.genealogy.infrastructure;

import com.gwangmeu.genealogy.domain.PersonInvitation;
import com.gwangmeu.genealogy.domain.enums.InvitationStatusEnum;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface PersonInvitationRepository extends JpaRepository<PersonInvitation, UUID> {

    Optional<PersonInvitation> findByToken(String token);

    List<PersonInvitation> findByPersonIdAndStatus(UUID personId, InvitationStatusEnum status);

    boolean existsByPersonIdAndStatus(UUID personId, InvitationStatusEnum status);
}
