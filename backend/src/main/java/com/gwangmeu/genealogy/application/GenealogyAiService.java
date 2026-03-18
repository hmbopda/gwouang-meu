package com.gwangmeu.genealogy.application;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gwangmeu.genealogy.domain.AiGenealogySuggestion;
import com.gwangmeu.genealogy.domain.Person;
import com.gwangmeu.genealogy.domain.enums.AiSuggestionStatusEnum;
import com.gwangmeu.genealogy.dto.AiSuggestionDTO;
import com.gwangmeu.genealogy.dto.GenealogyMapper;
import com.gwangmeu.genealogy.infrastructure.AiGenealogySuggestionRepository;
import com.gwangmeu.genealogy.infrastructure.PersonNodeRepository;
import com.gwangmeu.genealogy.infrastructure.PersonRepository;
import com.gwangmeu.genealogy.infrastructure.PersonVillageRepository;
import com.gwangmeu.genealogy.neo4j.PersonNode;
import com.gwangmeu.shared.ai.ClaudeAiClient;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class GenealogyAiService {

    private final ClaudeAiClient claudeAiClient;
    private final PersonRepository personRepository;
    private final PersonNodeRepository personNodeRepository;
    private final PersonVillageRepository personVillageRepository;
    private final AiGenealogySuggestionRepository aiSuggestionRepository;
    private final ObjectMapper objectMapper;

    private static final String SYSTEM_PROMPT = """
            Tu es un expert en genealogie africaine specialise dans les structures familiales
            des peuples d'Afrique centrale et occidentale.

            Analyse l'arbre genealogique partiel fourni et identifie les liens familiaux
            probables entre la personne centrale et les candidats.

            Regles :
            - Un enfant a EXACTEMENT 2 parents biologiques (pere + mere)
            - Un homme peut avoir plusieurs epouses (polygamie possible)
            - Utilise le clan, le totem, le village, les dates et les noms pour inferer les liens
            - Ne jamais affirmer avec certitude : toujours un score de confiance
            - Score < 0.3 : ne pas suggerer
            - Retourne UNIQUEMENT du JSON valide, aucun texte avant ni apres

            Format de sortie JSON :
            {
              "suggestions": [
                {
                  "person_a_id": "uuid",
                  "person_b_id": "uuid",
                  "suggested_relation": "FATHER|MOTHER|CHILD|SIBLING|WIFE",
                  "confidence": 0.0-1.0,
                  "reasons": ["raison 1", "raison 2"]
                }
              ]
            }
            """;

    public List<AiSuggestionDTO> suggestLinks(UUID personId) {
        Person person = personRepository.findById(personId)
                .orElseThrow(() -> new IllegalArgumentException("Person not found: " + personId));

        // Recuperer les parents/enfants connus
        List<PersonNode> knownParents = personNodeRepository.findParents(personId.toString());
        List<PersonNode> knownChildren = personNodeRepository.findChildren(personId.toString());
        List<PersonNode> knownSiblings = personNodeRepository.findSiblings(personId.toString());

        // Candidats : meme clan, sans lien connu
        List<PersonNode> candidates = person.getClan() != null
                ? personNodeRepository.findUnconnectedClanMembers(person.getClan())
                : List.of();

        if (candidates.isEmpty()) {
            log.info("No unconnected clan members found for person {}", personId);
            return List.of();
        }

        // Construire le contexte
        String userMessage = buildContext(person, knownParents, knownChildren, knownSiblings, candidates);

        // Appeler Claude
        String response;
        try {
            response = claudeAiClient.complete(ClaudeAiClient.SONNET, SYSTEM_PROMPT, userMessage, 2048);
        } catch (Exception e) {
            log.error("Claude AI call failed for person {}: {}", personId, e.getMessage());
            return List.of();
        }

        // Parser et sauvegarder
        return parseSuggestionsAndSave(personId, response);
    }

    private String buildContext(Person person, List<PersonNode> parents,
                                 List<PersonNode> children, List<PersonNode> siblings,
                                 List<PersonNode> candidates) {
        StringBuilder sb = new StringBuilder();
        sb.append("Personne centrale:\n");
        List<UUID> villageIds = personVillageRepository.findVillageIdsByPersonId(person.getId());
        sb.append(String.format("  id: %s, nom: %s %s, genre: %s, clan: %s, totem: %s, villages: %s\n",
                person.getId(), person.getFirstName(), person.getLastName(),
                person.getGender(), person.getClan(), person.getTotem(), villageIds));

        sb.append("\nParents connus:\n");
        for (PersonNode p : parents) {
            sb.append(String.format("  id: %s, nom: %s %s, genre: %s, clan: %s\n",
                    p.getPostgresId(), p.getFirstName(), p.getLastName(), p.getGender(), p.getClan()));
        }

        sb.append("\nEnfants connus:\n");
        for (PersonNode c : children) {
            sb.append(String.format("  id: %s, nom: %s %s, genre: %s\n",
                    c.getPostgresId(), c.getFirstName(), c.getLastName(), c.getGender()));
        }

        sb.append("\nFreres/Soeurs connus:\n");
        for (PersonNode s : siblings) {
            sb.append(String.format("  id: %s, nom: %s %s, genre: %s\n",
                    s.getPostgresId(), s.getFirstName(), s.getLastName(), s.getGender()));
        }

        sb.append("\nCandidats (meme clan, sans lien connu):\n");
        for (PersonNode c : candidates) {
            sb.append(String.format("  id: %s, nom: %s %s, genre: %s, clan: %s, totem: %s\n",
                    c.getPostgresId(), c.getFirstName(), c.getLastName(),
                    c.getGender(), c.getClan(), c.getTotem()));
        }

        return sb.toString();
    }

    @SuppressWarnings("unchecked")
    private List<AiSuggestionDTO> parseSuggestionsAndSave(UUID personId, String response) {
        List<AiSuggestionDTO> result = new ArrayList<>();
        try {
            Map<String, Object> parsed = objectMapper.readValue(response, new TypeReference<>() {});
            List<Map<String, Object>> suggestions = (List<Map<String, Object>>) parsed.get("suggestions");

            if (suggestions == null) return result;

            for (Map<String, Object> s : suggestions) {
                double confidence = ((Number) s.get("confidence")).doubleValue();
                if (confidence < 0.3) continue;

                UUID personAId = UUID.fromString((String) s.get("person_a_id"));
                UUID personBId = UUID.fromString((String) s.get("person_b_id"));
                String relation = (String) s.get("suggested_relation");
                List<String> reasons = (List<String>) s.get("reasons");

                AiGenealogySuggestion entity = AiGenealogySuggestion.builder()
                        .personAId(personAId)
                        .personBId(personBId)
                        .suggestedRelation(relation)
                        .confidence(BigDecimal.valueOf(confidence))
                        .reasons(reasons)
                        .status(AiSuggestionStatusEnum.PENDING)
                        .expiresAt(Instant.now().plus(90, ChronoUnit.DAYS))
                        .build();

                AiGenealogySuggestion saved = aiSuggestionRepository.save(entity);

                Person a = personRepository.findById(personAId).orElse(null);
                Person b = personRepository.findById(personBId).orElse(null);
                result.add(GenealogyMapper.toDTO(saved, a, b));
            }

            log.info("AI generated {} suggestions for person {}", result.size(), personId);
        } catch (Exception e) {
            log.error("Failed to parse AI suggestions for person {}: {}", personId, e.getMessage());
        }
        return result;
    }
}
