package com.gwangmeu.genealogy.application;

import com.gwangmeu.genealogy.domain.*;
import com.gwangmeu.genealogy.domain.enums.*;
import com.gwangmeu.shared.domain.enums.GenderEnum;
import com.gwangmeu.genealogy.dto.*;
import com.gwangmeu.genealogy.events.ParentChildLinkedEvent;
import com.gwangmeu.genealogy.infrastructure.ParentChildRepository;
import com.gwangmeu.genealogy.infrastructure.PersonInvitationRepository;
import com.gwangmeu.genealogy.infrastructure.PersonRepository;
import com.gwangmeu.genealogy.infrastructure.PersonVillageRepository;
import com.gwangmeu.shared.mail.EmailService;
import com.gwangmeu.shared.mail.SmsService;
import com.gwangmeu.user.User;
import com.gwangmeu.user.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
public class PersonInvitationService {

    private final PersonInvitationRepository invitationRepository;
    private final PersonRepository personRepository;
    private final PersonVillageRepository personVillageRepository;
    private final ParentChildRepository parentChildRepository;
    private final UserRepository userRepository;
    private final EmailService emailService;
    private final SmsService smsService;
    private final ApplicationEventPublisher eventPublisher;

    /**
     * Cree une invitation pour une personne encore vivante.
     * Genere un token unique et envoie le lien par email/SMS.
     */
    public InvitationDTO invitePerson(InvitePersonRequest req, UUID invitedBy) {
        if (req.getEmail() == null && req.getPhone() == null) {
            throw new IllegalArgumentException("Email ou telephone requis pour envoyer l'invitation");
        }

        Person person = personRepository.findById(req.getPersonId())
                .orElseThrow(() -> new IllegalArgumentException("Personne non trouvee: " + req.getPersonId()));

        if (!person.isAlive()) {
            throw new IllegalStateException("Impossible d'inviter une personne decedee");
        }

        if (person.getUserId() != null) {
            throw new IllegalStateException("Cette personne a deja un compte utilisateur");
        }

        // Verifier s'il y a deja une invitation en attente
        if (invitationRepository.existsByPersonIdAndStatus(req.getPersonId(), InvitationStatusEnum.PENDING)) {
            throw new IllegalStateException("Une invitation est deja en attente pour cette personne");
        }

        String token = UUID.randomUUID().toString().replace("-", "");
        String type = req.getInvitationType() != null ? req.getInvitationType() : "PARENT";

        PersonInvitation invitation = PersonInvitation.builder()
                .personId(req.getPersonId())
                .email(req.getEmail())
                .phone(req.getPhone())
                .token(token)
                .invitedBy(invitedBy)
                .invitationType(type)
                .expiresAt(Instant.now().plus(30, ChronoUnit.DAYS))
                .build();

        PersonInvitation saved = invitationRepository.save(invitation);

        // Recuperer le nom de l'inviteur
        String inviterName = userRepository.findById(invitedBy)
                .map(User::getDisplayName)
                .orElse("Un membre");

        String personFullName = person.getFirstName() + " " + person.getLastName();
        log.info("Invitation creee pour {}", personFullName);

        // Envoyer l'email d'invitation, fallback SMS si echec
        boolean emailSent = false;
        if (req.getEmail() != null) {
            emailSent = emailService.sendInvitationEmail(req.getEmail(), inviterName, person.getFirstName(), token);
        }

        // Si pas d'email ou echec email -> envoyer par SMS
        if (!emailSent && req.getPhone() != null) {
            smsService.sendInvitationSms(req.getPhone(), inviterName, person.getFirstName(), token);
            log.info("Fallback SMS envoye a {} (email echoue ou absent)", req.getPhone());
        } else if (req.getPhone() != null) {
            // Email reussi + telephone fourni : envoyer aussi par SMS
            smsService.sendInvitationSms(req.getPhone(), inviterName, person.getFirstName(), token);
        }

        return toDTO(saved, person, invitedBy);
    }

    /**
     * Recupere les details d'une invitation par token (endpoint public).
     * Retourne les infos pre-remplies + le nom de l'inviteur.
     */
    @Transactional(readOnly = true)
    public InvitationDTO getInvitationByToken(String token) {
        PersonInvitation invitation = invitationRepository.findByToken(token)
                .orElseThrow(() -> new IllegalArgumentException("Invitation non trouvee"));

        if (invitation.getStatus() != InvitationStatusEnum.PENDING) {
            throw new IllegalStateException("Cette invitation a deja ete " +
                    (invitation.getStatus() == InvitationStatusEnum.ACCEPTED ? "acceptee" : "expiree"));
        }

        if (invitation.getExpiresAt().isBefore(Instant.now())) {
            invitation.setStatus(InvitationStatusEnum.EXPIRED);
            invitationRepository.save(invitation);
            throw new IllegalStateException("Cette invitation a expire");
        }

        Person person = personRepository.findById(invitation.getPersonId()).orElse(null);
        return toDTO(invitation, person, invitation.getInvitedBy());
    }

    /**
     * Accepte une invitation : met a jour la fiche Person avec les infos corrigees
     * et lie le userId du nouvel utilisateur.
     */
    public InvitationDTO acceptInvitation(String token, AcceptInvitationRequest req,
                                            String supabaseId, String email) {
        PersonInvitation invitation = invitationRepository.findByToken(token)
                .orElseThrow(() -> new IllegalArgumentException("Invitation non trouvee"));

        if (invitation.getStatus() != InvitationStatusEnum.PENDING) {
            throw new IllegalStateException("Cette invitation n'est plus valide");
        }

        if (invitation.getExpiresAt().isBefore(Instant.now())) {
            invitation.setStatus(InvitationStatusEnum.EXPIRED);
            invitationRepository.save(invitation);
            throw new IllegalStateException("Cette invitation a expire");
        }

        Person person = personRepository.findById(invitation.getPersonId())
                .orElseThrow(() -> new IllegalArgumentException("Personne non trouvee"));

        // Mettre a jour les infos corrigees par le parent
        person.setFirstName(req.getFirstName());
        person.setLastName(req.getLastName());
        if (req.getMaidenName() != null) person.setMaidenName(req.getMaidenName());
        if (req.getClan() != null) person.setClan(req.getClan());
        if (req.getTotem() != null) person.setTotem(req.getTotem());
        if (req.getNativeLanguage() != null) person.setNativeLanguage(req.getNativeLanguage());
        if (req.getEmail() != null) person.setEmail(req.getEmail());
        if (req.getPhone() != null) person.setPhone(req.getPhone());
        if (req.getBirthDate() != null) person.setBirthDate(req.getBirthDate());
        if (req.getBirthPlace() != null) person.setBirthPlace(req.getBirthPlace());
        if (req.getReligion() != null) person.setReligion(req.getReligion());
        if (req.getProfession() != null) person.setProfession(req.getProfession());
        if (req.getMaritalStatus() != null) {
            person.setMaritalStatus(MaritalStatusEnum.valueOf(req.getMaritalStatus()));
        }

        // Lier le compte utilisateur : trouver ou creer le User a partir du supabaseId
        if (supabaseId != null) {
            User user = userRepository.findBySupabaseId(supabaseId)
                    .orElseGet(() -> {
                        log.info("Creation auto du User pour supabaseId={} email={}", supabaseId, email);
                        return userRepository.save(User.builder()
                                .supabaseId(supabaseId)
                                .email(email != null ? email : person.getEmail())
                                .displayName(person.getFirstName() + " " + person.getLastName())
                                .build());
                    });
            // Verifier que ce userId n'est pas deja lie a une autre Person
            var existingPerson = personRepository.findByUserId(user.getId());
            if (existingPerson.isPresent() && !existingPerson.get().getId().equals(person.getId())) {
                log.warn("userId {} deja lie a une autre personne — lien compte ignore", user.getId());
            } else {
                person.setUserId(user.getId());
            }
        }
        person.setStatus(PersonStatusEnum.CONFIRMED);
        personRepository.save(person);

        // Creer le lien parent-enfant uniquement pour les invitations de type PARENT
        // Pour les invitations SPOUSE, l'union existe deja
        if ("PARENT".equals(invitation.getInvitationType())) {
            createParentChildLinkFromInvitation(person, invitation);
        } else {
            log.info("Invitation SPOUSE acceptee: pas de lien parent-enfant a creer (person={})", person.getId());
        }

        // Mettre a jour l'invitation
        invitation.setStatus(InvitationStatusEnum.ACCEPTED);
        invitation.setAcceptedAt(Instant.now());
        invitation.setKnowsInviter(req.getKnowsInviter());
        invitationRepository.save(invitation);

        log.info("Invitation acceptee: person={}, supabaseId={}, knowsInviter={}",
                person.getId(), supabaseId, req.getKnowsInviter());

        return toDTO(invitation, person, invitation.getInvitedBy());
    }

    /**
     * Cree le lien parent_child entre la personne invitee (parent) et l'inviteur (enfant).
     * L'inviteur a cree la fiche Person pour son parent, donc :
     * - parent = la Person de l'invitation (person)
     * - enfant = la Person liee au userId de l'inviteur (invited_by)
     */
    private void createParentChildLinkFromInvitation(Person parent, PersonInvitation invitation) {
        // Trouver la Person de l'inviteur (celui qui a envoye l'invitation)
        UUID inviterUserId = invitation.getInvitedBy();
        if (inviterUserId == null) return;

        // L'inviteur est un User, chercher sa Person
        Person inviterPerson = personRepository.findByUserId(inviterUserId).orElse(null);
        if (inviterPerson == null) {
            log.warn("Inviteur userId={} n'a pas de fiche Person, impossible de creer le lien parent-enfant",
                    inviterUserId);
            return;
        }

        // Verifier si le lien existe deja
        if (parentChildRepository.existsByParentIdAndChildId(parent.getId(), inviterPerson.getId())) {
            log.info("Lien parent-enfant deja existant: parent={} -> enfant={}", parent.getId(), inviterPerson.getId());
            return;
        }

        // Determiner le role parental selon le genre du parent
        ParentRoleEnum role = parent.getGender() == GenderEnum.FEMALE
                ? ParentRoleEnum.MOTHER : ParentRoleEnum.FATHER;

        // Verifier qu'il n'y a pas deja un parent biologique de ce role
        boolean hasExistingBioParent = parentChildRepository.findByChildId(inviterPerson.getId()).stream()
                .anyMatch(pc -> pc.getParentRole() == role && pc.getParentType() == ParentTypeEnum.BIOLOGICAL);
        if (hasExistingBioParent) {
            log.warn("L'enfant {} a deja un {} biologique, lien non cree", inviterPerson.getId(), role);
            return;
        }

        ParentChild link = ParentChild.builder()
                .parentId(parent.getId())
                .childId(inviterPerson.getId())
                .parentRole(role)
                .parentType(ParentTypeEnum.BIOLOGICAL)
                .source(RelationSourceEnum.DECLARED)
                .createdBy(inviterUserId)
                .build();

        parentChildRepository.save(link);
        log.info("Lien parent-enfant cree via invitation: parent={} ({}) -> enfant={} ({})",
                parent.getFirstName(), parent.getId(),
                inviterPerson.getFirstName(), inviterPerson.getId());

        // Emettre l'evenement pour la sync Neo4j
        eventPublisher.publishEvent(new ParentChildLinkedEvent(
                parent.getId(), inviterPerson.getId(), role, ParentTypeEnum.BIOLOGICAL,
                RelationSourceEnum.DECLARED));
    }

    private InvitationDTO toDTO(PersonInvitation inv, Person person, UUID invitedById) {
        String inviterName = null;
        if (invitedById != null) {
            inviterName = userRepository.findById(invitedById)
                    .map(User::getDisplayName)
                    .orElse(null);
        }

        List<UUID> villageIds = person != null
                ? personVillageRepository.findVillageIdsByPersonId(person.getId())
                : List.of();

        return InvitationDTO.builder()
                .id(inv.getId())
                .personId(inv.getPersonId())
                .email(inv.getEmail())
                .phone(inv.getPhone())
                .token(inv.getToken())
                .status(inv.getStatus().name())
                .invitedBy(inv.getInvitedBy())
                .inviterName(inviterName)
                .invitationType(inv.getInvitationType())
                .person(person != null ? GenealogyMapper.toDTO(person, villageIds) : null)
                .createdAt(inv.getCreatedAt())
                .expiresAt(inv.getExpiresAt())
                .build();
    }
}
