package com.gwangmeu.genealogy.application;

import com.gwangmeu.feed.application.CreatePostCommand;
import com.gwangmeu.feed.application.FeedService;
import com.gwangmeu.genealogy.domain.Person;
import com.gwangmeu.genealogy.events.*;
import com.gwangmeu.genealogy.infrastructure.PersonRepository;
import com.gwangmeu.genealogy.infrastructure.PersonVillageRepository;
import com.gwangmeu.notification.NotificationService;
import com.gwangmeu.shared.mail.EmailService;
import com.gwangmeu.shared.notification.FcmNotificationService;
import com.gwangmeu.user.User;
import com.gwangmeu.user.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Component
@RequiredArgsConstructor
public class GenealogyEventListener {

    private final PersonRepository personRepository;
    private final PersonVillageRepository personVillageRepository;
    private final UserRepository userRepository;
    private final FcmNotificationService fcmNotificationService;
    private final NotificationService notificationService;
    private final EmailService emailService;
    private final FeedService feedService;

    @Async
    @EventListener
    public void onParentChildLinked(ParentChildLinkedEvent event) {
        Person parent = personRepository.findById(event.parentId()).orElse(null);
        Person child = personRepository.findById(event.childId()).orElse(null);
        if (parent == null || child == null) return;

        String parentName = parent.getFirstName() + " " + parent.getLastName();
        String childName = child.getFirstName() + " " + child.getLastName();
        String roleLabel = event.role().name().equals("FATHER") ? "pere" : "mere";

        // 1. Notification FCM aux membres de la famille (personnes liees ayant un userId)
        String fcmTitle = "Nouvel ajout genealogique";
        String fcmBody = parentName + " a ete ajoute(e) comme " + roleLabel + " de " + childName;
        Map<String, String> fcmData = Map.of("type", "PARENT_ADDED",
                "parentId", event.parentId().toString(),
                "childId", event.childId().toString());
        sendFamilyNotification(child.getId(), fcmTitle, fcmBody, fcmData);

        // Notifications in-app pour le parent et l'enfant
        Map<String, Object> inAppData = Map.of("type", "PARENT_ADDED",
                "parentId", event.parentId().toString(),
                "childId", event.childId().toString());

        if (parent.getUserId() != null) {
            notificationService.create(parent.getUserId(), "PARENT_ADDED", fcmTitle, fcmBody, inAppData);
        }
        if (child.getUserId() != null) {
            notificationService.create(child.getUserId(), "PARENT_ADDED", fcmTitle, fcmBody, inAppData);
        }

        // 2. Auto-post dans le feed du village
        List<UUID> villageIds = personVillageRepository.findVillageIdsByPersonId(child.getId());
        if (villageIds.isEmpty()) {
            villageIds = personVillageRepository.findVillageIdsByPersonId(parent.getId());
        }

        UUID authorId = child.getCreatedBy();
        String content = "\uD83C\uDF33 " + parentName + " a ete ajoute(e) comme " + roleLabel
                + " de " + childName + " dans l'arbre genealogique.";

        for (UUID villageId : villageIds) {
            try {
                feedService.createPost(new CreatePostCommand(authorId, villageId, content, null));
                log.info("Auto-post created in village {} for parent-child link", villageId);
            } catch (Exception e) {
                log.warn("Failed to create auto-post in village {}: {}", villageId, e.getMessage());
            }
        }
    }

    @Async
    @EventListener
    public void onUnionCreated(UnionCreatedEvent event) {
        log.info("onUnionCreated triggered: husbandId={}, wifeId={}, unionId={}",
                event.husbandId(), event.wifeId(), event.unionId());

        Person husband = personRepository.findById(event.husbandId()).orElse(null);
        Person wife = personRepository.findById(event.wifeId()).orElse(null);
        if (husband == null || wife == null) {
            log.warn("onUnionCreated: husband or wife not found in DB");
            return;
        }

        String husbandName = husband.getFirstName() + " " + husband.getLastName();
        String wifeName = wife.getFirstName() + " " + wife.getLastName();
        String inAppTitle = "Demande d'union";
        String inAppBody = husbandName + " souhaite enregistrer une union avec " + wifeName
                + ". Veuillez confirmer ou contester cette demande.";

        // 1. Notifications in-app pour les deux epoux
        Map<String, Object> inAppData = Map.of(
                "type", "UNION_PENDING",
                "unionId", event.unionId().toString(),
                "husbandId", event.husbandId().toString(),
                "wifeId", event.wifeId().toString()
        );

        if (wife.getUserId() != null) {
            try {
                notificationService.create(wife.getUserId(), "UNION_PENDING", inAppTitle, inAppBody, inAppData);
                log.info("In-app notification created for wife userId={}", wife.getUserId());
            } catch (Exception e) {
                log.error("Failed to create in-app notification for wife: {}", e.getMessage(), e);
            }
        }
        if (husband.getUserId() != null) {
            try {
                notificationService.create(husband.getUserId(), "UNION_PENDING", inAppTitle, inAppBody, inAppData);
                log.info("In-app notification created for husband userId={}", husband.getUserId());
            } catch (Exception e) {
                log.error("Failed to create in-app notification for husband: {}", e.getMessage(), e);
            }
        }

        // 2. Emails aux deux epoux (email depuis users table, pas persons)
        sendUnionEmailToUser(wife.getUserId(), wife.getFirstName(), husbandName);
        sendUnionEmailToUser(husband.getUserId(), husband.getFirstName(), wifeName);

        // 3. Notification FCM
        sendFamilyNotification(
                husband.getId(),
                inAppTitle,
                inAppBody,
                Map.of("type", "UNION_PENDING", "unionId", event.unionId().toString())
        );

        // 4. Auto-post dans le feed (en attente de validation)
        List<UUID> villageIds = personVillageRepository.findVillageIdsByPersonId(husband.getId());
        UUID authorId = husband.getCreatedBy();
        String content = "\uD83D\uDC8D Une demande d'union entre " + husbandName + " et " + wifeName
                + " est en attente de confirmation.";

        for (UUID villageId : villageIds) {
            try {
                feedService.createPost(new CreatePostCommand(authorId, villageId, content, null));
            } catch (Exception e) {
                log.warn("Failed to create auto-post for union in village {}: {}", villageId, e.getMessage());
            }
        }
    }

    @Async
    @EventListener
    public void onChildAssociationRequested(ChildAssociationRequestedEvent event) {
        log.info("onChildAssociationRequested: requestId={}, childId={}, requesterId={}, targetParentId={}",
                event.requestId(), event.childId(), event.requesterId(), event.targetParentId());

        Person requester = personRepository.findById(event.requesterId()).orElse(null);
        Person targetParent = personRepository.findById(event.targetParentId()).orElse(null);
        Person child = personRepository.findById(event.childId()).orElse(null);
        if (requester == null || targetParent == null || child == null) {
            log.warn("onChildAssociationRequested: missing person data");
            return;
        }

        String requesterName = requester.getFirstName() + " " + requester.getLastName();
        String childName = child.getFirstName() + " " + child.getLastName();
        String title = "Demande d'association d'enfant";
        String body = requesterName + " souhaite associer l'enfant " + childName
                + " a votre arbre genealogique. Confirmez-vous cette filiation ?";

        // 1. Notification in-app pour le co-parent cible
        if (targetParent.getUserId() != null) {
            Map<String, Object> inAppData = Map.of(
                    "type", "CHILD_ASSOCIATION_REQUEST",
                    "requestId", event.requestId().toString(),
                    "childId", event.childId().toString(),
                    "requesterId", event.requesterId().toString()
            );
            try {
                notificationService.create(targetParent.getUserId(), "CHILD_ASSOCIATION_REQUEST",
                        title, body, inAppData);
                log.info("In-app notification created for targetParent userId={}", targetParent.getUserId());
            } catch (Exception e) {
                log.error("Failed to create in-app notification for child association: {}", e.getMessage(), e);
            }
        }

        // 2. Email au co-parent cible
        if (targetParent.getUserId() != null) {
            userRepository.findById(targetParent.getUserId()).ifPresent(user -> {
                String email = user.getEmail();
                if (email != null && !email.isBlank()) {
                    try {
                        emailService.sendChildAssociationEmail(email, targetParent.getFirstName(),
                                requesterName, childName);
                    } catch (Exception e) {
                        log.error("Failed to send child association email to {}: {}", email, e.getMessage(), e);
                    }
                }
            });
        }

        // 3. FCM push au co-parent cible
        if (targetParent.getUserId() != null) {
            userRepository.findById(targetParent.getUserId()).ifPresent(user -> {
                if (user.getFcmToken() != null && !user.getFcmToken().isBlank()) {
                    fcmNotificationService.sendToTokens(
                            List.of(user.getFcmToken()), title, body,
                            Map.of("type", "CHILD_ASSOCIATION_REQUEST",
                                    "requestId", event.requestId().toString()));
                }
            });
        }
    }

    @Async
    @EventListener
    public void onChildAssociationResponded(ChildAssociationRespondedEvent event) {
        log.info("onChildAssociationResponded: requestId={}, accepted={}, responderId={}",
                event.requestId(), event.accepted(), event.responderId());

        Person requester = personRepository.findById(event.requesterId()).orElse(null);
        Person responder = personRepository.findById(event.responderId()).orElse(null);
        Person child = personRepository.findById(event.childId()).orElse(null);
        if (requester == null || responder == null || child == null) {
            log.warn("onChildAssociationResponded: missing person data");
            return;
        }

        String responderName = responder.getFirstName() + " " + responder.getLastName();
        String childName = child.getFirstName() + " " + child.getLastName();
        String status = event.accepted() ? "accepte" : "refuse";
        String title = "Reponse a votre demande d'association";
        String body = responderName + " a " + status + " l'association de " + childName + " a son arbre genealogique.";

        // Notification in-app pour le demandeur
        if (requester.getUserId() != null) {
            Map<String, Object> inAppData = Map.of(
                    "type", "CHILD_ASSOCIATION_RESPONSE",
                    "requestId", event.requestId().toString(),
                    "childId", event.childId().toString(),
                    "accepted", event.accepted()
            );
            try {
                notificationService.create(requester.getUserId(), "CHILD_ASSOCIATION_RESPONSE",
                        title, body, inAppData);
            } catch (Exception e) {
                log.error("Failed to create in-app notification for association response: {}", e.getMessage(), e);
            }
        }

        // FCM push au demandeur
        if (requester.getUserId() != null) {
            userRepository.findById(requester.getUserId()).ifPresent(user -> {
                if (user.getFcmToken() != null && !user.getFcmToken().isBlank()) {
                    fcmNotificationService.sendToTokens(
                            List.of(user.getFcmToken()), title, body,
                            Map.of("type", "CHILD_ASSOCIATION_RESPONSE",
                                    "requestId", event.requestId().toString(),
                                    "accepted", String.valueOf(event.accepted())));
                }
            });
        }
    }

    @Async
    @EventListener
    public void onPersonModificationRequested(PersonModificationRequestedEvent event) {
        log.info("onPersonModificationRequested: requestId={}, personId={}, requesterId={}, targetParentId={}",
                event.requestId(), event.personId(), event.requesterId(), event.targetParentId());

        Person requester = personRepository.findById(event.requesterId()).orElse(null);
        Person targetParent = personRepository.findById(event.targetParentId()).orElse(null);
        Person child = personRepository.findById(event.personId()).orElse(null);
        if (requester == null || targetParent == null || child == null) {
            log.warn("onPersonModificationRequested: missing person data");
            return;
        }

        String requesterName = requester.getFirstName() + " " + requester.getLastName();
        String childName = child.getFirstName() + " " + child.getLastName();
        String title = "Demande de modification";
        String body = requesterName + " souhaite modifier les informations de " + childName
                + ". Veuillez valider ou refuser cette modification.";

        if (targetParent.getUserId() != null) {
            Map<String, Object> inAppData = Map.of(
                    "type", "PERSON_MODIFICATION_REQUEST",
                    "requestId", event.requestId().toString(),
                    "personId", event.personId().toString(),
                    "requesterId", event.requesterId().toString()
            );
            try {
                notificationService.create(targetParent.getUserId(), "PERSON_MODIFICATION_REQUEST",
                        title, body, inAppData);
                log.info("In-app notification created for modification request, targetParent userId={}",
                        targetParent.getUserId());
            } catch (Exception e) {
                log.error("Failed to create notification for modification request: {}", e.getMessage(), e);
            }
        }

        // FCM push
        if (targetParent.getUserId() != null) {
            userRepository.findById(targetParent.getUserId()).ifPresent(user -> {
                if (user.getFcmToken() != null && !user.getFcmToken().isBlank()) {
                    fcmNotificationService.sendToTokens(
                            List.of(user.getFcmToken()), title, body,
                            Map.of("type", "PERSON_MODIFICATION_REQUEST",
                                    "requestId", event.requestId().toString()));
                }
            });
        }
    }

    @Async
    @EventListener
    public void onPersonModificationResponded(PersonModificationRespondedEvent event) {
        log.info("onPersonModificationResponded: requestId={}, accepted={}, responderId={}",
                event.requestId(), event.accepted(), event.responderId());

        Person requester = personRepository.findById(event.requesterId()).orElse(null);
        Person responder = personRepository.findById(event.responderId()).orElse(null);
        Person child = personRepository.findById(event.personId()).orElse(null);
        if (requester == null || responder == null || child == null) {
            log.warn("onPersonModificationResponded: missing person data");
            return;
        }

        String responderName = responder.getFirstName() + " " + responder.getLastName();
        String childName = child.getFirstName() + " " + child.getLastName();
        String status = event.accepted() ? "accepte" : "refuse";
        String title = "Reponse a votre demande de modification";
        String body = responderName + " a " + status + " la modification de la fiche de " + childName + ".";

        if (requester.getUserId() != null) {
            Map<String, Object> inAppData = Map.of(
                    "type", "PERSON_MODIFICATION_RESPONSE",
                    "requestId", event.requestId().toString(),
                    "personId", event.personId().toString(),
                    "accepted", event.accepted()
            );
            try {
                notificationService.create(requester.getUserId(), "PERSON_MODIFICATION_RESPONSE",
                        title, body, inAppData);
            } catch (Exception e) {
                log.error("Failed to create notification for modification response: {}", e.getMessage(), e);
            }
        }

        // FCM push
        if (requester.getUserId() != null) {
            userRepository.findById(requester.getUserId()).ifPresent(user -> {
                if (user.getFcmToken() != null && !user.getFcmToken().isBlank()) {
                    fcmNotificationService.sendToTokens(
                            List.of(user.getFcmToken()), title, body,
                            Map.of("type", "PERSON_MODIFICATION_RESPONSE",
                                    "requestId", event.requestId().toString(),
                                    "accepted", String.valueOf(event.accepted())));
                }
            });
        }
    }

    private void sendUnionEmailToUser(UUID userId, String recipientFirstName, String spouseName) {
        if (userId == null) return;
        userRepository.findById(userId).ifPresent(user -> {
            String email = user.getEmail();
            if (email != null && !email.isBlank()) {
                try {
                    emailService.sendUnionEmail(email, recipientFirstName, spouseName);
                    log.info("Union email sent to {}", email);
                } catch (Exception e) {
                    log.error("Failed to send union email to {}: {}", email, e.getMessage(), e);
                }
            } else {
                log.warn("No email for userId={}, skipping union email", userId);
            }
        });
    }

    private void sendFamilyNotification(UUID personId, String title, String body, Map<String, String> data) {
        // Trouver les personnes liees qui ont un userId (= utilisateurs enregistres)
        List<User> familyUsers = findFamilyUsers(personId);
        List<String> tokens = familyUsers.stream()
                .map(User::getFcmToken)
                .filter(t -> t != null && !t.isBlank())
                .toList();

        if (!tokens.isEmpty()) {
            fcmNotificationService.sendToTokens(tokens, title, body, data);
            log.info("FCM notifications sent to {} family members", tokens.size());
        }
    }

    private List<User> findFamilyUsers(UUID personId) {
        // Recuperer les personnes de la meme famille (parents, enfants, fratrie)
        // qui ont un user_id (= utilisateurs enregistres)
        return personRepository.findFamilyUserIds(personId).stream()
                .map(userRepository::findById)
                .filter(java.util.Optional::isPresent)
                .map(java.util.Optional::get)
                .toList();
    }
}
