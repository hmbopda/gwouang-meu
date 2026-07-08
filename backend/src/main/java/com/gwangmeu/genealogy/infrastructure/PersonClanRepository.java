package com.gwangmeu.genealogy.infrastructure;

import com.gwangmeu.genealogy.domain.PersonClan;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface PersonClanRepository extends JpaRepository<PersonClan, PersonClan.PersonClanId> {

    List<PersonClan> findByPersonId(UUID personId);

    List<PersonClan> findByPersonIdIn(java.util.Collection<UUID> personIds);

    List<PersonClan> findByClanId(UUID clanId);

    @Query("SELECT pc.clanId FROM PersonClan pc WHERE pc.personId = :personId")
    List<UUID> findClanIdsByPersonId(UUID personId);

    @Query("SELECT pc.personId FROM PersonClan pc WHERE pc.clanId = :clanId")
    List<UUID> findPersonIdsByClanId(UUID clanId);

    void deleteByPersonId(UUID personId);
}
