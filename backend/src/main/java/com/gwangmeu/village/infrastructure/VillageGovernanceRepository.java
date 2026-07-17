package com.gwangmeu.village.infrastructure;

import com.gwangmeu.village.domain.VillageGovernance;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface VillageGovernanceRepository extends JpaRepository<VillageGovernance, UUID> {
}
