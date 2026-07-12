package com.gwangmeu.village.application;

import com.gwangmeu.shared.mail.EmailService;
import com.gwangmeu.user.User;
import com.gwangmeu.user.UserRepository;
import com.gwangmeu.village.domain.Village;
import com.gwangmeu.village.domain.VillageInvitation;
import com.gwangmeu.village.domain.VillageInvitationStatus;
import com.gwangmeu.village.domain.VillageSubscription;
import com.gwangmeu.village.dto.VillageInvitationDto;
import com.gwangmeu.village.infrastructure.VillageInvitationRepository;
import com.gwangmeu.village.infrastructure.VillageRepository;
import com.gwangmeu.village.infrastructure.VillageSubscriptionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Invitations a rejoindre un village.
 *
 * <p>Un membre (VillageSubscription MEMBER) du village invite un utilisateur existant.
 * L'invitation reste PENDING jusqu'a acceptation (cree une adhesion MEMBER) ou refus.</p>
 */
@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
public class VillageInvitationService {

    private final VillageInvitationRepository invitationRepository;
    private final VillageRepository villageRepository;
    private final VillageSubscriptionRepository subscriptionRepository;
    private final UserRepository userRepository;
    private final EmailService emailService;

    // ------------------------------------------------------------------
    // Emission d'une invitation
    // ------------------------------------------------------------------

    /**
     * Invite {@code invitedUserId} a rejoindre {@code villageId}. L'inviteur doit etre
     * MEMBER du village. Upsert : reactive/renvoie l'invitation PENDING existante plutot
     * que de creer un doublon.
     */
    public VillageInvitationDto invite(UUID villageId, UUID invitedUserId, UUID byUserId, String message) {
        Village village = villageRepository.findById(villageId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Village introuvable : " + villageId));

        // L'inviteur doit etre MEMBER du village.
        if (!subscriptionRepository.existsByUserIdAndVillageIdAndType(
                byUserId, villageId, VillageSubscription.SubscriptionType.MEMBER)) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN, "Seul un membre du village peut inviter.");
        }

        if (invitedUserId == null) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "invitedUserId est obligatoire.");
        }
        User invited = userRepository.findById(invitedUserId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Utilisateur invite introuvable : " + invitedUserId));

        // Deja MEMBER : rien a inviter.
        if (subscriptionRepository.existsByUserIdAndVillageIdAndType(
                invitedUserId, villageId, VillageSubscription.SubscriptionType.MEMBER)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT, "L'utilisateur est deja membre de ce village.");
        }

        // Upsert : pas de doublon actif (contrainte unique village_id + invited_user_id).
        VillageInvitation invitation = invitationRepository
                .findByVillageIdAndInvitedUserId(villageId, invitedUserId)
                .orElseGet(() -> VillageInvitation.builder()
                        .villageId(villageId)
                        .invitedUserId(invitedUserId)
                        .invitedEmail(invited.getEmail())
                        .build());
        invitation.setInvitedBy(byUserId);
        invitation.setInvitedEmail(invited.getEmail());
        invitation.setStatus(VillageInvitationStatus.PENDING);
        invitation.setMessage(message);
        invitation.setDecidedAt(null);
        VillageInvitation saved = invitationRepository.save(invitation);
        log.info("Invitation village={} invited={} par={} statut=PENDING",
                villageId, invitedUserId, byUserId);

        // Notification email best-effort : l'invite est un membre existant (email connu).
        // Un echec d'envoi ne bloque pas l'invitation (visible aussi in-app).
        String invitedEmail = invited.getEmail();
        if (invitedEmail != null && !invitedEmail.isBlank()) {
            try {
                emailService.sendVillageInvitationEmail(
                        invitedEmail, invited.getDisplayName(),
                        displayNameOf(byUserId), village.getName());
            } catch (RuntimeException e) {
                log.warn("Email invitation village non envoye a {} : {}", invitedEmail, e.getMessage());
            }
        }

        return toDto(saved, village.getName(), displayNameOf(byUserId));
    }

    // ------------------------------------------------------------------
    // Consultation par l'invite
    // ------------------------------------------------------------------

    /** Invitations PENDING recues par {@code userId}, enrichies du nom du village/inviteur. */
    @Transactional(readOnly = true)
    public List<VillageInvitationDto> myInvitations(UUID userId) {
        List<VillageInvitation> invitations = invitationRepository
                .findByInvitedUserIdAndStatus(userId, VillageInvitationStatus.PENDING);
        if (invitations.isEmpty()) {
            return List.of();
        }

        Set<UUID> villageIds = invitations.stream()
                .map(VillageInvitation::getVillageId).collect(Collectors.toSet());
        Map<UUID, String> villageNames = new HashMap<>();
        villageRepository.findAllById(villageIds)
                .forEach(v -> villageNames.put(v.getId(), v.getName()));

        Set<UUID> inviterIds = invitations.stream()
                .map(VillageInvitation::getInvitedBy).collect(Collectors.toSet());
        Map<UUID, String> inviterNames = new HashMap<>();
        userRepository.findAllById(inviterIds)
                .forEach(u -> inviterNames.put(u.getId(), u.getDisplayName()));

        return invitations.stream()
                .map(inv -> toDto(inv,
                        villageNames.get(inv.getVillageId()),
                        inviterNames.get(inv.getInvitedBy())))
                .toList();
    }

    // ------------------------------------------------------------------
    // Decisions de l'invite
    // ------------------------------------------------------------------

    /**
     * L'invite accepte : cree une adhesion MEMBER (idempotent), incremente memberCount,
     * passe l'invitation en ACCEPTED.
     */
    public VillageInvitationDto accept(UUID invitationId, UUID userId) {
        VillageInvitation invitation = loadForInvitee(invitationId, userId);
        Village village = villageRepository.findById(invitation.getVillageId())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Village introuvable : " + invitation.getVillageId()));

        if (invitation.getStatus() == VillageInvitationStatus.PENDING) {
            ensureMemberSubscription(userId, village);
            invitation.setStatus(VillageInvitationStatus.ACCEPTED);
            invitation.setDecidedAt(Instant.now());
            invitationRepository.save(invitation);
            log.info("Invitation {} ACCEPTED par user={}", invitationId, userId);
        }
        return toDto(invitation, village.getName(), displayNameOf(invitation.getInvitedBy()));
    }

    /** L'invite refuse : passe l'invitation en DECLINED. */
    public VillageInvitationDto decline(UUID invitationId, UUID userId) {
        VillageInvitation invitation = loadForInvitee(invitationId, userId);
        if (invitation.getStatus() == VillageInvitationStatus.PENDING) {
            invitation.setStatus(VillageInvitationStatus.DECLINED);
            invitation.setDecidedAt(Instant.now());
            invitationRepository.save(invitation);
            log.info("Invitation {} DECLINED par user={}", invitationId, userId);
        }
        String villageName = villageRepository.findById(invitation.getVillageId())
                .map(Village::getName).orElse(null);
        return toDto(invitation, villageName, displayNameOf(invitation.getInvitedBy()));
    }

    // ------------------------------------------------------------------
    // Helpers internes
    // ------------------------------------------------------------------

    private VillageInvitation loadForInvitee(UUID invitationId, UUID userId) {
        VillageInvitation invitation = invitationRepository.findById(invitationId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Invitation introuvable : " + invitationId));
        if (!userId.equals(invitation.getInvitedUserId())) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN, "Cette invitation ne vous est pas destinee.");
        }
        return invitation;
    }

    /** Cree la subscription MEMBER si absente et incremente memberCount. Idempotent. */
    private void ensureMemberSubscription(UUID userId, Village village) {
        Optional<VillageSubscription> existing =
                subscriptionRepository.findByUserIdAndVillageId(userId, village.getId());
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
                .villageId(village.getId())
                .type(VillageSubscription.SubscriptionType.MEMBER)
                .build());
        village.setMemberCount(village.getMemberCount() + 1);
        villageRepository.save(village);
    }

    private String displayNameOf(UUID userId) {
        if (userId == null) {
            return null;
        }
        return userRepository.findById(userId).map(User::getDisplayName).orElse(null);
    }

    private VillageInvitationDto toDto(VillageInvitation inv, String villageName, String invitedByName) {
        return new VillageInvitationDto(
                inv.getId(),
                inv.getVillageId(),
                villageName,
                invitedByName,
                inv.getStatus(),
                inv.getMessage(),
                inv.getCreatedAt());
    }
}
