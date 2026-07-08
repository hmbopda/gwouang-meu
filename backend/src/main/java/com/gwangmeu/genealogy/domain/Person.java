package com.gwangmeu.genealogy.domain;

import com.gwangmeu.shared.domain.enums.GenderEnum;
import com.gwangmeu.genealogy.domain.enums.MaritalStatusEnum;
import com.gwangmeu.genealogy.domain.enums.PersonStatusEnum;
import com.gwangmeu.genealogy.domain.enums.PrivacyEnum;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "persons")
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Person {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_id")
    private UUID userId;

    @Column(name = "first_name", nullable = false, length = 100)
    private String firstName;

    @Column(name = "last_name", nullable = false, length = 100)
    private String lastName;

    @Column(name = "maiden_name", length = 100)
    private String maidenName;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    @Column(nullable = false)
    private GenderEnum gender;

    @Column(name = "birth_date")
    private LocalDate birthDate;

    @Column(name = "birth_place", length = 200)
    private String birthPlace;

    @Column(name = "death_date")
    private LocalDate deathDate;

    @Column(length = 100)
    private String clan;

    @Column(length = 100)
    private String totem;

    @Column(name = "native_language", length = 50)
    private String nativeLanguage;

    @Column(length = 80)
    private String religion;

    @Column(length = 120)
    private String profession;

    @Column(length = 255)
    private String email;

    @Column(length = 30)
    private String phone;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    @Column(name = "marital_status", length = 30)
    private MaritalStatusEnum maritalStatus;

    /** Pays de residence, ISO-3166 alpha-2 (ex: CM, FR). */
    @Column(name = "residence_country", length = 2)
    private String residenceCountry;

    /** Regime matrimonial declare (MONOGAMY, POLYGAMY, CUSTOMARY, DE_FACTO, UNKNOWN). */
    @Column(name = "marital_regime", length = 20)
    private String maritalRegime;

    @Column(columnDefinition = "TEXT")
    private String biography;

    @Column(name = "photo_url", columnDefinition = "TEXT")
    private String photoUrl;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    @Column(nullable = false)
    @Builder.Default
    private PrivacyEnum privacy = PrivacyEnum.FAMILY_ONLY;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    @Column(nullable = false)
    @Builder.Default
    private PersonStatusEnum status = PersonStatusEnum.PENDING;

    @Column(name = "neo4j_node_id", unique = true, length = 100)
    private String neo4jNodeId;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Column(name = "created_by", nullable = false, updatable = false)
    private UUID createdBy;

    @Transient
    public boolean isAlive() {
        return this.deathDate == null;
    }
}
