package com.gwangmeu.user.dto;

import com.gwangmeu.shared.domain.enums.GenderEnum;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

@Schema(description = "Requete de creation d'utilisateur depuis le frontend (apres signUp Supabase)")
public record CreateUserRequest(

        @Schema(description = "ID Supabase (sub du JWT)", example = "a1b2c3d4-e5f6-7890-abcd-ef1234567890")
        @NotBlank(message = "Le supabaseId est obligatoire")
        String supabaseId,

        @Schema(description = "Email de l'utilisateur", example = "kofi@gmail.com")
        @NotBlank(message = "L'email est obligatoire")
        @Email(message = "Format email invalide")
        String email,

        @Schema(description = "Nom affiche", example = "Kofi Mensah")
        @NotBlank(message = "Le nom est obligatoire")
        @Size(min = 2, max = 80)
        String displayName,

        @Schema(description = "Pays d'origine", example = "Cameroun")
        String country,

        @Schema(description = "Langue maternelle", example = "Bassa")
        @Size(max = 20)
        String nativeLanguage,

        @Schema(description = "Biographie")
        @Size(max = 500)
        String bio,

        @Schema(description = "ID du village d'origine selectionne a l'inscription")
        java.util.UUID villageId,

        @Schema(description = "Clan/famille selectionne ou saisi a l'inscription")
        @Size(max = 50)
        String clan,

        @Schema(description = "Genre de l'utilisateur", example = "MALE")
        @NotNull(message = "Le genre est obligatoire")
        GenderEnum gender
) {}
