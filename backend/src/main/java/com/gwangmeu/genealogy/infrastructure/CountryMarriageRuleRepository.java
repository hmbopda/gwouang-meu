package com.gwangmeu.genealogy.infrastructure;

import com.gwangmeu.genealogy.domain.CountryMarriageRule;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * Acces lecture au referentiel pays. Les cles ISO-2 sont normalisees en
 * majuscules au niveau service ; le cache memoire evite les allers-retours DB.
 */
@Repository
public interface CountryMarriageRuleRepository extends JpaRepository<CountryMarriageRule, String> {

    Optional<CountryMarriageRule> findByIso2IgnoreCase(String iso2);
}
