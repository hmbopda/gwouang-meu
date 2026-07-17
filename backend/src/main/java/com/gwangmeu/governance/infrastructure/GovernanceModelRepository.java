package com.gwangmeu.governance.infrastructure;

import com.gwangmeu.governance.domain.GovernanceModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface GovernanceModelRepository extends JpaRepository<GovernanceModel, UUID> {

    List<GovernanceModel> findByStatus(String status);

    Optional<GovernanceModel> findFirstByCodeAndStatusOrderByModelVersionDesc(String code, String status);

    Optional<GovernanceModel> findByDefaultModelTrueAndCountryIso2IsNullAndStatus(String status);
}
