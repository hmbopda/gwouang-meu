package com.gwangmeu.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

import java.util.List;

/**
 * Configuration WebSocket STOMP.
 * Utilise par : messaging-module (Phase 3).
 * Prepare des Phase 1 pour ne pas avoir a reconfigurer la securite plus tard.
 *
 * Connexion client Flutter : StompClient sur ws://host/ws
 * Topics : /topic/village/{id}, /user/{id}/queue/messages
 */
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Value("${application.cors.allowed-origins}")
    private List<String> allowedOrigins;

    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        // Prefixe pour les messages envoyes vers le broker
        registry.enableSimpleBroker("/topic", "/queue");
        // Prefixe pour les messages envoyes vers les controllers @MessageMapping
        registry.setApplicationDestinationPrefixes("/app");
        // Prefixe pour les messages utilisateur
        registry.setUserDestinationPrefix("/user");
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws")
                // Memes origines que le CORS HTTP — jamais "*"
                .setAllowedOriginPatterns(allowedOrigins.toArray(String[]::new))
                .withSockJS(); // Fallback SockJS pour les navigateurs sans WebSocket natif
    }
}
