package com.gwangmeu.config;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.info.Contact;
import io.swagger.v3.oas.annotations.info.Info;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import io.swagger.v3.oas.annotations.servers.Server;
import org.springframework.context.annotation.Configuration;

/**
 * Configuration Swagger / OpenAPI 3.
 * Accessible : http://localhost:8080/swagger-ui.html
 * Desactive en production (voir application-prod.yml).
 */
@Configuration
@OpenAPIDefinition(
        info = @Info(
                title = "GWANG MEU API",
                version = "v1.0",
                description = """
                        Plateforme culturelle africaine — Langues · Culture · Futur

                        ## Authentification
                        1. Connecte-toi via Supabase Auth (email / Google / Phone)
                        2. Recupere ton JWT depuis la reponse Supabase
                        3. Clique **Authorize** ci-dessous → colle `Bearer {ton_token}`

                        ## Roles disponibles
                        - **SUPER_ADMIN** — Acces total plateforme
                        - **MODERATEUR** — Moderation contenu multi-villages
                        - **AMBASSADEUR** — Gestion d'un village specifique
                        - **MEMBRE** — Utilisateur authentifie standard
                        - **VISITEUR** — Lecture publique (non authentifie)
                        - **API** — Chercheurs / integrations externes

                        ## Phase 1 — Modules actifs
                        - Users (sync Supabase, profils RBAC)
                        - Villages (creation, adhesion, hierarchie geo)
                        - Feed (publications, reactions, commentaires, moderation)
                        """,
                contact = @Contact(name = "GWANG MEU", url = "https://gwouangmeu.com")
        ),
        servers = {
                @Server(url = "http://localhost:8080", description = "Local Dev"),
                @Server(url = "https://api.gwouangmeu.com", description = "Production")
        },
        security = @SecurityRequirement(name = "BearerAuth")
)
@SecurityScheme(
        name = "BearerAuth",
        type = SecuritySchemeType.HTTP,
        scheme = "bearer",
        bearerFormat = "JWT",
        description = "Token JWT Supabase. Obtenu via POST https://{project}.supabase.co/auth/v1/token"
)
public class SwaggerConfig {
}
