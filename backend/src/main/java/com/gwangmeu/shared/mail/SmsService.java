package com.gwangmeu.shared.mail;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

@Slf4j
@Service
public class SmsService {

    @Value("${application.base-url}")
    private String baseUrl;

    /**
     * Envoie un SMS d'invitation avec le lien de validation.
     * TODO: Brancher un provider SMS (Twilio, Vonage, etc.)
     * Pour l'instant, log le message qui serait envoye.
     */
    @Async
    public void sendInvitationSms(String phoneNumber, String inviterName, String personFirstName, String token) {
        String inviteLink = baseUrl + "/invite?token=" + token;

        String message = String.format(
            "Bonjour %s, %s vous a ajoute a son arbre genealogique sur Gwang Meu. " +
            "Confirmez votre identite ici : %s",
            personFirstName, inviterName, inviteLink
        );

        // TODO: Remplacer par l'appel reel au provider SMS
        // Exemple Twilio :
        // Message.creator(new PhoneNumber(phoneNumber), new PhoneNumber(twilioFromNumber), message).create();

        log.info("SMS d'invitation envoye a {} : {}", phoneNumber, message);
    }

    /**
     * Envoie un SMS de rappel pour dissolution (divorce ou deces).
     */
    @Async
    public void sendDissolutionSms(String phoneNumber, String requesterName,
                                   String recipientFirstName, String type, String unionId) {
        String action = "DIVORCE".equals(type)
                ? "a demande le divorce"
                : "a declare votre deces";

        String message = String.format(
                "Bonjour %s, %s %s sur Gwang Meu. " +
                "Connectez-vous pour confirmer ou contester cette demande.",
                recipientFirstName, requesterName, action
        );

        // TODO: Remplacer par l'appel reel au provider SMS
        log.info("SMS dissolution envoye a {} : {}", phoneNumber, message);
    }
}
