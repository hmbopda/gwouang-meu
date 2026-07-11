package com.gwangmeu.user.dto;

import com.gwangmeu.shared.security.UserRole;
import io.swagger.v3.oas.annotations.media.Schema;

import java.time.Instant;
import java.util.UUID;

@Schema(description = "Profil utilisateur GWANG MEU")
public record UserDto(

        @Schema(description = "ID unique")
        UUID id,

        @Schema(description = "Email")
        String email,

        @Schema(description = "Nom affiche")
        String displayName,

        @Schema(description = "Role RBAC")
        UserRole role,

        @Schema(description = "Pays d'origine")
        String country,

        @Schema(description = "Langue maternelle")
        String nativeLanguage,

        @Schema(description = "Biographie culturelle")
        String bio,

        @Schema(description = "URL photo de profil")
        String avatarUrl,

        @Schema(description = "URL photo de couverture")
        String coverUrl,

        @Schema(description = "ID du village d'origine")
        UUID originVillageId,

        // ── Parents ──────────────────────────────────────
        String fatherName,
        String fatherOrigin,
        String motherName,
        String motherOrigin,

        // ── Famille ──────────────────────────────────────
        String maritalStatus,
        String matrimonialRegime,
        Integer childrenCount,
        String diet,

        // ── Origines culturelles (village gere via village_subscriptions) ──
        String tribe,
        String clan,

        // ── Origine referentielle (ancre de la lignee, noms du referentiel) ──
        String originCountry,
        String originRegion,
        String originDepartment,
        String originArrondissement,
        String originVillage,

        // ── Residence & Profession ───────────────────────
        String profession,
        String employer,
        String residenceCity,
        String residenceCountry,

        @Schema(description = "Date de creation")
        Instant createdAt
) {}
