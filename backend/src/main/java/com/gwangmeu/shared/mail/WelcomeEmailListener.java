package com.gwangmeu.shared.mail;

import com.gwangmeu.user.events.UserCreatedEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

/**
 * Envoie l'email de bienvenue a la creation d'un compte ({@link UserCreatedEvent}).
 * Asynchrone et best-effort : n'impacte jamais le flux d'inscription.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class WelcomeEmailListener {

    private final EmailService emailService;

    @Async
    @EventListener
    public void onUserCreated(UserCreatedEvent event) {
        String email = event.getEmail();
        if (email == null || email.isBlank()) {
            return;
        }
        try {
            emailService.sendWelcomeEmail(email, event.getUsername());
        } catch (RuntimeException e) {
            log.warn("Email de bienvenue non envoye a {} : {}", email, e.getMessage());
        }
    }
}
