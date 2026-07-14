package com.gwangmeu.language.ai.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.*;

/**
 * Requete de traduction.
 * languageCode est optionnel : defaut = "moye-bandenkop" (seule langue disponible a ce jour).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TranslateRequest {

    /** Code de la langue native concernee (ex. "moye-bandenkop"). Optionnel. */
    private String languageCode;

    /** Sens de traduction : FR_TO_NATIVE | NATIVE_TO_FR. */
    @NotNull(message = "direction est obligatoire (FR_TO_NATIVE | NATIVE_TO_FR)")
    private TranslationDirection direction;

    /** Texte a traduire. */
    @NotBlank(message = "text est obligatoire")
    @Size(max = 2000, message = "text ne doit pas depasser 2000 caracteres")
    private String text;
}
