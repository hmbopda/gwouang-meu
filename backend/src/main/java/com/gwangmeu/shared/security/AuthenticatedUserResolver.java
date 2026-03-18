package com.gwangmeu.shared.security;

import org.springframework.security.oauth2.jwt.Jwt;

import java.util.UUID;

/**
 * Interface pour resoudre un JWT en UUID utilisateur interne.
 * Implementee par le module user, utilisable par tous les modules
 * sans creer de couplage direct vers le module user.
 */
public interface AuthenticatedUserResolver {

    UUID resolve(Jwt jwt);
}
