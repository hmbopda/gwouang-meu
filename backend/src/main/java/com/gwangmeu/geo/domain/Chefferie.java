package com.gwangmeu.geo.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.UUID;

/**
 * Chefferie traditionnelle (read-only). Table chefferies (migration V44).
 * Pas de colonnes created_at/updated_at → n'etend PAS AuditEntity.
 */
@Entity
@Table(name = "chefferies")
@Getter
@NoArgsConstructor
public class Chefferie {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "country_iso2", nullable = false, length = 2)
    private String countryIso2;

    @Column(name = "degre", nullable = false)
    private Short degre;

    @Column(name = "region_name", nullable = false, length = 150)
    private String regionName;

    @Column(name = "department_name", length = 150)
    private String departmentName;

    @Column(name = "department_code", length = 20)
    private String departmentCode;

    @Column(name = "numero")
    private Integer numero;

    @Column(name = "denomination", nullable = false, length = 250)
    private String denomination;

    @Column(name = "acte", length = 500)
    private String acte;
}
