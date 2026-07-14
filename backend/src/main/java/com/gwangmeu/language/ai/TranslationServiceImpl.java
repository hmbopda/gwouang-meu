package com.gwangmeu.language.ai;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gwangmeu.language.ai.dto.TranslateRequest;
import com.gwangmeu.language.ai.dto.TranslateResponse;
import com.gwangmeu.language.ai.dto.TranslationDirection;
import com.gwangmeu.shared.ai.ClaudeAiClient;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ClassPathResource;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.util.DigestUtils;
import org.springframework.util.StringUtils;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Implementation du moteur de traduction — optimise pour la vitesse.
 *
 * Principe :
 *  - le dictionnaire (lexique atteste + regles de codification) est charge UNE fois
 *    depuis le classpath et mis en cache memoire, puis injecte dans un system prompt
 *    STABLE (donc mis en cache cote API Anthropic via cache_control ephemeral) ;
 *  - Claude repond par un JSON strict {translation, pronunciation, confidence, notes} ;
 *  - il lui est INTERDIT d'inventer une forme native inexistante.
 *
 * Optimisations :
 *  1. Modele HAIKU (rapide + economique) par defaut, avec repli automatique sur SONNET
 *     si Haiku est indisponible pour le compte (bascule une fois, jamais de crash).
 *     Surchargeable via la propriete `application.translation-model`.
 *  2. Cache Redis des traductions (best-effort) : une phrase deja traduite revient
 *     instantanement, sans rappeler l'IA. Toute erreur Redis est ignoree.
 *  3. Contexte injecte compacte (JSON minifie), `max_tokens` borne.
 *
 * Aucune migration ni acces base SQL : lecture fichier ressource + cache Redis.
 * Si la cle API est absente au runtime -> TranslationUnavailableException (503) :
 * le demarrage n'est jamais impacte.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class TranslationServiceImpl implements TranslationService {

    private static final String DEFAULT_LANGUAGE = "moye-bandenkop";
    private static final int MAX_TOKENS = 800;
    private static final int MAX_LEXICON_ENTRIES = 3000;
    private static final Duration CACHE_TTL = Duration.ofDays(30);
    private static final String CACHE_PREFIX = "gw:tr:";

    private final ClaudeAiClient claudeAiClient;
    private final ObjectMapper objectMapper;
    private final RedisConnectionFactory redisConnectionFactory;

    /** Meme source de cle que ClaudeAiClient. Defaut vide -> pas de crash au boot. */
    @Value("${application.anthropic-api-key:}")
    private String anthropicApiKey;

    /** Force un modele precis (ex. un ID Haiku propre au compte). Vide -> Haiku puis repli Sonnet. */
    @Value("${application.translation-model:}")
    private String forcedModel;

    /** Cache memoire du contexte lexical, par code de langue (construit une fois). */
    private final Map<String, String> contextCache = new ConcurrentHashMap<>();

    /** Cache Redis best-effort (null si indisponible). */
    private StringRedisTemplate redis;

    /** Passe a false si le modele rapide echoue une fois (repli Sonnet le reste de la vie du process). */
    private volatile boolean fastModelOk = true;

    @PostConstruct
    void initRedis() {
        try {
            StringRedisTemplate t = new StringRedisTemplate(redisConnectionFactory);
            t.afterPropertiesSet();
            this.redis = t;
        } catch (Exception e) {
            log.warn("Cache Redis indisponible pour la traduction (on continue sans) : {}", e.getMessage());
            this.redis = null;
        }
    }

    @Override
    public TranslateResponse translate(TranslateRequest request) {
        String code = StringUtils.hasText(request.getLanguageCode())
                ? request.getLanguageCode().trim()
                : DEFAULT_LANGUAGE;
        TranslationDirection direction = request.getDirection() != null
                ? request.getDirection()
                : TranslationDirection.FR_TO_NATIVE;
        String text = request.getText() == null ? "" : request.getText().trim();

        if (!StringUtils.hasText(anthropicApiKey)) {
            throw new TranslationUnavailableException(
                    "Service de traduction indisponible : cle API IA non configuree.");
        }

        // 1. Cache Redis (instantané si déjà traduit).
        String cacheKey = cacheKey(code, direction, text);
        TranslateResponse cached = readCache(cacheKey, text, direction);
        if (cached != null) {
            return cached;
        }

        // 2. Peut lever IllegalArgumentException (langue non supportee) -> 400.
        String languageContext = getLanguageContext(code);
        String systemPrompt = buildSystemPrompt(code, languageContext);
        String userMessage = buildUserMessage(direction, text);

        // 3. Appel IA (Haiku rapide, repli Sonnet).
        String raw = callClaude(systemPrompt, userMessage, code, direction);

        // 4. Parse + mise en cache.
        return parseResponse(raw, text, direction, cacheKey);
    }

    // ------------------------------------------------------------------
    // Appel modele (Haiku -> repli Sonnet)
    // ------------------------------------------------------------------

    private String callClaude(String systemPrompt, String userMessage, String code, TranslationDirection direction) {
        if (StringUtils.hasText(forcedModel)) {
            return callOrThrow(forcedModel, systemPrompt, userMessage, code, direction);
        }
        if (fastModelOk) {
            try {
                return claudeAiClient.complete(ClaudeAiClient.HAIKU, systemPrompt, userMessage, MAX_TOKENS);
            } catch (Exception e) {
                fastModelOk = false;
                log.warn("Modele rapide (Haiku) indisponible, bascule definitive sur Sonnet : {}", e.getMessage());
            }
        }
        return callOrThrow(ClaudeAiClient.SONNET, systemPrompt, userMessage, code, direction);
    }

    private String callOrThrow(String model, String systemPrompt, String userMessage,
                               String code, TranslationDirection direction) {
        try {
            return claudeAiClient.complete(model, systemPrompt, userMessage, MAX_TOKENS);
        } catch (Exception e) {
            log.error("Translation Claude call failed [model={}, lang={}, dir={}]: {}",
                    model, code, direction, e.getMessage());
            throw new TranslationUnavailableException(
                    "Service de traduction momentanement indisponible.", e);
        }
    }

    // ------------------------------------------------------------------
    // Cache Redis (best-effort — jamais bloquant)
    // ------------------------------------------------------------------

    private String cacheKey(String code, TranslationDirection direction, String text) {
        String hash = DigestUtils.md5DigestAsHex(text.toLowerCase().getBytes(StandardCharsets.UTF_8));
        return CACHE_PREFIX + code + ':' + direction.name() + ':' + hash;
    }

    private TranslateResponse readCache(String key, String sourceText, TranslationDirection direction) {
        if (redis == null) {
            return null;
        }
        try {
            String json = redis.opsForValue().get(key);
            if (json == null) {
                return null;
            }
            JsonNode n = objectMapper.readTree(json);
            String pron = n.path("p").asText("").trim();
            String notes = n.path("n").asText("").trim();
            return TranslateResponse.builder()
                    .translation(n.path("t").asText("").trim())
                    .pronunciation(pron.isEmpty() ? null : pron)
                    .confidence(n.path("c").asDouble(0.0))
                    .notes(notes.isEmpty() ? null : notes)
                    .sourceText(sourceText)
                    .direction(direction)
                    .build();
        } catch (Exception e) {
            return null; // cache best-effort : on ignore et on appellera l'IA
        }
    }

    private void writeCache(String key, String translation, String pronunciation, double confidence, String notes) {
        if (redis == null || translation == null || translation.isEmpty()) {
            return;
        }
        try {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("t", translation);
            m.put("p", pronunciation);
            m.put("c", confidence);
            m.put("n", notes);
            redis.opsForValue().set(key, objectMapper.writeValueAsString(m), CACHE_TTL);
        } catch (Exception e) {
            // best-effort : on n'echoue jamais une traduction a cause du cache
        }
    }

    // ------------------------------------------------------------------
    // Construction du prompt
    // ------------------------------------------------------------------

    private String buildSystemPrompt(String code, String languageContext) {
        return """
                Tu es un traducteur-linguiste expert d'une langue bamileke des Hauts-Plateaux
                de l'Ouest Cameroun (code : %s). Tu traduis FIDELEMENT entre le francais et cette
                langue native, en t'appuyant EXCLUSIVEMENT sur le lexique atteste et les regles
                de codification fournis ci-dessous.

                REGLES ABSOLUES :
                - N'invente JAMAIS une forme native inexistante. Si le mot ou la tournure demande
                  n'est pas atteste, dis-le explicitement dans "notes" et propose la forme attestee
                  la PLUS PROCHE (meme champ semantique, ou construction via les prefixes de classe
                  et la morphologie), en baissant la confiance.
                - Applique la morphologie fournie : pluriels par prefixe (P-/Pt-/Pe-, "pe" pour les
                  personnes), possessifs postposes, negation circonfixe "Pe tche ... peu",
                  conjugaison SUJET + marqueur temporel + radical, numeration, prefixes de classe.
                - Donne la prononciation tonale quand elle est attestee ou surement inferable
                  (5 tons AGLC : haut, moyen, bas, montant, descendant ; occlusive glottale ').
                  Sinon laisse "pronunciation" vide.
                - Donne une confiance entre 0 et 1 (1 = forme directement attestee ; 0.5 = reconstruite
                  par regles ; proche de 0 = tres incertaine).
                - Reponds STRICTEMENT avec un unique objet JSON valide, SANS aucun texte ni balise
                  avant ou apres, au format EXACT :
                  {"translation": "...", "pronunciation": "...", "confidence": 0.0, "notes": "..."}

                %s
                """.formatted(code, languageContext);
    }

    private String buildUserMessage(TranslationDirection direction, String text) {
        String sens = (direction == TranslationDirection.NATIVE_TO_FR)
                ? "langue native -> francais"
                : "francais -> langue native";
        return "Sens de traduction : " + sens + "\n"
                + "Texte a traduire (entre les balises) :\n"
                + "<<<\n" + text + "\n>>>";
    }

    // ------------------------------------------------------------------
    // Parsing de la reponse (+ mise en cache)
    // ------------------------------------------------------------------

    private TranslateResponse parseResponse(String raw, String sourceText,
                                            TranslationDirection direction, String cacheKey) {
        String json = extractJson(raw);
        try {
            JsonNode node = objectMapper.readTree(json);

            String translation = node.path("translation").asText("").trim();
            String pronunciation = node.path("pronunciation").asText("").trim();
            String notes = node.path("notes").asText("").trim();

            double confidence = node.path("confidence").asDouble(0.0);
            if (confidence < 0) confidence = 0;
            if (confidence > 1) confidence = 1;

            // Mise en cache best-effort (uniquement si traduction non vide).
            writeCache(cacheKey, translation, pronunciation.isEmpty() ? null : pronunciation,
                    confidence, notes.isEmpty() ? null : notes);

            return TranslateResponse.builder()
                    .translation(translation)
                    .pronunciation(pronunciation.isEmpty() ? null : pronunciation)
                    .confidence(confidence)
                    .notes(notes.isEmpty() ? null : notes)
                    .sourceText(sourceText)
                    .direction(direction)
                    .build();
        } catch (Exception e) {
            log.error("Failed to parse translation JSON: {} | raw='{}'", e.getMessage(), abbreviate(raw, 300));
            throw new TranslationUnavailableException(
                    "Reponse du moteur de traduction illisible.", e);
        }
    }

    /** Isole l'objet JSON meme si Claude l'entoure de texte ou de balises ```json. */
    private String extractJson(String raw) {
        if (raw == null) {
            return "{}";
        }
        String s = raw.trim();
        int first = s.indexOf('{');
        int last = s.lastIndexOf('}');
        if (first >= 0 && last > first) {
            return s.substring(first, last + 1);
        }
        return s;
    }

    private static String abbreviate(String s, int max) {
        if (s == null) {
            return "";
        }
        return s.length() <= max ? s : s.substring(0, max) + "...";
    }

    // ------------------------------------------------------------------
    // Chargement + cache du contexte lexical
    // ------------------------------------------------------------------

    private String getLanguageContext(String code) {
        return contextCache.computeIfAbsent(code, this::buildLanguageContext);
    }

    private String buildLanguageContext(String code) {
        JsonNode base = readJsonResource("dictionaries/" + code + ".json");
        if (base == null) {
            throw new IllegalArgumentException("Langue non supportee : " + code);
        }
        JsonNode enrichment = readJsonResource("dictionaries/" + code + ".enrichissement.json");

        StringBuilder sb = new StringBuilder();

        // Identite de la langue
        JsonNode lang = base.path("language");
        if (!lang.isMissingNode()) {
            sb.append("LANGUE : ")
                    .append(lang.path("name").asText(code))
                    .append(" (").append(lang.path("frenchName").asText("")).append("), ")
                    .append(lang.path("group").asText("")).append(".\n\n");
        }

        // Regles de codification (morphologie, phonologie, prefixes de classe) — JSON compact.
        if (enrichment != null) {
            JsonNode codification = enrichment.path("codification");
            if (!codification.isMissingNode()) {
                sb.append("REGLES DE CODIFICATION (morphologie, phonologie, prefixes de classe) :\n");
                sb.append(codification.toString()).append("\n\n");
            }
        }

        // Lexique atteste (francais = forme native)
        Set<String> lexicon = new LinkedHashSet<>();
        collectLexicon(base, lexicon);
        if (enrichment != null) {
            collectLexicon(enrichment.path("entreesEnrichies"), lexicon);
        }
        sb.append("LEXIQUE ATTESTE (francais = forme native) :\n");
        int count = 0;
        for (String line : lexicon) {
            if (count++ >= MAX_LEXICON_ENTRIES) {
                break;
            }
            sb.append(line).append("\n");
        }
        sb.append("\n");

        // Mots connus comme non attestes : a signaler, jamais a inventer
        if (enrichment != null) {
            JsonNode manquants = enrichment.path("aRecueillir").path("manquants");
            if (manquants.isArray() && manquants.size() > 0) {
                sb.append("MOTS NON ENCORE ATTESTES (ne pas inventer de forme native ; ")
                        .append("les signaler comme inconnus dans \"notes\") :\n");
                for (JsonNode m : manquants) {
                    String fr = m.path("fr").asText("");
                    if (!fr.isBlank()) {
                        sb.append("- ").append(fr).append("\n");
                    }
                }
            }
        }

        String context = sb.toString();
        log.info("Language context built [{}] : {} lexicon entries, {} chars",
                code, Math.min(lexicon.size(), MAX_LEXICON_ENTRIES), context.length());
        return context;
    }

    /** Collecte recursivement toute paire {fr, mo} attestee (mo non vide et != "?"). */
    private void collectLexicon(JsonNode node, Set<String> out) {
        if (node == null || node.isMissingNode()) {
            return;
        }
        if (node.isObject()) {
            JsonNode fr = node.get("fr");
            JsonNode mo = node.get("mo");
            if (fr != null && fr.isTextual() && mo != null && mo.isTextual()) {
                String frv = fr.asText().trim();
                String mov = mo.asText().trim();
                if (!frv.isEmpty() && !mov.isEmpty() && !"?".equals(mov)) {
                    out.add(frv + " = " + mov);
                }
            }
            Iterator<Map.Entry<String, JsonNode>> it = node.fields();
            while (it.hasNext()) {
                collectLexicon(it.next().getValue(), out);
            }
        } else if (node.isArray()) {
            for (JsonNode child : node) {
                collectLexicon(child, out);
            }
        }
    }

    private JsonNode readJsonResource(String path) {
        ClassPathResource resource = new ClassPathResource(path);
        if (!resource.exists()) {
            log.warn("Dictionary resource not found on classpath: {}", path);
            return null;
        }
        try (InputStream is = resource.getInputStream()) {
            byte[] bytes = is.readAllBytes();
            return objectMapper.readTree(new String(bytes, StandardCharsets.UTF_8));
        } catch (Exception e) {
            log.error("Cannot read dictionary resource '{}': {}", path, e.getMessage());
            return null;
        }
    }
}
