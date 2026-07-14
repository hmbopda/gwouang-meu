package com.gwangmeu.language.ai;

import com.gwangmeu.language.ai.dto.TranslateRequest;
import com.gwangmeu.language.ai.dto.TranslateResponse;

/**
 * Moteur de traduction francais <-> langue native (Bandenkop et suivantes).
 * S'appuie sur le client Claude existant + un dictionnaire injecte en contexte.
 */
public interface TranslationService {

    /**
     * Traduit un texte selon le sens demande.
     *
     * @throws TranslationUnavailableException si la couche IA est indisponible (cle absente,
     *                                         appel en echec, reponse illisible)
     * @throws IllegalArgumentException        si la langue demandee n'est pas supportee
     */
    TranslateResponse translate(TranslateRequest request);
}
