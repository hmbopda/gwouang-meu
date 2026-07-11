package com.gwangmeu.geo.dto;

import com.gwangmeu.geo.domain.Country;
import io.swagger.v3.oas.annotations.media.Schema;

import java.util.UUID;

/**
 * DTO flat pour la liste des pays.
 * flagEmoji prioritaire sur flagUrl (economise la bande passante).
 */
@Schema(description = "Pays africain avec emoji drapeau et statistiques")
public record CountryDto(

        @Schema(description = "ID du pays") UUID id,
        @Schema(description = "Code ISO alpha-3", example = "CMR") String isoCode,
        @Schema(description = "Code ISO alpha-2", example = "CM") String iso2,
        @Schema(description = "Nom du pays", example = "Cameroun") String name,
        @Schema(description = "Code du continent", example = "AF-CENTRAL") String continentCode,
        @Schema(description = "Emoji drapeau (ultra-compact)", example = "\uD83C\uDDE8\uD83C\uDDF2") String flagEmoji,
        @Schema(description = "URL SVG du drapeau (fallback CDN)") String flagUrl,
        @Schema(description = "Indicatif telephonique", example = "+237") String phoneCode,
        @Schema(description = "Nombre de villages enregistres") long villageCount
) {
    public static CountryDto from(Country c, long villageCount) {
        return new CountryDto(
                c.getId(), c.getIsoCode(), c.getIso2(), c.getName(),
                c.getContinentCode(), c.getFlagEmoji(), c.getFlagUrl(),
                c.getPhoneCode(), villageCount
        );
    }
}
