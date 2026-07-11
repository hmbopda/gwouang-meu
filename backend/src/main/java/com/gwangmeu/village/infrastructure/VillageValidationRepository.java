package com.gwangmeu.village.infrastructure;

import com.gwangmeu.village.domain.VillageValidation;
import com.gwangmeu.village.domain.VillageValidationKind;
import com.gwangmeu.village.domain.VillageValidationStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface VillageValidationRepository extends JpaRepository<VillageValidation, UUID> {

    List<VillageValidation> findByVillageIdAndStatusOrderByCreatedAtDesc(
            UUID villageId, VillageValidationStatus status);

    List<VillageValidation> findByVillageIdAndKindAndStatusOrderByCreatedAtDesc(
            UUID villageId, VillageValidationKind kind, VillageValidationStatus status);

    List<VillageValidation> findByVillageIdAndKindOrderByCreatedAtDesc(
            UUID villageId, VillageValidationKind kind);

    List<VillageValidation> findByVillageIdOrderByCreatedAtDesc(UUID villageId);
}
