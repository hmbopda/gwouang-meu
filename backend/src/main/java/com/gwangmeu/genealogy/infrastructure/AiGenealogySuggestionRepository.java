package com.gwangmeu.genealogy.infrastructure;

import com.gwangmeu.genealogy.domain.AiGenealogySuggestion;
import com.gwangmeu.genealogy.domain.enums.AiSuggestionStatusEnum;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface AiGenealogySuggestionRepository extends JpaRepository<AiGenealogySuggestion, UUID> {

    List<AiGenealogySuggestion> findByPersonAIdAndStatus(UUID personAId, AiSuggestionStatusEnum status);

    @Query("SELECT s FROM AiGenealogySuggestion s WHERE (s.personAId = :personId OR s.personBId = :personId) AND s.status = :status")
    List<AiGenealogySuggestion> findByPersonIdAndStatus(UUID personId, AiSuggestionStatusEnum status);
}
