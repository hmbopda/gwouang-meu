package com.gwangmeu.language.ai;

import com.gwangmeu.language.ai.dto.TranslateRequest;
import com.gwangmeu.language.ai.dto.TranslateResponse;
import com.gwangmeu.shared.api.ApiResponse;
import com.gwangmeu.shared.security.CurrentUser;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Moteur de traduction francais <-> langue native (IA Claude + dictionnaire injecte).
 * Endpoint authentifie (regle par defaut anyRequest().authenticated() de SecurityConfig).
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/translate")
@RequiredArgsConstructor
public class TranslationController {

    private final TranslationService translationService;
    private final TranslationAccessGuard accessGuard;

    @PostMapping
    @Operation(summary = "Traduire un texte francais <-> langue native (moteur IA + dictionnaire)")
    public ResponseEntity<ApiResponse<TranslateResponse>> translate(
            @Valid @RequestBody TranslateRequest request,
            @CurrentUser Jwt jwt) {
        accessGuard.enforce(jwt); // quota 5/jour hors admin de village & super-admin
        TranslateResponse result = translationService.translate(request);
        return ResponseEntity.ok(ApiResponse.ok(result));
    }

    /** 429 — quota quotidien de traductions atteint (utilisateur non privilegie). */
    @ExceptionHandler(TranslationLimitException.class)
    public ResponseEntity<ApiResponse<Void>> handleLimit(TranslationLimitException ex) {
        return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
                .body(ApiResponse.error(ex.getMessage(), 429));
    }

    /** 503 — couche IA indisponible (cle absente, appel Claude en echec, reponse illisible). */
    @ExceptionHandler(TranslationUnavailableException.class)
    public ResponseEntity<ApiResponse<Void>> handleUnavailable(TranslationUnavailableException ex) {
        log.warn("Translation unavailable: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                .body(ApiResponse.error(ex.getMessage(), 503));
    }
}
