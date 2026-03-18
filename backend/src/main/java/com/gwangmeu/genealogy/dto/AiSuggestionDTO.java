package com.gwangmeu.genealogy.dto;

import com.gwangmeu.genealogy.domain.enums.AiSuggestionStatusEnum;
import lombok.*;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AiSuggestionDTO {
    private UUID id;
    private UUID personAId;
    private UUID personBId;
    private PersonDTO personA;
    private PersonDTO personB;
    private String suggestedRelation;
    private double confidence;
    private List<String> reasons;
    private AiSuggestionStatusEnum status;
    private Instant createdAt;
    private Instant expiresAt;
}
