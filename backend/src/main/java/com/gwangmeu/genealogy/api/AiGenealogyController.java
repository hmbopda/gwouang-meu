package com.gwangmeu.genealogy.api;

import com.gwangmeu.genealogy.application.GenealogyService;
import com.gwangmeu.genealogy.dto.AiSuggestionDTO;
import com.gwangmeu.shared.api.ApiResponse;
import com.gwangmeu.shared.security.CurrentUser;
import com.gwangmeu.shared.security.UserIdResolver;
import io.swagger.v3.oas.annotations.Operation;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/v1/genealogy/ai")
@RequiredArgsConstructor
public class AiGenealogyController {

    private final GenealogyService genealogyService;
    private final UserIdResolver userIdResolver;

    @PostMapping("/suggest/{personId}")
    @Operation(summary = "Generate AI link suggestions for a person")
    public ResponseEntity<ApiResponse<List<AiSuggestionDTO>>> generateAiSuggestions(
            @PathVariable UUID personId) {
        List<AiSuggestionDTO> suggestions = genealogyService.generateAiSuggestions(personId);
        return ResponseEntity.ok(ApiResponse.ok(suggestions));
    }

    @GetMapping("/suggestions/{personId}")
    @Operation(summary = "Get pending AI suggestions for a person")
    public ResponseEntity<ApiResponse<List<AiSuggestionDTO>>> getPendingSuggestions(
            @PathVariable UUID personId) {
        return ResponseEntity.ok(ApiResponse.ok(genealogyService.getPendingSuggestions(personId)));
    }

    @PutMapping("/suggestions/{id}/review")
    @Operation(summary = "Accept or reject an AI suggestion")
    public ResponseEntity<ApiResponse<AiSuggestionDTO>> reviewAiSuggestion(
            @PathVariable UUID id,
            @RequestBody Map<String, Boolean> body,
            @CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        boolean accepted = Boolean.TRUE.equals(body.get("accepted"));
        AiSuggestionDTO result = genealogyService.reviewAiSuggestion(id, accepted, userId);
        return ResponseEntity.ok(ApiResponse.ok(result));
    }
}
