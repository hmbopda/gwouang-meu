package com.gwangmeu.language.ai;

/**
 * Levee quand le moteur de traduction ne peut pas produire de resultat pour une
 * raison d'infrastructure IA : cle API absente au runtime, appel Claude en echec,
 * ou reponse illisible.
 *
 * Mappee en HTTP 503 par le controller. N'impacte JAMAIS le demarrage :
 * aucun bean n'echoue a la construction a cause d'une cle manquante.
 */
public class TranslationUnavailableException extends RuntimeException {

    public TranslationUnavailableException(String message) {
        super(message);
    }

    public TranslationUnavailableException(String message, Throwable cause) {
        super(message, cause);
    }
}
