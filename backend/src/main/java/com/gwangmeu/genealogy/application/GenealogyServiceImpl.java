package com.gwangmeu.genealogy.application;

import com.gwangmeu.genealogy.domain.*;
import com.gwangmeu.genealogy.domain.enums.*;
import com.gwangmeu.shared.domain.enums.GenderEnum;
import com.gwangmeu.genealogy.dto.*;
import com.gwangmeu.genealogy.events.*;
import com.gwangmeu.genealogy.infrastructure.*;
import com.gwangmeu.genealogy.neo4j.PersonNode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
class GenealogyServiceImpl implements GenealogyService {

    private final PersonRepository personRepository;
    private final PersonVillageRepository personVillageRepository;
    private final ParentChildRepository parentChildRepository;
    private final UnionRepository unionRepository;
    private final ChildAssociationRequestRepository childAssociationRequestRepository;
    private final PersonModificationRequestRepository personModificationRequestRepository;
    private final AiGenealogySuggestionRepository aiSuggestionRepository;
    private final PersonNodeRepository personNodeRepository;
    private final ApplicationEventPublisher eventPublisher;
    private final GenealogyAiService genealogyAiService;

    // ── PERSONS ────────────────────────────────────────────

    @Override
    public PersonDTO createPerson(CreatePersonRequest req, UUID createdBy) {
        Person person = Person.builder()
                .firstName(req.getFirstName())
                .lastName(req.getLastName())
                .maidenName(req.getMaidenName())
                .gender(req.getGender())
                .birthDate(req.getBirthDate())
                .birthPlace(req.getBirthPlace())
                .clan(req.getClan())
                .totem(req.getTotem())
                .nativeLanguage(req.getNativeLanguage())
                .email(req.getEmail())
                .phone(req.getPhone())
                .religion(req.getReligion())
                .profession(req.getProfession())
                .deathDate(req.getDeathDate())
                .biography(req.getBiography())
                .privacy(req.getPrivacy() != null ? req.getPrivacy() : PrivacyEnum.FAMILY_ONLY)
                .createdBy(createdBy)
                .build();

        Person saved = personRepository.save(person);

        List<UUID> villageIds = req.getVillageIds() != null ? req.getVillageIds() : List.of();
        savePersonVillages(saved.getId(), villageIds);

        log.info("Person created: {} {} (id={})", saved.getFirstName(), saved.getLastName(), saved.getId());

        eventPublisher.publishEvent(new PersonCreatedEvent(saved.getId(), villageIds, createdBy));
        return GenealogyMapper.toDTO(saved, villageIds);
    }

    @Override
    public PersonDTO updatePerson(UUID personId, UpdatePersonRequest req, UUID requestedBy) {
        Person person = findPersonOrThrow(personId);

        // Seul le createur ou la personne elle-meme peut modifier la fiche
        boolean isCreator = person.getCreatedBy().equals(requestedBy);
        boolean isOwner = requestedBy.equals(person.getUserId());
        if (!isCreator && !isOwner) {
            throw new IllegalStateException("Vous n'etes pas autorise a modifier cette fiche");
        }

        if (req.getFirstName() != null) person.setFirstName(req.getFirstName());
        if (req.getLastName() != null) person.setLastName(req.getLastName());
        if (req.getMaidenName() != null) person.setMaidenName(req.getMaidenName());
        if (req.getBirthDate() != null) person.setBirthDate(req.getBirthDate());
        if (req.getBirthPlace() != null) person.setBirthPlace(req.getBirthPlace());
        if (req.getDeathDate() != null) person.setDeathDate(req.getDeathDate());
        if (req.getClan() != null) person.setClan(req.getClan());
        if (req.getTotem() != null) person.setTotem(req.getTotem());
        if (req.getNativeLanguage() != null) person.setNativeLanguage(req.getNativeLanguage());
        if (req.getReligion() != null) person.setReligion(req.getReligion());
        if (req.getProfession() != null) person.setProfession(req.getProfession());
        if (req.getBiography() != null) person.setBiography(req.getBiography());
        if (req.getPhotoUrl() != null) person.setPhotoUrl(req.getPhotoUrl());
        if (req.getPrivacy() != null) person.setPrivacy(req.getPrivacy());

        if (req.getVillageIds() != null) {
            validateAncestorVillages(personId, req.getVillageIds());
            personVillageRepository.deleteByPersonId(personId);
            savePersonVillages(personId, req.getVillageIds());
        }

        Person saved = personRepository.save(person);
        List<UUID> villageIds = personVillageRepository.findVillageIdsByPersonId(personId);
        eventPublisher.publishEvent(new PersonUpdatedEvent(saved.getId(), villageIds));
        return GenealogyMapper.toDTO(saved, villageIds);
    }

    @Override
    @Transactional(readOnly = true)
    public PersonDTO getPersonById(UUID personId) {
        Person person = findPersonOrThrow(personId);
        List<UUID> villageIds = personVillageRepository.findVillageIdsByPersonId(personId);
        return GenealogyMapper.toDTO(person, villageIds);
    }

    @Override
    @Transactional(readOnly = true)
    public PersonDTO getMyPerson(UUID userId) {
        Person person = personRepository.findByUserId(userId)
                .orElseThrow(() -> new IllegalArgumentException("Aucune fiche personne liee a cet utilisateur"));
        List<UUID> villageIds = personVillageRepository.findVillageIdsByPersonId(person.getId());
        return GenealogyMapper.toDTO(person, villageIds);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<PersonDTO> getPersonsByVillage(UUID villageId, Pageable pageable) {
        return personRepository.findByVillageIdAndStatus(villageId, PersonStatusEnum.CONFIRMED, pageable)
                .map(p -> {
                    List<UUID> vIds = personVillageRepository.findVillageIdsByPersonId(p.getId());
                    return GenealogyMapper.toDTO(p, vIds);
                });
    }

    @Override
    public void deletePerson(UUID personId, UUID requestedBy) {
        Person person = findPersonOrThrow(personId);
        if (!person.getCreatedBy().equals(requestedBy)) {
            throw new IllegalStateException("Only the creator can delete this person");
        }
        personRepository.delete(person);
        log.info("Person deleted: {} (by {})", personId, requestedBy);

        eventPublisher.publishEvent(new PersonDeletedEvent(personId));
    }

    // ── FILIATION ──────────────────────────────────────────

    @Override
    public ParentChildDTO linkParentChild(UUID parentId, UUID childId, ParentRoleEnum role,
                                           ParentTypeEnum type, UUID createdBy) {
        findPersonOrThrow(parentId);
        findPersonOrThrow(childId);

        ParentTypeEnum resolvedType = type != null ? type : ParentTypeEnum.BIOLOGICAL;

        if (resolvedType == ParentTypeEnum.BIOLOGICAL) {
            parentChildRepository.findByChildId(childId).stream()
                    .filter(pc -> pc.getParentRole() == role && pc.getParentType() == ParentTypeEnum.BIOLOGICAL)
                    .findFirst()
                    .ifPresent(existing -> {
                        throw new IllegalStateException(
                                "Child already has a biological " + role + " (parent_id=" + existing.getParentId() + ")");
                    });
        }

        // Idempotent : si le lien existe deja, retourner le lien existant
        var existingLink = parentChildRepository.findByChildId(childId).stream()
                .filter(pc -> pc.getParentId().equals(parentId))
                .findFirst();
        if (existingLink.isPresent()) {
            log.info("Parent-child link already exists: parent={}, child={} — returning existing", parentId, childId);
            return GenealogyMapper.toDTO(existingLink.get());
        }

        ParentChild link = ParentChild.builder()
                .parentId(parentId)
                .childId(childId)
                .parentRole(role)
                .parentType(resolvedType)
                .source(RelationSourceEnum.DECLARED)
                .createdBy(createdBy)
                .build();

        ParentChild saved = parentChildRepository.save(link);
        log.info("Parent-child link created: {} -> {} (role={})", parentId, childId, role);

        eventPublisher.publishEvent(new ParentChildLinkedEvent(parentId, childId, role, resolvedType, RelationSourceEnum.DECLARED));
        return GenealogyMapper.toDTO(saved);
    }

    @Override
    public PersonDTO createChild(UUID parentId, CreateChildRequest req, UUID createdBy) {
        Person parent = findPersonOrThrow(parentId);

        Person child;

        // Si l'utilisateur a confirme un doublon, utiliser la personne existante
        if (req.getExistingPersonId() != null) {
            child = findPersonOrThrow(req.getExistingPersonId());
            if (parentChildRepository.existsByParentIdAndChildId(parentId, child.getId())) {
                log.info("Enfant deja lie: parent={}, child={} — retour existant", parentId, child.getId());
                List<UUID> villageIds = personVillageRepository.findVillageIdsByPersonId(child.getId());
                return GenealogyMapper.toDTO(child, villageIds);
            }
            log.info("Utilisation personne existante confirmee par l'utilisateur (person={})", child.getId());
        } else {
            // Deduplication automatique : chercher si une personne identique existe deja
            Person existingPerson = findDuplicate(req);
            if (existingPerson != null) {
                if (parentChildRepository.existsByParentIdAndChildId(parentId, existingPerson.getId())) {
                    log.info("Enfant deja lie: parent={}, child={} — retour existant", parentId, existingPerson.getId());
                    List<UUID> villageIds = personVillageRepository.findVillageIdsByPersonId(existingPerson.getId());
                    return GenealogyMapper.toDTO(existingPerson, villageIds);
                }
                child = existingPerson;
                log.info("Doublon detecte (person={}), creation du lien uniquement", child.getId());
            } else {
                // Creer la personne
                child = Person.builder()
                        .firstName(req.getFirstName())
                        .lastName(req.getLastName())
                        .gender(req.getGender())
                        .birthDate(req.getBirthDate())
                        .clan(req.getClan())
                        .email(req.getEmail())
                        .createdBy(createdBy)
                        .build();
                child = personRepository.save(child);
                log.info("Enfant cree: {} {} (id={})", child.getFirstName(), child.getLastName(), child.getId());
                eventPublisher.publishEvent(new PersonCreatedEvent(child.getId(), List.of(), createdBy));
            }
        }

        // Creer le lien parent-enfant atomiquement
        ParentRoleEnum role = parent.getGender() == GenderEnum.FEMALE
                ? ParentRoleEnum.MOTHER : ParentRoleEnum.FATHER;
        ParentTypeEnum type = req.getParentType() != null ? req.getParentType() : ParentTypeEnum.BIOLOGICAL;

        ParentChild link = ParentChild.builder()
                .parentId(parentId)
                .childId(child.getId())
                .parentRole(role)
                .parentType(type)
                .source(RelationSourceEnum.DECLARED)
                .createdBy(createdBy)
                .build();
        parentChildRepository.save(link);
        log.info("Lien parent-enfant cree: {} -> {} (role={})", parentId, child.getId(), role);

        eventPublisher.publishEvent(new ParentChildLinkedEvent(
                parentId, child.getId(), role, type, RelationSourceEnum.DECLARED));

        // Si un co-parent est specifie, creer une demande d'association
        if (req.getCoParentPersonId() != null) {
            Person coParent = findPersonOrThrow(req.getCoParentPersonId());

            // Verifier qu'il n'y a pas deja une demande ou un lien existant
            if (!parentChildRepository.existsByParentIdAndChildId(coParent.getId(), child.getId())
                    && childAssociationRequestRepository.findByChildIdAndTargetParentId(child.getId(), coParent.getId()).isEmpty()) {

                ChildAssociationRequest request = ChildAssociationRequest.builder()
                        .childId(child.getId())
                        .requesterId(parentId)
                        .targetParentId(coParent.getId())
                        .build();
                childAssociationRequestRepository.save(request);
                log.info("Demande d'association enfant creee: child={}, requester={}, target={}",
                        child.getId(), parentId, coParent.getId());

                eventPublisher.publishEvent(new ChildAssociationRequestedEvent(
                        request.getId(), child.getId(), parentId, coParent.getId()));
            }
        }

        List<UUID> villageIds = personVillageRepository.findVillageIdsByPersonId(child.getId());
        return GenealogyMapper.toDTO(child, villageIds);
    }

    @Override
    public List<PersonDTO> checkDuplicate(DuplicateCheckRequest req) {
        List<Person> candidates = new ArrayList<>();

        // Chercher par email d'abord (plus discriminant)
        if (req.getEmail() != null && !req.getEmail().isBlank()) {
            personRepository.findByEmailIgnoreCase(req.getEmail().trim())
                    .ifPresent(candidates::add);
        }

        // Chercher par nom + prenom + date naissance + genre
        if (req.getBirthDate() != null) {
            List<Person> byNameAndBirth = personRepository.findByNameBirthDateAndGender(
                    req.getFirstName().trim(), req.getLastName().trim(),
                    req.getBirthDate(), req.getGender());
            for (Person p : byNameAndBirth) {
                if (candidates.stream().noneMatch(c -> c.getId().equals(p.getId()))) {
                    candidates.add(p);
                }
            }
        }

        return candidates.stream()
                .map(p -> GenealogyMapper.toDTO(p, personVillageRepository.findVillageIdsByPersonId(p.getId())))
                .toList();
    }

    // ── ASSOCIATION ENFANT CO-PARENT ──────────────────────────

    @Override
    public void acceptChildAssociation(UUID requestId, UUID responderId) {
        ChildAssociationRequest request = childAssociationRequestRepository.findById(requestId)
                .orElseThrow(() -> new IllegalArgumentException("Demande d'association non trouvee"));

        if (request.getStatus() != AssociationRequestStatus.PENDING) {
            throw new IllegalStateException("Cette demande a deja ete traitee");
        }

        Person targetParent = findPersonOrThrow(request.getTargetParentId());
        if (targetParent.getUserId() == null || !targetParent.getUserId().equals(responderId)) {
            throw new SecurityException("Vous n'etes pas autorise a repondre a cette demande");
        }

        // Creer le lien parent-enfant pour le co-parent
        Person child = findPersonOrThrow(request.getChildId());
        ParentRoleEnum role = targetParent.getGender() == GenderEnum.FEMALE
                ? ParentRoleEnum.MOTHER : ParentRoleEnum.FATHER;

        if (!parentChildRepository.existsByParentIdAndChildId(targetParent.getId(), child.getId())) {
            ParentChild link = ParentChild.builder()
                    .parentId(targetParent.getId())
                    .childId(child.getId())
                    .parentRole(role)
                    .parentType(ParentTypeEnum.BIOLOGICAL)
                    .source(RelationSourceEnum.DECLARED)
                    .createdBy(responderId)
                    .build();
            parentChildRepository.save(link);
            log.info("Lien co-parent cree apres validation: {} -> {} (role={})",
                    targetParent.getId(), child.getId(), role);

            eventPublisher.publishEvent(new ParentChildLinkedEvent(
                    targetParent.getId(), child.getId(), role, ParentTypeEnum.BIOLOGICAL, RelationSourceEnum.DECLARED));
        }

        request.setStatus(AssociationRequestStatus.ACCEPTED);
        request.setRespondedAt(Instant.now());
        childAssociationRequestRepository.save(request);

        eventPublisher.publishEvent(new ChildAssociationRespondedEvent(
                requestId, request.getChildId(), request.getRequesterId(), targetParent.getId(), true));
    }

    @Override
    public void rejectChildAssociation(UUID requestId, UUID responderId) {
        ChildAssociationRequest request = childAssociationRequestRepository.findById(requestId)
                .orElseThrow(() -> new IllegalArgumentException("Demande d'association non trouvee"));

        if (request.getStatus() != AssociationRequestStatus.PENDING) {
            throw new IllegalStateException("Cette demande a deja ete traitee");
        }

        Person targetParent = findPersonOrThrow(request.getTargetParentId());
        if (targetParent.getUserId() == null || !targetParent.getUserId().equals(responderId)) {
            throw new SecurityException("Vous n'etes pas autorise a repondre a cette demande");
        }

        request.setStatus(AssociationRequestStatus.REJECTED);
        request.setRespondedAt(Instant.now());
        childAssociationRequestRepository.save(request);
        log.info("Demande d'association refusee: requestId={}", requestId);

        eventPublisher.publishEvent(new ChildAssociationRespondedEvent(
                requestId, request.getChildId(), request.getRequesterId(), targetParent.getId(), false));
    }

    // ── MODIFICATION FICHE ENFANT (< 4 ANS) ──────────────────

    @Override
    public void requestChildModification(UUID personId, java.util.Map<String, Object> changes, UUID requestedBy) {
        Person child = findPersonOrThrow(personId);

        // Verifier que l'enfant a moins de 4 ans
        if (child.getBirthDate() == null) {
            throw new IllegalStateException("La date de naissance de l'enfant n'est pas renseignee");
        }
        int age = java.time.Period.between(child.getBirthDate(), LocalDate.now()).getYears();
        if (age >= 4) {
            throw new IllegalStateException("L'enfant a 4 ans ou plus. La modification doit se faire depuis son propre compte.");
        }

        // Trouver la fiche personne du demandeur
        Person requester = personRepository.findByUserId(requestedBy)
                .orElseThrow(() -> new IllegalArgumentException("Personne non trouvee pour cet utilisateur"));

        // Verifier que le demandeur est un parent de l'enfant
        List<ParentChild> parentLinks = parentChildRepository.findByChildId(personId);
        boolean isParent = parentLinks.stream().anyMatch(pc -> pc.getParentId().equals(requester.getId()));
        if (!isParent) {
            throw new SecurityException("Vous n'etes pas un parent de cet enfant");
        }

        // Trouver l'autre parent
        UUID otherParentId = parentLinks.stream()
                .map(ParentChild::getParentId)
                .filter(pid -> !pid.equals(requester.getId()))
                .findFirst()
                .orElse(null);

        // Si pas d'autre parent, appliquer directement
        if (otherParentId == null) {
            applyModificationChanges(child, changes);
            personRepository.save(child);
            log.info("Modification directe appliquee pour enfant {} (pas d'autre parent)", personId);
            return;
        }

        // Creer la demande de modification
        PersonModificationRequest request = PersonModificationRequest.builder()
                .personId(personId)
                .requesterId(requester.getId())
                .changes(changes)
                .build();
        PersonModificationRequest saved = personModificationRequestRepository.save(request);

        log.info("Demande de modification creee: requestId={}, personId={}, requesterId={}",
                saved.getId(), personId, requester.getId());

        eventPublisher.publishEvent(new PersonModificationRequestedEvent(
                saved.getId(), personId, requester.getId(), otherParentId));
    }

    @Override
    public void acceptModificationRequest(UUID requestId, UUID responderId) {
        PersonModificationRequest request = personModificationRequestRepository.findById(requestId)
                .orElseThrow(() -> new IllegalArgumentException("Demande de modification non trouvee"));

        if (request.getStatus() != AssociationRequestStatus.PENDING) {
            throw new IllegalStateException("Cette demande a deja ete traitee");
        }

        // Verifier que le repondeur est un parent de l'enfant
        Person responder = personRepository.findByUserId(responderId)
                .orElseThrow(() -> new IllegalArgumentException("Personne non trouvee pour cet utilisateur"));

        List<ParentChild> parentLinks = parentChildRepository.findByChildId(request.getPersonId());
        boolean isParent = parentLinks.stream().anyMatch(pc -> pc.getParentId().equals(responder.getId()));
        if (!isParent) {
            throw new SecurityException("Vous n'etes pas un parent de cet enfant");
        }

        // Appliquer les modifications
        Person child = findPersonOrThrow(request.getPersonId());
        applyModificationChanges(child, request.getChanges());
        personRepository.save(child);

        request.setStatus(AssociationRequestStatus.ACCEPTED);
        request.setRespondedAt(Instant.now());
        request.setResponderId(responder.getId());
        personModificationRequestRepository.save(request);

        log.info("Modification acceptee: requestId={}, personId={}", requestId, request.getPersonId());

        List<UUID> villageIds = personVillageRepository.findVillageIdsByPersonId(child.getId());
        eventPublisher.publishEvent(new PersonUpdatedEvent(child.getId(), villageIds));
        eventPublisher.publishEvent(new PersonModificationRespondedEvent(
                requestId, request.getPersonId(), request.getRequesterId(), responder.getId(), true));
    }

    @Override
    public void rejectModificationRequest(UUID requestId, UUID responderId) {
        PersonModificationRequest request = personModificationRequestRepository.findById(requestId)
                .orElseThrow(() -> new IllegalArgumentException("Demande de modification non trouvee"));

        if (request.getStatus() != AssociationRequestStatus.PENDING) {
            throw new IllegalStateException("Cette demande a deja ete traitee");
        }

        Person responder = personRepository.findByUserId(responderId)
                .orElseThrow(() -> new IllegalArgumentException("Personne non trouvee pour cet utilisateur"));

        List<ParentChild> parentLinks = parentChildRepository.findByChildId(request.getPersonId());
        boolean isParent = parentLinks.stream().anyMatch(pc -> pc.getParentId().equals(responder.getId()));
        if (!isParent) {
            throw new SecurityException("Vous n'etes pas un parent de cet enfant");
        }

        request.setStatus(AssociationRequestStatus.REJECTED);
        request.setRespondedAt(Instant.now());
        request.setResponderId(responder.getId());
        personModificationRequestRepository.save(request);

        log.info("Modification refusee: requestId={}", requestId);

        eventPublisher.publishEvent(new PersonModificationRespondedEvent(
                requestId, request.getPersonId(), request.getRequesterId(), responder.getId(), false));
    }

    private void applyModificationChanges(Person person, java.util.Map<String, Object> changes) {
        if (changes.containsKey("firstName")) person.setFirstName((String) changes.get("firstName"));
        if (changes.containsKey("lastName")) person.setLastName((String) changes.get("lastName"));
        if (changes.containsKey("birthPlace")) person.setBirthPlace((String) changes.get("birthPlace"));
        if (changes.containsKey("clan")) person.setClan((String) changes.get("clan"));
        if (changes.containsKey("totem")) person.setTotem((String) changes.get("totem"));
        if (changes.containsKey("birthDate") && changes.get("birthDate") != null) {
            person.setBirthDate(LocalDate.parse((String) changes.get("birthDate")));
        }
    }

    /**
     * Recherche un doublon base sur: email OU (prenom + nom + date naissance + genre).
     * Retourne null si aucun doublon trouve.
     */
    private Person findDuplicate(CreateChildRequest req) {
        // Chercher par email d'abord (plus discriminant)
        if (req.getEmail() != null && !req.getEmail().isBlank()) {
            var byEmail = personRepository.findByEmailIgnoreCase(req.getEmail().trim());
            if (byEmail.isPresent()) return byEmail.get();
        }

        // Chercher par nom + prenom + date naissance + genre
        if (req.getBirthDate() != null) {
            List<Person> candidates = personRepository.findByNameBirthDateAndGender(
                    req.getFirstName().trim(), req.getLastName().trim(),
                    req.getBirthDate(), req.getGender());
            if (candidates.size() == 1) return candidates.get(0);
        }

        return null;
    }

    @Override
    public void unlinkParentChild(UUID parentId, UUID childId, UUID requestedBy) {
        parentChildRepository.findByChildId(childId).stream()
                .filter(pc -> pc.getParentId().equals(parentId))
                .findFirst()
                .ifPresent(pc -> {
                    parentChildRepository.delete(pc);
                    log.info("Parent-child link removed: {} -> {}", parentId, childId);

                    eventPublisher.publishEvent(new ParentChildUnlinkedEvent(parentId, childId));
                });
    }

    // ── UNIONS ─────────────────────────────────────────────

    @Override
    public UnionDTO createUnion(CreateUnionRequest req, UUID createdBy) {
        Person husband = findPersonOrThrow(req.getHusbandId());
        Person wife = findPersonOrThrow(req.getWifeId());

        if (husband.getGender() != GenderEnum.MALE) {
            throw new IllegalStateException("Husband must be MALE");
        }

        // Validation monogamie civile — vérifier les 2 côtés
        validateNoActiveCivilUnion(req.getHusbandId(), husband.getFirstName() + " " + husband.getLastName());
        validateNoActiveCivilUnion(req.getWifeId(), wife.getFirstName() + " " + wife.getLastName());

        // Si la nouvelle union contient CIVIL, vérifier qu'aucune union active n'existe
        if (req.getUnionTypes().contains("CIVIL")) {
            List<GenealogyUnion> husbandActive = unionRepository.findActiveUnionsByPerson(req.getHusbandId());
            if (!husbandActive.isEmpty()) {
                throw new IllegalStateException(
                        "Impossible d'ajouter un mariage civil : " + husband.getFirstName() + " " + husband.getLastName()
                                + " a deja une union active. Le mariage civil impose la monogamie.");
            }
            List<GenealogyUnion> wifeActive = unionRepository.findActiveUnionsByPerson(req.getWifeId());
            if (!wifeActive.isEmpty()) {
                throw new IllegalStateException(
                        "Impossible d'ajouter un mariage civil : " + wife.getFirstName() + " " + wife.getLastName()
                                + " a deja une union active. Le mariage civil impose la monogamie.");
            }
        }

        int nextOrder = unionRepository.findMaxUnionOrderByHusband(req.getHusbandId()) + 1;

        GenealogyUnion union = GenealogyUnion.builder()
                .husbandId(req.getHusbandId())
                .wifeId(req.getWifeId())
                .unionTypes(req.getUnionTypes().toArray(new String[0]))
                .unionOrder(nextOrder)
                .startDate(req.getStartDate())
                .isDotPaid(req.isDotPaid())
                .dotDate(req.getDotDate())
                .dotPaidBy(req.getDotPaidBy())
                .dotDescription(req.getDotDescription())
                .dotWitnesses(req.getDotWitnesses() != null ? req.getDotWitnesses().toArray(new UUID[0]) : null)
                .status("PENDING_APPROVAL")
                .createdBy(createdBy)
                .build();

        GenealogyUnion saved = unionRepository.save(union);
        log.info("Union created: {} <-> {} (types={}, order={})", req.getHusbandId(), req.getWifeId(),
                req.getUnionTypes(), nextOrder);

        eventPublisher.publishEvent(new UnionCreatedEvent(req.getHusbandId(), req.getWifeId(),
                saved.getId(), saved.isDotPaid()));
        return GenealogyMapper.toDTO(saved, husband, wife);
    }

    @Override
    public UnionDTO confirmUnion(UUID unionId, UUID confirmedBy) {
        GenealogyUnion union = unionRepository.findById(unionId)
                .orElseThrow(() -> new IllegalArgumentException("Union not found: " + unionId));

        if (!"PENDING_APPROVAL".equals(union.getStatus())) {
            throw new IllegalStateException("Cette union n'est pas en attente de validation (statut actuel: " + union.getStatus() + ")");
        }

        // Vérifier que c'est bien le conjoint qui confirme (pas celui qui a créé)
        Person husband = findPersonOrThrow(union.getHusbandId());
        Person wife = findPersonOrThrow(union.getWifeId());
        UUID husbandUserId = husband.getUserId();
        UUID wifeUserId = wife.getUserId();

        if (!confirmedBy.equals(husbandUserId) && !confirmedBy.equals(wifeUserId)) {
            throw new IllegalStateException("Seul un des conjoints peut confirmer cette union.");
        }
        if (confirmedBy.equals(union.getCreatedBy())) {
            throw new IllegalStateException("Vous ne pouvez pas confirmer une union que vous avez vous-meme creee. Seul votre conjoint peut la valider.");
        }

        union.setStatus("ACTIVE");
        GenealogyUnion saved = unionRepository.save(union);
        log.info("Union confirmed: unionId={}, confirmedBy={}", unionId, confirmedBy);

        return GenealogyMapper.toDTO(saved, husband, wife);
    }

    @Override
    public UnionDTO contestUnion(UUID unionId, UUID contestedBy, String reason) {
        GenealogyUnion union = unionRepository.findById(unionId)
                .orElseThrow(() -> new IllegalArgumentException("Union not found: " + unionId));

        if (!"PENDING_APPROVAL".equals(union.getStatus())) {
            throw new IllegalStateException("Cette union n'est pas en attente de validation (statut actuel: " + union.getStatus() + ")");
        }

        Person husband = findPersonOrThrow(union.getHusbandId());
        Person wife = findPersonOrThrow(union.getWifeId());

        union.setStatus("REJECTED");
        union.setDisputeReason(reason != null ? reason : "Union contestee sans motif precis");
        GenealogyUnion saved = unionRepository.save(union);
        log.info("Union contested: unionId={}, contestedBy={}, reason={}", unionId, contestedBy, reason);

        return GenealogyMapper.toDTO(saved, husband, wife);
    }

    @Override
    public UnionDTO updateDotStatus(UUID unionId, UpdateDotRequest req, UUID requestedBy) {
        GenealogyUnion union = unionRepository.findById(unionId)
                .orElseThrow(() -> new IllegalArgumentException("Union not found: " + unionId));

        union.setDotPaid(req.isDotPaid());
        if (req.getDotDate() != null) union.setDotDate(req.getDotDate());
        if (req.getDotPaidBy() != null) union.setDotPaidBy(req.getDotPaidBy());
        if (req.getDotDescription() != null) union.setDotDescription(req.getDotDescription());

        GenealogyUnion saved = unionRepository.save(union);

        if (req.isDotPaid()) {
            eventPublisher.publishEvent(new UnionDotPaidEvent(unionId, union.getHusbandId(),
                    union.getWifeId(), req.getDotPaidBy()));
        }

        Person husband = findPersonOrThrow(union.getHusbandId());
        Person wife = findPersonOrThrow(union.getWifeId());
        return GenealogyMapper.toDTO(saved, husband, wife);
    }

    @Override
    public void endUnion(UUID unionId, EndUnionRequest req, UUID requestedBy) {
        GenealogyUnion union = unionRepository.findById(unionId)
                .orElseThrow(() -> new IllegalArgumentException("Union not found: " + unionId));

        union.setEndDate(req.getEndDate() != null ? req.getEndDate() : LocalDate.now());
        union.setEndReason(req.getEndReason());
        unionRepository.save(union);
        log.info("Union ended: {} (reason={})", unionId, req.getEndReason());

        eventPublisher.publishEvent(new UnionEndedEvent(unionId, union.getHusbandId(), union.getWifeId()));
    }

    @Override
    @Transactional(readOnly = true)
    public List<UnionDTO> getUnionsByPerson(UUID personId) {
        return unionRepository.findByPersonId(personId).stream()
                .map(u -> {
                    Person h = personRepository.findById(u.getHusbandId()).orElse(null);
                    Person w = personRepository.findById(u.getWifeId()).orElse(null);
                    return GenealogyMapper.toDTO(u, h, w);
                })
                .collect(Collectors.toList());
    }

    // ── ARBRE (Neo4j avec fallback PostgreSQL) ─────────────

    @Override
    @Transactional(readOnly = true)
    public FamilyTreeDTO getFullTree(UUID personId) {
        Person person = findPersonOrThrow(personId);
        List<UUID> villageIds = personVillageRepository.findVillageIdsByPersonId(personId);

        List<PersonDTO> parents = getParents(personId);
        List<PersonDTO> father = parents.stream().filter(p -> p.getGender() == GenderEnum.MALE).toList();
        List<PersonDTO> mother = parents.stream().filter(p -> p.getGender() == GenderEnum.FEMALE).toList();

        List<PersonDTO> paternalGP = new ArrayList<>();
        List<PersonDTO> maternalGP = new ArrayList<>();
        for (PersonDTO f : father) {
            paternalGP.addAll(getParents(f.getId()));
        }
        for (PersonDTO m : mother) {
            maternalGP.addAll(getParents(m.getId()));
        }

        // Oncles/tantes = frères et sœurs des parents (hors parents eux-mêmes)
        Set<UUID> parentIds = parents.stream().map(PersonDTO::getId).collect(java.util.stream.Collectors.toSet());
        List<PersonDTO> uncles = new ArrayList<>();
        for (PersonDTO p : parents) {
            getSiblings(p.getId()).stream()
                    .filter(s -> !parentIds.contains(s.getId()))
                    .forEach(uncles::add);
        }

        List<AiSuggestionDTO> suggestions = aiSuggestionRepository
                .findByPersonIdAndStatus(personId, AiSuggestionStatusEnum.PENDING)
                .stream()
                .map(s -> {
                    Person a = personRepository.findById(s.getPersonAId()).orElse(null);
                    Person b = personRepository.findById(s.getPersonBId()).orElse(null);
                    return GenealogyMapper.toDTO(s, a, b);
                })
                .toList();

        return FamilyTreeDTO.builder()
                .subject(GenealogyMapper.toDTO(person, villageIds))
                .father(father)
                .mother(mother)
                .paternalGP(paternalGP)
                .maternalGP(maternalGP)
                .siblings(getSiblingsWithType(personId))
                .children(getChildren(personId))
                .unions(getUnionsByPerson(personId))
                .cousins(getFirstCousins(personId))
                .uncles(uncles)
                .pendingSuggestions(suggestions)
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public List<PersonDTO> getParents(UUID personId) {
        // PostgreSQL est la source de verite
        List<PersonDTO> pgResult = parentChildRepository.findByChildId(personId).stream()
                .map(pc -> personRepository.findById(pc.getParentId()).orElse(null))
                .filter(java.util.Objects::nonNull)
                .map(p -> GenealogyMapper.toDTO(p, personVillageRepository.findVillageIdsByPersonId(p.getId())))
                .collect(Collectors.toList());
        if (!pgResult.isEmpty()) return pgResult;

        // Fallback Neo4j si PostgreSQL vide
        try {
            return nodeListToDTO(personNodeRepository.findParents(personId.toString()));
        } catch (Exception e) {
            log.warn("Neo4j aussi indisponible pour getParents({}): {}", personId, e.getMessage());
            return List.of();
        }
    }

    @Override
    @Transactional(readOnly = true)
    public List<PersonDTO> getChildren(UUID personId) {
        List<PersonDTO> pgResult = parentChildRepository.findByParentId(personId).stream()
                .map(pc -> personRepository.findById(pc.getChildId()).orElse(null))
                .filter(java.util.Objects::nonNull)
                .map(p -> GenealogyMapper.toDTO(p, personVillageRepository.findVillageIdsByPersonId(p.getId())))
                .collect(Collectors.toList());
        if (!pgResult.isEmpty()) return pgResult;

        try {
            return nodeListToDTO(personNodeRepository.findChildren(personId.toString()));
        } catch (Exception e) {
            log.warn("Neo4j aussi indisponible pour getChildren({}): {}", personId, e.getMessage());
            return List.of();
        }
    }

    @Override
    @Transactional(readOnly = true)
    public List<PersonDTO> getSiblings(UUID personId) {
        // PostgreSQL: trouver les parents, puis les autres enfants de ces parents
        Set<UUID> siblingIds = new HashSet<>();
        parentChildRepository.findByChildId(personId).forEach(pc ->
                parentChildRepository.findByParentId(pc.getParentId()).forEach(sibling -> {
                    if (!sibling.getChildId().equals(personId)) {
                        siblingIds.add(sibling.getChildId());
                    }
                })
        );
        if (!siblingIds.isEmpty()) {
            return siblingIds.stream()
                    .map(id -> personRepository.findById(id).orElse(null))
                    .filter(java.util.Objects::nonNull)
                    .map(p -> GenealogyMapper.toDTO(p, personVillageRepository.findVillageIdsByPersonId(p.getId())))
                    .collect(Collectors.toList());
        }

        try {
            return nodeListToDTO(personNodeRepository.findSiblings(personId.toString()));
        } catch (Exception e) {
            log.warn("Neo4j aussi indisponible pour getSiblings({}): {}", personId, e.getMessage());
            return List.of();
        }
    }

    /**
     * Retourne les frères/sœurs avec le type de fratrie calculé automatiquement
     * en comparant les ensembles de parents.
     */
    private List<SiblingDTO> getSiblingsWithType(UUID personId) {
        // Parents du sujet
        List<ParentChild> subjectParentLinks = parentChildRepository.findByChildId(personId);
        Set<UUID> subjectParentIds = subjectParentLinks.stream()
                .map(ParentChild::getParentId)
                .collect(Collectors.toSet());

        // Trouver tous les siblings (enfants des parents du sujet, sauf le sujet)
        Set<UUID> siblingIds = new HashSet<>();
        for (UUID parentId : subjectParentIds) {
            parentChildRepository.findByParentId(parentId).forEach(pc -> {
                if (!pc.getChildId().equals(personId)) {
                    siblingIds.add(pc.getChildId());
                }
            });
        }

        if (siblingIds.isEmpty()) return List.of();

        List<SiblingDTO> result = new ArrayList<>();
        for (UUID sibId : siblingIds) {
            Person sibPerson = personRepository.findById(sibId).orElse(null);
            if (sibPerson == null) continue;

            List<UUID> sibVillages = personVillageRepository.findVillageIdsByPersonId(sibId);
            PersonDTO sibDTO = GenealogyMapper.toDTO(sibPerson, sibVillages);

            // Parents du sibling
            Set<UUID> sibParentIds = parentChildRepository.findByChildId(sibId).stream()
                    .map(ParentChild::getParentId)
                    .collect(Collectors.toSet());

            // Intersection des parents
            Set<UUID> commonParents = new HashSet<>(subjectParentIds);
            commonParents.retainAll(sibParentIds);

            SiblingTypeEnum type;
            UUID sharedParentId = null;

            if (commonParents.size() >= 2) {
                type = SiblingTypeEnum.FULL;
            } else if (commonParents.size() == 1) {
                UUID commonId = commonParents.iterator().next();
                sharedParentId = commonId;
                Person commonParent = personRepository.findById(commonId).orElse(null);
                if (commonParent != null && commonParent.getGender() == GenderEnum.MALE) {
                    type = SiblingTypeEnum.HALF_PATERNAL;
                } else {
                    type = SiblingTypeEnum.HALF_MATERNAL;
                }
            } else {
                type = SiblingTypeEnum.STEP;
            }

            result.add(SiblingDTO.builder()
                    .person(sibDTO)
                    .type(type)
                    .sharedParentId(sharedParentId)
                    .build());
        }
        return result;
    }

    @Override
    @Transactional(readOnly = true)
    public List<PersonDTO> getGrandparents(UUID personId) {
        // PostgreSQL: parents des parents
        List<PersonDTO> grandparents = new ArrayList<>();
        parentChildRepository.findByChildId(personId).forEach(pc ->
                parentChildRepository.findByChildId(pc.getParentId()).forEach(gpc ->
                        personRepository.findById(gpc.getParentId()).ifPresent(p ->
                                grandparents.add(GenealogyMapper.toDTO(p,
                                        personVillageRepository.findVillageIdsByPersonId(p.getId())))
                        )
                )
        );
        if (!grandparents.isEmpty()) return grandparents;

        try {
            return nodeListToDTO(personNodeRepository.findGrandparents(personId.toString()));
        } catch (Exception e) {
            log.warn("Neo4j aussi indisponible pour getGrandparents({}): {}", personId, e.getMessage());
            return List.of();
        }
    }

    @Override
    @Transactional(readOnly = true)
    public List<PersonDTO> getFirstCousins(UUID personId) {
        // PostgreSQL: enfants des freres/soeurs des parents
        Set<UUID> cousinIds = new HashSet<>();
        parentChildRepository.findByChildId(personId).forEach(pc -> {
            UUID parentId = pc.getParentId();
            parentChildRepository.findByChildId(parentId).forEach(gpc -> {
                parentChildRepository.findByParentId(gpc.getParentId()).forEach(uncle -> {
                    if (!uncle.getChildId().equals(parentId)) {
                        parentChildRepository.findByParentId(uncle.getChildId()).forEach(cousin ->
                                cousinIds.add(cousin.getChildId())
                        );
                    }
                });
            });
        });
        if (!cousinIds.isEmpty()) {
            return cousinIds.stream()
                    .map(id -> personRepository.findById(id).orElse(null))
                    .filter(java.util.Objects::nonNull)
                    .map(p -> GenealogyMapper.toDTO(p, personVillageRepository.findVillageIdsByPersonId(p.getId())))
                    .collect(Collectors.toList());
        }

        try {
            return nodeListToDTO(personNodeRepository.findFirstCousins(personId.toString()));
        } catch (Exception e) {
            log.warn("Neo4j aussi indisponible pour getFirstCousins({}): {}", personId, e.getMessage());
            return List.of();
        }
    }

    @Override
    @Transactional(readOnly = true)
    public List<UnionDTO> getActiveSpouses(UUID personId) {
        // PostgreSQL : chercher comme mari ET comme femme
        List<GenealogyUnion> asHusband = unionRepository.findActiveUnionsByHusband(personId);
        List<GenealogyUnion> asWife = unionRepository.findActiveUnionsByWife(personId);

        List<UnionDTO> results = new ArrayList<>();

        for (GenealogyUnion u : asHusband) {
            Person h = personRepository.findById(u.getHusbandId()).orElse(null);
            Person w = personRepository.findById(u.getWifeId()).orElse(null);
            results.add(GenealogyMapper.toDTO(u, h, w));
        }
        for (GenealogyUnion u : asWife) {
            Person h = personRepository.findById(u.getHusbandId()).orElse(null);
            Person w = personRepository.findById(u.getWifeId()).orElse(null);
            results.add(GenealogyMapper.toDTO(u, h, w));
        }

        if (!results.isEmpty()) return results;

        // Fallback Neo4j (cote mari uniquement car relation directionnelle)
        try {
            List<PersonNode> wives = personNodeRepository.findActiveWives(personId.toString());
            return wives.stream().map(w -> {
                Person wife = personRepository.findById(UUID.fromString(w.getPostgresId())).orElse(null);
                GenealogyUnion union = unionRepository.findActiveUnionsByHusband(personId).stream()
                        .filter(u -> u.getWifeId().equals(UUID.fromString(w.getPostgresId())))
                        .findFirst().orElse(null);
                Person husband = personRepository.findById(personId).orElse(null);
                return GenealogyMapper.toDTO(union, husband, wife);
            }).collect(Collectors.toList());
        } catch (Exception e) {
            log.warn("Neo4j aussi indisponible pour getActiveSpouses({}): {}", personId, e.getMessage());
            return List.of();
        }
    }

    @Override
    @Transactional(readOnly = true)
    public List<PersonDTO> getAncestors(UUID personId, int depth) {
        findPersonOrThrow(personId);
        try {
            return nodeListToDTO(personNodeRepository.findAncestors(personId.toString(), depth));
        } catch (Exception e) {
            log.warn("Neo4j indisponible pour getAncestors({}): {}", personId, e.getMessage());
            // Fallback PostgreSQL : remontee recursive limitee
            Set<UUID> visited = new HashSet<>();
            List<PersonDTO> result = new ArrayList<>();
            collectAncestorsPG(personId, depth, 0, visited, result);
            return result;
        }
    }

    private void collectAncestorsPG(UUID personId, int maxDepth, int currentDepth,
                                     Set<UUID> visited, List<PersonDTO> result) {
        if (currentDepth >= maxDepth || visited.contains(personId)) return;
        visited.add(personId);

        parentChildRepository.findByChildId(personId).forEach(pc -> {
            UUID parentId = pc.getParentId();
            if (!visited.contains(parentId)) {
                personRepository.findById(parentId).ifPresent(p -> {
                    List<UUID> vIds = personVillageRepository.findVillageIdsByPersonId(p.getId());
                    result.add(GenealogyMapper.toDTO(p, vIds));
                });
                collectAncestorsPG(parentId, maxDepth, currentDepth + 1, visited, result);
            }
        });
    }

    @Override
    @Transactional(readOnly = true)
    public List<PersonDTO> getDescendants(UUID personId, int depth) {
        findPersonOrThrow(personId);
        try {
            return nodeListToDTO(personNodeRepository.findDescendants(personId.toString(), depth));
        } catch (Exception e) {
            log.warn("Neo4j indisponible pour getDescendants({}): {}", personId, e.getMessage());
            Set<UUID> visited = new HashSet<>();
            List<PersonDTO> result = new ArrayList<>();
            collectDescendantsPG(personId, depth, 0, visited, result);
            return result;
        }
    }

    private void collectDescendantsPG(UUID personId, int maxDepth, int currentDepth,
                                       Set<UUID> visited, List<PersonDTO> result) {
        if (currentDepth >= maxDepth || visited.contains(personId)) return;
        visited.add(personId);

        parentChildRepository.findByParentId(personId).forEach(pc -> {
            UUID childId = pc.getChildId();
            if (!visited.contains(childId)) {
                personRepository.findById(childId).ifPresent(p -> {
                    List<UUID> vIds = personVillageRepository.findVillageIdsByPersonId(p.getId());
                    result.add(GenealogyMapper.toDTO(p, vIds));
                });
                collectDescendantsPG(childId, maxDepth, currentDepth + 1, visited, result);
            }
        });
    }

    // ── CLAUDE AI ──────────────────────────────────────────

    @Override
    public List<AiSuggestionDTO> generateAiSuggestions(UUID personId) {
        return genealogyAiService.suggestLinks(personId);
    }

    @Override
    @Transactional(readOnly = true)
    public List<AiSuggestionDTO> getPendingSuggestions(UUID personId) {
        return aiSuggestionRepository
                .findByPersonIdAndStatus(personId, AiSuggestionStatusEnum.PENDING)
                .stream()
                .map(s -> {
                    Person a = personRepository.findById(s.getPersonAId()).orElse(null);
                    Person b = personRepository.findById(s.getPersonBId()).orElse(null);
                    return GenealogyMapper.toDTO(s, a, b);
                })
                .toList();
    }

    @Override
    public AiSuggestionDTO reviewAiSuggestion(UUID suggestionId, boolean accepted, UUID reviewedBy) {
        AiGenealogySuggestion suggestion = aiSuggestionRepository.findById(suggestionId)
                .orElseThrow(() -> new IllegalArgumentException("Suggestion not found: " + suggestionId));

        suggestion.setReviewedBy(reviewedBy);
        suggestion.setReviewedAt(Instant.now());

        if (accepted) {
            suggestion.setStatus(AiSuggestionStatusEnum.ACCEPTED);
            aiSuggestionRepository.save(suggestion);

            eventPublisher.publishEvent(new AiSuggestionAcceptedEvent(
                    suggestionId, suggestion.getPersonAId(), suggestion.getPersonBId(),
                    suggestion.getSuggestedRelation()));
            log.info("AI suggestion accepted: {} (relation={})", suggestionId, suggestion.getSuggestedRelation());
        } else {
            suggestion.setStatus(AiSuggestionStatusEnum.REJECTED);
            aiSuggestionRepository.save(suggestion);
            log.info("AI suggestion rejected: {}", suggestionId);
        }

        Person a = personRepository.findById(suggestion.getPersonAId()).orElse(null);
        Person b = personRepository.findById(suggestion.getPersonBId()).orElse(null);
        return GenealogyMapper.toDTO(suggestion, a, b);
    }

    // ── HELPERS ────────────────────────────────────────────

    /**
     * Verifie qu'une personne n'a pas d'union active contenant 'CIVIL'.
     * Si elle en a → refuse toute nouvelle union (monogamie legale).
     */
    private void validateNoActiveCivilUnion(UUID personId, String personName) {
        List<GenealogyUnion> activeUnions = unionRepository.findActiveUnionsByPerson(personId);
        for (GenealogyUnion u : activeUnions) {
            if (u.getUnionTypes() != null) {
                for (String type : u.getUnionTypes()) {
                    if ("CIVIL".equals(type)) {
                        throw new IllegalStateException(
                                personName + " est deja marie(e) au civil (monogamie legale). "
                                        + "Un divorce ou un deces du conjoint est necessaire avant de creer une nouvelle union. "
                                        + "Pour plus d'informations, veuillez contacter le concerne.");
                    }
                }
            }
        }
    }

    private Person findPersonOrThrow(UUID personId) {
        return personRepository.findById(personId)
                .orElseThrow(() -> new IllegalArgumentException("Person not found: " + personId));
    }

    private List<PersonDTO> nodeListToDTO(List<PersonNode> nodes) {
        return nodes.stream()
                .map(node -> personRepository.findById(UUID.fromString(node.getPostgresId()))
                        .map(p -> {
                            List<UUID> vIds = personVillageRepository.findVillageIdsByPersonId(p.getId());
                            return GenealogyMapper.toDTO(p, vIds);
                        })
                        .orElse(null))
                .filter(java.util.Objects::nonNull)
                .collect(Collectors.toList());
    }

    private void savePersonVillages(UUID personId, List<UUID> villageIds) {
        if (villageIds == null || villageIds.isEmpty()) return;
        List<PersonVillage> links = villageIds.stream()
                .map(vid -> PersonVillage.builder().personId(personId).villageId(vid).build())
                .toList();
        personVillageRepository.saveAll(links);
    }

    /**
     * Verifie que les villages demandes font partie des villages des ancetres.
     * Si la personne n'a aucun ancetre (racine), tous les villages sont autorises.
     */
    private void validateAncestorVillages(UUID personId, List<UUID> villageIds) {
        if (villageIds == null || villageIds.isEmpty()) return;

        List<String> ancestorPgIds;
        try {
            ancestorPgIds = personNodeRepository.findAncestorPostgresIds(personId.toString());
        } catch (Exception e) {
            log.warn("Neo4j indisponible pour validation villages, skip: {}", e.getMessage());
            return; // Skip validation quand Neo4j est down
        }

        if (ancestorPgIds.isEmpty()) {
            // Personne racine, pas de restriction
            return;
        }

        // Collecter tous les villages des ancetres
        Set<UUID> allowedVillages = new HashSet<>();
        for (String ancestorId : ancestorPgIds) {
            allowedVillages.addAll(
                    personVillageRepository.findVillageIdsByPersonId(UUID.fromString(ancestorId)));
        }

        for (UUID vid : villageIds) {
            if (!allowedVillages.contains(vid)) {
                throw new IllegalStateException(
                        "Village " + vid + " non autorise : aucun parent ou ancetre n'appartient a ce village");
            }
        }
    }
}
