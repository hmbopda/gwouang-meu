package com.gwangmeu.genealogy.infrastructure;

import com.gwangmeu.genealogy.domain.PersonComment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface PersonCommentRepository extends JpaRepository<PersonComment, UUID> {

    List<PersonComment> findByPersonIdOrderByCreatedAtDesc(UUID personId);

    long countByPersonId(UUID personId);
}
