package com.gwangmeu.genealogy.infrastructure;

import com.gwangmeu.genealogy.domain.Clan;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ClanRepository extends JpaRepository<Clan, UUID> {

    List<Clan> findByVillageIdOrderByNameAsc(UUID villageId);

    List<Clan> findByNameIgnoreCaseAndVillageId(String name, UUID villageId);
}
