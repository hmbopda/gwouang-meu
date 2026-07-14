package com.gwangmeu.language.ai;

/**
 * Quota quotidien de traductions atteint pour un utilisateur non privilégié.
 * Mappé en HTTP 429 (Too Many Requests) par le controller.
 */
public class TranslationLimitException extends RuntimeException {
    public TranslationLimitException(String message) {
        super(message);
    }
}
