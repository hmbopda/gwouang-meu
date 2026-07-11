package com.gwangmeu.user;

import com.gwangmeu.shared.domain.enums.GenderEnum;
import com.gwangmeu.user.dto.CreateUserRequest;
import com.gwangmeu.user.dto.UpdateUserRequest;
import com.gwangmeu.user.dto.UserDto;
import com.gwangmeu.user.events.UserCreatedEvent;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("UserService — Tests unitaires")
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private UserMapper userMapper;

    @Mock
    private ApplicationEventPublisher eventPublisher;

    @InjectMocks
    private UserService userService;

    @Captor
    private ArgumentCaptor<User> userCaptor;

    @Captor
    private ArgumentCaptor<UserCreatedEvent> eventCaptor;

    private static final UUID USER_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final String SUPABASE_ID = "supabase-test-id-123";
    private static final String EMAIL = "kofi@gwangmeu.com";
    private static final String DISPLAY_NAME = "Kofi Mensah";
    private static final UUID VILLAGE_ID = UUID.fromString("22222222-2222-2222-2222-222222222222");

    private User defaultUser;
    private UserDto defaultUserDto;

    @BeforeEach
    void setUp() {
        defaultUser = User.builder()
                .supabaseId(SUPABASE_ID)
                .email(EMAIL)
                .displayName(DISPLAY_NAME)
                .country("Cameroun")
                .nativeLanguage("Bassa")
                .bio("Bio test")
                .originVillageId(VILLAGE_ID)
                .clan("Bakoko")
                .build();
        defaultUser.setId(USER_ID);

        defaultUserDto = new UserDto(
                USER_ID, EMAIL, DISPLAY_NAME, null, "Cameroun", "Bassa", "Bio test",
                null, null, VILLAGE_ID,
                null, null, null, null,
                null, null, null, null,
                null, null,
                null, null, null, null, null,
                null, null, null, null,
                Instant.now()
        );
    }

    // ════════════════════════════════════════════════════════
    // getById
    // ════════════════════════════════════════════════════════

    @Nested
    @DisplayName("getById — Recherche par UUID interne")
    class GetByIdTests {

        @Test
        @DisplayName("Doit retourner le UserDto quand l'utilisateur existe")
        void shouldReturnUserDtoWhenUserExists() {
            when(userRepository.findById(USER_ID)).thenReturn(Optional.of(defaultUser));
            when(userMapper.toDto(defaultUser)).thenReturn(defaultUserDto);

            UserDto result = userService.getById(USER_ID);

            assertThat(result).isNotNull();
            assertThat(result.id()).isEqualTo(USER_ID);
            assertThat(result.email()).isEqualTo(EMAIL);
            verify(userRepository).findById(USER_ID);
            verify(userMapper).toDto(defaultUser);
        }

        @Test
        @DisplayName("Doit lancer EntityNotFoundException quand l'utilisateur n'existe pas")
        void shouldThrowWhenUserNotFound() {
            UUID unknownId = UUID.randomUUID();
            when(userRepository.findById(unknownId)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> userService.getById(unknownId))
                    .isInstanceOf(EntityNotFoundException.class)
                    .hasMessageContaining("Utilisateur introuvable");

            verify(userMapper, never()).toDto(any(User.class));
        }
    }

    // ════════════════════════════════════════════════════════
    // getBySupabaseId
    // ════════════════════════════════════════════════════════

    @Nested
    @DisplayName("getBySupabaseId — Recherche par ID Supabase")
    class GetBySupabaseIdTests {

        @Test
        @DisplayName("Doit retourner le UserDto quand le supabaseId existe")
        void shouldReturnUserDtoWhenSupabaseIdExists() {
            when(userRepository.findBySupabaseId(SUPABASE_ID)).thenReturn(Optional.of(defaultUser));
            when(userMapper.toDto(defaultUser)).thenReturn(defaultUserDto);

            UserDto result = userService.getBySupabaseId(SUPABASE_ID);

            assertThat(result).isNotNull();
            assertThat(result.id()).isEqualTo(USER_ID);
            verify(userRepository).findBySupabaseId(SUPABASE_ID);
        }

        @Test
        @DisplayName("Doit lancer EntityNotFoundException quand le supabaseId n'existe pas")
        void shouldThrowWhenSupabaseIdNotFound() {
            when(userRepository.findBySupabaseId("unknown")).thenReturn(Optional.empty());

            assertThatThrownBy(() -> userService.getBySupabaseId("unknown"))
                    .isInstanceOf(EntityNotFoundException.class)
                    .hasMessageContaining("Utilisateur introuvable");
        }
    }

    // ════════════════════════════════════════════════════════
    // register
    // ════════════════════════════════════════════════════════

    @Nested
    @DisplayName("register — Creation d'utilisateur depuis le frontend")
    class RegisterTests {

        private CreateUserRequest buildRequest() {
            return new CreateUserRequest(
                    SUPABASE_ID, EMAIL, DISPLAY_NAME,
                    "Cameroun", "Bassa", "Bio test",
                    VILLAGE_ID, "Bakoko", GenderEnum.MALE
            );
        }

        @Test
        @DisplayName("Doit creer un nouvel utilisateur et publier un UserCreatedEvent")
        void shouldCreateNewUserAndPublishEvent() {
            CreateUserRequest request = buildRequest();

            when(userRepository.findBySupabaseId(SUPABASE_ID)).thenReturn(Optional.empty());
            when(userRepository.findByEmail(EMAIL)).thenReturn(Optional.empty());
            when(userRepository.save(any(User.class))).thenAnswer(invocation -> {
                User saved = invocation.getArgument(0);
                saved.setId(USER_ID);
                return saved;
            });
            when(userMapper.toDto(any(User.class))).thenReturn(defaultUserDto);

            UserDto result = userService.register(request);

            assertThat(result).isNotNull();
            assertThat(result.id()).isEqualTo(USER_ID);

            verify(userRepository).save(userCaptor.capture());
            User capturedUser = userCaptor.getValue();
            assertThat(capturedUser.getSupabaseId()).isEqualTo(SUPABASE_ID);
            assertThat(capturedUser.getEmail()).isEqualTo(EMAIL);
            assertThat(capturedUser.getDisplayName()).isEqualTo(DISPLAY_NAME);
            assertThat(capturedUser.getCountry()).isEqualTo("Cameroun");
            assertThat(capturedUser.getClan()).isEqualTo("Bakoko");

            verify(eventPublisher).publishEvent(eventCaptor.capture());
            UserCreatedEvent event = eventCaptor.getValue();
            assertThat(event.getUserId()).isEqualTo(USER_ID);
            assertThat(event.getEmail()).isEqualTo(EMAIL);
            assertThat(event.getGender()).isEqualTo(GenderEnum.MALE);
        }

        @Test
        @DisplayName("Doit retourner l'utilisateur existant si le supabaseId existe deja")
        void shouldReturnExistingWhenSupabaseIdExists() {
            CreateUserRequest request = buildRequest();

            when(userRepository.findBySupabaseId(SUPABASE_ID)).thenReturn(Optional.of(defaultUser));
            when(userMapper.toDto(defaultUser)).thenReturn(defaultUserDto);

            UserDto result = userService.register(request);

            assertThat(result).isNotNull();
            verify(userRepository, never()).findByEmail(anyString());
            verify(userRepository, never()).save(any(User.class));
            verify(eventPublisher, never()).publishEvent(any(Object.class));
        }

        @Test
        @DisplayName("Doit mettre a jour le supabaseId si l'email existe deja")
        void shouldUpdateSupabaseIdWhenEmailExists() {
            CreateUserRequest request = buildRequest();
            User existingByEmail = User.builder()
                    .supabaseId("old-supabase-id")
                    .email(EMAIL)
                    .displayName("Ancien Nom")
                    .build();
            existingByEmail.setId(USER_ID);

            when(userRepository.findBySupabaseId(SUPABASE_ID)).thenReturn(Optional.empty());
            when(userRepository.findByEmail(EMAIL)).thenReturn(Optional.of(existingByEmail));
            when(userRepository.save(existingByEmail)).thenReturn(existingByEmail);
            when(userMapper.toDto(existingByEmail)).thenReturn(defaultUserDto);

            userService.register(request);

            assertThat(existingByEmail.getSupabaseId()).isEqualTo(SUPABASE_ID);
            verify(userRepository).save(existingByEmail);
            verify(eventPublisher, never()).publishEvent(any(Object.class));
        }

        @Test
        @DisplayName("Doit creer l'utilisateur avec des champs optionnels a null")
        void shouldCreateUserWithOptionalNullFields() {
            CreateUserRequest request = new CreateUserRequest(
                    SUPABASE_ID, EMAIL, DISPLAY_NAME,
                    null, null, null,
                    null, null, GenderEnum.OTHER
            );

            when(userRepository.findBySupabaseId(SUPABASE_ID)).thenReturn(Optional.empty());
            when(userRepository.findByEmail(EMAIL)).thenReturn(Optional.empty());
            when(userRepository.save(any(User.class))).thenAnswer(invocation -> {
                User saved = invocation.getArgument(0);
                saved.setId(USER_ID);
                return saved;
            });
            when(userMapper.toDto(any(User.class))).thenReturn(defaultUserDto);

            userService.register(request);

            verify(userRepository).save(userCaptor.capture());
            User capturedUser = userCaptor.getValue();
            assertThat(capturedUser.getCountry()).isNull();
            assertThat(capturedUser.getNativeLanguage()).isNull();
            assertThat(capturedUser.getBio()).isNull();
            assertThat(capturedUser.getOriginVillageId()).isNull();
            assertThat(capturedUser.getClan()).isNull();
        }
    }

    // ════════════════════════════════════════════════════════
    // updateProfile
    // ════════════════════════════════════════════════════════

    @Nested
    @DisplayName("updateProfile — Mise a jour du profil utilisateur")
    class UpdateProfileTests {

        @Test
        @DisplayName("Doit mettre a jour uniquement les champs non-null de la requete")
        void shouldUpdateOnlyNonNullFields() {
            UpdateUserRequest request = new UpdateUserRequest(
                    "Nouveau Nom", null, null, null, null, null, null,
                    null, null, null, null,
                    null, null, null, null,
                    null, null,
                    null, null, null, null, null,
                    null, null, null, null
            );

            User existingUser = User.builder()
                    .supabaseId(SUPABASE_ID)
                    .email(EMAIL)
                    .displayName(DISPLAY_NAME)
                    .bio("Ancienne bio")
                    .country("Cameroun")
                    .build();
            existingUser.setId(USER_ID);

            when(userRepository.findBySupabaseId(SUPABASE_ID)).thenReturn(Optional.of(existingUser));
            when(userRepository.save(existingUser)).thenReturn(existingUser);
            when(userMapper.toDto(existingUser)).thenReturn(defaultUserDto);

            userService.updateProfile(SUPABASE_ID, request);

            assertThat(existingUser.getDisplayName()).isEqualTo("Nouveau Nom");
            assertThat(existingUser.getBio()).isEqualTo("Ancienne bio");
            assertThat(existingUser.getCountry()).isEqualTo("Cameroun");
            verify(userRepository).save(existingUser);
        }

        @Test
        @DisplayName("Doit mettre a jour tous les champs quand tous sont fournis")
        void shouldUpdateAllFieldsWhenAllProvided() {
            UUID newVillageId = UUID.randomUUID();
            UpdateUserRequest request = new UpdateUserRequest(
                    "Nouveau Nom", "Nouvelle bio",
                    "https://cdn.gwangmeu.com/new-avatar.jpg",
                    "https://cdn.gwangmeu.com/new-cover.jpg",
                    "Gabon", "Fang", newVillageId,
                    "Nouveau Pere", "Libreville",
                    "Nouvelle Mere", "Oyem",
                    "Celibataire", "N/A", 0, "Vegetarien",
                    "Fang", "Essakane",
                    "GA", "Estuaire", "Komo", "Libreville", "Oyem",
                    "Medecin", "Hopital Central", "Libreville", "Gabon"
            );

            User existingUser = User.builder()
                    .supabaseId(SUPABASE_ID).email(EMAIL).displayName(DISPLAY_NAME)
                    .build();
            existingUser.setId(USER_ID);

            when(userRepository.findBySupabaseId(SUPABASE_ID)).thenReturn(Optional.of(existingUser));
            when(userRepository.save(existingUser)).thenReturn(existingUser);
            when(userMapper.toDto(existingUser)).thenReturn(defaultUserDto);

            userService.updateProfile(SUPABASE_ID, request);

            assertThat(existingUser.getDisplayName()).isEqualTo("Nouveau Nom");
            assertThat(existingUser.getBio()).isEqualTo("Nouvelle bio");
            assertThat(existingUser.getCountry()).isEqualTo("Gabon");
            assertThat(existingUser.getOriginVillageId()).isEqualTo(newVillageId);
            assertThat(existingUser.getFatherName()).isEqualTo("Nouveau Pere");
            assertThat(existingUser.getMotherName()).isEqualTo("Nouvelle Mere");
            assertThat(existingUser.getProfession()).isEqualTo("Medecin");
        }

        @Test
        @DisplayName("Doit lancer EntityNotFoundException si le supabaseId n'existe pas")
        void shouldThrowWhenUserNotFound() {
            UpdateUserRequest request = new UpdateUserRequest(
                    "Nom", null, null, null, null, null, null,
                    null, null, null, null,
                    null, null, null, null,
                    null, null,
                    null, null, null, null, null,
                    null, null, null, null
            );
            when(userRepository.findBySupabaseId("unknown")).thenReturn(Optional.empty());

            assertThatThrownBy(() -> userService.updateProfile("unknown", request))
                    .isInstanceOf(EntityNotFoundException.class)
                    .hasMessageContaining("Utilisateur introuvable");

            verify(userRepository, never()).save(any(User.class));
        }
    }

    // ════════════════════════════════════════════════════════
    // deleteAccount
    // ════════════════════════════════════════════════════════

    @Nested
    @DisplayName("deleteAccount — Suppression RGPD du compte (soft delete)")
    class DeleteAccountTests {

        @Test
        @DisplayName("Doit anonymiser completement le compte")
        void shouldAnonymizeAccount() {
            User existingUser = User.builder()
                    .supabaseId(SUPABASE_ID)
                    .email(EMAIL)
                    .displayName(DISPLAY_NAME)
                    .bio("Bio confidentielle")
                    .avatarUrl("https://cdn.gwangmeu.com/avatar.jpg")
                    .build();
            existingUser.setId(USER_ID);

            when(userRepository.findBySupabaseId(SUPABASE_ID)).thenReturn(Optional.of(existingUser));
            when(userRepository.save(existingUser)).thenReturn(existingUser);

            userService.deleteAccount(SUPABASE_ID);

            verify(userRepository).save(userCaptor.capture());
            User capturedUser = userCaptor.getValue();
            assertThat(capturedUser.isActive()).isFalse();
            assertThat(capturedUser.getEmail()).isEqualTo("deleted_" + USER_ID + "@gwangmeu.deleted");
            assertThat(capturedUser.getDisplayName()).isEqualTo("[Compte supprime]");
            assertThat(capturedUser.getBio()).isNull();
            assertThat(capturedUser.getAvatarUrl()).isNull();
        }

        @Test
        @DisplayName("Doit lancer EntityNotFoundException si le supabaseId n'existe pas")
        void shouldThrowWhenUserNotFound() {
            when(userRepository.findBySupabaseId("unknown")).thenReturn(Optional.empty());

            assertThatThrownBy(() -> userService.deleteAccount("unknown"))
                    .isInstanceOf(EntityNotFoundException.class)
                    .hasMessageContaining("Utilisateur introuvable");

            verify(userRepository, never()).save(any(User.class));
        }
    }
}
