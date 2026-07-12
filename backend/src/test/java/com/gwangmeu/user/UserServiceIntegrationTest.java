package com.gwangmeu.user;

import com.gwangmeu.shared.BaseIntegrationTest;
import com.gwangmeu.shared.domain.enums.GenderEnum;
import com.gwangmeu.shared.security.UserRole;
import com.gwangmeu.user.dto.CreateUserRequest;
import com.gwangmeu.user.dto.UpdateUserRequest;
import com.gwangmeu.user.dto.UserDto;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@Transactional
@DisplayName("UserService - Tests d'integration")
class UserServiceIntegrationTest extends BaseIntegrationTest {

    @Autowired
    private UserService userService;

    @Autowired
    private UserRepository userRepository;

    @BeforeEach
    void setUp() {
        userRepository.deleteAllInBatch();
    }

    private User insertUser(String supabaseId, String email) {
        User user = User.builder()
                .supabaseId(supabaseId)
                .email(email)
                .displayName("Test User")
                .country("Cameroun")
                .nativeLanguage("Bassa")
                .bio("Bio de test")
                .build();
        return userRepository.saveAndFlush(user);
    }

    // ── register ─────────────────────────────────────────────────────────────

    @Nested
    @DisplayName("register()")
    class Register {

        @Test
        @DisplayName("doit creer un nouvel utilisateur avec tous les champs")
        void shouldCreateNewUser() {
            CreateUserRequest request = new CreateUserRequest(
                    "sup-new-001",
                    "newuser@test.com",
                    "Aminata Diallo",
                    "Senegal",
                    "Wolof",
                    "Je suis une passionnee de genealogie",
                    null,
                    "Diop",
                    null, null, null, null, null,
                    GenderEnum.FEMALE
            );

            UserDto result = userService.register(request);

            assertThat(result).isNotNull();
            assertThat(result.id()).isNotNull();
            assertThat(result.email()).isEqualTo("newuser@test.com");
            assertThat(result.displayName()).isEqualTo("Aminata Diallo");
            assertThat(result.country()).isEqualTo("Senegal");
            assertThat(result.nativeLanguage()).isEqualTo("Wolof");
            assertThat(result.bio()).isEqualTo("Je suis une passionnee de genealogie");
            assertThat(result.clan()).isEqualTo("Diop");
            assertThat(result.role()).isEqualTo(UserRole.MEMBRE);
            assertThat(result.createdAt()).isNotNull();

            User persisted = userRepository.findBySupabaseId("sup-new-001").orElseThrow();
            assertThat(persisted.getEmail()).isEqualTo("newuser@test.com");
            assertThat(persisted.isActive()).isTrue();
            assertThat(persisted.getRole()).isEqualTo(UserRole.MEMBRE);
        }

        @Test
        @DisplayName("doit etre idempotent si le supabaseId existe deja")
        void shouldBeIdempotentWhenSupabaseIdExists() {
            User existing = insertUser("sup-idem-001", "existing@test.com");

            CreateUserRequest request = new CreateUserRequest(
                    "sup-idem-001",
                    "different-email@test.com",
                    "Autre Nom",
                    "Ghana",
                    "Twi",
                    "Autre bio",
                    null,
                    null,
                    null, null, null, null, null,
                    GenderEnum.MALE
            );

            UserDto result = userService.register(request);

            assertThat(result.id()).isEqualTo(existing.getId());
            assertThat(result.email()).isEqualTo("existing@test.com");
            assertThat(result.displayName()).isEqualTo("Test User");
            assertThat(userRepository.count()).isEqualTo(1);
        }

        @Test
        @DisplayName("doit mettre a jour le supabaseId si l'email existe deja")
        void shouldUpdateSupabaseIdWhenEmailExists() {
            User existing = insertUser("old-supabase-id", "shared@test.com");

            CreateUserRequest request = new CreateUserRequest(
                    "new-supabase-id",
                    "shared@test.com",
                    "Nom Different",
                    "Cameroun",
                    "Bassa",
                    null,
                    null,
                    null,
                    null, null, null, null, null,
                    GenderEnum.FEMALE
            );

            UserDto result = userService.register(request);

            assertThat(result.id()).isEqualTo(existing.getId());
            User updated = userRepository.findById(existing.getId()).orElseThrow();
            assertThat(updated.getSupabaseId()).isEqualTo("new-supabase-id");
            assertThat(userRepository.count()).isEqualTo(1);
        }
    }

    // ── getById ──────────────────────────────────────────────────────────────

    @Nested
    @DisplayName("getById()")
    class GetById {

        @Test
        @DisplayName("doit retourner le UserDto quand l'utilisateur existe")
        void shouldReturnUserDtoWhenUserExists() {
            User user = insertUser("sup-getid-001", "getbyid@test.com");

            UserDto result = userService.getById(user.getId());

            assertThat(result).isNotNull();
            assertThat(result.id()).isEqualTo(user.getId());
            assertThat(result.email()).isEqualTo("getbyid@test.com");
            assertThat(result.role()).isEqualTo(UserRole.MEMBRE);
        }

        @Test
        @DisplayName("doit lancer EntityNotFoundException quand l'utilisateur n'existe pas")
        void shouldThrowWhenUserNotFound() {
            UUID nonExistentId = UUID.randomUUID();

            assertThatThrownBy(() -> userService.getById(nonExistentId))
                    .isInstanceOf(EntityNotFoundException.class)
                    .hasMessageContaining(nonExistentId.toString());
        }
    }

    // ── getBySupabaseId ──────────────────────────────────────────────────────

    @Nested
    @DisplayName("getBySupabaseId()")
    class GetBySupabaseId {

        @Test
        @DisplayName("doit retourner le UserDto quand le supabaseId existe")
        void shouldReturnUserDtoWhenSupabaseIdExists() {
            insertUser("sup-lookup-001", "lookup@test.com");

            UserDto result = userService.getBySupabaseId("sup-lookup-001");

            assertThat(result).isNotNull();
            assertThat(result.email()).isEqualTo("lookup@test.com");
        }

        @Test
        @DisplayName("doit lancer EntityNotFoundException quand le supabaseId n'existe pas")
        void shouldThrowWhenSupabaseIdNotFound() {
            assertThatThrownBy(() -> userService.getBySupabaseId("non-existent-id"))
                    .isInstanceOf(EntityNotFoundException.class);
        }
    }

    // ── updateProfile ────────────────────────────────────────────────────────

    @Nested
    @DisplayName("updateProfile()")
    class UpdateProfile {

        @Test
        @DisplayName("doit mettre a jour uniquement les champs fournis (mise a jour partielle)")
        void shouldUpdateOnlyProvidedFields() {
            insertUser("sup-partial-001", "partial@test.com");

            UpdateUserRequest request = new UpdateUserRequest(
                    "Nouveau Nom", null, null, null, null, null, null,
                    null, null, null, null,
                    null, null, null, null,
                    null, null,
                    null, null, null, null, null,
                    "Developpeur", null, "Douala", null
            );

            UserDto result = userService.updateProfile("sup-partial-001", request);

            assertThat(result.displayName()).isEqualTo("Nouveau Nom");
            assertThat(result.profession()).isEqualTo("Developpeur");
            assertThat(result.residenceCity()).isEqualTo("Douala");
            assertThat(result.bio()).isEqualTo("Bio de test");
            assertThat(result.country()).isEqualTo("Cameroun");
        }

        @Test
        @DisplayName("doit mettre a jour tous les champs du profil")
        void shouldUpdateAllFields() {
            insertUser("sup-full-001", "full@test.com");

            UUID villageId = UUID.randomUUID();
            UpdateUserRequest request = new UpdateUserRequest(
                    "Nom Complet",
                    "Nouvelle bio",
                    "https://cdn.gwangmeu.com/avatar.jpg",
                    "https://cdn.gwangmeu.com/cover.jpg",
                    "Cameroun",
                    "Douala",
                    villageId,
                    "Papa Mensah", "Edea",
                    "Mama Njock", "Kribi",
                    "Marie(e)", "Monogamie",
                    3, "Omnivore",
                    "Bassa", "Bakoko",
                    "CM", "Ouest", "Koung-Khi", "Bayangam", "Bandenkop",
                    "Ingenieur", "Gwang Meu Inc.",
                    "Paris", "France"
            );

            UserDto result = userService.updateProfile("sup-full-001", request);

            assertThat(result.displayName()).isEqualTo("Nom Complet");
            assertThat(result.bio()).isEqualTo("Nouvelle bio");
            assertThat(result.avatarUrl()).isEqualTo("https://cdn.gwangmeu.com/avatar.jpg");
            assertThat(result.coverUrl()).isEqualTo("https://cdn.gwangmeu.com/cover.jpg");
            assertThat(result.originVillageId()).isEqualTo(villageId);
            assertThat(result.fatherName()).isEqualTo("Papa Mensah");
            assertThat(result.motherName()).isEqualTo("Mama Njock");
            assertThat(result.maritalStatus()).isEqualTo("Marie(e)");
            assertThat(result.childrenCount()).isEqualTo(3);
            assertThat(result.profession()).isEqualTo("Ingenieur");
            assertThat(result.residenceCountry()).isEqualTo("France");
        }

        @Test
        @DisplayName("doit lancer EntityNotFoundException si le supabaseId n'existe pas")
        void shouldThrowWhenSupabaseIdNotFound() {
            UpdateUserRequest request = new UpdateUserRequest(
                    "Nom", null, null, null, null, null, null,
                    null, null, null, null,
                    null, null, null, null,
                    null, null,
                    null, null, null, null, null,
                    null, null, null, null
            );

            assertThatThrownBy(() -> userService.updateProfile("inexistant", request))
                    .isInstanceOf(EntityNotFoundException.class);
        }
    }

    // ── deleteAccount ────────────────────────────────────────────────────────

    @Nested
    @DisplayName("deleteAccount() - Anonymisation RGPD")
    class DeleteAccount {

        @Test
        @DisplayName("doit anonymiser les donnees personnelles conformement au RGPD")
        void shouldAnonymizeUserDataForRgpd() {
            User user = insertUser("sup-delete-001", "todelete@test.com");
            user.setDisplayName("Nom a Supprimer");
            user.setBio("Biographie confidentielle");
            user.setAvatarUrl("https://cdn.gwangmeu.com/old-avatar.jpg");
            userRepository.saveAndFlush(user);

            userService.deleteAccount("sup-delete-001");

            User deleted = userRepository.findById(user.getId()).orElseThrow();
            assertThat(deleted.isActive()).isFalse();
            assertThat(deleted.getEmail()).isEqualTo("deleted_" + user.getId() + "@gwangmeu.deleted");
            assertThat(deleted.getDisplayName()).isEqualTo("[Compte supprime]");
            assertThat(deleted.getBio()).isNull();
            assertThat(deleted.getAvatarUrl()).isNull();
        }

        @Test
        @DisplayName("doit lancer EntityNotFoundException si le supabaseId n'existe pas")
        void shouldThrowWhenSupabaseIdNotFound() {
            assertThatThrownBy(() -> userService.deleteAccount("inexistant"))
                    .isInstanceOf(EntityNotFoundException.class);
        }

        @Test
        @DisplayName("le compte supprime ne doit plus etre trouvable par l'ancien email")
        void deletedAccountShouldNotBeFoundByOriginalEmail() {
            insertUser("sup-delete-002", "vanished@test.com");

            userService.deleteAccount("sup-delete-002");

            assertThat(userRepository.findByEmail("vanished@test.com")).isEmpty();
        }
    }
}
