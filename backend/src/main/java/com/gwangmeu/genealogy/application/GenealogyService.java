package com.gwangmeu.genealogy.application;

import com.gwangmeu.genealogy.domain.enums.ParentRoleEnum;
import com.gwangmeu.genealogy.domain.enums.ParentTypeEnum;
import com.gwangmeu.genealogy.dto.*;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.Map;
import java.util.UUID;

public interface GenealogyService {

    // Persons
    PersonDTO createPerson(CreatePersonRequest req, UUID createdBy);
    PersonDTO updatePerson(UUID personId, UpdatePersonRequest req, UUID requestedBy);
    PersonDTO getPersonById(UUID personId);
    PersonDTO getMyPerson(UUID userId);
    Page<PersonDTO> getPersonsByVillage(UUID villageId, Pageable pageable);
    void deletePerson(UUID personId, UUID requestedBy);

    // Filiation
    ParentChildDTO linkParentChild(UUID parentId, UUID childId, ParentRoleEnum role, ParentTypeEnum type, UUID createdBy);
    void unlinkParentChild(UUID parentId, UUID childId, UUID requestedBy);
    PersonDTO createChild(UUID parentId, CreateChildRequest req, UUID createdBy);
    List<PersonDTO> checkDuplicate(DuplicateCheckRequest req);

    // Association enfant co-parent
    void acceptChildAssociation(UUID requestId, UUID responderId);
    void rejectChildAssociation(UUID requestId, UUID responderId);

    // Modification fiche enfant (< 4 ans)
    void requestChildModification(UUID personId, Map<String, Object> changes, UUID requestedBy);
    void acceptModificationRequest(UUID requestId, UUID responderId);
    void rejectModificationRequest(UUID requestId, UUID responderId);

    // Unions
    UnionDTO createUnion(CreateUnionRequest req, UUID createdBy);
    UnionDTO confirmUnion(UUID unionId, UUID confirmedBy);
    UnionDTO contestUnion(UUID unionId, UUID contestedBy, String reason);
    UnionDTO updateDotStatus(UUID unionId, UpdateDotRequest req, UUID requestedBy);
    void endUnion(UUID unionId, EndUnionRequest req, UUID requestedBy);
    List<UnionDTO> getUnionsByPerson(UUID personId);

    // Arbre
    FamilyTreeDTO getFullTree(UUID personId);
    List<PersonDTO> getParents(UUID personId);
    List<PersonDTO> getChildren(UUID personId);
    List<PersonDTO> getSiblings(UUID personId);
    List<PersonDTO> getGrandparents(UUID personId);
    List<PersonDTO> getFirstCousins(UUID personId);
    List<UnionDTO> getActiveSpouses(UUID personId);
    List<PersonDTO> getAncestors(UUID personId, int depth);
    List<PersonDTO> getDescendants(UUID personId, int depth);

    // Claude AI
    List<AiSuggestionDTO> generateAiSuggestions(UUID personId);
    List<AiSuggestionDTO> getPendingSuggestions(UUID personId);
    AiSuggestionDTO reviewAiSuggestion(UUID suggestionId, boolean accepted, UUID reviewedBy);
}
