package com.gwangmeu.genealogy.api;

import com.gwangmeu.genealogy.application.PersonInvitationService;
import com.gwangmeu.genealogy.dto.AcceptInvitationRequest;
import com.gwangmeu.genealogy.dto.InvitationDTO;
import com.gwangmeu.genealogy.dto.InvitePersonRequest;
import com.gwangmeu.shared.api.ApiResponse;
import com.gwangmeu.shared.security.CurrentUser;
import com.gwangmeu.shared.security.UserIdResolver;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/invitations")
@RequiredArgsConstructor
public class InvitationController {

    private final PersonInvitationService invitationService;
    private final UserIdResolver userIdResolver;

    @PostMapping
    @Operation(summary = "Invite a living person to create their account")
    public ResponseEntity<ApiResponse<InvitationDTO>> invitePerson(
            @Valid @RequestBody InvitePersonRequest req,
            @CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        return ResponseEntity.status(201)
                .body(ApiResponse.created(invitationService.invitePerson(req, userId)));
    }

    @GetMapping("/token/{token}")
    @Operation(summary = "Get invitation details by token (public, for the invited person)")
    public ResponseEntity<ApiResponse<InvitationDTO>> getInvitation(@PathVariable String token) {
        return ResponseEntity.ok(ApiResponse.ok(invitationService.getInvitationByToken(token)));
    }

    @PostMapping("/token/{token}/accept")
    @Operation(summary = "Accept an invitation and link to the new user account")
    public ResponseEntity<ApiResponse<InvitationDTO>> acceptInvitation(
            @PathVariable String token,
            @Valid @RequestBody AcceptInvitationRequest req,
            @CurrentUser Jwt jwt) {
        // Le user invité vient de créer son compte Supabase, il peut ne pas encore
        // exister dans la table users → on passe le supabaseId pour auto-creation
        String supabaseId = jwt != null ? jwt.getSubject() : null;
        String email = jwt != null ? jwt.getClaimAsString("email") : null;
        return ResponseEntity.ok(ApiResponse.ok(
                invitationService.acceptInvitation(token, req, supabaseId, email)));
    }
}
