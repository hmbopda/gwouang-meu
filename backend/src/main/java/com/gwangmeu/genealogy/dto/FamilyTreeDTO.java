package com.gwangmeu.genealogy.dto;

import lombok.*;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FamilyTreeDTO {
    private PersonDTO subject;
    private List<PersonDTO> father;
    private List<PersonDTO> mother;
    private List<PersonDTO> paternalGP;
    private List<PersonDTO> maternalGP;
    private List<SiblingDTO> siblings;
    private List<PersonDTO> children;
    private List<UnionDTO> unions;
    private List<PersonDTO> cousins;
    private List<PersonDTO> uncles;
    private List<AiSuggestionDTO> pendingSuggestions;
}
