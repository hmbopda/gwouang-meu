package com.gwangmeu.governance.infrastructure;

import com.gwangmeu.governance.domain.GovernanceTitleLabel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface GovernanceTitleLabelRepository extends JpaRepository<GovernanceTitleLabel, UUID> {

    List<GovernanceTitleLabel> findByTitleId(UUID titleId);
}
