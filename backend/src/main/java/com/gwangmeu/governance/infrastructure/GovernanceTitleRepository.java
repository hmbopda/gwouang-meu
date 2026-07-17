package com.gwangmeu.governance.infrastructure;

import com.gwangmeu.governance.domain.GovernanceTitle;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface GovernanceTitleRepository extends JpaRepository<GovernanceTitle, UUID> {

    List<GovernanceTitle> findByModelIdOrderByTierAscRankAsc(UUID modelId);

    Optional<GovernanceTitle> findByModelIdAndApexTrue(UUID modelId);
}
