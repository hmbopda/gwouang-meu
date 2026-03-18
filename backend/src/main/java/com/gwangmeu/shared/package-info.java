/**
 * Shared Kernel — GWANG MEU
 *
 * Ce package contient les composants partagés par tous les modules.
 * Il n'est PAS un module Spring Modulith (accessible librement par tous).
 * Ne jamais y mettre de logique metier specifique a un module.
 *
 * Contenu :
 *  - security   : JWT, SecurityConfig, UserPrincipal, GwangMeuRole
 *  - events     : DomainEvent (classe de base)
 *  - ai         : ClaudeAiClient (Anthropic API)
 *  - media      : MediaService (Cloudflare R2)
 *  - geo        : GeoContext
 *  - domain     : AuditEntity
 *  - config     : Redis, WebClient, R2, Firebase
 */
@org.springframework.modulith.ApplicationModule(
        type = org.springframework.modulith.ApplicationModule.Type.OPEN,
        displayName = "Shared Kernel")
package com.gwangmeu.shared;
