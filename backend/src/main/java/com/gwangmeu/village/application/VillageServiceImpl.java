package com.gwangmeu.village.application;

import com.gwangmeu.geo.domain.Chefferie;
import com.gwangmeu.geo.dto.ChefferieDto;
import com.gwangmeu.geo.infrastructure.ChefferieRepository;
import com.gwangmeu.user.User;
import com.gwangmeu.user.UserRepository;
import com.gwangmeu.village.domain.Village;
import com.gwangmeu.village.domain.VillageSubscription;
import com.gwangmeu.village.events.UserJoinedVillageEvent;
import com.gwangmeu.village.events.VillageCreatedEvent;
import com.gwangmeu.village.infrastructure.VillageRepository;
import com.gwangmeu.village.infrastructure.VillageSubscriptionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
class VillageServiceImpl implements VillageService {

    private final VillageRepository villageRepository;
    private final VillageSubscriptionRepository subscriptionRepository;
    private final ChefferieRepository chefferieRepository;
    private final UserRepository userRepository;
    private final ApplicationEventPublisher eventPublisher;

    @Override
    public Village create(CreateVillageCommand command) {
        Village village = Village.builder()
                .name(command.name())
                .description(command.description())
                .country(command.country())
                .region(command.region())
                .continentCode(command.continentCode())
                .latitude(command.latitude())
                .longitude(command.longitude())
                .primaryDialect(command.primaryDialect())
                .creatorId(command.creatorId())
                .build();

        Village saved = villageRepository.save(village);
        eventPublisher.publishEvent(new VillageCreatedEvent(saved.getId(), saved.getName(), saved.getCountry()));
        log.info("Village created: {} ({})", saved.getName(), saved.getId());
        return saved;
    }

    @Override
    public Village update(UUID villageId, UpdateVillageCommand command) {
        Village village = villageRepository.findById(villageId)
                .orElseThrow(() -> new IllegalArgumentException("Village not found: " + villageId));

        if (command.description() != null) village.setDescription(command.description());
        if (command.coverImageUrl() != null) village.setCoverImageUrl(command.coverImageUrl());
        if (command.foundedYear() != null) village.setFoundedYear(command.foundedYear());
        if (command.populationEstimate() != null) village.setPopulationEstimate(command.populationEstimate());
        if (command.historicalSummary() != null) village.setHistoricalSummary(command.historicalSummary());

        return villageRepository.save(village);
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<Village> findById(UUID villageId) {
        return villageRepository.findById(villageId);
    }

    @Override
    @Transactional(readOnly = true)
    public List<Village> findAllById(java.util.Collection<UUID> villageIds) {
        return villageRepository.findAllById(villageIds);
    }

    @Override
    @Transactional(readOnly = true)
    public List<Village> findByCountry(String country) {
        return villageRepository.findByCountryIgnoreCase(country);
    }

    @Override
    @Transactional(readOnly = true)
    public List<Village> findByContinent(String continentCode) {
        return villageRepository.findByContinentCode(continentCode);
    }

    @Override
    @Transactional(readOnly = true)
    public List<Village> search(String query) {
        return villageRepository.findByNameContainingIgnoreCase(query);
    }

    @Override
    public Village foundFromChefferie(UUID chefferieId, UUID userId) {
        Chefferie chefferie = chefferieRepository.findById(chefferieId)
                .orElseThrow(() -> new IllegalArgumentException("Chefferie introuvable: " + chefferieId));

        // find-or-create : une chefferie ne se matérialise qu'une fois.
        Village village = villageRepository.findByChefferieId(chefferieId).orElseGet(() -> {
            Village v = Village.builder()
                    .name(ChefferieDto.cleanLabel(chefferie.getDenomination()))
                    .country(chefferie.getCountryIso2())
                    .region(chefferie.getRegionName())
                    .chefferieId(chefferieId)
                    .creatorId(userId)
                    .verified(true) // adossé au référentiel MINAT
                    .build();
            Village saved = villageRepository.save(v);
            eventPublisher.publishEvent(
                    new VillageCreatedEvent(saved.getId(), saved.getName(), saved.getCountry()));
            log.info("Village materialise depuis chefferie {}: {} ({})",
                    chefferieId, saved.getName(), saved.getId());
            return saved;
        });

        // Auto-adhésion comme membre si pas déjà inscrit.
        if (!subscriptionRepository.existsByUserIdAndVillageId(userId, village.getId())) {
            join(userId, village.getId(), VillageSubscription.SubscriptionType.MEMBER);
        }
        return village;
    }

    @Override
    public Optional<Village> foundFromOrigin(UUID userId) {
        User user = userRepository.findById(userId).orElse(null);
        if (user == null) {
            return Optional.empty();
        }
        String name = user.getOriginVillage();
        String country = user.getOriginCountry();
        if (name == null || name.isBlank() || country == null || country.isBlank()) {
            return Optional.empty();
        }
        // Résolution floue de la chefferie d'origine (accent/faute-tolérante),
        // filtrée sur la région d'origine quand disponible.
        List<Chefferie> matches = chefferieRepository.searchGlobalFuzzy(country, name.trim(), 5);
        if (matches.isEmpty()) {
            return Optional.empty();
        }
        String region = user.getOriginRegion();
        Chefferie chosen = matches.stream()
                .filter(c -> region == null || region.isBlank()
                        || region.equalsIgnoreCase(c.getRegionName()))
                .findFirst()
                .orElse(matches.get(0));
        return Optional.of(foundFromChefferie(chosen.getId(), userId));
    }

    @Override
    public VillageSubscription join(UUID userId, UUID villageId, VillageSubscription.SubscriptionType type) {
        Village village = villageRepository.findById(villageId)
                .orElseThrow(() -> new IllegalArgumentException("Village not found: " + villageId));

        if (subscriptionRepository.existsByUserIdAndVillageId(userId, villageId)) {
            throw new IllegalStateException("User already subscribed to this village");
        }

        VillageSubscription subscription = VillageSubscription.builder()
                .userId(userId)
                .villageId(villageId)
                .type(type)
                .build();

        VillageSubscription saved = subscriptionRepository.save(subscription);
        village.setMemberCount(village.getMemberCount() + 1);
        villageRepository.save(village);

        eventPublisher.publishEvent(new UserJoinedVillageEvent(userId, villageId, type.name()));
        return saved;
    }

    @Override
    public void leave(UUID userId, UUID villageId) {
        subscriptionRepository.deleteByUserIdAndVillageId(userId, villageId);
        villageRepository.findById(villageId).ifPresent(v -> {
            v.setMemberCount(Math.max(0, v.getMemberCount() - 1));
            villageRepository.save(v);
        });
    }

    @Override
    @Transactional(readOnly = true)
    public List<VillageSubscription> getMemberships(UUID userId) {
        return subscriptionRepository.findByUserId(userId);
    }

    @Override
    @Transactional(readOnly = true)
    public List<VillageSubscription> getVillageMembers(UUID villageId) {
        return subscriptionRepository.findByVillageId(villageId);
    }

    @Override
    @Transactional(readOnly = true)
    public List<Village> getVillagesForUser(UUID userId) {
        List<UUID> villageIds = subscriptionRepository.findByUserId(userId)
                .stream().map(VillageSubscription::getVillageId).toList();
        return villageRepository.findAllById(villageIds);
    }
}
