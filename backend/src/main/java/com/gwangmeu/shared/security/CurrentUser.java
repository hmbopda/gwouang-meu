package com.gwangmeu.shared.security;

import org.springframework.security.core.annotation.AuthenticationPrincipal;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Annotation raccourci pour injecter le JWT Supabase valide dans les controllers.
 *
 * Usage dans les controllers :
 *   {@code @CurrentUser Jwt jwt}
 *   String supabaseId = jwt.getSubject();    // UUID Supabase de l'utilisateur
 *   String email      = jwt.getClaimAsString("email");
 *
 * Le JWT est valide a ce stade (valide par l'OAuth2 Resource Server via JWKS).
 */
@Target(ElementType.PARAMETER)
@Retention(RetentionPolicy.RUNTIME)
@AuthenticationPrincipal
public @interface CurrentUser {
}
