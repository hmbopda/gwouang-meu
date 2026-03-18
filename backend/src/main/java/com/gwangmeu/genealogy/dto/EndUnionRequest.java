package com.gwangmeu.genealogy.dto;

import com.gwangmeu.genealogy.domain.enums.EndReasonEnum;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EndUnionRequest {
    @NotNull private EndReasonEnum endReason;
    private LocalDate endDate;
}
