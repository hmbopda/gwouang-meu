package com.gwangmeu.genealogy.application;

import com.gwangmeu.genealogy.domain.CountryMarriageRule;
import com.gwangmeu.genealogy.domain.GenealogyUnion;
import com.gwangmeu.genealogy.infrastructure.CountryMarriageRuleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Evalue la conformite d'une nouvelle union au droit civil du pays de
 * residence/celebration.
 *
 * REGLE D'OR : on ENREGISTRE TOUJOURS le fait genealogique. Le vocabulaire
 * parle de « conformite au droit civil », jamais de « legitimite ».
 *
 * La SEULE exception dure (rejet) est une 2e union active de regime
 * CIVIL/monogamique dans un pays ou la polygamie est FORBIDDEN — cas
 * particulier generalise a partir de l'ancien blocage « CIVIL impose la
 * monogamie ». Tout le reste est persiste avec un complianceStatus.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ComplianceService {

    private final CountryMarriageRuleRepository ruleRepository;

    /** Cache memoire ISO2(maj) -> regle. */
    private final ConcurrentHashMap<String, CountryMarriageRule> cache = new ConcurrentHashMap<>();

    // Statuts de conformite
    public static final String COMPLIANT = "COMPLIANT";
    public static final String WARNING = "WARNING";
    public static final String NON_COMPLIANT = "NON_COMPLIANT";
    public static final String UNKNOWN = "UNKNOWN";

    // Valeurs polygamy du referentiel
    private static final String POLY_ALLOWED = "ALLOWED";
    private static final String POLY_CONDITIONAL = "CONDITIONAL";
    private static final String POLY_FORBIDDEN = "FORBIDDEN";

    /**
     * Regle pays (referentiel), depuis le cache memoire. Vide si pays absent
     * ou iso2 null/blanc → traite UNKNOWN a l'execution.
     */
    public Optional<CountryMarriageRule> getRule(String code) {
        if (code == null || code.isBlank()) return Optional.empty();
        String key = code.trim().toUpperCase();
        // Le front envoie le code de la table countries (ISO-3, ex "CMR"), mais le
        // referentiel est saisi en ISO-2 (ex "CM"). On tente les deux pour rester
        // tolerant quelle que soit la source du code pays.
        CountryMarriageRule cached = cache.computeIfAbsent(key, k -> {
            Optional<CountryMarriageRule> r = ruleRepository.findByIso2IgnoreCase(k);
            if (r.isEmpty()) r = ruleRepository.findByIso3IgnoreCase(k);
            return r.orElse(null);
        });
        return Optional.ofNullable(cached);
    }

    /**
     * Le mariage entre personnes de meme sexe est-il reconnu par le droit du
     * pays ? Lit la regle du referentiel (tolerant ISO-2/ISO-3 via getRule).
     * Pays inconnu ou absent → false : contexte par defaut heterosexuel, plus
     * prudent pour ce public (pays africains cibles ou l'union unit un homme et
     * une femme).
     */
    public boolean isSameSexAllowed(String countryCode) {
        return getRule(countryCode)
                .map(CountryMarriageRule::isSameSexAllowed)
                .orElse(false);
    }

    /** Resultat d'une evaluation de conformite. */
    public record ComplianceResult(String status, String note) {}

    /**
     * Evalue la conformite d'une nouvelle union.
     *
     * @param legalRegime   regime legal declare (ex: CIVIL, CUSTOMARY, RELIGIOUS) — nullable
     * @param legalCountry  pays de celebration/droit applicable, ISO-2 — nullable
     * @param existingActiveUnions unions actives existantes de la personne concernee
     * @param isNewUnionAdditional true si cette union porte le total actif de la personne a >= 2
     */
    public ComplianceResult evaluate(String legalRegime, String legalCountry,
                                     List<GenealogyUnion> existingActiveUnions,
                                     boolean isNewUnionAdditional) {
        Optional<CountryMarriageRule> ruleOpt = getRule(legalCountry);
        if (ruleOpt.isEmpty()) {
            return new ComplianceResult(UNKNOWN,
                    "Pays non renseigne ou absent du referentiel : conformite au droit civil non evaluee.");
        }

        CountryMarriageRule rule = ruleOpt.get();
        String polygamy = rule.getPolygamy() != null ? rule.getPolygamy().toUpperCase() : "";
        String countryName = rule.getCountryName() != null ? rule.getCountryName() : rule.getIso2();
        boolean isCivil = isCivilRegime(legalRegime);

        // Union unique (1ere union active) : conforme partout.
        if (!isNewUnionAdditional) {
            return new ComplianceResult(COMPLIANT,
                    "Union enregistree, conforme au droit civil de " + countryName + ".");
        }

        // Union additionnelle (>= 2 actives) : la conformite depend du pays.
        switch (polygamy) {
            case POLY_ALLOWED:
                return new ComplianceResult(COMPLIANT,
                        "Union polygame enregistree, admise par le droit civil de " + countryName + ".");
            case POLY_CONDITIONAL:
                return new ComplianceResult(WARNING,
                        "Union polygame enregistree. En " + countryName + ", elle suppose une option de "
                                + "polygamie declaree a l'etat civil ; a verifier au regard du regime choisi lors du mariage.");
            case POLY_FORBIDDEN:
                if (isCivil) {
                    // Cas particulier : 2e union CIVIL/monogamique en pays FORBIDDEN → traite en amont (rejet).
                    return new ComplianceResult(NON_COMPLIANT,
                            "Une 2e union civile active n'est pas conforme au droit civil de " + countryName
                                    + ", qui impose la monogamie.");
                }
                return new ComplianceResult(NON_COMPLIANT,
                        "Union additionnelle enregistree au titre du fait familial. Elle n'est pas conforme au "
                                + "droit civil de " + countryName + ", qui n'admet qu'une seule union civile a la fois.");
            default:
                return new ComplianceResult(UNKNOWN,
                        "Statut de polygamie inconnu pour " + countryName + " : conformite non evaluee.");
        }
    }

    /**
     * Determine s'il faut opposer un REFUS DUR (400). Seule exception autorisee :
     * 2e union active de regime CIVIL/monogamique dans un pays FORBIDDEN.
     *
     * @return true si l'union doit etre rejetee
     */
    public boolean mustHardReject(String legalRegime, String legalCountry, boolean isNewUnionAdditional) {
        if (!isNewUnionAdditional) return false;
        if (!isCivilRegime(legalRegime)) return false;
        return getRule(legalCountry)
                .map(r -> POLY_FORBIDDEN.equalsIgnoreCase(r.getPolygamy()))
                .orElse(false);
    }

    /**
     * Un regime est considere CIVIL/monogamique s'il contient "CIVIL" ou "MONOG".
     * (les unionTypes historiques utilisent "CIVIL").
     */
    public boolean isCivilRegime(String legalRegime) {
        if (legalRegime == null) return false;
        String r = legalRegime.toUpperCase();
        return r.contains("CIVIL") || r.contains("MONOG");
    }
}
