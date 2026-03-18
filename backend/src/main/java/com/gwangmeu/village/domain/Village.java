package com.gwangmeu.village.domain;

import com.gwangmeu.shared.audit.AuditEntity;
import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

@Entity
@Table(name = "villages", indexes = {
        @Index(name = "idx_villages_country", columnList = "country"),
        @Index(name = "idx_villages_continent_code", columnList = "continent_code")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Village extends AuditEntity {

    @Column(nullable = false)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(nullable = false)
    private String country;

    private String region;

    @Column(name = "continent_code", length = 10)
    private String continentCode;

    @Column(name = "cover_image_url")
    private String coverImageUrl;

    private Double latitude;
    private Double longitude;

    @Column(name = "founded_year")
    private Integer foundedYear;

    @Column(name = "population_estimate")
    private Integer populationEstimate;

    @Column(name = "primary_dialect")
    private String primaryDialect;

    @Column(name = "creator_id")
    private UUID creatorId;

    @Column(name = "is_verified")
    @Builder.Default
    private boolean verified = false;

    @Column(name = "member_count")
    @Builder.Default
    private int memberCount = 0;

    @Column(name = "historical_summary", columnDefinition = "TEXT")
    private String historicalSummary;

    @Column(name = "country_id")
    private UUID countryId;
}
