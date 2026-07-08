package com.gwangmeu.genealogy.dto;

import com.gwangmeu.genealogy.domain.AiGenealogySuggestion;
import com.gwangmeu.genealogy.domain.GenealogyUnion;
import com.gwangmeu.genealogy.domain.ParentChild;
import com.gwangmeu.genealogy.domain.Person;

import java.util.Arrays;
import java.util.List;
import java.util.UUID;

public final class GenealogyMapper {

    private GenealogyMapper() {}

    public static PersonDTO toDTO(Person p, List<UUID> villageIds) {
        return toDTO(p, villageIds, null);
    }

    /**
     * Variante avec nom de clan resolu (coalesce person_clans M2M / colonne legacy persons.clan).
     * Si {@code resolvedClanName} est null, la colonne legacy est utilisee.
     */
    public static PersonDTO toDTO(Person p, List<UUID> villageIds, String resolvedClanName) {
        if (p == null) return null;
        return PersonDTO.builder()
                .id(p.getId())
                .firstName(p.getFirstName())
                .lastName(p.getLastName())
                .maidenName(p.getMaidenName())
                .gender(p.getGender())
                .birthDate(p.getBirthDate())
                .birthPlace(p.getBirthPlace())
                .deathDate(p.getDeathDate())
                .isAlive(p.isAlive())
                .clan(resolvedClanName != null && !resolvedClanName.isBlank() ? resolvedClanName : p.getClan())
                .totem(p.getTotem())
                .nativeLanguage(p.getNativeLanguage())
                .religion(p.getReligion())
                .profession(p.getProfession())
                .email(p.getEmail())
                .phone(p.getPhone())
                .maritalStatus(p.getMaritalStatus() != null ? p.getMaritalStatus().name() : null)
                .residenceCountry(p.getResidenceCountry())
                .maritalRegime(p.getMaritalRegime())
                .photoUrl(p.getPhotoUrl())
                .privacy(p.getPrivacy())
                .status(p.getStatus())
                .userId(p.getUserId())
                .villageIds(villageIds != null ? villageIds : List.of())
                .createdAt(p.getCreatedAt())
                .updatedAt(p.getUpdatedAt())
                .build();
    }

    /**
     * Variante enrichie : rattache l'enfant a ses parents (mother/father) et,
     * si derivable, a l'union correspondante. Permet au front de regrouper les
     * enfants par mere / co-epouse.
     */
    public static PersonDTO toChildDTO(Person p, List<UUID> villageIds,
                                        UUID motherId, UUID fatherId, UUID unionId) {
        PersonDTO dto = toDTO(p, villageIds);
        if (dto == null) return null;
        dto.setMotherId(motherId != null ? motherId.toString() : null);
        dto.setFatherId(fatherId != null ? fatherId.toString() : null);
        dto.setUnionId(unionId != null ? unionId.toString() : null);
        return dto;
    }

    public static UnionDTO toDTO(GenealogyUnion u, Person husband, Person wife) {
        if (u == null) return null;
        return UnionDTO.builder()
                .id(u.getId())
                .husbandId(u.getHusbandId())
                .wifeId(u.getWifeId())
                .husband(toDTO(husband, null))
                .wife(toDTO(wife, null))
                .unionTypes(u.getUnionTypes() != null ? Arrays.asList(u.getUnionTypes()) : List.of())
                .unionOrder(u.getUnionOrder())
                .startDate(u.getStartDate())
                .endDate(u.getEndDate())
                .isActive(u.isActive())
                .status(u.getStatus())
                .endReason(u.getEndReason())
                .isDotPaid(u.isDotPaid())
                .dotDate(u.getDotDate())
                .dotPaidBy(u.getDotPaidBy())
                .dotDescription(u.getDotDescription())
                .dotWitnesses(u.getDotWitnesses() != null ? Arrays.asList(u.getDotWitnesses()) : List.of())
                .legalRegime(u.getLegalRegime())
                .isPolygamous(u.isPolygamous())
                .legalCountry(u.getLegalCountry())
                .complianceStatus(u.getComplianceStatus())
                .complianceNote(u.getComplianceNote())
                .build();
    }

    public static ParentChildDTO toDTO(ParentChild pc) {
        if (pc == null) return null;
        return ParentChildDTO.builder()
                .id(pc.getId())
                .parentId(pc.getParentId())
                .childId(pc.getChildId())
                .parentRole(pc.getParentRole())
                .parentType(pc.getParentType())
                .isAdopted(pc.isAdopted())
                .confidence(pc.getConfidence())
                .source(pc.getSource())
                .build();
    }

    public static AiSuggestionDTO toDTO(AiGenealogySuggestion s, Person personA, Person personB) {
        if (s == null) return null;
        return AiSuggestionDTO.builder()
                .id(s.getId())
                .personAId(s.getPersonAId())
                .personBId(s.getPersonBId())
                .personA(toDTO(personA, null))
                .personB(toDTO(personB, null))
                .suggestedRelation(s.getSuggestedRelation())
                .confidence(s.getConfidence().doubleValue())
                .reasons(s.getReasons())
                .status(s.getStatus())
                .createdAt(s.getCreatedAt())
                .expiresAt(s.getExpiresAt())
                .build();
    }
}
