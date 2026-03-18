package com.gwangmeu.geo.infrastructure;

import com.gwangmeu.geo.domain.Language;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface LanguageRepository extends JpaRepository<Language, UUID> {

    Optional<Language> findByNameIgnoreCase(String name);

    List<Language> findAllByIdIn(List<UUID> ids);

    List<Language> findAllByOrderByNameAsc();
}
