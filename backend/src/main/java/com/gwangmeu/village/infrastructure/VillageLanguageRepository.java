package com.gwangmeu.village.infrastructure;

import com.gwangmeu.village.domain.VillageLanguage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface VillageLanguageRepository
        extends JpaRepository<VillageLanguage, VillageLanguage.VillageLanguageId> {

    List<VillageLanguage> findByVillageId(UUID villageId);

    void deleteByVillageId(UUID villageId);
}
