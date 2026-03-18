package com.gwangmeu.shared.security;

/**
 * 6 roles RBAC de la plateforme GWANG MEU.
 * Definis dans ARCHITECTURE.md — section Securite & RBAC.
 */
public enum GwangMeuRole {
    /** Acces total plateforme */
    SUPER_ADMIN,
    /** Moderation contenu multi-villages */
    MODERATEUR,
    /** Gestion d'un village specifique */
    AMBASSADEUR,
    /** Utilisateur authentifie standard */
    MEMBRE,
    /** Utilisateur non-authentifie (lecture publique) */
    VISITEUR,
    /** Chercheurs / integrations externes */
    API
}
