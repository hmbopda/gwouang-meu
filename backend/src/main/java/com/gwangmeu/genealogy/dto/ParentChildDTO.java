package com.gwangmeu.genealogy.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.gwangmeu.genealogy.domain.enums.ParentRoleEnum;
import com.gwangmeu.genealogy.domain.enums.ParentTypeEnum;
import com.gwangmeu.genealogy.domain.enums.RelationSourceEnum;
import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ParentChildDTO {
    private UUID id;
    private UUID parentId;
    private UUID childId;
    private ParentRoleEnum parentRole;
    private ParentTypeEnum parentType;
    @JsonProperty("isAdopted")
    private boolean isAdopted;
    private BigDecimal confidence;
    private RelationSourceEnum source;
}
