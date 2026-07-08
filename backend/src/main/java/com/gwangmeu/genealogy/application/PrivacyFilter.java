package com.gwangmeu.genealogy.application;

import com.gwangmeu.genealogy.domain.Person;
import com.gwangmeu.genealogy.domain.enums.PrivacyEnum;
import com.gwangmeu.genealogy.dto.FamilyTreeDTO;
import com.gwangmeu.genealogy.dto.PersonDTO;
import com.gwangmeu.genealogy.infrastructure.ParentChildRepository;
import com.gwangmeu.genealogy.infrastructure.PersonRepository;
import com.gwangmeu.genealogy.infrastructure.PersonVillageRepository;
import com.gwangmeu.genealogy.infrastructure.UnionRepository;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.Collection;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * Filtre de confidentialite pour les personnes VIVANTES exposees par l'API genealogie.
 *
 * Relation lecteur / personne :
 * - SOI-MEME : la fiche est liee au compte du lecteur (userId) ou correspond a sa propre personne.
 * - FAMILLE : la personne est a 3 degres ou moins du lecteur via parent_child / unions.
 * - ETRANGER : tout le reste.
 *
 * Pour une personne vivante vue par un etranger, selon {@link PrivacyEnum} :
 * - PUBLIC        : nom + clan visibles ; email, phone, profession, religion masques,
 *                   birthDate reduite a l'annee seule.
 * - MEMBERS_ONLY  : visible (contacts masques) uniquement si le lecteur partage un village
 *                   commun avec la personne ; sinon anonymisation complete.
 * - FAMILY_ONLY   : anonymisation complete — nom remplace par "Vivant·e" + initiale.
 *
 * Les personnes decedees ne sont jamais filtrees (memoire genealogique partagee).
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class PrivacyFilter {

    /** Degre de parente maximal (inclus) pour etre considere comme membre de la famille. */
    private static final int FAMILY_DEGREE_LIMIT = 3;

    private static final String LIVING_PLACEHOLDER = "Vivant·e";

    private final PersonRepository personRepository;
    private final ParentChildRepository parentChildRepository;
    private final UnionRepository unionRepository;
    private final PersonVillageRepository personVillageRepository;

    /**
     * Contexte du lecteur : sa personne, sa famille (&le; 3 degres) et ses villages.
     */
    @Getter
    @RequiredArgsConstructor
    public static class ViewerContext {
        private final UUID viewerUserId;
        private final UUID viewerPersonId;
        private final Set<UUID> familyPersonIds;
        private final Set<UUID> viewerVillageIds;

        public boolean isSelfOrFamily(UUID personId, UUID personUserId) {
            if (personId != null && personId.equals(viewerPersonId)) return true;
            if (personUserId != null && personUserId.equals(viewerUserId)) return true;
            return personId != null && familyPersonIds.contains(personId);
        }
    }

    /**
     * Construit le contexte du lecteur. Nombre de requetes constant
     * (BFS borne a {@value FAMILY_DEGREE_LIMIT} niveaux, requetes IN batchees).
     */
    @Transactional(readOnly = true)
    public ViewerContext contextFor(UUID viewerUserId) {
        if (viewerUserId == null) {
            return new ViewerContext(null, null, Set.of(), Set.of());
        }
        Person viewerPerson = personRepository.findByUserId(viewerUserId).orElse(null);
        if (viewerPerson == null) {
            return new ViewerContext(viewerUserId, null, Set.of(), Set.of());
        }
        Set<UUID> familyIds = collectFamilyIds(viewerPerson.getId());
        Set<UUID> villageIds = new HashSet<>(
                personVillageRepository.findVillageIdsByPersonId(viewerPerson.getId()));
        return new ViewerContext(viewerUserId, viewerPerson.getId(), familyIds, villageIds);
    }

    /**
     * BFS sur le graphe familial (parent_child dans les deux sens + unions),
     * limite a {@value FAMILY_DEGREE_LIMIT} degres.
     */
    private Set<UUID> collectFamilyIds(UUID rootPersonId) {
        Set<UUID> visited = new HashSet<>();
        visited.add(rootPersonId);
        Set<UUID> frontier = Set.of(rootPersonId);

        for (int degree = 0; degree < FAMILY_DEGREE_LIMIT && !frontier.isEmpty(); degree++) {
            Set<UUID> next = new HashSet<>();
            parentChildRepository.findByChildIdIn(frontier).forEach(pc -> next.add(pc.getParentId()));
            parentChildRepository.findByParentIdIn(frontier).forEach(pc -> next.add(pc.getChildId()));
            unionRepository.findByPersonIdIn(frontier).forEach(u -> {
                next.add(u.getHusbandId());
                next.add(u.getWifeId());
            });
            next.removeAll(visited);
            visited.addAll(next);
            frontier = next;
        }
        return visited;
    }

    /**
     * Filtre un arbre complet. Si le lecteur consulte son propre arbre ou celui
     * d'un proche (&le; 3 degres), aucune redaction n'est appliquee.
     */
    public FamilyTreeDTO filterTree(FamilyTreeDTO tree, ViewerContext ctx) {
        if (tree == null || tree.getSubject() == null || ctx == null) return tree;

        PersonDTO subject = tree.getSubject();
        if (ctx.isSelfOrFamily(subject.getId(), subject.getUserId())) {
            return tree; // lecteur = sujet ou membre de la famille — aucune redaction
        }

        tree.setSubject(filterPerson(subject, ctx));
        tree.setFather(filterPersons(tree.getFather(), ctx));
        tree.setMother(filterPersons(tree.getMother(), ctx));
        tree.setPaternalGP(filterPersons(tree.getPaternalGP(), ctx));
        tree.setMaternalGP(filterPersons(tree.getMaternalGP(), ctx));
        tree.setChildren(filterPersons(tree.getChildren(), ctx));
        tree.setCousins(filterPersons(tree.getCousins(), ctx));
        tree.setUncles(filterPersons(tree.getUncles(), ctx));
        if (tree.getSiblings() != null) {
            tree.getSiblings().forEach(s -> s.setPerson(filterPerson(s.getPerson(), ctx)));
        }
        if (tree.getUnions() != null) {
            tree.getUnions().forEach(u -> {
                u.setHusband(filterPerson(u.getHusband(), ctx));
                u.setWife(filterPerson(u.getWife(), ctx));
            });
        }
        if (tree.getPendingSuggestions() != null) {
            tree.getPendingSuggestions().forEach(s -> {
                s.setPersonA(filterPerson(s.getPersonA(), ctx));
                s.setPersonB(filterPerson(s.getPersonB(), ctx));
            });
        }
        return tree;
    }

    public List<PersonDTO> filterPersons(List<PersonDTO> persons, ViewerContext ctx) {
        if (persons == null) return null;
        persons.forEach(p -> filterPerson(p, ctx));
        return persons;
    }

    /**
     * Applique la redaction sur une personne (mutation en place du DTO fraichement construit).
     */
    public PersonDTO filterPerson(PersonDTO dto, ViewerContext ctx) {
        if (dto == null || ctx == null) return dto;
        if (!dto.isAlive()) return dto; // personnes decedees : memoire partagee, pas de filtre
        if (ctx.isSelfOrFamily(dto.getId(), dto.getUserId())) return dto;

        PrivacyEnum privacy = dto.getPrivacy() != null ? dto.getPrivacy() : PrivacyEnum.FAMILY_ONLY;
        switch (privacy) {
            case PUBLIC -> maskContacts(dto);
            case MEMBERS_ONLY -> {
                if (sharesVillage(dto, ctx)) {
                    maskContacts(dto);
                } else {
                    anonymize(dto);
                }
            }
            case FAMILY_ONLY -> anonymize(dto);
        }
        return dto;
    }

    private boolean sharesVillage(PersonDTO dto, ViewerContext ctx) {
        Collection<UUID> personVillages = dto.getVillageIds();
        if (personVillages == null || personVillages.isEmpty() || ctx.getViewerVillageIds().isEmpty()) {
            return false;
        }
        return personVillages.stream().anyMatch(ctx.getViewerVillageIds()::contains);
    }

    /** PUBLIC / MEMBERS_ONLY (village commun) : contacts et infos sensibles masques. */
    private void maskContacts(PersonDTO dto) {
        dto.setEmail(null);
        dto.setPhone(null);
        dto.setProfession(null);
        dto.setReligion(null);
        if (dto.getBirthDate() != null) {
            dto.setBirthDate(LocalDate.of(dto.getBirthDate().getYear(), 1, 1)); // annee seule
        }
    }

    /** FAMILY_ONLY : la personne vivante devient "Vivant·e" + initiale, tout le reste est masque. */
    private void anonymize(PersonDTO dto) {
        String initial = dto.getLastName() != null && !dto.getLastName().isBlank()
                ? dto.getLastName().trim().substring(0, 1).toUpperCase() + "."
                : "";
        dto.setFirstName(LIVING_PLACEHOLDER);
        dto.setLastName(initial);
        dto.setMaidenName(null);
        dto.setBirthDate(null);
        dto.setBirthPlace(null);
        dto.setEmail(null);
        dto.setPhone(null);
        dto.setReligion(null);
        dto.setProfession(null);
        dto.setClan(null);
        dto.setTotem(null);
        dto.setNativeLanguage(null);
        dto.setMaritalStatus(null);
        dto.setPhotoUrl(null);
        dto.setUserId(null);
        dto.setUpdatedAt(null);
        dto.setVillageIds(List.of());
    }
}
