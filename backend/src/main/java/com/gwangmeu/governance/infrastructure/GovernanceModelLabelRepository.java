package com.gwangmeu.governance.infrastructure;

import com.gwangmeu.governance.domain.GovernanceModelLabel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface GovernanceModelLabelRepository extends JpaRepository<GovernanceModelLabel, UUID> {

    List<GovernanceModelLabel> findByModelId(UUID modelId);
}
