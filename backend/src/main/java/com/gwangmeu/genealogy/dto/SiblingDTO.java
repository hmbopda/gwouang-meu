package com.gwangmeu.genealogy.dto;

import com.gwangmeu.genealogy.domain.enums.SiblingTypeEnum;
import lombok.*;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SiblingDTO {
    private PersonDTO person;
    private SiblingTypeEnum type;
    private UUID sharedParentId;
}
