package com.gwangmeu.genealogy.dto;

import com.gwangmeu.genealogy.domain.enums.AssociationRequestStatus;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ChildAssociationRequestDTO {
    private UUID id;
    private UUID childId;
    private String childName;
    private UUID requesterId;
    private String requesterName;
    private UUID targetParentId;
    private String targetParentName;
    private AssociationRequestStatus status;
    private Instant createdAt;
    private Instant respondedAt;
}
