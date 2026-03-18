package com.gwangmeu.genealogy.dto;

import com.gwangmeu.genealogy.domain.enums.ParentRoleEnum;
import com.gwangmeu.genealogy.domain.enums.ParentTypeEnum;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LinkParentChildRequest {
    @NotNull private UUID parentId;
    @NotNull private UUID childId;
    @NotNull private ParentRoleEnum role;
    private ParentTypeEnum type;
}
