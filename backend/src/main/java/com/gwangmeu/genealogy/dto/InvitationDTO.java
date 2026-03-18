package com.gwangmeu.genealogy.dto;

import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InvitationDTO {
    private UUID id;
    private UUID personId;
    private String email;
    private String phone;
    private String token;
    private String status;
    private UUID invitedBy;
    private String inviterName;
    private String invitationType;
    private PersonDTO person;
    private Instant createdAt;
    private Instant expiresAt;
}
