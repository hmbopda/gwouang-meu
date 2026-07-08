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
    /** Regime legal declare (ex: CIVIL, CUSTOMARY, RELIGIOUS). Optionnel. */
    private String legalRegime;
    /** Pays de celebration / droit applicable, ISO-3166 alpha-2. Optionnel. */
    private String legalCountry;
    private LocalDate startDate;
    @JsonProperty("isDotPaid")
    private boolean isDotPaid;
    private LocalDate dotDate;
    private UUID dotPaidBy;
    private String dotDescription;
    private List<UUID> dotWitnesses;
}
