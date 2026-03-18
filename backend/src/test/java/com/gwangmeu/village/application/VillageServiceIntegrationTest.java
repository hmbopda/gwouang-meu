package com.gwangmeu.village.application;

import com.gwangmeu.shared.BaseIntegrationTest;
import com.gwangmeu.village.domain.Village;
import com.gwangmeu.village.domain.VillageSubscription;
import com.gwangmeu.village.infrastructure.VillageRepository;
import com.gwangmeu.village.infrastructure.VillageSubscriptionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@Transactional
@DisplayName("VillageService - Tests d'integration")
class VillageServiceIntegrationTest extends BaseIntegrationTest {

    @Autowired
    private VillageService villageService;

    @Autowired
    private VillageRepository villageRepository;

    @Autowired
    private VillageSubscriptionRepository subscriptionRepository;

    @BeforeEach
    void setUp() {
        subscriptionRepository.deleteAllInBatch();
        villageRepository.deleteAllInBatch();
    }

    private Village insertVillage(String name, String country) {
        Village village = Village.builder()
                .name(name)
                .country(country)
                .continentCode("AF")
                .build();
        return villageRepository.saveAndFlush(village);
    }

    // ── create ───────────────────────────────────────────────────────────────

    @Nested
    @DisplayName("create()")
    class Create {

        @Test
        @DisplayName("doit creer un village avec tous les champs")
        void shouldCreateVillage() {
            CreateVillageCommand command = new CreateVillageCommand(
                    "Bafia", "Capitale du Mbam", "Cameroun", "Centre",
                    "AF", 4.75, 11.23, "Rikpa", UUID.randomUUID()
            );

            Village result = villageService.create(command);

            assertThat(result.getId()).isNotNull();
            assertThat(result.getName()).isEqualTo("Bafia");
            assertThat(result.getCountry()).isEqualTo("Cameroun");
            assertThat(result.getRegion()).isEqualTo("Centre");
            assertThat(result.getLatitude()).isEqualTo(4.75);
            assertThat(result.getLongitude()).isEqualTo(11.23);
            assertThat(result.getPrimaryDialect()).isEqualTo("Rikpa");
            assertThat(result.getMemberCount()).isZero();

            assertThat(villageRepository.findById(result.getId())).isPresent();
        }
    }

    // ── update ───────────────────────────────────────────────────────────────

    @Nested
    @DisplayName("update()")
    class Update {

        @Test
        @DisplayName("doit mettre a jour partiellement le village")
        void shouldPartiallyUpdate() {
            Village village = insertVillage("Edea", "Cameroun");

            UpdateVillageCommand command = new UpdateVillageCommand(
                    "Nouvelle description", null, 1850, null, null
            );

            Village result = villageService.update(village.getId(), command);

            assertThat(result.getDescription()).isEqualTo("Nouvelle description");
            assertThat(result.getFoundedYear()).isEqualTo(1850);
            assertThat(result.getName()).isEqualTo("Edea");
        }

        @Test
        @DisplayName("doit lancer IllegalArgumentException si le village n'existe pas")
        void shouldThrowWhenVillageNotFound() {
            UpdateVillageCommand command = new UpdateVillageCommand("desc", null, null, null, null);

            assertThatThrownBy(() -> villageService.update(UUID.randomUUID(), command))
                    .isInstanceOf(IllegalArgumentException.class);
        }
    }

    // ── findById / findByCountry / search ────────────────────────────────────

    @Nested
    @DisplayName("Recherche de villages")
    class Search {

        @Test
        @DisplayName("doit trouver un village par son ID")
        void shouldFindById() {
            Village village = insertVillage("Kribi", "Cameroun");

            Optional<Village> result = villageService.findById(village.getId());

            assertThat(result).isPresent();
            assertThat(result.get().getName()).isEqualTo("Kribi");
        }

        @Test
        @DisplayName("doit retourner les villages par pays (case insensitive)")
        void shouldFindByCountry() {
            insertVillage("Bafia", "Cameroun");
            insertVillage("Edea", "Cameroun");
            insertVillage("Dakar", "Senegal");

            List<Village> result = villageService.findByCountry("cameroun");

            assertThat(result).hasSize(2);
        }

        @Test
        @DisplayName("doit rechercher les villages par nom")
        void shouldSearchByName() {
            insertVillage("Bafia", "Cameroun");
            insertVillage("Bafang", "Cameroun");
            insertVillage("Douala", "Cameroun");

            List<Village> result = villageService.search("Baf");

            assertThat(result).hasSize(2);
        }
    }

    // ── join / leave ─────────────────────────────────────────────────────────

    @Nested
    @DisplayName("join() / leave()")
    class JoinLeave {

        @Test
        @DisplayName("doit creer une souscription et incrementer le memberCount")
        void shouldJoinAndIncrementCount() {
            Village village = insertVillage("Bafia", "Cameroun");
            UUID userId = UUID.randomUUID();

            VillageSubscription sub = villageService.join(userId, village.getId(),
                    VillageSubscription.SubscriptionType.MEMBER);

            assertThat(sub.getUserId()).isEqualTo(userId);
            assertThat(sub.getVillageId()).isEqualTo(village.getId());
            assertThat(sub.getType()).isEqualTo(VillageSubscription.SubscriptionType.MEMBER);

            Village updated = villageRepository.findById(village.getId()).orElseThrow();
            assertThat(updated.getMemberCount()).isEqualTo(1);
        }

        @Test
        @DisplayName("doit lancer IllegalStateException si l'utilisateur est deja membre")
        void shouldThrowWhenAlreadySubscribed() {
            Village village = insertVillage("Edea", "Cameroun");
            UUID userId = UUID.randomUUID();
            villageService.join(userId, village.getId(), VillageSubscription.SubscriptionType.MEMBER);

            assertThatThrownBy(() -> villageService.join(userId, village.getId(),
                    VillageSubscription.SubscriptionType.MEMBER))
                    .isInstanceOf(IllegalStateException.class);
        }

        @Test
        @DisplayName("doit decrementer le memberCount en quittant sans descendre sous zero")
        void shouldLeaveAndDecrementCount() {
            Village village = insertVillage("Kribi", "Cameroun");
            UUID userId = UUID.randomUUID();
            villageService.join(userId, village.getId(), VillageSubscription.SubscriptionType.MEMBER);

            villageService.leave(userId, village.getId());

            Village updated = villageRepository.findById(village.getId()).orElseThrow();
            assertThat(updated.getMemberCount()).isZero();
        }
    }

    // ── getVillagesForUser / getVillageMembers ───────────────────────────────

    @Nested
    @DisplayName("getVillagesForUser() / getVillageMembers()")
    class Memberships {

        @Test
        @DisplayName("doit retourner tous les villages d'un utilisateur")
        void shouldReturnVillagesForUser() {
            Village v1 = insertVillage("Bafia", "Cameroun");
            Village v2 = insertVillage("Edea", "Cameroun");
            UUID userId = UUID.randomUUID();
            villageService.join(userId, v1.getId(), VillageSubscription.SubscriptionType.MEMBER);
            villageService.join(userId, v2.getId(), VillageSubscription.SubscriptionType.FOLLOW);

            List<Village> villages = villageService.getVillagesForUser(userId);

            assertThat(villages).hasSize(2);
        }

        @Test
        @DisplayName("doit retourner tous les membres d'un village")
        void shouldReturnVillageMembers() {
            Village village = insertVillage("Bafia", "Cameroun");
            UUID user1 = UUID.randomUUID();
            UUID user2 = UUID.randomUUID();
            villageService.join(user1, village.getId(), VillageSubscription.SubscriptionType.MEMBER);
            villageService.join(user2, village.getId(), VillageSubscription.SubscriptionType.AMBASSADOR);

            List<VillageSubscription> members = villageService.getVillageMembers(village.getId());

            assertThat(members).hasSize(2);
        }
    }
}
