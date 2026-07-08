package com.gwangmeu.genealogy.domain.enums;

/**
 * Regime matrimonial declare au niveau de la personne, refletant le
 * choix effectue aupres de l'etat civil de son pays de residence.
 *
 * On ENREGISTRE TOUJOURS le fait genealogique : ces valeurs decrivent la
 * realite historique/culturelle et ne portent aucun jugement de legitimite.
 */
public enum MaritalRegimeEnum {
    MONOGAMY,
    POLYGAMY,
    CUSTOMARY,
    DE_FACTO,
    UNKNOWN
}
