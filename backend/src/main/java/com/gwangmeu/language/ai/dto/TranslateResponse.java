package com.gwangmeu.language.ai.dto;

import lombok.*;

/**
 * Resultat d'une traduction produite par le moteur IA + dictionnaire.
 * confidence : indice 0..1 (1 = forme directement attestee).
 * pronunciation / notes peuvent etre null si non disponibles.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TranslateResponse {
    private String translation;
    private String pronunciation;
    private double confidence;
    private String notes;
    private String sourceText;
    private TranslationDirection direction;
}
