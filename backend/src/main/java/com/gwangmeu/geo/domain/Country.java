package com.gwangmeu.geo.domain;

import com.gwangmeu.shared.audit.AuditEntity;
import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

@Entity
@Table(name = "countries")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Country extends AuditEntity {

    @Column(name = "code", unique = true, nullable = false, length = 3)
    private String isoCode; // CMR, CIV, SEN, COD, NGA...

    @Column(name = "iso2", length = 2)
    private String iso2; // CM, CI, SN, CD, NG... (ISO-3166 alpha-2, V47)

    @Column(nullable = false)
    private String name;

    @Column(name = "name_fr")
    private String nameFr;

    @Column(name = "continent_code", nullable = false, length = 20)
    private String continentCode;

    @Column(name = "flag_url")
    private String flagUrl;

    @Column(name = "flag_emoji", length = 20)
    private String flagEmoji;

    @Column(name = "continent_id")
    private UUID continentId;

    @Column(name = "phone_code", length = 6)
    private String phoneCode;
}
