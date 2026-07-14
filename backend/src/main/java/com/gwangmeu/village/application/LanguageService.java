package com.gwangmeu.village.application;

import com.gwangmeu.geo.domain.Language;
import com.gwangmeu.village.domain.VillageLanguage;
import com.gwangmeu.village.dto.VillageLanguagesRequest;

import java.util.List;
import java.util.UUID;

/**
 * Referentiel des langues et association N:N avec les villages.
 *
 * <p>Le referentiel {@link Language} est partage (module geo). Les lectures sont
 * publiques ; l'ecriture des langues d'un village exige EDIT_VILLAGE (verifie dans
 * {@link #setVillageLanguages}).</p>
 */
public interface LanguageService {

    /** Langues actives du referentiel, triees par nom francais. */
    List<Language> listActive();

    /** Langues d'un village (lien N:N). */
    List<VillageLanguage> villageLanguages(UUID villageId);

    /**
     * Remplace l'ensemble des langues d'un village. Exige EDIT_VILLAGE.
     * Au plus une langue principale est conservee (la premiere marquee si plusieurs).
     */
    List<VillageLanguage> setVillageLanguages(UUID userId, UUID villageId, VillageLanguagesRequest req);
}
