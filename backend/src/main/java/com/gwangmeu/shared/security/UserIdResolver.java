package com.gwangmeu.shared.security;

import com.gwangmeu.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Component;

import java.util.UUID;

@Component
@RequiredArgsConstructor
public class UserIdResolver implements AuthenticatedUserResolver {

    private final UserRepository userRepository;

    /**
     * Resout le supabase_id (jwt.getSubject()) en users.id (UUID interne).
     * Utilise dans tous les controllers qui ont besoin du created_by FK.
     */
    @Override
    public UUID resolve(Jwt jwt) {
        String supabaseId = jwt.getSubject();
        return userRepository.findBySupabaseId(supabaseId)
                .orElseThrow(() -> new IllegalStateException("User not found for supabase_id: " + supabaseId))
                .getId();
    }
}
