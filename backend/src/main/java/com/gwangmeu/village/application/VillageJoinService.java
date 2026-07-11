package com.gwangmeu.village.application;

import com.gwangmeu.genealogy.domain.GenealogyUnion;
import com.gwangmeu.genealogy.domain.ParentChild;
import com.gwangmeu.genealogy.domain.Person;
import com.gwangmeu.genealogy.infrastructure.ParentChildRepository;
import com.gwangmeu.genealogy.infrastructure.PersonRepository;
import com.gwangmeu.genealogy.infrastructure.PersonVillageRepository;
import com.gwangmeu.genealogy.infrastructure.UnionRepository;
import com.gwangmeu.village.domain.Village;
import com.gwangmeu.village.domain.VillageJoinRequest;
import com.gwangmeu.village.domain.VillageJoinStatus;
import com.gwangmeu.village.domain.VillagePermission;
import com.gwangmeu.village.domain.VillageSubscription;
import com.gwangmeu.village.infrastructure.VillageJoinRequestRepository;
import com.gwangmeu.village.infrastructure.VillageRepository;
import com.gwangmeu.village.infrastructure.VillageSubscriptionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * Adhesion a un village avec regle d'admission AUTO par la genealogie.
 *
 * <p>Un utilisateur est auto-admis MEMBRE si un membre de sa famille au 1er degre
 * (parents, enfants, fratrie, conjoints) est deja rattache au village — soit via
 * {@code person_villages}, soit via une {@link VillageSubscription} de type MEMBER.</p>
 *
 * <p>Tolerant aux donnees manquantes : un utilisateur sans personne genealogique
 * ne peut pas etre auto-admis et tombe en PENDING.</p>
 */
@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
public class VillageJoinService {

    static final String AUTO_REASON_FAMILY =
            "Un membre de votre famille appartient deja a ce village";

    private final VillageRepository villageRepository;
    private final VillageSubscriptionRepository subscriptionRepository;
    private final VillageJoinRequestRepository joinRequestRepository;
    private final VillagePermissionService permissionService;

    private final PersonRepository personRepository;
    private final ParentChildRepository parentChildRepository;
    private final UnionRepository unionRepository;
    private final PersonVillageRepository personVillageRepository;

    // ------------------------------------------------------------------
    // Resultat d'une demande d'adhesion
    // ------------------------------------------------------------------

    public record JoinResult(VillageJoinStatus status, boolean member, String autoReason) {}

    // ------------------------------------------------------------------
    // Demande d'adhesion (avec regle AUTO)
    // ------------------------------------------------------------------

    public JoinResult requestJoin(UUID villageId, UUID userId) {
        Village village = villageRepository.findById(villageId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Village introuvable : " + villageId));

        // a. Deja MEMBER -> renvoyer l'etat existant.
        if (subscriptionRepository.existsByUserIdAndVillageIdAndType(
                userId, villageId, VillageSubscription.SubscriptionType.MEMBER)) {
            return new JoinResult(VillageJoinStatus.AUTO_APPROVED, true, null);
        }

        // b. Un parent de famille est-il deja membre du village ?
        boolean familyMember = hasFamilyMemberInVillage(userId, villageId);

        if (familyMember) {
            // c. Admission AUTO.
            ensureMemberSubscription(userId, villageId, village);
            upsertJoinRequest(villageId, userId, VillageJoinStatus.AUTO_APPROVED,
                    AUTO_REASON_FAMILY, userId);
            log.info("Adhesion AUTO village={} user={} (famille deja membre)", villageId, userId);
            return new JoinResult(VillageJoinStatus.AUTO_APPROVED, true, AUTO_REASON_FAMILY);
        }

        // d. Sinon : demande PENDING (pas d'abonnement encore).
        VillageJoinRequest existing = joinRequestRepository
                .findByVillageIdAndUserId(villageId, userId).orElse(null);
        if (existing != null && existing.getStatus() == VillageJoinStatus.PENDING) {
            return new JoinResult(VillageJoinStatus.PENDING, false, null);
        }
        upsertJoinRequest(villageId, userId, VillageJoinStatus.PENDING, null, null);
        log.info("Demande d'adhesion PENDING village={} user={}", villageId, userId);
        return new JoinResult(VillageJoinStatus.PENDING, false, null);
    }

    // ------------------------------------------------------------------
    // Decisions manuelles (VALIDATE_MEMBERS)
    // ------------------------------------------------------------------

    public JoinResult approveJoin(UUID villageId, UUID requestId, UUID deciderId) {
        permissionService.requireCan(deciderId, villageId, VillagePermission.VALIDATE_MEMBERS);
        VillageJoinRequest req = loadRequest(villageId, requestId);

        Village village = villageRepository.findById(villageId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Village introuvable : " + villageId));

        ensureMemberSubscription(req.getUserId(), villageId, village);
        req.setStatus(VillageJoinStatus.APPROVED);
        req.setDecidedBy(deciderId);
        req.setDecidedAt(Instant.now());
        joinRequestRepository.save(req);
        log.info("Adhesion APPROVED village={} req={} par={}", villageId, requestId, deciderId);
        return new JoinResult(VillageJoinStatus.APPROVED, true, null);
    }

    public JoinResult rejectJoin(UUID villageId, UUID requestId, UUID deciderId) {
        permissionService.requireCan(deciderId, villageId, VillagePermission.VALIDATE_MEMBERS);
        VillageJoinRequest req = loadRequest(villageId, requestId);
        req.setStatus(VillageJoinStatus.REJECTED);
        req.setDecidedBy(deciderId);
        req.setDecidedAt(Instant.now());
        joinRequestRepository.save(req);
        log.info("Adhesion REJECTED village={} req={} par={}", villageId, requestId, deciderId);
        return new JoinResult(VillageJoinStatus.REJECTED, false, null);
    }

    @Transactional(readOnly = true)
    public List<VillageJoinRequest> listPendingJoins(UUID villageId, UUID requesterId) {
        permissionService.requireCan(requesterId, villageId, VillagePermission.VALIDATE_MEMBERS);
        return joinRequestRepository.findByVillageIdAndStatusOrderByCreatedAtDesc(
                villageId, VillageJoinStatus.PENDING);
    }

    // ------------------------------------------------------------------
    // Calcul de parente 1er degre + presence dans le village
    // ------------------------------------------------------------------

    /**
     * true si l'utilisateur a un membre de famille (1er degre) rattache au village,
     * via person_villages OU via une subscription MEMBER.
     */
    boolean hasFamilyMemberInVillage(UUID userId, UUID villageId) {
        Set<UUID> familyPersonIds = familyPersonIds(userId);
        if (familyPersonIds.isEmpty()) {
            return false;
        }

        // 1. Une personne de la famille est-elle directement rattachee au village ?
        List<UUID> villagePersonIds = personVillageRepository.findPersonIdsByVillageId(villageId);
        for (UUID famPersonId : familyPersonIds) {
            if (villagePersonIds.contains(famPersonId)) {
                return true;
            }
        }

        // 2. Un utilisateur de la famille a-t-il une subscription MEMBER sur le village ?
        Set<UUID> familyUserIds = familyUserIds(userId, familyPersonIds);
        if (familyUserIds.isEmpty()) {
            return false;
        }
        return !subscriptionRepository.findByVillageIdAndTypeAndUserIdIn(
                villageId, VillageSubscription.SubscriptionType.MEMBER, familyUserIds).isEmpty();
    }

    /**
     * Personnes de la famille au 1er degre de l'utilisateur (parents, enfants, fratrie,
     * conjoints). Vide si l'utilisateur n'a pas de personne genealogique rattachee.
     * Ne contient jamais la personne de l'utilisateur lui-meme.
     */
    @Transactional(readOnly = true)
    public Set<UUID> familyPersonIds(UUID userId) {
        Optional<Person> selfOpt = personRepository.findByUserId(userId);
        if (selfOpt.isEmpty()) {
            return Set.of(); // pas de personne genealogique -> pas de famille exploitable
        }
        return firstDegreeFamily(selfOpt.get().getId());
    }

    /**
     * Villages ou une personne de la famille 1er degre de l'utilisateur est rattachee,
     * via person_villages OU via une subscription MEMBER d'un utilisateur de la famille.
     * C'est l'ensemble des villages « herites » (droit d'adhesion par filiation).
     */
    @Transactional(readOnly = true)
    public Set<UUID> eligibleVillageIds(UUID userId) {
        Set<UUID> familyPersonIds = familyPersonIds(userId);
        if (familyPersonIds.isEmpty()) {
            return Set.of();
        }

        Set<UUID> villageIds = new HashSet<>();

        // 1. Villages rattaches directement a une personne de la famille (person_villages).
        villageIds.addAll(personVillageRepository.findVillageIdsByPersonIdIn(familyPersonIds));

        // 2. Villages ou un utilisateur de la famille est MEMBER (village_subscriptions).
        Set<UUID> familyUserIds = familyUserIds(userId, familyPersonIds);
        if (!familyUserIds.isEmpty()) {
            villageIds.addAll(subscriptionRepository.findVillageIdsByTypeAndUserIdIn(
                    VillageSubscription.SubscriptionType.MEMBER, familyUserIds));
        }

        villageIds.removeIf(Objects::isNull);
        return villageIds;
    }

    /**
     * Utilisateurs (users.id) associes aux personnes de la famille fournies,
     * en excluant l'utilisateur courant.
     */
    private Set<UUID> familyUserIds(UUID userId, Set<UUID> familyPersonIds) {
        Set<UUID> familyUserIds = new HashSet<>();
        for (Person p : personRepository.findAllById(familyPersonIds)) {
            if (p.getUserId() != null) {
                familyUserIds.add(p.getUserId());
            }
        }
        familyUserIds.remove(userId); // ne pas se compter soi-meme
        return familyUserIds;
    }

    /**
     * Personnes de la famille au 1er degre : parents, enfants, fratrie, conjoints.
     * N'inclut jamais {@code personId} lui-meme.
     */
    Set<UUID> firstDegreeFamily(UUID personId) {
        Set<UUID> family = new HashSet<>();

        // Parents (personId est l'enfant) et enfants (personId est le parent).
        List<ParentChild> asChild = parentChildRepository.findByChildId(personId);
        List<UUID> parentIds = new ArrayList<>();
        for (ParentChild pc : asChild) {
            parentIds.add(pc.getParentId());
            family.add(pc.getParentId());
        }
        for (ParentChild pc : parentChildRepository.findByParentId(personId)) {
            family.add(pc.getChildId());
        }

        // Fratrie : autres enfants des memes parents.
        if (!parentIds.isEmpty()) {
            for (ParentChild pc : parentChildRepository.findByParentIdIn(parentIds)) {
                family.add(pc.getChildId());
            }
        }

        // Conjoints via les unions.
        for (GenealogyUnion u : unionRepository.findByPersonId(personId)) {
            if (personId.equals(u.getHusbandId())) {
                family.add(u.getWifeId());
            } else if (personId.equals(u.getWifeId())) {
                family.add(u.getHusbandId());
            }
        }

        family.remove(personId);
        family.removeIf(Objects::isNull);
        return family;
    }

    // ------------------------------------------------------------------
    // Helpers internes
    // ------------------------------------------------------------------

    private VillageJoinRequest loadRequest(UUID villageId, UUID requestId) {
        VillageJoinRequest req = joinRequestRepository.findById(requestId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Demande d'adhesion introuvable : " + requestId));
        if (!villageId.equals(req.getVillageId())) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND,
                    "Demande d'adhesion introuvable pour ce village.");
        }
        return req;
    }

    /** Cree la subscription MEMBER si absente et incremente memberCount. Idempotent. */
    private void ensureMemberSubscription(UUID userId, UUID villageId, Village village) {
        Optional<VillageSubscription> existing =
                subscriptionRepository.findByUserIdAndVillageId(userId, villageId);
        if (existing.isPresent()) {
            VillageSubscription sub = existing.get();
            if (sub.getType() != VillageSubscription.SubscriptionType.MEMBER) {
                // Promotion FOLLOW/AMBASSADOR -> MEMBER, sans re-incrementer memberCount.
                sub.setType(VillageSubscription.SubscriptionType.MEMBER);
                subscriptionRepository.save(sub);
            }
            return;
        }
        subscriptionRepository.save(VillageSubscription.builder()
                .userId(userId)
                .villageId(villageId)
                .type(VillageSubscription.SubscriptionType.MEMBER)
                .build());
        village.setMemberCount(village.getMemberCount() + 1);
        villageRepository.save(village);
    }

    /** Cree ou met a jour la demande d'adhesion (contrainte unique village+user). */
    private void upsertJoinRequest(UUID villageId, UUID userId, VillageJoinStatus status,
                                   String autoReason, UUID decidedBy) {
        VillageJoinRequest req = joinRequestRepository
                .findByVillageIdAndUserId(villageId, userId)
                .orElseGet(() -> VillageJoinRequest.builder()
                        .villageId(villageId)
                        .userId(userId)
                        .build());
        req.setStatus(status);
        req.setAutoReason(autoReason);
        if (status == VillageJoinStatus.AUTO_APPROVED) {
            req.setDecidedBy(decidedBy);
            req.setDecidedAt(Instant.now());
        }
        joinRequestRepository.save(req);
    }
}
