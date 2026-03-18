package com.gwangmeu;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.scheduling.annotation.EnableAsync;

/**
 * GWANG MEU — Plateforme de preservation culturelle africaine
 * Langues · Culture · Futur
 *
 * Phase 1 : Auth · Villages · Social Feed
 * Architecture : Spring Boot 3 + Spring Modulith
 * Auth : Supabase JWT (OAuth2 Resource Server + JWKS)
 * DB   : PostgreSQL (Supabase) + Flyway migrations
 * Docs : http://localhost:8080/swagger-ui.html
 */
@SpringBootApplication
@EnableJpaAuditing
@EnableAsync
public class GwangMeuApplication {

    public static void main(String[] args) {
        SpringApplication.run(GwangMeuApplication.class, args);
    }
}
