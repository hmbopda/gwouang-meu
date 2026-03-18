package com.gwangmeu.user;

import com.gwangmeu.shared.api.ApiResponse;
import com.gwangmeu.shared.security.CurrentUser;
import com.gwangmeu.user.dto.CreateUserRequest;
import com.gwangmeu.user.dto.UpdateUserRequest;
import com.gwangmeu.user.dto.UserDto;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
@Tag(name = "Users", description = "Gestion des profils utilisateurs GWANG MEU")
public class UserController {

    private final UserService userService;

    @GetMapping("/me")
    @Operation(summary = "Mon profil", description = "Retourne le profil de l'utilisateur connecte.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Profil retourne"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "Non authentifie"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Profil non trouve — appeler /auth/sync d'abord")
    })
    public ResponseEntity<ApiResponse<UserDto>> getMe(@CurrentUser Jwt jwt) {
        UserDto dto = userService.getBySupabaseId(jwt.getSubject());
        return ResponseEntity.ok(ApiResponse.ok(dto));
    }

    @PutMapping("/me")
    @Operation(summary = "Modifier mon profil", description = "Mise a jour du profil connecte.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Profil mis a jour"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "Validation echouee"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "Non authentifie")
    })
    public ResponseEntity<ApiResponse<UserDto>> updateMe(@CurrentUser Jwt jwt,
                                                          @Valid @RequestBody UpdateUserRequest request) {
        UserDto dto = userService.updateProfile(jwt.getSubject(), request);
        return ResponseEntity.ok(ApiResponse.ok(dto, "Profil mis a jour"));
    }

    @GetMapping("/{userId}")
    @Operation(summary = "Profil public", description = "Retourne le profil public d'un utilisateur.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Profil retourne"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Utilisateur introuvable")
    })
    public ResponseEntity<ApiResponse<UserDto>> getById(@PathVariable UUID userId) {
        return ResponseEntity.ok(ApiResponse.ok(userService.getById(userId)));
    }

    @PostMapping("/auth/sync")
    @Operation(
            summary = "Synchroniser depuis Supabase",
            description = "Cree ou met a jour le profil utilisateur depuis le JWT Supabase. "
                    + "A appeler apres chaque login.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Sync reussie"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "JWT invalide")
    })
    public ResponseEntity<ApiResponse<UserDto>> syncFromSupabase(@CurrentUser Jwt jwt) {
        UserDto dto = userService.syncFromJwt(jwt);
        return ResponseEntity.status(HttpStatus.OK).body(ApiResponse.ok(dto, "Sync reussie"));
    }

    @PostMapping("/auth/register")
    @Operation(
            summary = "Enregistrer un utilisateur",
            description = "Cree un utilisateur en BDD apres le signUp Supabase. "
                    + "Endpoint public — pas de JWT necessaire (le JWT n'existe pas encore si confirmation email activee).")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "201", description = "Utilisateur cree"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "Validation echouee")
    })
    public ResponseEntity<ApiResponse<UserDto>> register(@Valid @RequestBody CreateUserRequest request) {
        UserDto dto = userService.register(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(dto, "Inscription reussie"));
    }

    @DeleteMapping("/me")
    @Operation(
            summary = "Supprimer mon compte (RGPD)",
            description = "Anonymise les donnees personnelles. Action irreversible.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "204", description = "Compte supprime"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "Non authentifie")
    })
    public ResponseEntity<ApiResponse<Void>> deleteMe(@CurrentUser Jwt jwt) {
        userService.deleteAccount(jwt.getSubject());
        return ResponseEntity.noContent().build();
    }
}
