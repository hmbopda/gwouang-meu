package com.gwangmeu.shared.ai;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.util.List;
import java.util.Map;

/**
 * Client HTTP vers l'API Anthropic Claude.
 * Utilise RestClient (Spring 6, synchrone) — aucune dependance webflux.
 *
 * Modeles disponibles :
 *   SONNET = "claude-sonnet-4-6" (guide, quiz, moderation, resume)
 *   OPUS   = "claude-opus-4-6"   (enrichissement culturel profond)
 *
 * Prompt Caching active sur tous les system prompts (cache_control ephemeral).
 * Gain : -80% a -90% du cout sur les appels repetitifs.
 *
 * Ref : ARCHITECTURE.md — Pipeline RAG 5 etapes + 8 cas d'usage Claude.
 */
@Slf4j
@Component
public class ClaudeAiClient {

    public static final String SONNET = "claude-sonnet-4-6";
    public static final String OPUS   = "claude-opus-4-6";

    private final RestClient restClient;
    private final String apiKey;

    public ClaudeAiClient(@Value("${application.anthropic-api-key}") String apiKey) {
        this.apiKey = apiKey;
        this.restClient = RestClient.builder()
                .baseUrl("https://api.anthropic.com")
                .defaultHeader("anthropic-version", "2023-06-01")
                .build();
    }

    /**
     * Appel synchrone vers Claude.
     *
     * @param model        ClaudeAiClient.SONNET ou OPUS
     * @param systemPrompt Contexte culturel + role de Claude (mis en cache)
     * @param userMessage  Message de l'utilisateur
     * @param maxTokens    Max tokens de la reponse
     * @return Texte genere par Claude
     */
    public String complete(String model, String systemPrompt, String userMessage, int maxTokens) {
        Map<String, Object> body = Map.of(
                "model", model,
                "max_tokens", maxTokens,
                "system", List.of(Map.of(
                        "type", "text",
                        "text", systemPrompt,
                        "cache_control", Map.of("type", "ephemeral")
                )),
                "messages", List.of(Map.of("role", "user", "content", userMessage))
        );

        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> response = restClient.post()
                    .uri("/v1/messages")
                    .header("x-api-key", apiKey)
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(body)
                    .retrieve()
                    .body(Map.class);

            return extractText(response);
        } catch (Exception e) {
            log.error("Claude API error [model={}]: {}", model, e.getMessage());
            throw new RuntimeException("Erreur Claude API : " + e.getMessage(), e);
        }
    }

    @SuppressWarnings("unchecked")
    private String extractText(Map<String, Object> response) {
        if (response == null) return "";
        List<Map<String, Object>> content = (List<Map<String, Object>>) response.get("content");
        if (content == null || content.isEmpty()) return "";
        Object text = content.get(0).get("text");
        return text != null ? text.toString() : "";
    }
}
