package com.gwangmeu.genealogy.infrastructure;

import com.gwangmeu.genealogy.domain.DissolutionReminder;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface DissolutionReminderRepository extends JpaRepository<DissolutionReminder, UUID> {

    List<DissolutionReminder> findByUnionId(UUID unionId);

    boolean existsByUnionIdAndReminderType(UUID unionId, String reminderType);
}
