package com.gwangmeu.geo.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.UUID;

/**
 * Arrondissement / commune (read-only). Table geo_arrondissements (migration V44).
 * Pas de colonnes created_at/updated_at → n'etend PAS AuditEntity.
 */
@Entity
@Table(name = "geo_arrondissements")
@Getter
@NoArgsConstructor
public class GeoArrondissement {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "country_iso2", nullable = false, length = 2)
    private String countryIso2;

    @Column(name = "code", nullable = false, length = 30)
    private String code;

    @Column(name = "department_code", nullable = false, length = 20)
    private String departmentCode;

    @Column(name = "name", nullable = false, length = 150)
    private String name;

    @Column(name = "lat")
    private Double lat;

    @Column(name = "lng")
    private Double lng;
}
