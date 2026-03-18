package com.gwangmeu.genealogy.application;

import com.gwangmeu.genealogy.domain.Person;
import com.gwangmeu.genealogy.domain.PersonVillage;
import com.gwangmeu.shared.domain.enums.GenderEnum;
import com.gwangmeu.genealogy.domain.enums.PersonStatusEnum;
import com.gwangmeu.genealogy.domain.enums.PrivacyEnum;
import com.gwangmeu.genealogy.events.PersonCreatedEvent;
import com.gwangmeu.genealogy.infrastructure.PersonRepository;
import com.gwangmeu.genealogy.infrastructure.PersonVillageRepository;
import com.gwangmeu.user.User;
import com.gwangmeu.user.UserRepository;
import com.gwangmeu.user.events.UserCreatedEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Slf4j
@Component
@RequiredArgsConstructor
public class UserPersonSyncListener {

    private final UserRepository userRepository;
    private final PersonRepository personRepository;
    private final PersonVillageRepository personVillageRepository;
    private final ApplicationEventPublisher eventPublisher;

    @EventListener
    @Transactional
    public void onUserCreated(UserCreatedEvent event) {
        UUID userId = event.getUserId();

        User user = userRepository.findById(userId).orElse(null);
        if (user == null) {
            log.warn("UserPersonSync: user {} not found, skipping", userId);
            return;
        }

        boolean alreadyLinked = personRepository.findByCreatedBy(userId).stream()
                .anyMatch(p -> userId.equals(p.getUserId()));
        if (alreadyLinked) {
            log.info("UserPersonSync: person already linked for user {}", userId);
            return;
        }

        String displayName = user.getDisplayName() != null ? user.getDisplayName() : "Utilisateur";
        String[] parts = displayName.trim().split("\\s+", 2);
        String firstName = parts[0];
        String lastName = parts.length > 1 ? parts[1] : "";

        Person person = Person.builder()
                .userId(userId)
                .firstName(firstName)
                .lastName(lastName)
                .gender(event.getGender() != null ? event.getGender() : GenderEnum.OTHER)
                .email(user.getEmail())
                .clan(user.getClan())
                .totem(null)
                .nativeLanguage(user.getNativeLanguage())
                .photoUrl(user.getAvatarUrl())
                .privacy(PrivacyEnum.FAMILY_ONLY)
                .status(PersonStatusEnum.CONFIRMED)
                .createdBy(userId)
                .build();

        Person saved = personRepository.save(person);

        List<UUID> villageIds = List.of();
        if (user.getOriginVillageId() != null) {
            PersonVillage pv = PersonVillage.builder()
                    .personId(saved.getId())
                    .villageId(user.getOriginVillageId())
                    .build();
            personVillageRepository.save(pv);
            villageIds = List.of(user.getOriginVillageId());
        }

        log.info("UserPersonSync: auto-created person {} for user {}", saved.getId(), userId);

        eventPublisher.publishEvent(new PersonCreatedEvent(saved.getId(), villageIds, userId));
    }
}
