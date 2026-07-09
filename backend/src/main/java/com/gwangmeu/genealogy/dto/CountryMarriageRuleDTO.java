package com.gwangmeu.genealogy.dto;

import com.gwangmeu.genealogy.domain.CountryMarriageRule;
import lombok.*;

import java.util.List;

/**
 * Regle de mariage d'un pays exposee a l'UI (lecture seule).
 * Un pays absent du referentiel renvoie polygamy=UNKNOWN.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CountryMarriageRuleDTO {
    private String iso2;
    private String countryName;
    /** ALLOWED | CONDITIONAL | FORBIDDEN | UNKNOWN */
    private String polygamy;
    private List<String> regimes;
    private String legalBasis;
    private String sourceUrl;
    private boolean isAdvisory;
    /** Mariage entre personnes de meme sexe reconnu par le pays (defaut false). */
    private boolean sameSexAllowed;

    public static CountryMarriageRuleDTO fromEntity(CountryMarriageRule r) {
        return CountryMarriageRuleDTO.builder()
                .iso2(r.getIso2())
                .countryName(r.getCountryName())
                .polygamy(r.getPolygamy())
                .regimes(splitRegimes(r.getRegimes()))
                .legalBasis(r.getLegalBasis())
                .sourceUrl(r.getSourceUrl())
                .isAdvisory(r.isAdvisory())
                .sameSexAllowed(r.isSameSexAllowed())
                .build();
    }

    /** Regle « inconnue » pour un pays absent du referentiel. */
    public static CountryMarriageRuleDTO unknown(String iso2) {
        return CountryMarriageRuleDTO.builder()
                .iso2(iso2 != null ? iso2.toUpperCase() : null)
                .polygamy("UNKNOWN")
                .regimes(List.of())
                .isAdvisory(true)
                .sameSexAllowed(false)
                .build();
    }

    private static List<String> splitRegimes(String csv) {
        if (csv == null || csv.isBlank()) return List.of();
        return java.util.Arrays.stream(csv.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .toList();
    }
}
