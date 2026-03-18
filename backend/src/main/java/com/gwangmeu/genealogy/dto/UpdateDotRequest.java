package com.gwangmeu.genealogy.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

import java.time.LocalDate;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateDotRequest {
    @JsonProperty("isDotPaid")
    private boolean isDotPaid;
    private LocalDate dotDate;
    private UUID dotPaidBy;
    private String dotDescription;
}
