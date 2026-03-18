package com.gwangmeu.genealogy.application;

import com.gwangmeu.genealogy.domain.GenealogyUnion;
import com.gwangmeu.genealogy.domain.Person;
import com.gwangmeu.genealogy.domain.enums.ParentRoleEnum;
import com.gwangmeu.genealogy.domain.enums.ParentTypeEnum;
import com.gwangmeu.genealogy.events.*;
import com.gwangmeu.genealogy.infrastructure.*;
import com.gwangmeu.genealogy.neo4j.MarriedToRelationship;
import com.gwangmeu.genealogy.neo4j.ParentOfRelationship;
import com.gwangmeu.genealogy.neo4j.PersonNode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class Neo4jSyncService {

    private final PersonNodeRepository personNodeRepository;
    private final PersonRepository personRepository;
    private final PersonVillageRepository personVillageRepository;
    private final ParentChildRepository parentChildRepository;
    private final UnionRepository unionRepository;

    // ── PERSON CREATED ──────────────────────────────────────

    @Async
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onPersonCreated(PersonCreatedEvent event) {
        try {
            Person person = personRepository.findById(event.personId()).orElse(null);
            if (person == null) return;

            List<String> villageIdStrs = event.villageIds() != null
                    ? event.villageIds().stream().map(UUID::toString).toList()
                    : List.of();

            // Idempotence : verifier si le noeud existe deja
            PersonNode existing = personNodeRepository.findByPostgresId(person.getId().toString()).orElse(null);
            if (existing != null) {
                updateNodeFromPerson(existing, person, villageIdStrs);
                personNodeRepository.save(existing);
                person.setNeo4jNodeId(String.valueOf(existing.getNeoId()));
                personRepository.save(person);
                log.info("Neo4j sync: person node updated (already existed) for {}", event.personId());
                return;
            }

            PersonNode node = buildNodeFromPerson(person, villageIdStrs);
            PersonNode saved = personNodeRepository.save(node);

            person.setNeo4jNodeId(String.valueOf(saved.getNeoId()));
            personRepository.save(person);

            log.info("Neo4j sync: person node created for {}", event.personId());
        } catch (Exception e) {
            log.error("Neo4j sync FAILED for person {}: {}", event.personId(), e.getMessage(), e);
        }
    }

    // ── PERSON UPDATED ──────────────────────────────────────

    @Async
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onPersonUpdated(PersonUpdatedEvent event) {
        try {
            Person person = personRepository.findById(event.personId()).orElse(null);
            if (person == null) return;

            PersonNode node = personNodeRepository.findByPostgresId(person.getId().toString()).orElse(null);
            if (node == null) {
                log.warn("Neo4j sync: person node not found for update {}, creating it", event.personId());
                onPersonCreated(new PersonCreatedEvent(event.personId(), event.villageIds(), person.getCreatedBy()));
                return;
            }

            List<String> villageIdStrs = event.villageIds() != null
                    ? event.villageIds().stream().map(UUID::toString).toList()
                    : List.of();

            updateNodeFromPerson(node, person, villageIdStrs);
            personNodeRepository.save(node);

            log.info("Neo4j sync: person node updated for {}", event.personId());
        } catch (Exception e) {
            log.error("Neo4j sync FAILED for person update {}: {}", event.personId(), e.getMessage(), e);
        }
    }

    // ── PERSON DELETED ──────────────────────────────────────

    @Async
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onPersonDeleted(PersonDeletedEvent event) {
        try {
            PersonNode node = personNodeRepository.findByPostgresId(event.personId().toString()).orElse(null);
            if (node == null) return;

            personNodeRepository.delete(node);
            log.info("Neo4j sync: person node deleted for {}", event.personId());
        } catch (Exception e) {
            log.error("Neo4j sync FAILED for person delete {}: {}", event.personId(), e.getMessage(), e);
        }
    }

    // ── PARENT-CHILD LINKED ─────────────────────────────────

    @Async
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onParentChildLinked(ParentChildLinkedEvent event) {
        try {
            PersonNode parentNode = personNodeRepository.findByPostgresId(event.parentId().toString())
                    .orElse(null);
            PersonNode childNode = personNodeRepository.findByPostgresId(event.childId().toString())
                    .orElse(null);

            if (parentNode == null || childNode == null) {
                log.warn("Neo4j sync: cannot link parent-child, node(s) not found (parent={}, child={})",
                        event.parentId(), event.childId());
                return;
            }

            // Idempotence
            boolean alreadyLinked = parentNode.getChildren().stream()
                    .anyMatch(rel -> rel.getChild().getPostgresId().equals(childNode.getPostgresId()));
            if (alreadyLinked) {
                log.info("Neo4j sync: PARENT_OF already exists {} -> {}", event.parentId(), event.childId());
                return;
            }

            // Recuperer confidence depuis PostgreSQL
            Double confidence = parentChildRepository.findByChildId(event.childId()).stream()
                    .filter(pc -> pc.getParentId().equals(event.parentId()))
                    .findFirst()
                    .map(pc -> pc.getConfidence() != null ? pc.getConfidence().doubleValue() : null)
                    .orElse(null);

            ParentOfRelationship rel = ParentOfRelationship.builder()
                    .child(childNode)
                    .role(event.role().name())
                    .type(event.type().name())
                    .isAdopted(event.type() == ParentTypeEnum.ADOPTIVE)
                    .confidence(confidence)
                    .build();

            parentNode.getChildren().add(rel);
            personNodeRepository.save(parentNode);

            log.info("Neo4j sync: PARENT_OF created {} -> {}", event.parentId(), event.childId());
        } catch (Exception e) {
            log.error("Neo4j sync FAILED for parent-child link: {}", e.getMessage(), e);
        }
    }

    // ── PARENT-CHILD UNLINKED ───────────────────────────────

    @Async
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onParentChildUnlinked(ParentChildUnlinkedEvent event) {
        try {
            PersonNode parentNode = personNodeRepository.findByPostgresId(event.parentId().toString())
                    .orElse(null);
            if (parentNode == null) return;

            boolean removed = parentNode.getChildren().removeIf(
                    rel -> rel.getChild().getPostgresId().equals(event.childId().toString()));

            if (removed) {
                personNodeRepository.save(parentNode);
                log.info("Neo4j sync: PARENT_OF removed {} -> {}", event.parentId(), event.childId());
            }
        } catch (Exception e) {
            log.error("Neo4j sync FAILED for parent-child unlink: {}", e.getMessage(), e);
        }
    }

    // ── UNION CREATED ───────────────────────────────────────

    @Async
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onUnionCreated(UnionCreatedEvent event) {
        try {
            PersonNode husbandNode = personNodeRepository.findByPostgresId(event.husbandId().toString())
                    .orElse(null);
            PersonNode wifeNode = personNodeRepository.findByPostgresId(event.wifeId().toString())
                    .orElse(null);

            if (husbandNode == null || wifeNode == null) {
                log.warn("Neo4j sync: cannot create MARRIED_TO, node(s) not found");
                return;
            }

            // Idempotence par unionId
            boolean alreadyLinked = husbandNode.getSpouses().stream()
                    .anyMatch(rel -> event.unionId().toString().equals(rel.getUnionId()));
            if (alreadyLinked) {
                log.info("Neo4j sync: MARRIED_TO already exists for union {}", event.unionId());
                return;
            }

            GenealogyUnion union = unionRepository.findById(event.unionId()).orElse(null);

            MarriedToRelationship rel = MarriedToRelationship.builder()
                    .wife(wifeNode)
                    .unionId(event.unionId().toString())
                    .isDotPaid(event.isDotPaid())
                    .order(union != null ? union.getUnionOrder() : 1)
                    .isActive(true)
                    .unionType(union != null && union.getUnionTypes() != null ? String.join(",", union.getUnionTypes()) : null)
                    .build();

            husbandNode.getSpouses().add(rel);
            personNodeRepository.save(husbandNode);

            log.info("Neo4j sync: MARRIED_TO created {} -> {}", event.husbandId(), event.wifeId());
        } catch (Exception e) {
            log.error("Neo4j sync FAILED for union: {}", e.getMessage(), e);
        }
    }

    // ── UNION DOT PAID ─────────────────────────────────────

    @Async
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onUnionDotPaid(UnionDotPaidEvent event) {
        try {
            PersonNode husbandNode = personNodeRepository.findByPostgresId(event.husbandId().toString())
                    .orElse(null);
            if (husbandNode == null) return;

            husbandNode.getSpouses().stream()
                    .filter(rel -> event.unionId().toString().equals(rel.getUnionId()))
                    .findFirst()
                    .ifPresent(rel -> rel.setIsDotPaid(true));

            personNodeRepository.save(husbandNode);
            log.info("Neo4j sync: MARRIED_TO dotPaid updated for union {}", event.unionId());
        } catch (Exception e) {
            log.error("Neo4j sync FAILED for union dot paid {}: {}", event.unionId(), e.getMessage(), e);
        }
    }

    // ── UNION ENDED ─────────────────────────────────────────

    @Async
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onUnionEnded(UnionEndedEvent event) {
        try {
            PersonNode husbandNode = personNodeRepository.findByPostgresId(event.husbandId().toString())
                    .orElse(null);
            if (husbandNode == null) return;

            husbandNode.getSpouses().stream()
                    .filter(rel -> event.unionId().toString().equals(rel.getUnionId()))
                    .findFirst()
                    .ifPresent(rel -> rel.setIsActive(false));

            personNodeRepository.save(husbandNode);
            log.info("Neo4j sync: MARRIED_TO deactivated for union {}", event.unionId());
        } catch (Exception e) {
            log.error("Neo4j sync FAILED for union end: {}", e.getMessage(), e);
        }
    }

    // ── AI SUGGESTION ACCEPTED ──────────────────────────────

    @Async
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onAiSuggestionAccepted(AiSuggestionAcceptedEvent event) {
        try {
            String relation = event.relation().toUpperCase();

            switch (relation) {
                case "FATHER" -> syncParentChildFromSuggestion(event.personAId(), event.personBId(),
                        ParentRoleEnum.FATHER);
                case "MOTHER" -> syncParentChildFromSuggestion(event.personAId(), event.personBId(),
                        ParentRoleEnum.MOTHER);
                case "CHILD" -> {
                    Person parentB = personRepository.findById(event.personBId()).orElse(null);
                    if (parentB != null) {
                        ParentRoleEnum role = switch (parentB.getGender()) {
                            case MALE -> ParentRoleEnum.FATHER;
                            case FEMALE -> ParentRoleEnum.MOTHER;
                            default -> ParentRoleEnum.FATHER;
                        };
                        syncParentChildFromSuggestion(event.personBId(), event.personAId(), role);
                    }
                }
                case "SIBLING" -> log.info("Neo4j sync: sibling relation computed by PostgreSQL trigger");
                case "WIFE" -> {
                    PersonNode husbandNode = personNodeRepository.findByPostgresId(event.personAId().toString())
                            .orElse(null);
                    PersonNode wifeNode = personNodeRepository.findByPostgresId(event.personBId().toString())
                            .orElse(null);
                    if (husbandNode != null && wifeNode != null) {
                        MarriedToRelationship rel = MarriedToRelationship.builder()
                                .wife(wifeNode)
                                .unionId(event.suggestionId().toString())
                                .isDotPaid(false)
                                .order(1)
                                .isActive(true)
                                .build();
                        husbandNode.getSpouses().add(rel);
                        personNodeRepository.save(husbandNode);
                        log.info("Neo4j sync: MARRIED_TO from AI suggestion {} -> {}",
                                event.personAId(), event.personBId());
                    }
                }
                default -> log.warn("Neo4j sync: unknown AI relation type: {}", relation);
            }
        } catch (Exception e) {
            log.error("Neo4j sync FAILED for AI suggestion: {}", e.getMessage(), e);
        }
    }

    private void syncParentChildFromSuggestion(UUID parentId, UUID childId, ParentRoleEnum role) {
        PersonNode parentNode = personNodeRepository.findByPostgresId(parentId.toString()).orElse(null);
        PersonNode childNode = personNodeRepository.findByPostgresId(childId.toString()).orElse(null);

        if (parentNode == null || childNode == null) {
            log.warn("Neo4j sync: cannot create PARENT_OF from AI, node(s) not found");
            return;
        }

        boolean alreadyLinked = parentNode.getChildren().stream()
                .anyMatch(rel -> rel.getChild().getPostgresId().equals(childNode.getPostgresId()));
        if (alreadyLinked) return;

        ParentOfRelationship rel = ParentOfRelationship.builder()
                .child(childNode)
                .role(role.name())
                .type(ParentTypeEnum.BIOLOGICAL.name())
                .isAdopted(false)
                .build();

        parentNode.getChildren().add(rel);
        personNodeRepository.save(parentNode);
        log.info("Neo4j sync: PARENT_OF from AI {} -> {}", parentId, childId);
    }

    // ── FULL SYNC ───────────────────────────────────────────

    public void fullSyncPerson(UUID personId) {
        Person person = personRepository.findById(personId).orElse(null);
        if (person == null) return;

        List<UUID> villageIds = personVillageRepository.findVillageIdsByPersonId(personId);
        List<String> villageIdStrs = villageIds.stream().map(UUID::toString).toList();

        PersonNode existing = personNodeRepository.findByPostgresId(personId.toString()).orElse(null);
        PersonNode node = existing != null ? existing : new PersonNode();

        if (existing == null) {
            node.setPostgresId(person.getId().toString());
        }
        updateNodeFromPerson(node, person, villageIdStrs);

        PersonNode saved = personNodeRepository.save(node);

        String neo4jId = String.valueOf(saved.getNeoId());
        if (!neo4jId.equals(person.getNeo4jNodeId())) {
            person.setNeo4jNodeId(neo4jId);
            personRepository.save(person);
        }

        log.info("Neo4j full sync completed for person {}", personId);
    }

    /**
     * Re-synchronise TOUTES les personnes et relations de PostgreSQL vers Neo4j.
     * Nettoie aussi les noeuds orphelins dans Neo4j.
     */
    public String fullSyncAll() {
        log.info("=== Neo4j FULL SYNC ALL started ===");
        int personCount = 0;
        int relationCount = 0;
        int unionCount = 0;
        int orphansCleaned = 0;
        List<String> errors = new ArrayList<>();

        // 0. Nettoyer les noeuds orphelins (supprimes de PostgreSQL)
        Set<String> validPostgresIds = personRepository.findAll().stream()
                .map(p -> p.getId().toString())
                .collect(Collectors.toSet());

        List<PersonNode> allNodes = personNodeRepository.findAll();
        for (PersonNode node : allNodes) {
            if (!validPostgresIds.contains(node.getPostgresId())) {
                try {
                    personNodeRepository.delete(node);
                    orphansCleaned++;
                    log.info("Neo4j sync: orphan node deleted (postgresId={})", node.getPostgresId());
                } catch (Exception e) {
                    errors.add("Orphan " + node.getPostgresId() + ": " + e.getMessage());
                }
            }
        }

        // 1. Sync toutes les personnes
        List<Person> allPersons = personRepository.findAll();
        for (Person person : allPersons) {
            try {
                fullSyncPerson(person.getId());
                personCount++;
            } catch (Exception e) {
                errors.add("Person " + person.getId() + ": " + e.getMessage());
                log.error("Neo4j sync failed for person {}: {}", person.getId(), e.getMessage());
            }
        }
        log.info("Neo4j sync: {} persons synced", personCount);

        // 2. Sync relations parent-enfant
        var allLinks = parentChildRepository.findAll();
        for (var link : allLinks) {
            try {
                PersonNode parentNode = personNodeRepository.findByPostgresId(link.getParentId().toString())
                        .orElse(null);
                PersonNode childNode = personNodeRepository.findByPostgresId(link.getChildId().toString())
                        .orElse(null);

                if (parentNode == null || childNode == null) {
                    errors.add("ParentChild " + link.getId() + ": node(s) not found");
                    continue;
                }

                boolean alreadyLinked = parentNode.getChildren().stream()
                        .anyMatch(rel -> rel.getChild().getPostgresId().equals(childNode.getPostgresId()));
                if (alreadyLinked) {
                    relationCount++;
                    continue;
                }

                ParentOfRelationship rel = ParentOfRelationship.builder()
                        .child(childNode)
                        .role(link.getParentRole().name())
                        .type(link.getParentType().name())
                        .isAdopted(link.getParentType() == ParentTypeEnum.ADOPTIVE)
                        .confidence(link.getConfidence() != null ? link.getConfidence().doubleValue() : null)
                        .build();

                parentNode.getChildren().add(rel);
                personNodeRepository.save(parentNode);
                relationCount++;
            } catch (Exception e) {
                errors.add("ParentChild " + link.getId() + ": " + e.getMessage());
                log.error("Neo4j sync failed for parent-child {}: {}", link.getId(), e.getMessage());
            }
        }
        log.info("Neo4j sync: {} parent-child relations synced", relationCount);

        // 3. Sync unions
        var allUnions = unionRepository.findAll();
        for (var union : allUnions) {
            try {
                PersonNode husbandNode = personNodeRepository.findByPostgresId(union.getHusbandId().toString())
                        .orElse(null);
                PersonNode wifeNode = personNodeRepository.findByPostgresId(union.getWifeId().toString())
                        .orElse(null);

                if (husbandNode == null || wifeNode == null) {
                    errors.add("Union " + union.getId() + ": node(s) not found");
                    continue;
                }

                boolean alreadyLinked = husbandNode.getSpouses().stream()
                        .anyMatch(rel -> union.getId().toString().equals(rel.getUnionId()));
                if (alreadyLinked) {
                    unionCount++;
                    continue;
                }

                MarriedToRelationship rel = MarriedToRelationship.builder()
                        .wife(wifeNode)
                        .unionId(union.getId().toString())
                        .isDotPaid(union.isDotPaid())
                        .order(union.getUnionOrder())
                        .isActive(union.getEndDate() == null)
                        .unionType(union.getUnionTypes() != null ? String.join(",", union.getUnionTypes()) : null)
                        .build();

                husbandNode.getSpouses().add(rel);
                personNodeRepository.save(husbandNode);
                unionCount++;
            } catch (Exception e) {
                errors.add("Union " + union.getId() + ": " + e.getMessage());
                log.error("Neo4j sync failed for union {}: {}", union.getId(), e.getMessage());
            }
        }
        log.info("Neo4j sync: {} unions synced", unionCount);

        String summary = String.format(
                "Sync terminee: %d personnes, %d liens, %d unions, %d orphelins nettoyes. %d erreurs.",
                personCount, relationCount, unionCount, orphansCleaned, errors.size());
        log.info("=== Neo4j FULL SYNC ALL finished: {} ===", summary);

        if (!errors.isEmpty()) {
            summary += " Erreurs: " + String.join("; ", errors.subList(0, Math.min(5, errors.size())));
        }
        return summary;
    }

    // ── HELPERS ─────────────────────────────────────────────

    private PersonNode buildNodeFromPerson(Person person, List<String> villageIdStrs) {
        return PersonNode.builder()
                .postgresId(person.getId().toString())
                .firstName(person.getFirstName())
                .lastName(person.getLastName())
                .gender(person.getGender().name())
                .birthYear(person.getBirthDate() != null ? person.getBirthDate().getYear() : null)
                .clan(person.getClan())
                .totem(person.getTotem())
                .villageIds(villageIdStrs)
                .isAlive(person.isAlive())
                .build();
    }

    private void updateNodeFromPerson(PersonNode node, Person person, List<String> villageIdStrs) {
        node.setFirstName(person.getFirstName());
        node.setLastName(person.getLastName());
        node.setGender(person.getGender().name());
        node.setBirthYear(person.getBirthDate() != null ? person.getBirthDate().getYear() : null);
        node.setClan(person.getClan());
        node.setTotem(person.getTotem());
        node.setVillageIds(villageIdStrs);
        node.setIsAlive(person.isAlive());
    }
}
