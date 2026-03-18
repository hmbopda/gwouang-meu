package com.gwangmeu.shared.security;

/**
 * 6 roles RBAC de la plateforme GWANG MEU.
 * Stockes dans user_metadata.role du JWT Supabase.
 * Ref: ARCHITECTURE.md — section Securite & RBAC.
 */
public enum UserRole {
    SUPER_ADMIN,  // Acces total plateforme
    MODERATEUR,   // Moderation contenu multi-villages
    AMBASSADEUR,  // Gestion d'un village specifique
    MEMBRE,       // Utilisateur authentifie standard
    VISITEUR,     // Lecture publique non authentifiee
    API           // Chercheurs / integrations externes
}
