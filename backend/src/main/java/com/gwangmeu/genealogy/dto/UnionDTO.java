package com.gwangmeu.genealogy.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.gwangmeu.genealogy.domain.enums.EndReasonEnum;
import lombok.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UnionDTO {
    private UUID id;
    private UUID husbandId;
    private UUID wifeId;
    private PersonDTO husband;
    private PersonDTO wife;
    private List<String> unionTypes;
    private int unionOrder;
    private LocalDate startDate;
    private LocalDate endDate;
    @JsonProperty("isActive")
    private boolean isActive;
    private String status;
    private EndReasonEnum endReason;
    @JsonProperty("isDotPaid")
    private boolean isDotPaid;
    private LocalDate dotDate;
    private UUID dotPaidBy;
    private String dotDescription;
    private List<UUID> dotWitnesses;
}
