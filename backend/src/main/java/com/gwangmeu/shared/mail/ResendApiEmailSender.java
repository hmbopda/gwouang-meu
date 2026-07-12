package com.gwangmeu.shared.mail;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.Map;

/**
 * Transport via l'API HTTP Resend (https://api.resend.com/emails).
 *
 * <p>Plus robuste que le SMTP sur Cloud Run (pas de dependance aux ports SMTP sortants).
 * Actif quand {@code application.mail.provider=resend-api}. La cle est lue dans
 * {@code application.mail.resend-api-key} (= RESEND_API_KEY). Utilise le client HTTP
 * du JDK : aucune dependance supplementaire.</p>
 */
@Slf4j
@Component
@ConditionalOnProperty(name = "application.mail.provider", havingValue = "resend-api")
class ResendApiEmailSender implements EmailSender {

    private static final URI ENDPOINT = URI.create("https://api.resend.com/emails");

    private final HttpClient http = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();
    private final ObjectMapper mapper = new ObjectMapper();

    @Value("${application.mail.resend-api-key:}")
    private String apiKey;

    @Override
    public boolean send(String from, String to, String subject, String html) {
        if (apiKey == null || apiKey.isBlank()) {
            log.error("Resend API: cle manquante (application.mail.resend-api-key) — envoi a {} ignore", to);
            return false;
        }
        try {
            String payload = mapper.writeValueAsString(Map.of(
                    "from", from,
                    "to", to,
                    "subject", subject,
                    "html", html));
            HttpRequest request = HttpRequest.newBuilder(ENDPOINT)
                    .timeout(Duration.ofSeconds(20))
                    .header("Authorization", "Bearer " + apiKey)
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(payload))
                    .build();
            HttpResponse<String> response = http.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() >= 200 && response.statusCode() < 300) {
                return true;
            }
            log.error("Resend API: echec ({}) a {} : {}", response.statusCode(), to, response.body());
            return false;
        } catch (Exception e) {
            log.error("Resend API: exception a {} : {}", to, e.getMessage());
            return false;
        }
    }

    @Override
    public String providerName() {
        return "resend-api";
    }
}
