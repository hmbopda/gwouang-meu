package com.gwangmeu.user;

import com.gwangmeu.shared.audit.AuditEntity;
import com.gwangmeu.shared.security.UserRole;
import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

@Entity
@Table(name = "users", indexes = {
        @Index(name = "idx_users_supabase_id", columnList = "supabase_id"),
        @Index(name = "idx_users_email",        columnList = "email")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User extends AuditEntity {

    @Column(name = "supabase_id", unique = true, nullable = false)
    private String supabaseId;

    @Column(unique = true, nullable = false)
    private String email;

    @Column(name = "display_name")
    private String displayName;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private UserRole role = UserRole.MEMBRE;

    private String country;

    @Column(name = "native_language", length = 20)
    private String nativeLanguage;

    @Column(columnDefinition = "TEXT")
    private String bio;

    @Column(name = "avatar_url")
    private String avatarUrl;

    @Column(name = "cover_url")
    private String coverUrl;

    @Column(name = "origin_village_id")
    private UUID originVillageId;

    // ── Parents ──────────────────────────────────────────
    @Column(name = "father_name")
    private String fatherName;

    @Column(name = "father_origin")
    private String fatherOrigin;

    @Column(name = "mother_name")
    private String motherName;

    @Column(name = "mother_origin")
    private String motherOrigin;

    // ── Famille ──────────────────────────────────────────
    @Column(name = "marital_status", length = 30)
    private String maritalStatus;

    @Column(name = "matrimonial_regime", length = 30)
    private String matrimonialRegime;

    @Column(name = "children_count")
    private Integer childrenCount;

    @Column(length = 30)
    private String diet;

    // ── Origines culturelles ─────────────────────────────
    // village(s) gere(s) via village_subscriptions (relation N:N)

    @Column(length = 50)
    private String tribe;

    @Column(length = 50)
    private String clan;

    // ── Origine référentielle (ancre de la lignée, noms du référentiel) ──
    @Column(name = "origin_country", length = 2)
    private String originCountry;

    @Column(name = "origin_region", length = 150)
    private String originRegion;

    @Column(name = "origin_department", length = 150)
    private String originDepartment;

    @Column(name = "origin_arrondissement", length = 150)
    private String originArrondissement;

    @Column(name = "origin_village", length = 150)
    private String originVillage;

    // ── Residence & Profession ───────────────────────────
    private String profession;

    private String employer;

    @Column(name = "residence_city")
    private String residenceCity;

    @Column(name = "residence_country")
    private String residenceCountry;

    @Column(name = "fcm_token")
    private String fcmToken;

    @Column(name = "is_active")
    @Builder.Default
    private boolean active = true;
}
