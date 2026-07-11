package com.gwangmeu.user;

import com.gwangmeu.shared.domain.enums.GenderEnum;
import com.gwangmeu.user.dto.CreateUserRequest;
import com.gwangmeu.user.dto.UpdateUserRequest;
import com.gwangmeu.user.dto.UserDto;
import com.gwangmeu.user.events.UserCreatedEvent;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final UserMapper userMapper;
    private final ApplicationEventPublisher eventPublisher;

    @Transactional(readOnly = true)
    public UserDto getById(UUID userId) {
        return userRepository.findById(userId)
                .map(userMapper::toDto)
                .orElseThrow(() -> new EntityNotFoundException("Utilisateur introuvable : " + userId));
    }

    @Transactional(readOnly = true)
    public UserDto getBySupabaseId(String supabaseId) {
        return userRepository.findBySupabaseId(supabaseId)
                .map(userMapper::toDto)
                .orElseThrow(() -> new EntityNotFoundException("Utilisateur introuvable : " + supabaseId));
    }

    /**
     * Synchronise l'utilisateur depuis le JWT Supabase.
     * Cree l'utilisateur s'il n'existe pas encore (premier login).
     * Met a jour les infos de base si deja existant.
     */
    @Transactional
    public UserDto syncFromJwt(Jwt jwt) {
        String supabaseId = jwt.getSubject();
        String email      = jwt.getClaimAsString("email");
        Map<String, Object> userMeta = jwt.getClaimAsMap("user_metadata");

        return userRepository.findBySupabaseId(supabaseId)
                .map(user -> {
                    // Mise a jour minimale sur re-sync
                    if (email != null && !email.equals(user.getEmail())) {
                        user.setEmail(email);
                    }
                    return userMapper.toDto(userRepository.save(user));
                })
                .orElseGet(() -> {
                    // Nouveau utilisateur — extraire toutes les metadata Supabase
                    User.UserBuilder builder = User.builder()
                            .supabaseId(supabaseId)
                            .email(email != null ? email : "")
                            .displayName(extractDisplayName(jwt));

                    if (userMeta != null) {
                        if (userMeta.containsKey("country")) {
                            builder.country(userMeta.get("country").toString());
                        }
                        if (userMeta.containsKey("native_language")) {
                            builder.nativeLanguage(userMeta.get("native_language").toString());
                        }
                        if (userMeta.containsKey("bio")) {
                            builder.bio(userMeta.get("bio").toString());
                        }
                    }

                    User saved = userRepository.save(builder.build());
                    log.info("Nouvel utilisateur synced depuis Supabase : {}", saved.getId());
                    eventPublisher.publishEvent(new UserCreatedEvent(saved.getId(), saved.getEmail(), saved.getDisplayName(), null));
                    return userMapper.toDto(saved);
                });
    }

    @Transactional
    public UserDto updateProfile(String supabaseId, UpdateUserRequest request) {
        User user = userRepository.findBySupabaseId(supabaseId)
                .orElseThrow(() -> new EntityNotFoundException("Utilisateur introuvable"));

        // Identite
        if (request.displayName() != null) user.setDisplayName(request.displayName());
        if (request.bio() != null) user.setBio(request.bio());
        if (request.avatarUrl() != null) user.setAvatarUrl(request.avatarUrl());
        if (request.coverUrl() != null) user.setCoverUrl(request.coverUrl());
        if (request.country() != null) user.setCountry(request.country());
        if (request.nativeLanguage() != null) user.setNativeLanguage(request.nativeLanguage());
        if (request.originVillageId() != null) user.setOriginVillageId(request.originVillageId());
        // Parents
        if (request.fatherName() != null) user.setFatherName(request.fatherName());
        if (request.fatherOrigin() != null) user.setFatherOrigin(request.fatherOrigin());
        if (request.motherName() != null) user.setMotherName(request.motherName());
        if (request.motherOrigin() != null) user.setMotherOrigin(request.motherOrigin());
        // Famille
        if (request.maritalStatus() != null) user.setMaritalStatus(request.maritalStatus());
        if (request.matrimonialRegime() != null) user.setMatrimonialRegime(request.matrimonialRegime());
        if (request.childrenCount() != null) user.setChildrenCount(request.childrenCount());
        if (request.diet() != null) user.setDiet(request.diet());
        // Origines culturelles (village gere via village_subscriptions)
        if (request.tribe() != null) user.setTribe(request.tribe());
        if (request.clan() != null) user.setClan(request.clan());
        // Origine referentielle (ancre de la lignee)
        if (request.originCountry() != null) user.setOriginCountry(request.originCountry());
        if (request.originRegion() != null) user.setOriginRegion(request.originRegion());
        if (request.originDepartment() != null) user.setOriginDepartment(request.originDepartment());
        if (request.originArrondissement() != null) user.setOriginArrondissement(request.originArrondissement());
        if (request.originVillage() != null) user.setOriginVillage(request.originVillage());
        // Residence & Profession
        if (request.profession() != null) user.setProfession(request.profession());
        if (request.employer() != null) user.setEmployer(request.employer());
        if (request.residenceCity() != null) user.setResidenceCity(request.residenceCity());
        if (request.residenceCountry() != null) user.setResidenceCountry(request.residenceCountry());

        return userMapper.toDto(userRepository.save(user));
    }

    /**
     * Cree un utilisateur en BDD directement depuis les donnees du frontend.
     * Endpoint PUBLIC — appele juste apres le signUp Supabase (pas de JWT necessaire).
     * Si l'utilisateur existe deja (par supabaseId ou email), retourne le profil existant.
     */
    @Transactional
    public UserDto register(CreateUserRequest request) {
        // Verifier si l'utilisateur existe deja
        var existing = userRepository.findBySupabaseId(request.supabaseId());
        if (existing.isPresent()) {
            log.info("Utilisateur deja existant pour supabaseId={}, skip creation", request.supabaseId());
            return userMapper.toDto(existing.get());
        }

        var existingByEmail = userRepository.findByEmail(request.email());
        if (existingByEmail.isPresent()) {
            log.info("Utilisateur deja existant pour email={}, mise a jour supabaseId", request.email());
            User user = existingByEmail.get();
            user.setSupabaseId(request.supabaseId());
            return userMapper.toDto(userRepository.save(user));
        }

        User newUser = User.builder()
                .supabaseId(request.supabaseId())
                .email(request.email())
                .displayName(request.displayName())
                .country(request.country())
                .nativeLanguage(request.nativeLanguage())
                .bio(request.bio())
                .originVillageId(request.villageId())
                .clan(request.clan())
                .build();

        User saved = userRepository.save(newUser);
        log.info("Nouvel utilisateur cree en BDD : id={}, email={}", saved.getId(), saved.getEmail());
        eventPublisher.publishEvent(new UserCreatedEvent(saved.getId(), saved.getEmail(), saved.getDisplayName(), request.gender()));
        return userMapper.toDto(saved);
    }

    @Transactional
    public void updateFcmToken(String supabaseId, String fcmToken) {
        User user = userRepository.findBySupabaseId(supabaseId)
                .orElseThrow(() -> new EntityNotFoundException("Utilisateur introuvable"));
        user.setFcmToken(fcmToken);
        userRepository.save(user);
        log.debug("FCM token mis a jour pour : {}", supabaseId);
    }

    @Transactional
    public void deleteAccount(String supabaseId) {
        User user = userRepository.findBySupabaseId(supabaseId)
                .orElseThrow(() -> new EntityNotFoundException("Utilisateur introuvable"));
        user.setActive(false);
        user.setEmail("deleted_" + user.getId() + "@gwangmeu.deleted");
        user.setDisplayName("[Compte supprime]");
        user.setBio(null);
        user.setAvatarUrl(null);
        userRepository.save(user);
        log.info("Compte RGPD supprime : {}", user.getId());
    }

    private String extractDisplayName(Jwt jwt) {
        Object meta = jwt.getClaim("user_metadata");
        if (meta instanceof java.util.Map<?,?> map) {
            // Le frontend Flutter envoie "display_name"
            Object displayName = map.get("display_name");
            if (displayName != null) return displayName.toString();
            // OAuth providers envoient "full_name"
            Object fullName = map.get("full_name");
            if (fullName != null) return fullName.toString();
            Object email = map.get("email");
            if (email != null) return email.toString().split("@")[0];
        }
        String email = jwt.getClaimAsString("email");
        return email != null ? email.split("@")[0] : "Utilisateur";
    }
}
