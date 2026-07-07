package com.gwangmeu.config;

import com.gwangmeu.shared.security.UserRole;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jose.jws.SignatureAlgorithm;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Collection;
import java.util.List;
import java.util.Map;

/**
 * Configuration Spring Security.
 * - JWT valide via Supabase JWKS (OAuth2 Resource Server) — aucune cle hardcodee
 * - Stateless (pas de sessions)
 * - CORS configure pour Flutter + Next.js + Swagger
 * - Roles extraits du claim user_metadata.role du JWT Supabase
 */
@Slf4j
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    @Value("${spring.security.oauth2.resourceserver.jwt.jwk-set-uri}")
    private String jwksUri;

    /**
     * JwtDecoder explicitement configure pour ES256 (ECC P-256).
     * Spring Boot auto-configure seulement RS256 — Supabase utilise ES256.
     */
    @Bean
    public JwtDecoder jwtDecoder() {
        return NimbusJwtDecoder.withJwkSetUri(jwksUri)
                .jwsAlgorithm(SignatureAlgorithm.ES256)
                .build();
    }

    // Endpoints publics (GET uniquement sauf /auth/sync)
    private static final String[] PUBLIC_GET = {
            "/api/v1/villages/**",
            "/api/v1/geo/**",
            "/api/v1/posts/*",
            "/api/v1/invitations/token/**",
            "/swagger-ui/**",
            "/swagger-ui.html",
            "/v3/api-docs/**",
            "/actuator/health"
    };

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        return http
                .csrf(AbstractHttpConfigurer::disable)
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(HttpMethod.GET, PUBLIC_GET).permitAll()
                        .requestMatchers("/actuator/health").permitAll()
                        .requestMatchers("/uploads/**").permitAll()
                        .requestMatchers("/swagger-ui.html", "/swagger-ui/**", "/v3/api-docs/**").permitAll()
                        .requestMatchers("/ws/**").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/v1/users/auth/register").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/v1/invitations/token/*/accept").authenticated()
                        .anyRequest().authenticated()
                )
                .oauth2ResourceServer(oauth2 -> oauth2
                        .jwt(jwt -> jwt.jwtAuthenticationConverter(jwtAuthenticationConverter()))
                )
                .build();
    }

    /**
     * Extrait le role GWANG MEU depuis les claims Supabase JWT.
     * Cherche d'abord dans user_metadata.role, puis app_metadata.role,
     * puis defaulte a MEMBRE.
     */
    @Bean
    public JwtAuthenticationConverter jwtAuthenticationConverter() {
        JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
        converter.setJwtGrantedAuthoritiesConverter(this::extractAuthorities);
        return converter;
    }

    private Collection<GrantedAuthority> extractAuthorities(Jwt jwt) {
        String role = null;

        // 1. Chercher dans user_metadata
        Map<String, Object> userMeta = jwt.getClaimAsMap("user_metadata");
        if (userMeta != null && userMeta.containsKey("role")) {
            role = userMeta.get("role").toString();
        }

        // 2. Chercher dans app_metadata
        if (role == null) {
            Map<String, Object> appMeta = jwt.getClaimAsMap("app_metadata");
            if (appMeta != null && appMeta.containsKey("role")) {
                role = appMeta.get("role").toString();
            }
        }

        // 3. Default : MEMBRE
        if (role == null || role.isBlank()) {
            role = UserRole.MEMBRE.name();
        }

        try {
            UserRole.valueOf(role.toUpperCase());
        } catch (IllegalArgumentException e) {
            log.warn("Role JWT inconnu '{}', defaulting to MEMBRE", role);
            role = UserRole.MEMBRE.name();
        }

        return List.of(new SimpleGrantedAuthority("ROLE_" + role.toUpperCase()));
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOriginPatterns(List.of(
                "http://localhost:*",      // Flutter web, Next.js, Vite, Swagger (tout port local)
                "https://gwangmeu.com",
                "https://app.gwangmeu.com",
                "https://hmbopda.github.io",  // Build web hébergé sur GitHub Pages
                "https://*.trycloudflare.com" // Tunnel de démo (exposition temporaire)
        ));
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("*"));
        config.setAllowCredentials(true);
        config.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}
