package com.gwangmeu.geo.domain;

import com.gwangmeu.shared.audit.AuditEntity;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "continents")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Continent extends AuditEntity {

    @Column(unique = true, nullable = false, length = 10)
    private String code; // AF-CENTRAL, AF-WEST, AF-EAST, DIASPORA

    @Column(nullable = false)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "cover_image_url")
    private String coverImageUrl;
}
