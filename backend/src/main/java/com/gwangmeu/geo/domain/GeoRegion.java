package com.gwangmeu.geo.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.UUID;

/**
 * Region administrative (read-only). Table geo_regions (migration V44).
 * Pas de colonnes created_at/updated_at → n'etend PAS AuditEntity.
 */
@Entity
@Table(name = "geo_regions")
@Getter
@NoArgsConstructor
public class GeoRegion {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "country_iso2", nullable = false, length = 2)
    private String countryIso2;

    @Column(name = "code", nullable = false, length = 10)
    private String code;

    @Column(name = "name", nullable = false, length = 150)
    private String name;

    @Column(name = "chief_town", length = 150)
    private String chiefTown;

    @Column(name = "lat")
    private Double lat;

    @Column(name = "lng")
    private Double lng;
}
