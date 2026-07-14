package com.gwangmeu.config;

import com.gwangmeu.shared.security.UserRole;
import com.gwangmeu.user.UserRepository;
import lombok.RequiredArgsConstructor;
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
import java.util.concurrent.ConcurrentHashMap;

/**
 * Configuration Spring Security.
 * - JWT valide via Supabase JWKS (OAuth2 Resource Server) — aucune cle hardcodee
 * - Stateless (pas de sessions)
 * - CORS configure pour Flutter + Next.js + Swagger
 * - Role = source de verite unique : la base (users.role). Repli sur le claim
 *   JWT Supabase (user_metadata/app_metadata.role) puis MEMBRE.
 */
@Slf4j
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    /** Source de verite du role = la base (users.role) ; cache court (60 s) pour
     *  ne pas interroger la DB a chaque requete. Un changement de role prend donc
     *  effet en <= 60 s, sans re-login. */
    private static final long ROLE_TTL_MS = 60_000L;
    private final Map<String, CachedRole> roleCache = new ConcurrentHashMap<>();
    private record CachedRole(String role, long expiresAt) {}

    private final UserRepository userRepository;

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
            "/api/v1/genealogy/marriage-rules/**",
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
        String role = resolveRole(jwt);

        try {
            UserRole.valueOf(role.toUpperCase());
        } catch (IllegalArgumentException e) {
            log.warn("Role inconnu '{}', defaulting to MEMBRE", role);
            role = UserRole.MEMBRE.name();
        }

        return List.of(new SimpleGrantedAuthority("ROLE_" + role.toUpperCase()));
    }

    /**
     * Résout le rôle : la BASE (users.role) fait foi ; cache court pour ne pas
     * frapper la DB à chaque requête. Repli sur les claims JWT puis MEMBRE si la
     * DB est indisponible ou l'utilisateur introuvable (résilience — on ne casse
     * jamais l'authentification).
     */
    private String resolveRole(Jwt jwt) {
        String supabaseId = jwt.getSubject();
        long now = System.currentTimeMillis();
        if (supabaseId != null) {
            CachedRole cached = roleCache.get(supabaseId);
            if (cached != null && cached.expiresAt() > now) {
                return cached.role();
            }
            try {
                String dbRole = userRepository.findBySupabaseId(supabaseId)
                        .map(u -> u.getRole() != null ? u.getRole().name() : null)
                        .orElse(null);
                if (dbRole != null && !dbRole.isBlank()) {
                    roleCache.put(supabaseId, new CachedRole(dbRole, now + ROLE_TTL_MS));
                    return dbRole;
                }
            } catch (Exception e) {
                log.warn("Lecture du role en base echouee ({}), repli sur le JWT : {}",
                        supabaseId, e.getMessage());
            }
        }
        return roleFromClaims(jwt);
    }

    /** Repli : rôle depuis user_metadata puis app_metadata du JWT, défaut MEMBRE. */
    private String roleFromClaims(Jwt jwt) {
        String role = null;
        Map<String, Object> userMeta = jwt.getClaimAsMap("user_metadata");
        if (userMeta != null && userMeta.containsKey("role")) {
            role = userMeta.get("role").toString();
        }
        if (role == null) {
            Map<String, Object> appMeta = jwt.getClaimAsMap("app_metadata");
            if (appMeta != null && appMeta.containsKey("role")) {
                role = appMeta.get("role").toString();
            }
        }
        if (role == null || role.isBlank()) {
            role = UserRole.MEMBRE.name();
        }
        return role;
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOriginPatterns(List.of(
                "http://localhost:*",      // Flutter web, Next.js, Vite, Swagger (tout port local)
                "https://gwouangmeu.com",
                "https://app.gwouangmeu.com",
                "https://hmbopda.github.io",  // Build web hébergé sur GitHub Pages
                "https://*.trycloudflare.com", // Tunnel de démo (exposition temporaire)
                "https://gwangmeu-app.pages.dev",   // Cloudflare Pages (production)
                "https://*.gwangmeu-app.pages.dev"  // Cloudflare Pages (previews)
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
