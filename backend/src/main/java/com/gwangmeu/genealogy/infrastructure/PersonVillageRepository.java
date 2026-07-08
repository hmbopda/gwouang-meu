package com.gwangmeu.genealogy.infrastructure;

import com.gwangmeu.genealogy.domain.PersonVillage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.UUID;

@Repository
public interface PersonVillageRepository extends JpaRepository<PersonVillage, PersonVillage.PersonVillageId> {

    List<PersonVillage> findByPersonId(UUID personId);

    List<PersonVillage> findByPersonIdIn(Collection<UUID> personIds);

    List<PersonVillage> findByVillageId(UUID villageId);

    void deleteByPersonId(UUID personId);

    @Query("SELECT pv.villageId FROM PersonVillage pv WHERE pv.personId = :personId")
    List<UUID> findVillageIdsByPersonId(UUID personId);

    @Query("SELECT pv.personId FROM PersonVillage pv WHERE pv.villageId = :villageId")
    List<UUID> findPersonIdsByVillageId(UUID villageId);
}
