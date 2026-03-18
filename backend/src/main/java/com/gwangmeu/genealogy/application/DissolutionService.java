package com.gwangmeu.genealogy.application;

import com.gwangmeu.genealogy.domain.DissolutionReminder;
import com.gwangmeu.genealogy.domain.GenealogyUnion;
import com.gwangmeu.genealogy.domain.ParentChild;
import com.gwangmeu.genealogy.domain.Person;
import com.gwangmeu.genealogy.infrastructure.DissolutionReminderRepository;
import com.gwangmeu.genealogy.infrastructure.ParentChildRepository;
import com.gwangmeu.genealogy.infrastructure.PersonRepository;
import com.gwangmeu.genealogy.infrastructure.UnionRepository;
import com.gwangmeu.notification.NotificationService;
import com.gwangmeu.shared.mail.EmailService;
import com.gwangmeu.shared.mail.SmsService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class DissolutionService {

    private final UnionRepository unionRepository;
    private final PersonRepository personRepository;
    private final ParentChildRepository parentChildRepository;
    private final DissolutionReminderRepository reminderRepository;
    private final NotificationService notificationService;
    private final EmailService emailService;
    private final SmsService smsService;

    // ── DIVORCE ─────────────────────────────────────────────

    /**
     * Demande de divorce : A déclare vouloir divorcer de B.
     * - Union passe en DIVORCE_PENDING
     * - Notification email + in-app à B
     * - Scheduler gère J+10 SMS, J+30 auto-validation
     */
    @Transactional
    public GenealogyUnion requestDivorce(UUID unionId, UUID requestedBy, String docUrl) {
        GenealogyUnion union = unionRepository.findById(unionId)
                .orElseThrow(() -> new IllegalArgumentException("Union non trouvee"));

        if (!"ACTIVE".equals(union.getStatus())) {
            throw new IllegalStateException("Cette union n'est pas active (statut: " + union.getStatus() + ")");
        }

        union.setStatus("DIVORCE_PENDING");
        union.setDissolutionType("DIVORCE");
        union.setDissolutionDocUrl(docUrl);
        union.setDissolutionRequestedBy(requestedBy);
        union.setDissolutionRequestedAt(Instant.now());
        unionRepository.save(union);

        // Identifier le conjoint (B)
        UUID spousePersonId = getSpouseId(union, requestedBy);
        Person spouse = personRepository.findById(spousePersonId)
                .orElseThrow(() -> new IllegalStateException("Conjoint non trouve"));
        Person requester = personRepository.findById(requestedBy)
                .orElseThrow(() -> new IllegalStateException("Demandeur non trouve"));

        String requesterName = requester.getFirstName() + " " + requester.getLastName();

        // Notification email à B
        if (spouse.getEmail() != null && !spouse.getEmail().isBlank()) {
            emailService.sendDissolutionEmail(
                    spouse.getEmail(), requesterName,
                    spouse.getFirstName(), "DIVORCE", unionId.toString());
            logReminder(unionId, "INITIAL_EMAIL", "EMAIL", "Email divorce envoye a " + spouse.getEmail());
        }

        // Notification in-app à B (si B a un userId)
        if (spouse.getUserId() != null) {
            notificationService.create(
                    spouse.getUserId(),
                    "DIVORCE_REQUEST",
                    "Demande de divorce",
                    requesterName + " a demande le divorce. Veuillez confirmer ou contester.",
                    Map.of("unionId", unionId.toString(), "type", "DIVORCE")
            );
            logReminder(unionId, "INITIAL_INAPP", "IN_APP", "Notification in-app divorce envoyee");
        }

        log.info("Demande de divorce initiee: union={}, par={}", unionId, requestedBy);
        return union;
    }

    /**
     * Le conjoint B confirme le divorce → union finalisée.
     */
    @Transactional
    public GenealogyUnion confirmDivorce(UUID unionId, UUID confirmedBy) {
        GenealogyUnion union = unionRepository.findById(unionId)
                .orElseThrow(() -> new IllegalArgumentException("Union non trouvee"));

        if (!"DIVORCE_PENDING".equals(union.getStatus())) {
            throw new IllegalStateException("Cette union n'est pas en attente de divorce");
        }

        UUID spouseId = getSpouseId(union, union.getDissolutionRequestedBy());
        if (!spouseId.equals(confirmedBy)) {
            throw new IllegalStateException("Seul le conjoint concerne peut confirmer le divorce");
        }

        finalizeDivorce(union);
        logReminder(unionId, "CONFIRMED_BY_SPOUSE", "SYSTEM", "Divorce confirme par le conjoint");
        log.info("Divorce confirme: union={}, par={}", unionId, confirmedBy);
        return union;
    }

    /**
     * Le conjoint B conteste le divorce → statut DISPUTE.
     */
    @Transactional
    public GenealogyUnion contestDivorce(UUID unionId, UUID contestedBy, String reason) {
        GenealogyUnion union = unionRepository.findById(unionId)
                .orElseThrow(() -> new IllegalArgumentException("Union non trouvee"));

        if (!"DIVORCE_PENDING".equals(union.getStatus())) {
            throw new IllegalStateException("Cette union n'est pas en attente de divorce");
        }

        union.setStatus("DISPUTE");
        union.setDisputeReason(reason);
        unionRepository.save(union);

        logReminder(unionId, "CONTESTED", "SYSTEM", "Divorce conteste par " + contestedBy + ": " + reason);
        log.info("Divorce conteste: union={}, par={}, raison={}", unionId, contestedBy, reason);
        return union;
    }

    // ── DECES ───────────────────────────────────────────────

    /**
     * Déclaration de décès : A déclare que B est décédé(e).
     * - Union passe en DEATH_PENDING
     * - Notification email + in-app à B (si vivant, pour contester)
     * - Notification au chef de famille + enfants
     * - Scheduler : J+30 → revue manuelle, J+45 → décision admin
     */
    @Transactional
    public GenealogyUnion declareDeath(UUID unionId, UUID requestedBy, String deathCertificateUrl) {
        GenealogyUnion union = unionRepository.findById(unionId)
                .orElseThrow(() -> new IllegalArgumentException("Union non trouvee"));

        if (!"ACTIVE".equals(union.getStatus())) {
            throw new IllegalStateException("Cette union n'est pas active (statut: " + union.getStatus() + ")");
        }

        union.setStatus("DEATH_PENDING");
        union.setDissolutionType("DEATH");
        union.setDissolutionDocUrl(deathCertificateUrl);
        union.setDissolutionRequestedBy(requestedBy);
        union.setDissolutionRequestedAt(Instant.now());
        unionRepository.save(union);

        UUID declaredDeadPersonId = getSpouseId(union, requestedBy);
        Person declaredDead = personRepository.findById(declaredDeadPersonId)
                .orElseThrow(() -> new IllegalStateException("Personne declaree decedee non trouvee"));
        Person requester = personRepository.findById(requestedBy)
                .orElseThrow(() -> new IllegalStateException("Demandeur non trouve"));

        String requesterName = requester.getFirstName() + " " + requester.getLastName();
        String deadPersonName = declaredDead.getFirstName() + " " + declaredDead.getLastName();

        // Notification email à B (le déclaré décédé — peut contester si vivant)
        if (declaredDead.getEmail() != null && !declaredDead.getEmail().isBlank()) {
            emailService.sendDissolutionEmail(
                    declaredDead.getEmail(), requesterName,
                    declaredDead.getFirstName(), "DEATH", unionId.toString());
            logReminder(unionId, "INITIAL_EMAIL", "EMAIL", "Email deces envoye a " + declaredDead.getEmail());
        }

        // Notification in-app à B
        if (declaredDead.getUserId() != null) {
            notificationService.create(
                    declaredDead.getUserId(),
                    "DEATH_DECLARATION",
                    "Declaration de deces vous concernant",
                    requesterName + " a declare votre deces. Si c'est une erreur, veuillez contester.",
                    Map.of("unionId", unionId.toString(), "type", "DEATH")
            );
            logReminder(unionId, "INITIAL_INAPP", "IN_APP", "Notification in-app deces envoyee a la personne concernee");
        }

        // Notifier le chef de famille (le parent le plus haut) et les enfants
        notifyFamilyOfDeath(declaredDeadPersonId, deadPersonName, requesterName, unionId);

        log.info("Declaration de deces initiee: union={}, personne={}, par={}", unionId, declaredDeadPersonId, requestedBy);
        return union;
    }

    /**
     * B conteste le décès ("je ne suis pas mort") → DISPUTE → revue manuelle.
     */
    @Transactional
    public GenealogyUnion contestDeath(UUID unionId, UUID contestedBy, String reason) {
        GenealogyUnion union = unionRepository.findById(unionId)
                .orElseThrow(() -> new IllegalArgumentException("Union non trouvee"));

        if (!"DEATH_PENDING".equals(union.getStatus())) {
            throw new IllegalStateException("Cette union n'est pas en attente de validation deces");
        }

        union.setStatus("DISPUTE");
        union.setDisputeReason(reason != null ? reason : "La personne declaree decedee conteste cette declaration");
        unionRepository.save(union);

        logReminder(unionId, "CONTESTED", "SYSTEM", "Deces conteste par " + contestedBy);
        log.info("Deces conteste: union={}, par={}", unionId, contestedBy);
        return union;
    }

    /**
     * Validation admin du décès (après revue manuelle) → union terminée.
     * Le décès n'est JAMAIS auto-validé.
     */
    @Transactional
    public GenealogyUnion adminValidateDeath(UUID unionId, boolean approved) {
        GenealogyUnion union = unionRepository.findById(unionId)
                .orElseThrow(() -> new IllegalArgumentException("Union non trouvee"));

        if (!"DEATH_PENDING".equals(union.getStatus()) && !"DISPUTE".equals(union.getStatus())) {
            throw new IllegalStateException("Cette union n'est pas en attente de validation deces");
        }

        if (approved) {
            union.setStatus("ENDED_DEATH");
            union.setDissolutionConfirmedAt(Instant.now());
            union.setEndDate(java.time.LocalDate.now());
            union.setEndReason(com.gwangmeu.genealogy.domain.enums.EndReasonEnum.DEATH);

            // Marquer la personne comme décédée
            UUID deadPersonId = getSpouseId(union, union.getDissolutionRequestedBy());
            personRepository.findById(deadPersonId).ifPresent(p -> {
                p.setDeathDate(java.time.LocalDate.now());
                personRepository.save(p);
            });

            logReminder(unionId, "ADMIN_VALIDATED", "SYSTEM", "Deces valide par admin");
            log.info("Deces valide par admin: union={}", unionId);
        } else {
            union.setStatus("ACTIVE");
            union.setDissolutionType(null);
            union.setDissolutionDocUrl(null);
            union.setDissolutionRequestedBy(null);
            union.setDissolutionRequestedAt(null);
            union.setDisputeReason(null);

            logReminder(unionId, "ADMIN_REJECTED", "SYSTEM", "Declaration de deces rejetee par admin");
            log.info("Declaration de deces rejetee par admin: union={}", unionId);
        }

        unionRepository.save(union);
        return union;
    }

    /**
     * Résolution admin d'un litige divorce → finalise ou annule.
     */
    @Transactional
    public GenealogyUnion adminResolveDivorceDispute(UUID unionId, boolean approved) {
        GenealogyUnion union = unionRepository.findById(unionId)
                .orElseThrow(() -> new IllegalArgumentException("Union non trouvee"));

        if (!"DISPUTE".equals(union.getStatus()) || !"DIVORCE".equals(union.getDissolutionType())) {
            throw new IllegalStateException("Ce n'est pas un litige de divorce en cours");
        }

        if (approved) {
            finalizeDivorce(union);
            logReminder(unionId, "ADMIN_VALIDATED", "SYSTEM", "Divorce litige valide par admin");
        } else {
            union.setStatus("ACTIVE");
            union.setDissolutionType(null);
            union.setDissolutionDocUrl(null);
            union.setDissolutionRequestedBy(null);
            union.setDissolutionRequestedAt(null);
            union.setDisputeReason(null);
            unionRepository.save(union);
            logReminder(unionId, "ADMIN_REJECTED", "SYSTEM", "Divorce litige rejete par admin");
        }

        log.info("Litige divorce resolu par admin: union={}, approuve={}", unionId, approved);
        return union;
    }

    // ── SCHEDULERS ──────────────────────────────────────────

    /**
     * Exécuté toutes les heures. Gère les rappels automatiques :
     * - Divorce J+10 : SMS de rappel
     * - Divorce J+30 : auto-validation si pas de contestation
     * - Décès J+30 : passage en revue manuelle (notification admin)
     */
    @Scheduled(cron = "0 0 * * * *") // toutes les heures
    @Transactional
    public void processDissolutionReminders() {
        log.debug("Processing dissolution reminders...");

        Instant now = Instant.now();

        // ── Divorce : rappels et auto-validation ──
        List<GenealogyUnion> pendingDivorces = unionRepository.findAll().stream()
                .filter(u -> "DIVORCE_PENDING".equals(u.getStatus()))
                .filter(u -> u.getDissolutionRequestedAt() != null)
                .toList();

        for (GenealogyUnion union : pendingDivorces) {
            long daysSinceRequest = ChronoUnit.DAYS.between(union.getDissolutionRequestedAt(), now);

            // J+10 : SMS de rappel
            if (daysSinceRequest >= 10 && !reminderRepository.existsByUnionIdAndReminderType(union.getId(), "SMS_REMINDER")) {
                sendDivorceSmsReminder(union);
            }

            // J+30 : auto-validation
            if (daysSinceRequest >= 30 && !reminderRepository.existsByUnionIdAndReminderType(union.getId(), "AUTO_VALIDATE")) {
                autoValidateDivorce(union);
            }
        }

        // ── Décès : revue manuelle à J+30, décision admin J+45 ──
        List<GenealogyUnion> pendingDeaths = unionRepository.findAll().stream()
                .filter(u -> "DEATH_PENDING".equals(u.getStatus()))
                .filter(u -> u.getDissolutionRequestedAt() != null)
                .toList();

        for (GenealogyUnion union : pendingDeaths) {
            long daysSinceRequest = ChronoUnit.DAYS.between(union.getDissolutionRequestedAt(), now);

            // J+30 : passage en revue manuelle (notif admin)
            if (daysSinceRequest >= 30 && !reminderRepository.existsByUnionIdAndReminderType(union.getId(), "MANUAL_REVIEW")) {
                flagForManualReview(union, "DEATH");
            }
        }

        // ── Litiges décès : J+30 après contestation → revue manuelle si pas déjà fait
        List<GenealogyUnion> disputedDeaths = unionRepository.findAll().stream()
                .filter(u -> "DISPUTE".equals(u.getStatus()) && "DEATH".equals(u.getDissolutionType()))
                .filter(u -> u.getDissolutionRequestedAt() != null)
                .toList();

        for (GenealogyUnion union : disputedDeaths) {
            long daysSinceRequest = ChronoUnit.DAYS.between(union.getDissolutionRequestedAt(), now);

            // J+30 après la demande initiale → revue manuelle
            if (daysSinceRequest >= 30 && !reminderRepository.existsByUnionIdAndReminderType(union.getId(), "DISPUTE_MANUAL_REVIEW")) {
                flagForManualReview(union, "DEATH_DISPUTE");
            }
        }
    }

    // ── HELPERS ─────────────────────────────────────────────

    private UUID getSpouseId(GenealogyUnion union, UUID onePartyId) {
        if (union.getHusbandId().equals(onePartyId)) {
            return union.getWifeId();
        } else if (union.getWifeId().equals(onePartyId)) {
            return union.getHusbandId();
        }
        throw new IllegalStateException("La personne " + onePartyId + " ne fait pas partie de cette union");
    }

    private void finalizeDivorce(GenealogyUnion union) {
        union.setStatus("DIVORCED");
        union.setDissolutionConfirmedAt(Instant.now());
        union.setEndDate(java.time.LocalDate.now());
        union.setEndReason(com.gwangmeu.genealogy.domain.enums.EndReasonEnum.DIVORCE);
        unionRepository.save(union);
    }

    private void sendDivorceSmsReminder(GenealogyUnion union) {
        UUID spouseId = getSpouseId(union, union.getDissolutionRequestedBy());
        personRepository.findById(spouseId).ifPresent(spouse -> {
            if (spouse.getPhone() != null && !spouse.getPhone().isBlank()) {
                Person requester = personRepository.findById(union.getDissolutionRequestedBy()).orElse(null);
                String requesterName = requester != null
                        ? requester.getFirstName() + " " + requester.getLastName()
                        : "Votre conjoint(e)";

                smsService.sendDissolutionSms(spouse.getPhone(), requesterName,
                        spouse.getFirstName(), "DIVORCE", union.getId().toString());

                logReminder(union.getId(), "SMS_REMINDER", "SMS",
                        "SMS rappel divorce envoye a " + spouse.getPhone());
                log.info("SMS rappel divorce envoye: union={}, tel={}", union.getId(), spouse.getPhone());
            }
        });
    }

    private void autoValidateDivorce(GenealogyUnion union) {
        finalizeDivorce(union);
        logReminder(union.getId(), "AUTO_VALIDATE", "SYSTEM",
                "Divorce auto-valide apres 30 jours sans reponse");
        log.info("Divorce auto-valide: union={}", union.getId());
    }

    private void flagForManualReview(GenealogyUnion union, String context) {
        String reminderType = context.contains("DISPUTE") ? "DISPUTE_MANUAL_REVIEW" : "MANUAL_REVIEW";
        logReminder(union.getId(), reminderType, "SYSTEM",
                "Union " + union.getId() + " necessite une revue manuelle (" + context + ")");
        // TODO: notifier les admins via notification in-app ou email
        log.warn("REVUE MANUELLE REQUISE: union={}, contexte={}", union.getId(), context);
    }

    private void notifyFamilyOfDeath(UUID deadPersonId, String deadPersonName,
                                     String requesterName, UUID unionId) {
        // Notifier les enfants
        List<ParentChild> children = parentChildRepository.findByParentId(deadPersonId);
        for (ParentChild pc : children) {
            personRepository.findById(pc.getChildId()).ifPresent(child -> {
                if (child.getUserId() != null) {
                    notificationService.create(
                            child.getUserId(),
                            "DEATH_FAMILY_NOTICE",
                            "Declaration de deces",
                            requesterName + " a declare le deces de " + deadPersonName + ".",
                            Map.of("unionId", unionId.toString(), "type", "DEATH",
                                    "deceasedPersonId", deadPersonId.toString())
                    );
                }
                if (child.getEmail() != null && !child.getEmail().isBlank()) {
                    emailService.sendDissolutionEmail(
                            child.getEmail(), requesterName,
                            child.getFirstName(), "DEATH_FAMILY", unionId.toString());
                }
            });
        }

        // Notifier les parents (chef de famille potentiel)
        List<ParentChild> parents = parentChildRepository.findByChildId(deadPersonId);
        for (ParentChild pc : parents) {
            personRepository.findById(pc.getParentId()).ifPresent(parent -> {
                if (parent.getUserId() != null) {
                    notificationService.create(
                            parent.getUserId(),
                            "DEATH_FAMILY_NOTICE",
                            "Declaration de deces",
                            requesterName + " a declare le deces de " + deadPersonName + ".",
                            Map.of("unionId", unionId.toString(), "type", "DEATH",
                                    "deceasedPersonId", deadPersonId.toString())
                    );
                }
            });
        }
    }

    private void logReminder(UUID unionId, String type, String channel, String notes) {
        reminderRepository.save(DissolutionReminder.builder()
                .unionId(unionId)
                .reminderType(type)
                .channel(channel)
                .notes(notes)
                .build());
    }
}
