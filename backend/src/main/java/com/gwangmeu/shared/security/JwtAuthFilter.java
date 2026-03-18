package com.gwangmeu.shared.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/**
 * Filtre supplementaire post-validation JWT.
 * La validation du JWT est geree par OAuth2 Resource Server (JWKS Supabase).
 * Ce filtre enrichit les attributs de requete pour un acces rapide dans les services.
 */
@Slf4j
@Component
public class JwtAuthFilter extends OncePerRequestFilter {

    public static final String SUPABASE_ID_ATTR = "supabaseId";
    public static final String USER_EMAIL_ATTR  = "userEmail";

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();

        if (auth instanceof JwtAuthenticationToken jwtAuth) {
            Jwt jwt = jwtAuth.getToken();
            String supabaseId = jwt.getSubject();
            String email = jwt.getClaimAsString("email");

            request.setAttribute(SUPABASE_ID_ATTR, supabaseId);
            if (email != null) {
                request.setAttribute(USER_EMAIL_ATTR, email);
            }

            log.debug("Requete auth — supabaseId={} path={}", supabaseId, request.getRequestURI());
        }

        filterChain.doFilter(request, response);
    }
}
