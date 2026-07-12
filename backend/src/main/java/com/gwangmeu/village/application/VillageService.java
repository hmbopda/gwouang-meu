package com.gwangmeu.village.application;

import com.gwangmeu.village.domain.Village;
import com.gwangmeu.village.domain.VillageSubscription;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface VillageService {

    Village create(CreateVillageCommand command);

    Village update(UUID villageId, UpdateVillageCommand command);

    Optional<Village> findById(UUID villageId);

    List<Village> findAllById(Collection<UUID> villageIds);

    List<Village> findByCountry(String country);

    List<Village> findByContinent(String continentCode);

    List<Village> search(String query);

    VillageSubscription join(UUID userId, UUID villageId, VillageSubscription.SubscriptionType type);

    /**
     * Matérialise une chefferie du référentiel en communauté (find-or-create par
     * chefferie_id) puis inscrit l'utilisateur comme membre. Idempotent.
     */
    Village foundFromChefferie(UUID chefferieId, UUID userId);

    /**
     * Matérialise et rejoint le village d'origine de l'utilisateur, résolu depuis
     * son origine référentielle (nom + région + pays). {@code Optional.empty()} si
     * l'origine n'est pas renseignée ou qu'aucune chefferie ne correspond. Idempotent.
     */
    Optional<Village> foundFromOrigin(UUID userId);

    void leave(UUID userId, UUID villageId);

    List<VillageSubscription> getMemberships(UUID userId);

    List<Village> getVillagesForUser(UUID userId);

    List<VillageSubscription> getVillageMembers(UUID villageId);
}
