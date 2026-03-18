package com.gwangmeu.village.application;

import com.gwangmeu.village.domain.Village;
import com.gwangmeu.village.domain.VillageSubscription;
import com.gwangmeu.village.domain.VillageSubscription.SubscriptionType;
import com.gwangmeu.village.events.UserJoinedVillageEvent;
import com.gwangmeu.village.events.VillageCreatedEvent;
import com.gwangmeu.village.infrastructure.VillageRepository;
import com.gwangmeu.village.infrastructure.VillageSubscriptionRepository;
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

import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("VillageServiceImpl — Tests unitaires")
class VillageServiceImplTest {

    @Mock private VillageRepository villageRepository;
    @Mock private VillageSubscriptionRepository subscriptionRepository;
    @Mock private ApplicationEventPublisher eventPublisher;

    @InjectMocks private VillageServiceImpl villageService;

    @Captor private ArgumentCaptor<Village> villageCaptor;
    @Captor private ArgumentCaptor<VillageSubscription> subscriptionCaptor;
    @Captor private ArgumentCaptor<Object> eventCaptor;

    private final UUID villageId = UUID.randomUUID();
    private final UUID userId = UUID.randomUUID();

    // ========================================================================
    // create
    // ========================================================================

    @Nested
    @DisplayName("create — Creation d'un village")
    class CreateTests {

        @Test
        @DisplayName("Doit creer un village et publier VillageCreatedEvent")
        void shouldCreateVillageAndPublishEvent() {
            CreateVillageCommand command = new CreateVillageCommand(
                    "Bafia", "Village historique", "Cameroun", "Centre",
                    "AF", 4.75, 11.23, "Rikpa", userId
            );

            Village savedVillage = Village.builder()
                    .name("Bafia").country("Cameroun").description("Village historique")
                    .region("Centre").continentCode("AF").latitude(4.75).longitude(11.23)
                    .primaryDialect("Rikpa").creatorId(userId).build();
            savedVillage.setId(villageId);

            when(villageRepository.save(any(Village.class))).thenReturn(savedVillage);

            Village result = villageService.create(command);

            assertThat(result.getId()).isEqualTo(villageId);
            assertThat(result.getName()).isEqualTo("Bafia");

            verify(villageRepository).save(villageCaptor.capture());
            Village captured = villageCaptor.getValue();
            assertThat(captured.getName()).isEqualTo("Bafia");
            assertThat(captured.getCountry()).isEqualTo("Cameroun");
            assertThat(captured.getCreatorId()).isEqualTo(userId);

            verify(eventPublisher).publishEvent(any(VillageCreatedEvent.class));
        }
    }

    // ========================================================================
    // update
    // ========================================================================

    @Nested
    @DisplayName("update — Mise a jour d'un village")
    class UpdateTests {

        @Test
        @DisplayName("Doit mettre a jour uniquement les champs non-null")
        void shouldUpdateNonNullFields() {
            Village village = Village.builder().name("Bafia").country("Cameroun")
                    .description("Ancienne description").build();
            village.setId(villageId);

            UpdateVillageCommand command = new UpdateVillageCommand(
                    "Nouvelle description", null, null, null, null
            );

            when(villageRepository.findById(villageId)).thenReturn(Optional.of(village));
            when(villageRepository.save(any(Village.class))).thenAnswer(inv -> inv.getArgument(0));

            Village result = villageService.update(villageId, command);

            assertThat(result.getDescription()).isEqualTo("Nouvelle description");
            assertThat(result.getCoverImageUrl()).isNull();
        }

        @Test
        @DisplayName("Doit lever IllegalArgumentException quand le village n'existe pas")
        void shouldThrowWhenNotFound() {
            when(villageRepository.findById(villageId)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> villageService.update(villageId,
                    new UpdateVillageCommand("desc", null, null, null, null)))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("Village not found");
        }
    }

    // ========================================================================
    // findById
    // ========================================================================

    @Nested
    @DisplayName("findById — Recherche par ID")
    class FindByIdTests {

        @Test
        @DisplayName("Doit retourner le village quand il existe")
        void shouldReturnWhenExists() {
            Village village = Village.builder().name("Bafia").country("Cameroun").build();
            village.setId(villageId);
            when(villageRepository.findById(villageId)).thenReturn(Optional.of(village));

            Optional<Village> result = villageService.findById(villageId);

            assertThat(result).isPresent();
            assertThat(result.get().getName()).isEqualTo("Bafia");
        }

        @Test
        @DisplayName("Doit retourner empty quand le village n'existe pas")
        void shouldReturnEmptyWhenNotExists() {
            when(villageRepository.findById(villageId)).thenReturn(Optional.empty());

            assertThat(villageService.findById(villageId)).isEmpty();
        }
    }

    // ========================================================================
    // join
    // ========================================================================

    @Nested
    @DisplayName("join — Adhesion a un village")
    class JoinTests {

        @Test
        @DisplayName("Doit creer un abonnement, incrementer le compteur et publier un evenement")
        void shouldCreateSubscriptionAndPublishEvent() {
            Village village = Village.builder().name("Bafia").country("Cameroun").build();
            village.setId(villageId);
            village.setMemberCount(5);

            VillageSubscription savedSub = VillageSubscription.builder()
                    .userId(userId).villageId(villageId).type(SubscriptionType.MEMBER).build();
            savedSub.setId(UUID.randomUUID());

            when(villageRepository.findById(villageId)).thenReturn(Optional.of(village));
            when(subscriptionRepository.existsByUserIdAndVillageId(userId, villageId)).thenReturn(false);
            when(subscriptionRepository.save(any(VillageSubscription.class))).thenReturn(savedSub);
            when(villageRepository.save(any(Village.class))).thenAnswer(inv -> inv.getArgument(0));

            VillageSubscription result = villageService.join(userId, villageId, SubscriptionType.MEMBER);

            assertThat(result.getUserId()).isEqualTo(userId);
            assertThat(village.getMemberCount()).isEqualTo(6);

            verify(eventPublisher).publishEvent(eventCaptor.capture());
            assertThat(eventCaptor.getValue()).isInstanceOf(UserJoinedVillageEvent.class);
        }

        @Test
        @DisplayName("Doit lever IllegalArgumentException quand le village n'existe pas")
        void shouldThrowWhenVillageNotFound() {
            when(villageRepository.findById(villageId)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> villageService.join(userId, villageId, SubscriptionType.MEMBER))
                    .isInstanceOf(IllegalArgumentException.class);

            verify(subscriptionRepository, never()).save(any());
        }

        @Test
        @DisplayName("Doit lever IllegalStateException quand l'utilisateur est deja abonne")
        void shouldThrowWhenAlreadySubscribed() {
            Village village = Village.builder().name("Bafia").country("Cameroun").build();
            village.setId(villageId);

            when(villageRepository.findById(villageId)).thenReturn(Optional.of(village));
            when(subscriptionRepository.existsByUserIdAndVillageId(userId, villageId)).thenReturn(true);

            assertThatThrownBy(() -> villageService.join(userId, villageId, SubscriptionType.MEMBER))
                    .isInstanceOf(IllegalStateException.class)
                    .hasMessageContaining("already subscribed");
        }
    }

    // ========================================================================
    // leave
    // ========================================================================

    @Nested
    @DisplayName("leave — Depart d'un village")
    class LeaveTests {

        @Test
        @DisplayName("Doit supprimer l'abonnement et decrementer le compteur")
        void shouldDeleteAndDecrement() {
            Village village = Village.builder().name("Bafia").country("Cameroun").build();
            village.setId(villageId);
            village.setMemberCount(10);

            when(villageRepository.findById(villageId)).thenReturn(Optional.of(village));
            when(villageRepository.save(any(Village.class))).thenAnswer(inv -> inv.getArgument(0));

            villageService.leave(userId, villageId);

            verify(subscriptionRepository).deleteByUserIdAndVillageId(userId, villageId);
            assertThat(village.getMemberCount()).isEqualTo(9);
        }

        @Test
        @DisplayName("Ne doit pas decrementer en dessous de zero")
        void shouldNotDecrementBelowZero() {
            Village village = Village.builder().name("Bafia").country("Cameroun").build();
            village.setId(villageId);
            village.setMemberCount(0);

            when(villageRepository.findById(villageId)).thenReturn(Optional.of(village));
            when(villageRepository.save(any(Village.class))).thenAnswer(inv -> inv.getArgument(0));

            villageService.leave(userId, villageId);

            assertThat(village.getMemberCount()).isEqualTo(0);
        }
    }

    // ========================================================================
    // getMemberships & getVillageMembers & getVillagesForUser
    // ========================================================================

    @Nested
    @DisplayName("Requetes de lecture")
    class ReadTests {

        @Test
        @DisplayName("getMemberships doit deleguer au subscriptionRepository")
        void shouldReturnMemberships() {
            when(subscriptionRepository.findByUserId(userId)).thenReturn(Collections.emptyList());

            List<VillageSubscription> result = villageService.getMemberships(userId);

            assertThat(result).isEmpty();
            verify(subscriptionRepository).findByUserId(userId);
        }

        @Test
        @DisplayName("getVillageMembers doit deleguer au subscriptionRepository")
        void shouldReturnMembers() {
            when(subscriptionRepository.findByVillageId(villageId)).thenReturn(Collections.emptyList());

            List<VillageSubscription> result = villageService.getVillageMembers(villageId);

            assertThat(result).isEmpty();
            verify(subscriptionRepository).findByVillageId(villageId);
        }

        @Test
        @DisplayName("getVillagesForUser doit retourner les villages de l'utilisateur")
        void shouldReturnVillagesForUser() {
            VillageSubscription sub = VillageSubscription.builder()
                    .userId(userId).villageId(villageId).type(SubscriptionType.MEMBER).build();

            when(subscriptionRepository.findByUserId(userId)).thenReturn(List.of(sub));
            when(villageRepository.findAllById(List.of(villageId))).thenReturn(
                    List.of(Village.builder().name("Bafia").country("Cameroun").build()));

            List<Village> result = villageService.getVillagesForUser(userId);

            assertThat(result).hasSize(1);
        }
    }
}
