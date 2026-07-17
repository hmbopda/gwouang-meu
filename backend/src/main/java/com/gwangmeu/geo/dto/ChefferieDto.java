package com.gwangmeu.geo.dto;

import com.gwangmeu.geo.domain.Chefferie;
import io.swagger.v3.oas.annotations.media.Schema;

import java.util.Locale;
import java.util.UUID;
import java.util.regex.Pattern;

/**
 * DTO flat pour une chefferie traditionnelle.
 */
@Schema(description = "Chefferie traditionnelle")
public record ChefferieDto(
        @Schema(description = "Identifiant référentiel de la chefferie") UUID id,
        @Schema(description = "Degre de la chefferie", example = "2") Short degre,
        @Schema(description = "Nom de la region") String regionName,
        @Schema(description = "Nom du departement") String departmentName,
        @Schema(description = "Code du departement") String departmentCode,
        @Schema(description = "Numero d'ordre") Integer numero,
        @Schema(description = "Denomination brute (ex: 'Chefferie BANDENKOP')") String denomination,
        @Schema(description = "Libelle propre pour affichage (ex: 'Bandenkop')") String label
) {
    public static ChefferieDto from(Chefferie c) {
        // Dual-read : le champ structuré `proper_name` (V60) prime ; à défaut,
        // repli sur le nettoyage regex — la regex quitte peu à peu le runtime.
        final String proper = c.getProperName();
        final String label = (proper != null && !proper.isBlank())
                ? cleanLabel(proper)
                : cleanLabel(c.getDenomination());
        return new ChefferieDto(
                c.getId(), c.getDegre(), c.getRegionName(), c.getDepartmentName(),
                c.getDepartmentCode(), c.getNumero(), c.getDenomination(), label
        );
    }

    // Préfixes administratifs à retirer pour l'affichage (insensible à la casse).
    private static final Pattern PREFIX = Pattern.compile(
            "^(chefferie sup[eé]rieure|chefferie|lamidat de|lamidat|sultanat de|sultanat|canton|groupement)\\s+",
            Pattern.CASE_INSENSITIVE);

    /**
     * Libellé lisible : retire le préfixe administratif et normalise la casse
     * si la dénomination est tout en majuscules ('Chefferie BANDENKOP' → 'Bandenkop').
     */
    public static String cleanLabel(String denomination) {
        if (denomination == null || denomination.isBlank()) return denomination;
        String s = PREFIX.matcher(denomination.trim()).replaceFirst("").trim();
        if (s.isEmpty()) s = denomination.trim();
        if (s.equals(s.toUpperCase(Locale.ROOT))) {
            s = titleCase(s);
        }
        return s;
    }

    /** Title-case tolérant aux séparateurs (espace, tiret, apostrophe). */
    private static String titleCase(String s) {
        StringBuilder out = new StringBuilder(s.length());
        boolean capNext = true;
        for (int i = 0; i < s.length(); i++) {
            char ch = s.charAt(i);
            if (ch == ' ' || ch == '-' || ch == '\'' || ch == '/') {
                capNext = true;
                out.append(ch);
            } else if (capNext) {
                out.append(Character.toUpperCase(ch));
                capNext = false;
            } else {
                out.append(Character.toLowerCase(ch));
            }
        }
        return out.toString();
    }
}
