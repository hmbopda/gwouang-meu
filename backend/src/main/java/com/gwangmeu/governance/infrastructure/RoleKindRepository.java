package com.gwangmeu.governance.infrastructure;

import com.gwangmeu.governance.domain.RoleKind;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface RoleKindRepository extends JpaRepository<RoleKind, String> {
}
