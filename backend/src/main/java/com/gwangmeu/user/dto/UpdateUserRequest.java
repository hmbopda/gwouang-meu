package com.gwangmeu.user.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Size;

import java.util.UUID;

@Schema(description = "Requete de mise a jour du profil")
public record UpdateUserRequest(

        @Schema(description = "Nom affiche", example = "Kofi Mensah")
        @Size(min = 2, max = 80, message = "Le nom doit contenir entre 2 et 80 caracteres")
        String displayName,

        @Schema(description = "Biographie culturelle (max 500 chars)")
        @Size(max = 500, message = "La bio ne peut pas depasser 500 caracteres")
        String bio,

        @Schema(description = "URL avatar")
        String avatarUrl,

        @Schema(description = "URL photo de couverture")
        String coverUrl,

        @Schema(description = "Pays d'origine", example = "Cameroun")
        String country,

        @Schema(description = "Langue maternelle", example = "Bassa")
        @Size(max = 20)
        String nativeLanguage,

        @Schema(description = "ID du village d'origine")
        UUID originVillageId,

        // ── Parents ──────────────────────────────────────
        @Schema(description = "Nom complet du pere")
        String fatherName,

        @Schema(description = "Village/lieu d'origine du pere")
        String fatherOrigin,

        @Schema(description = "Nom complet de la mere")
        String motherName,

        @Schema(description = "Village/lieu d'origine de la mere")
        String motherOrigin,

        // ── Famille ──────────────────────────────────────
        @Schema(description = "Situation maritale", example = "Marie(e)")
        String maritalStatus,

        @Schema(description = "Regime matrimonial", example = "Monogamie")
        String matrimonialRegime,

        @Schema(description = "Nombre d'enfants")
        Integer childrenCount,

        @Schema(description = "Regime alimentaire", example = "Omnivore")
        String diet,

        // ── Origines culturelles (village gere via village_subscriptions) ──
        @Schema(description = "Ethnie / Tribu", example = "Bassa")
        String tribe,

        @Schema(description = "Clan", example = "Bakoko")
        String clan,

        // ── Residence & Profession ───────────────────────
        @Schema(description = "Profession / Metier", example = "Ingenieur logiciel")
        String profession,

        @Schema(description = "Employeur / Entreprise")
        String employer,

        @Schema(description = "Ville de residence", example = "Paris")
        String residenceCity,

        @Schema(description = "Pays de residence", example = "France")
        String residenceCountry
) {}
