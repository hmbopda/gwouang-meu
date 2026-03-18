package com.gwangmeu.geo.infrastructure;

import com.gwangmeu.geo.domain.DialectArea;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface DialectAreaRepository extends JpaRepository<DialectArea, UUID> {
    List<DialectArea> findByNameContainingIgnoreCase(String name);
}
