package com.gwangmeu.shared.mail;

/**
 * Transport d'email transactionnel. Abstraction permettant de basculer entre
 * SMTP ({@link SmtpEmailSender}) et l'API HTTP Resend ({@link ResendApiEmailSender})
 * via la propriete {@code application.mail.provider} (smtp | resend-api), sans
 * toucher aux templates ni aux appelants ({@link EmailService}).
 */
public interface EmailSender {

    /**
     * Envoie un email HTML. Ne leve pas d'exception : retourne {@code false} en cas
     * d'echec (permet un fallback ou un simple log sans casser le flux metier).
     *
     * @return {@code true} si l'envoi a reussi
     */
    boolean send(String from, String to, String subject, String html);

    /** Nom court du provider actif (pour le journal des emails). */
    String providerName();
}
