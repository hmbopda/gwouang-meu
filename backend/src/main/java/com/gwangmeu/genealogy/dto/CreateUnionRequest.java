package com.gwangmeu.genealogy.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateUnionRequest {
    @NotNull private UUID husbandId;
    @NotNull private UUID wifeId;
    @NotNull private List<String> unionTypes;
    private LocalDate startDate;
    @JsonProperty("isDotPaid")
    private boolean isDotPaid;
    private LocalDate dotDate;
    private UUID dotPaidBy;
    private String dotDescription;
    private List<UUID> dotWitnesses;
}
