# PROMPT CLAUDE CODE — GWANG MEU
## Bootstrapping complet : Projet · CI/CD · IntelliJ · Swagger

> **Utilisation :** Colle le contenu de chaque bloc entre les lignes `---` directement
> dans Claude Code (terminal intégré à ton éditeur).
> Exécute les 4 prompts **dans l'ordre**.
> Place ce fichier et `ARCHITECTURE.md` à la **racine du repo** avant de commencer.

---

## ══════════════════════════════════════════════
## PROMPT 1 / 4 — SQUELETTE DU PROJET COMPLET
## ══════════════════════════════════════════════

Tu es un expert Spring Boot 3 / Java 21 / Spring Modulith.
Réfère-toi à ARCHITECTURE.md présent à la racine du projet.
Génère le squelette complet du projet GWANG MEU (Phase 1 uniquement).
Ne résume rien : écris le contenu intégral de chaque fichier.

## ARBORESCENCE À CRÉER

```
gwangmeu/
├── .env.example
├── .gitignore
├── Makefile
├── docker-compose.dev.yml
└── backend/
    ├── pom.xml
    ├── Dockerfile
    ├── railway.toml
    └── src/
        ├── main/
        │   ├── java/com/gwangmeu/
        │   │   ├── GwangMeuApplication.java
        │   │   ├── config/
        │   │   │   ├── SecurityConfig.java
        │   │   │   ├── SwaggerConfig.java
        │   │   │   ├── WebSocketConfig.java
        │   │   │   └── RedisConfig.java
        │   │   ├── shared/
        │   │   │   ├── api/
        │   │   │   │   ├── ApiResponse.java
        │   │   │   │   └── GlobalExceptionHandler.java
        │   │   │   ├── audit/AuditEntity.java
        │   │   │   ├── security/
        │   │   │   │   ├── JwtAuthFilter.java
        │   │   │   │   ├── CurrentUser.java
        │   │   │   │   └── UserRole.java
        │   │   │   ├── events/DomainEvent.java
        │   │   │   ├── ai/ClaudeAiClient.java
        │   │   │   └── media/MediaService.java
        │   │   ├── user/
        │   │   │   ├── UserController.java
        │   │   │   ├── UserService.java
        │   │   │   ├── UserRepository.java
        │   │   │   ├── User.java
        │   │   │   └── dto/
        │   │   │       ├── UserDto.java
        │   │   │       └── UpdateUserRequest.java
        │   │   ├── village/
        │   │   │   ├── VillageController.java
        │   │   │   ├── VillageService.java
        │   │   │   ├── VillageRepository.java
        │   │   │   ├── Village.java
        │   │   │   ├── geo/
        │   │   │   │   ├── Continent.java
        │   │   │   │   ├── Country.java
        │   │   │   │   └── GeoController.java
        │   │   │   └── dto/
        │   │   │       ├── VillageDto.java
        │   │   │       └── CreateVillageRequest.java
        │   │   └── feed/
        │   │       ├── FeedController.java
        │   │       ├── FeedService.java
        │   │       ├── PostRepository.java
        │   │       ├── Post.java
        │   │       ├── Reaction.java
        │   │       ├── Comment.java
        │   │       └── dto/
        │   │           ├── PostDto.java
        │   │           ├── CreatePostRequest.java
        │   │           └── ModeratePostRequest.java
        │   └── resources/
        │       ├── application.yml
        │       ├── application-dev.yml
        │       ├── application-prod.yml
        │       └── db/migration/
        │           ├── V1__init_extensions.sql
        │           ├── V2__users.sql
        │           ├── V3__villages.sql
        │           └── V4__feed.sql
        └── test/java/com/gwangmeu/
            ├── GwangMeuApplicationTests.java
            ├── shared/BaseIntegrationTest.java
            ├── user/UserControllerTest.java
            ├── village/VillageControllerTest.java
            └── feed/FeedControllerTest.java
```

## POM.XML — DÉPENDANCES EXACTES

Parent: spring-boot-starter-parent 3.3.5 | Java: 21 | groupId: com.gwangmeu

Inclure ces dépendances (versions gérées par BOM sauf annotation contraire):
- spring-boot-starter-web
- spring-boot-starter-security
- spring-boot-starter-data-jpa
- spring-boot-starter-data-redis
- spring-boot-starter-websocket
- spring-boot-starter-actuator
- spring-boot-starter-validation
- spring-boot-starter-oauth2-resource-server
- spring-modulith-starter-core:1.2.3
- spring-modulith-starter-jpa:1.2.3
- springdoc-openapi-starter-webmvc-ui:2.6.0    ← Swagger UI
- org.postgresql:postgresql
- org.flywaydb:flyway-core + flyway-database-postgresql
- com.bucket4j:bucket4j-core:8.10.1
- org.springframework.data:spring-data-neo4j
- com.anthropic:anthropic-java-sdk:0.8.0
- software.amazon.awssdk:s3:2.28.0
- com.google.firebase:firebase-admin:9.3.0
- io.sentry:sentry-spring-boot-starter-jakarta:7.14.0
- org.projectlombok:lombok (provided)
- org.mapstruct:mapstruct:1.6.2
- org.testcontainers:junit-jupiter (test)
- org.testcontainers:postgresql (test)
- org.testcontainers:neo4j (test)
- com.redis.testcontainers:testcontainers-redis:1.6.4 (test)
- io.rest-assured:rest-assured (test)

Maven plugins: maven-compiler-plugin avec annotationProcessorPaths lombok+mapstruct,
spring-boot-maven-plugin, flyway-maven-plugin.

## APPLICATION.YML

```yaml
spring:
  application.name: gwangmeu-backend
  datasource:
    url: ${SUPABASE_DB_URL}
    driver-class-name: org.postgresql.Driver
    hikari: { maximum-pool-size: 10, minimum-idle: 2 }
  jpa:
    hibernate.ddl-auto: validate
    properties.hibernate.dialect: org.hibernate.dialect.PostgreSQLDialect
  flyway:
    enabled: true
    locations: classpath:db/migration
    baseline-on-migrate: true
  data.redis.url: ${REDIS_URL}
  neo4j:
    uri: ${NEO4J_URI}
    authentication: { username: ${NEO4J_USERNAME}, password: ${NEO4J_PASSWORD} }
  security.oauth2.resourceserver.jwt:
    issuer-uri: ${SUPABASE_URL}/auth/v1
    jwk-set-uri: ${SUPABASE_URL}/auth/v1/.well-known/jwks.json

springdoc:
  swagger-ui:
    path: /swagger-ui.html
    operationsSorter: alpha
    tagsSorter: alpha
    display-request-duration: true
    try-it-out-enabled: true
  api-docs.path: /v3/api-docs

management.endpoints.web.exposure.include: health,info,metrics,flyway
server.port: 8080
application:
  jwt-secret: ${JWT_SECRET}
  anthropic-api-key: ${ANTHROPIC_API_KEY}
```

application-dev.yml: logging.level.com.gwangmeu: DEBUG, jpa.show-sql: true
application-prod.yml: springdoc.api-docs.enabled: false (swagger OFF en prod)

## SwaggerConfig.java

```java
@Configuration
@OpenAPIDefinition(
  info = @Info(
    title = "GWANG MEU API", version = "v1.0",
    description = """
      Plateforme culturelle africaine — Langues · Culture · Futur

      ## Authentification
      1. Connecte-toi via Supabase Auth
      2. Récupère ton JWT
      3. Clique **Authorize** → colle `Bearer {ton_token}`

      ## Rôles: SUPER_ADMIN · MODERATEUR · AMBASSADEUR · MEMBRE · VISITEUR · API
      """,
    contact = @Contact(name = "GWANG MEU", url = "https://gwangmeu.com")
  ),
  servers = {
    @Server(url = "http://localhost:8080", description = "Local Dev"),
    @Server(url = "https://api.gwangmeu.com", description = "Production")
  },
  security = @SecurityRequirement(name = "BearerAuth")
)
@SecurityScheme(
  name = "BearerAuth", type = SecuritySchemeType.HTTP,
  scheme = "bearer", bearerFormat = "JWT",
  description = "Token JWT Supabase. Obtenu via POST /auth/v1/token"
)
public class SwaggerConfig {}
```

## SECURITY CONFIG — Règles exactes

Endpoints publics (permitAll):
  GET  /api/v1/villages/**, /api/v1/geo/**, /api/v1/posts/{id}
  /swagger-ui/**, /swagger-ui.html, /v3/api-docs/**, /actuator/health

CORS allowedOrigins: localhost:3000, localhost:5173, localhost:8080,
  gwangmeu.com, app.gwangmeu.com | allowedMethods: * | allowedHeaders: * | credentials: true

JWT validation via Supabase JWKS (oauth2ResourceServer).

## ApiResponse<T> WRAPPER

```java
public record ApiResponse<T>(
  boolean success, T data, String message, int status, LocalDateTime timestamp
) {
  public static <T> ApiResponse<T> ok(T data) { ... }
  public static <T> ApiResponse<T> created(T data) { ... }
  public static ApiResponse<Void> error(String msg, int status) { ... }
  public static <T> ApiResponse<Page<T>> paginated(Page<T> page) { ... }
}
```

GlobalExceptionHandler gère: MethodArgumentNotValidException(400),
EntityNotFoundException(404), AccessDeniedException(403),
AuthenticationException(401), DataIntegrityViolationException(409), Exception(500).

## CONTROLLERS — ENDPOINTS COMPLETS AVEC SWAGGER

Chaque endpoint: @Operation(summary, description) + @ApiResponse(200/401/403/404)
+ @Schema(example="...") sur chaque champ DTO.

UserController /api/v1/users, @Tag(name="👤 Users"):
  GET    /me           → profil connecté (auth required)
  PUT    /me           → mise à jour profil
  GET    /{id}         → profil public
  POST   /auth/sync    → sync depuis Supabase JWT
  DELETE /me           → suppression RGPD

VillageController /api/v1/villages, @Tag(name="🏘️ Villages"):
  GET    /             → liste paginée (?page,size,search,country)
  POST   /             → créer (AMBASSADEUR+)
  GET    /{id}         → détail
  PUT    /{id}         → modifier (AMBASSADEUR propriétaire)
  GET    /{id}/members → membres paginés
  POST   /{id}/join    → rejoindre (auth)
  DELETE /{id}/leave   → quitter (auth)

GeoController /api/v1/geo, @Tag(name="🌍 Géographie"):
  GET /continents             → liste continents
  GET /countries/{continentId}→ pays d'un continent
  GET /villages/{countryId}  → villages d'un pays

FeedController /api/v1, @Tag(name="📰 Feed"):
  GET    /feed                       → fil personnalisé (auth)
  GET    /villages/{id}/feed         → fil public village
  POST   /posts                      → créer publication (auth)
  GET    /posts/{id}                 → détail (public)
  DELETE /posts/{id}                 → supprimer (auteur ou MODERATEUR)
  POST   /posts/{id}/reactions       → ajouter réaction (auth)
  DELETE /posts/{id}/reactions       → retirer réaction (auth)
  GET    /posts/{id}/comments        → liste commentaires
  POST   /posts/{id}/comments        → commenter (auth)
  PUT    /posts/{id}/moderate        → modérer (MODERATEUR+) → APPROVED/REJECTED

## FLYWAY MIGRATIONS

V1__init_extensions.sql:
  CREATE EXTENSION uuid-ossp, postgis;
  CREATE TYPE role_type AS ENUM('SUPER_ADMIN','MODERATEUR','AMBASSADEUR','MEMBRE','VISITEUR','API');
  CREATE TYPE post_status AS ENUM('PENDING','APPROVED','REJECTED');
  CREATE TYPE reaction_type AS ENUM('LIKE','LOVE','FIRE','SUPPORT');

V2__users.sql: table users(id UUID PK, supabase_id UUID UNIQUE, email UNIQUE,
  display_name, role role_type DEFAULT 'MEMBRE', country, native_language, bio,
  avatar_url, created_at, updated_at). Index sur supabase_id, email.

V3__villages.sql: tables continents, countries, villages(id, name, slug UNIQUE,
  country_id FK, description, history, coordinates GEOGRAPHY(POINT,4326),
  member_count INT DEFAULT 0, created_by FK users, timestamps).
  table village_members(village_id, user_id, joined_at). Index GiST sur coordinates.

V4__feed.sql: table posts(id, author_id FK, village_id FK, content, media_urls JSONB,
  status post_status DEFAULT 'PENDING', pinned BOOL, moderated_by, timestamps).
  table reactions(id, post_id FK, user_id FK, type, UNIQUE(post_id,user_id)).
  table comments(id, post_id FK, author_id FK, content, created_at).

## DOCKER-COMPOSE.DEV.YML

Services avec healthchecks:
- postgis/postgis:16-3.4-alpine → port 5432 → volume postgres_data
- redis:7-alpine → port 6379 → volume redis_data
- neo4j:5-community → ports 7474+7687 → NEO4J_AUTH=neo4j/${NEO4J_PASSWORD}
- getmeili/meilisearch:latest → port 7700 → MEILI_MASTER_KEY=${MEILISEARCH_API_KEY}

## DOCKERFILE MULTI-STAGE

Stage builder: eclipse-temurin:21-jdk-alpine → mvn clean package -DskipTests
Stage runtime: eclipse-temurin:21-jre-alpine → user non-root gwangmeu → EXPOSE 8080
HEALTHCHECK wget -qO- /actuator/health
ENTRYPOINT ["java","-XX:+UseContainerSupport","-XX:MaxRAMPercentage=75.0","-jar","app.jar"]

## TESTS TESTCONTAINERS

BaseIntegrationTest.java:
  @SpringBootTest(webEnvironment=RANDOM_PORT) @Testcontainers @ActiveProfiles("test")
  static PostgreSQLContainer (postgis), RedisContainer, Neo4jContainer
  @DynamicPropertySource override datasource.url, redis.url, neo4j.uri

Chaque XxxControllerTest extends BaseIntegrationTest:
  MockMvc + @WithMockUser → teste 200/401/403/404/400 pour chaque endpoint.

## MAKEFILE

make dev      → docker-compose -f docker-compose.dev.yml up -d
make stop     → docker-compose -f docker-compose.dev.yml down
make logs     → docker-compose -f docker-compose.dev.yml logs -f
make run      → cd backend && mvn spring-boot:run -Dspring-boot.run.profiles=dev
make build    → cd backend && mvn clean package -DskipTests
make test     → cd backend && mvn verify
make swagger  → open http://localhost:8080/swagger-ui.html (ou xdg-open sur Linux)
make health   → curl -s http://localhost:8080/actuator/health | python3 -m json.tool
make reset-db → docker-compose -f docker-compose.dev.yml down -v && make dev

## .ENV.EXAMPLE

```
# Docker local
DB_PASSWORD=gwangmeu_secret
SUPABASE_DB_URL=jdbc:postgresql://localhost:5432/gwangmeu_dev

# Supabase
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_KEY=

# JWT (min 32 chars: openssl rand -hex 32)
JWT_SECRET=change_me_in_production_at_least_32_chars

# Claude / Anthropic
ANTHROPIC_API_KEY=

# Neo4j
NEO4J_URI=bolt://localhost:7687
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=gwangmeu_neo4j

# Redis
REDIS_URL=redis://localhost:6379

# LiveKit
LIVEKIT_API_KEY=
LIVEKIT_API_SECRET=
LIVEKIT_WS_URL=wss://xxx.livekit.cloud

# Mapbox
MAPBOX_ACCESS_TOKEN=

# Meilisearch
MEILISEARCH_HOST=http://localhost:7700
MEILISEARCH_API_KEY=gwangmeu_meili

# Cloudflare R2
R2_ACCESS_KEY_ID=
R2_SECRET_ACCESS_KEY=
R2_BUCKET_NAME=gwangmeu-media
R2_ACCOUNT_ID=

# Firebase / Resend / Sentry
FIREBASE_SERVICE_ACCOUNT_JSON=
RESEND_API_KEY=
SENTRY_DSN_JAVA=

# URLs
APP_URL=https://app.gwangmeu.com
LANDING_URL=https://gwangmeu.com
```

## RÈGLES ABSOLUES

1. Compile sans erreurs ni warnings avec Java 21
2. Swagger UI accessible à http://localhost:8080/swagger-ui.html
3. Zéro clé hardcodée — tout via @Value("${...}")
4. Lombok (@Data @Builder @RequiredArgsConstructor) sur toutes les entités
5. MapStruct pour Entity ↔ DTO (zéro conversion manuelle)
6. Bean Validation (@NotBlank @Email @Size) sur tous les DTOs request
7. @Transactional(readOnly=true) en lecture, @Transactional en écriture
8. Jamais d'import direct entre packages modules → ApplicationEventPublisher uniquement
9. Chaque module a son sous-package events/ avec ses DomainEvents propres
10. GlobalExceptionHandler retourne toujours ApiResponse<Void> en erreur

---

## ══════════════════════════════════════════════
## PROMPT 2 / 4 — CI/CD GITHUB ACTIONS + RAILWAY
## ══════════════════════════════════════════════

Réfère-toi à ARCHITECTURE.md. Le projet Spring Boot est déjà dans backend/.
Génère la configuration CI/CD complète. Écris chaque fichier intégralement.

## FICHIERS À CRÉER

```
gwangmeu/
├── .github/workflows/
│   ├── ci.yml
│   ├── deploy-staging.yml
│   └── deploy-prod.yml
├── backend/railway.toml
└── GITHUB_SECRETS.md
```

## CI.YML — Tests sur chaque Pull Request

Déclenché sur: pull_request(main, develop) et push(develop)

Job test-backend (ubuntu-latest):
  services:
    postgres: postgis/postgis:16-3.4-alpine, port 5432,
      health: pg_isready -U postgres
    redis: redis:7-alpine, port 6379,
      health: redis-cli ping

  steps:
    - actions/checkout@v4
    - actions/setup-java@v4 (java-version: 21, distribution: temurin)
    - actions/cache@v4 (path: ~/.m2, key: ${{ runner.os }}-maven-${{ hashFiles('**/pom.xml') }})
    - name: Run tests
      working-directory: backend
      run: mvn verify -B -q
      env:
        SUPABASE_DB_URL: jdbc:postgresql://localhost:5432/gwangmeu_test
        REDIS_URL: redis://localhost:6379
        NEO4J_URI: bolt://localhost:7687    # Testcontainers le démarre
        JWT_SECRET: test_secret_ci_32_chars_minimum_here
        ANTHROPIC_API_KEY: sk-ant-test-dummy
        (toutes les autres avec valeurs dummy pour CI)
    - name: Upload surefire reports
      if: failure()
      uses: actions/upload-artifact@v4
      with: { name: surefire-reports, path: backend/target/surefire-reports/ }

Job build-docker (needs: test-backend):
  - docker build -f backend/Dockerfile backend/ --no-cache
  (validation uniquement, pas de push sur les PRs)

## DEPLOY-STAGING.YML — Deploy auto sur push main

Déclenché sur: push branch main

Jobs:
  1. test → (identique à ci.yml)
  2. deploy-staging (needs: test):
     - actions/checkout@v4
     - npm install -g @railway/cli
     - railway deploy --service gwangmeu-backend-staging --detach
       env: RAILWAY_TOKEN, RAILWAY_PROJECT_ID: ${{ secrets.RAILWAY_PROJECT_ID_STAGING }}
     - Health check:
       sleep 60
       STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://staging-api.gwangmeu.com/actuator/health)
       [ "$STATUS" = "200" ] && echo "✅ Staging OK" || (echo "❌ Health check failed" && exit 1)

## DEPLOY-PROD.YML — Deploy sur tag v*.*.*

Déclenché sur: push tags v*.*.*

Jobs:
  1. test → (identique)
  2. build-and-push (needs: test):
     - Login ghcr.io avec GHCR_TOKEN
     - Extract version depuis le tag git
     - docker build + push ghcr.io/ORG/gwangmeu-backend:$VERSION et :latest
  3. deploy-prod (needs: build-and-push):
     - railway deploy --service gwangmeu-backend-prod
     - Health check prod: https://api.gwangmeu.com/actuator/health
     - Si échec → railway rollback + exit 1
  4. create-release:
     - softprops/action-gh-release@v2 → release GitHub automatique

## RAILWAY.TOML

```toml
[build]
builder = "DOCKERFILE"
dockerfilePath = "Dockerfile"

[deploy]
startCommand = "java -jar app.jar"
healthcheckPath = "/actuator/health"
healthcheckTimeout = 300
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 3

[environments.staging.deploy]
healthcheckPath = "/actuator/health"

[environments.production.deploy]
healthcheckPath = "/actuator/health"
```

## GITHUB_SECRETS.MD

Génère un guide markdown "Configuration des Secrets GitHub" listant
chaque secret avec: nom exact, où le trouver, format attendu.

Secrets requis:
  RAILWAY_TOKEN              → railway.app → Account → Tokens
  RAILWAY_PROJECT_ID_STAGING → dashboard Railway → projet staging → Settings
  RAILWAY_PROJECT_ID_PROD    → idem prod
  SUPABASE_URL               → Supabase → Project Settings → API → Project URL
  SUPABASE_SERVICE_KEY       → Supabase → Project Settings → API → service_role key
  SUPABASE_DB_URL            → Supabase → Project Settings → Database → Connection string (JDBC)
  ANTHROPIC_API_KEY          → console.anthropic.com → API Keys
  NEO4J_URI                  → Neo4j Aura → Connect → bolt:// URI
  NEO4J_USERNAME             → toujours "neo4j"
  NEO4J_PASSWORD             → Neo4j Aura → generated password
  REDIS_URL                  → Upstash → database → REST URL ou redis://...
  LIVEKIT_API_KEY            → livekit.io → projet → Settings
  LIVEKIT_API_SECRET         → idem
  MAPBOX_ACCESS_TOKEN        → mapbox.com → Account → Tokens
  MEILISEARCH_HOST           → meilisearch.com → project → URL
  MEILISEARCH_API_KEY        → meilisearch.com → project → Master Key
  R2_ACCESS_KEY_ID           → Cloudflare → R2 → Manage R2 API Tokens
  R2_SECRET_ACCESS_KEY       → idem
  R2_BUCKET_NAME             → "gwangmeu-media"
  R2_ACCOUNT_ID              → Cloudflare → right sidebar → Account ID
  RESEND_API_KEY             → resend.com → API Keys
  SENTRY_DSN_JAVA            → sentry.io → projet → Settings → Client Keys
  JWT_SECRET                 → générer: openssl rand -hex 32
  GHCR_TOKEN                 → GitHub → Settings → Developer Settings → PAT → scopes: write:packages

---

## ══════════════════════════════════════════════
## PROMPT 3 / 4 — CONFIGURATION INTELLIJ IDEA
## ══════════════════════════════════════════════

Réfère-toi à ARCHITECTURE.md.
Génère tous les fichiers IntelliJ pour que le projet se lance immédiatement.
Écris chaque fichier XML intégralement (contenu valide, pas de pseudocode).

## FICHIERS À CRÉER

```
gwangmeu/
├── .idea/
│   ├── .gitignore
│   ├── runConfigurations/
│   │   ├── 1_Docker_Dev_Stack.xml
│   │   ├── 2_GwangMeu_Backend_Dev.xml
│   │   ├── 3_GwangMeu_Backend_Prod_Local.xml
│   │   ├── 4_Tests_All.xml
│   │   └── 5_Tests_Phase1.xml
│   ├── codeStyles/Project.xml
│   └── templates/GwangMeu.xml
├── backend/http/
│   ├── http-client.env.json
│   ├── 01_auth.http
│   ├── 02_users.http
│   ├── 03_villages.http
│   └── 04_feed.http
└── SETUP_INTELLIJ.md
```

## .IDEA/.GITIGNORE

```
# Garder en VCS
!runConfigurations/
!codeStyles/
!templates/

# Ignorer
workspace.xml
tasks.xml
usage.statistics.xml
dictionaries/
shelf/
aws.xml
*.iws
```

## RUN CONFIGURATIONS XML — CONTENU EXACT

1_Docker_Dev_Stack.xml:
  Type ShellScript → command "docker-compose -f $PROJECT_DIR$/docker-compose.dev.yml up -d"
  Nom: "🐳 Docker Dev Stack"

2_GwangMeu_Backend_Dev.xml:
  Type SpringBootApplicationConfigurationType
  SPRING_BOOT_MAIN_CLASS: com.gwangmeu.GwangMeuApplication
  ACTIVE_PROFILES: dev
  VM_PARAMETERS: -Xms256m -Xmx512m -XX:+UseG1GC -Dfile.encoding=UTF-8
  WORKING_DIRECTORY: $PROJECT_DIR$/backend
  Env var: SPRING_PROFILES_ACTIVE=dev
  EnvFile: enable=true, path=$PROJECT_DIR$/backend/.env
  Before launch: Run "🐳 Docker Dev Stack"
  Nom: "🚀 GwangMeu Backend (Dev)"

3_GwangMeu_Backend_Prod_Local.xml:
  Même type, profil prod
  VM_PARAMETERS: -Xms512m -Xmx1g -XX:+UseG1GC -XX:+OptimizeStringConcat
  Nom: "🔒 GwangMeu Backend (Prod local)"

4_Tests_All.xml:
  Type MavenRunConfiguration
  WORKING_DIRECTORY: $PROJECT_DIR$/backend
  GOALS: verify
  Nom: "🧪 Tests — All (Testcontainers)"

5_Tests_Phase1.xml:
  Type JUnit
  TEST_KIND: pattern
  PATTERN: com\.gwangmeu\.user\..+Test|com\.gwangmeu\.village\..+Test|com\.gwangmeu\.feed\..+Test
  VM_PARAMETERS: -Xmx512m
  Nom: "🧪 Tests — Phase 1"

## CODE STYLE Project.xml

```xml
<code_scheme name="Project" version="173">
  <option name="RIGHT_MARGIN" value="120"/>
  <JavaCodeStyleSettings>
    <option name="INDENT_SIZE" value="4"/>
    <option name="CONTINUATION_INDENT_SIZE" value="8"/>
    <option name="USE_SINGLE_CLASS_IMPORTS" value="true"/>
    <option name="IMPORT_LAYOUT_TABLE">
      java.*;javax.*;jakarta.*;org.*;com.*;*
    </option>
  </JavaCodeStyleSettings>
  <editorconfig>
    indent_style=space
    indent_size=4
    end_of_line=lf
    charset=utf-8
    trim_trailing_whitespace=true
    insert_final_newline=true
  </editorconfig>
</code_scheme>
```

## LIVE TEMPLATES GwangMeu.xml (groupe "GwangMeu")

gmc → Controller Spring Boot + Swagger:
```java
@RestController
@RequestMapping("/api/v1/$ENDPOINT$")
@RequiredArgsConstructor
@Tag(name = "$TAG$", description = "$TAG_DESC$")
public class $NAME$Controller {
    private final $NAME$Service $VAR$Service;
}
```

gms → Service:
```java
@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(readOnly = true)
public class $NAME$Service {
    private final $NAME$Repository $VAR$Repository;
    private final ApplicationEventPublisher eventPublisher;
}
```

gmr → Repository:
```java
@Repository
public interface $NAME$Repository extends JpaRepository<$ENTITY$, UUID> {
}
```

gme → Entity JPA:
```java
@Entity
@Table(name = "$TABLE$")
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class $NAME$ extends AuditEntity {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    $END$
}
```

gmd → DTO record:
```java
public record $NAME$Dto(
    @Schema(example = "$EXAMPLE$") $TYPE$ $FIELD$
) {}
```

gmev → Domain Event:
```java
public record $NAME$Event(
    UUID $ENTITY$Id,
    String triggeredBy,
    LocalDateTime occurredAt
) implements DomainEvent {}
```

gmtest → Test d'intégration:
```java
@DisplayName("$NAME$ Controller Tests")
class $NAME$ControllerTest extends BaseIntegrationTest {
    @Autowired MockMvc mockMvc;
    @Autowired ObjectMapper objectMapper;

    @Test @WithMockUser(roles = "MEMBRE")
    @DisplayName("Should $ACTION$ successfully")
    void should$ACTION$() throws Exception {
        mockMvc.perform(get("/api/v1/$ENDPOINT$"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true));
    }
}
```

swop → Swagger Operation:
```java
@Operation(summary = "$SUMMARY$", description = "$DESC$")
@ApiResponse(responseCode = "200", description = "Succès")
@ApiResponse(responseCode = "401", description = "Non authentifié",
    content = @Content(schema = @Schema(implementation = ApiResponse.class)))
@ApiResponse(responseCode = "403", description = "Accès refusé",
    content = @Content(schema = @Schema(implementation = ApiResponse.class)))
@ApiResponse(responseCode = "404", description = "Introuvable",
    content = @Content(schema = @Schema(implementation = ApiResponse.class)))
```

## HTTP CLIENT FILES

http-client.env.json:
```json
{
  "dev": {
    "baseUrl": "http://localhost:8080",
    "jwt": "COLLE_TON_TOKEN_SUPABASE_ICI",
    "userId": "550e8400-e29b-41d4-a716-446655440000",
    "villageId": "village-uuid-exemple"
  },
  "staging": {
    "baseUrl": "https://staging-api.gwangmeu.com",
    "jwt": ""
  }
}
```

01_auth.http:
```http
### Sync profil après login Supabase
POST {{baseUrl}}/api/v1/auth/sync
Authorization: Bearer {{jwt}}
Content-Type: application/json

{}

### Health check
GET {{baseUrl}}/actuator/health
```

02_users.http:
```http
### Mon profil
GET {{baseUrl}}/api/v1/users/me
Authorization: Bearer {{jwt}}

### Modifier mon profil
PUT {{baseUrl}}/api/v1/users/me
Authorization: Bearer {{jwt}}
Content-Type: application/json

{"displayName": "Kwame Diallo", "nativeLanguage": "Bassa", "country": "Cameroun"}

### Profil public
GET {{baseUrl}}/api/v1/users/{{userId}}
```

03_villages.http:
```http
### Liste villages
GET {{baseUrl}}/api/v1/villages?page=0&size=20

### Recherche par nom et pays
GET {{baseUrl}}/api/v1/villages?search=bassa&country=Cameroun

### Créer un village
POST {{baseUrl}}/api/v1/villages
Authorization: Bearer {{jwt}}
Content-Type: application/json

{"name": "Bassa-Likoko", "countryId": "uuid", "description": "Village traditionnel Bassa"}

### Rejoindre un village
POST {{baseUrl}}/api/v1/villages/{{villageId}}/join
Authorization: Bearer {{jwt}}

### Continents
GET {{baseUrl}}/api/v1/geo/continents
```

04_feed.http:
```http
### Fil personnalisé
GET {{baseUrl}}/api/v1/feed?page=0&size=20
Authorization: Bearer {{jwt}}

### Créer une publication
POST {{baseUrl}}/api/v1/posts
Authorization: Bearer {{jwt}}
Content-Type: application/json

{"villageId": "{{villageId}}", "content": "Bonjour depuis Gwang Meu! 🌍"}

### Ajouter réaction
POST {{baseUrl}}/api/v1/posts/POST_ID/reactions
Authorization: Bearer {{jwt}}
Content-Type: application/json

{"type": "LIKE"}
```

## SETUP_INTELLIJ.MD

Génère un guide complet avec ces sections:

# Démarrer GWANG MEU dans IntelliJ — 10 minutes

## Prérequis
- IntelliJ IDEA 2024.x (Ultimate ou Community)
- Java 21 JDK Temurin (https://adoptium.net)
- Docker Desktop en cours d'exécution
- Maven 3.9+

## Étape 1 — Cloner et configurer
```
git clone https://github.com/TON_ORG/gwangmeu.git
cd gwangmeu
cp backend/.env.example backend/.env
# Édite backend/.env (les valeurs locales suffisent pour démarrer)
```

## Étape 2 — Ouvrir dans IntelliJ
File → Open → sélectionner backend/pom.xml → "Open as Project"
Attendre l'indexation Maven (~2 min première fois)

## Étape 3 — Installer EnvFile (OBLIGATOIRE)
Settings → Plugins → Marketplace → "EnvFile" → Install → Restart IDE

## Étape 4 — Vérifier EnvFile dans la run config
Run → Edit Configurations → "🚀 GwangMeu Backend (Dev)"
Onglet "EnvFile" → Enable EnvFile ✓ → vérifier backend/.env listé

## Étape 5 — Lancer!
Run → "🐳 Docker Dev Stack"  ← PostgreSQL, Redis, Neo4j, Meilisearch
Attendre 30 secondes...
Run → "🚀 GwangMeu Backend (Dev)"
Attendre "Started GwangMeuApplication in X.XXX seconds"

## Étape 6 — Vérifier
✅ Health  : http://localhost:8080/actuator/health  → {"status":"UP"}
✅ Swagger : http://localhost:8080/swagger-ui.html  → Interface Swagger UI
✅ API     : http://localhost:8080/v3/api-docs      → JSON OpenAPI spec

## Étape 7 — Tester les APIs
Ouvre backend/http/01_auth.http dans IntelliJ
Sélectionne l'environnement "dev"
Clique ▶️ sur chaque requête

## Étape 8 — Lancer les tests
Run → "🧪 Tests — Phase 1"
Testcontainers démarre automatiquement les containers de test

## Plugins recommandés
- MapStruct Support — autocomplétion MapStruct
- Docker — gestion containers intégrée
- SonarLint — qualité code en temps réel
- GitToolBox — annotations Git inline

## Raccourcis utiles
- Ctrl+Shift+F10 → Lancer la config courante
- Ctrl+F9        → Recompiler (hot reload)
- gmc + Tab      → Live template Controller
- gms + Tab      → Live template Service
- gme + Tab      → Live template Entity
- swop + Tab     → Live template Swagger @Operation

## Connexion BDD locale (optionnel, IntelliJ Ultimate)
View → Tool Windows → Database → + → PostgreSQL
  Host: localhost | Port: 5432 | DB: gwangmeu_dev | User: postgres | Password: (depuis .env)
→ + → Neo4j: bolt://localhost:7687 / neo4j / (password .env)

---

## ══════════════════════════════════════════════
## PROMPT 4 / 4 — VALIDATION & RÉCAPITULATIF
## ══════════════════════════════════════════════

Réfère-toi à ARCHITECTURE.md.
Tous les fichiers des prompts 1-2-3 ont été générés.
Effectue la validation complète et corrige les erreurs si nécessaire.

## ÉTAPE 1 — COMPILATION

```bash
cd backend && mvn clean compile -q 2>&1
```

Si erreurs → identifie chaque fichier + ligne → corrige → relance.
Continuer jusqu'à 0 erreur. Rapport: "✅ Compilation OK" ou liste des corrections.

## ÉTAPE 2 — CHECKLIST COHÉRENCE (vérifie chaque point)

□ GwangMeuApplication.java a @SpringBootApplication et scan com.gwangmeu
□ SecurityConfig autorise /swagger-ui/**, /swagger-ui.html, /v3/api-docs/**
□ SwaggerConfig a @Configuration + @OpenAPIDefinition + @SecurityScheme BearerAuth
□ application.yml: springdoc.swagger-ui.path=/swagger-ui.html présent
□ application-prod.yml: springdoc.api-docs.enabled=false présent
□ Flyway migrations V1__→V4__ sans gap, nommage exact
□ BaseIntegrationTest a @DynamicPropertySource pour PG + Redis + Neo4j
□ GlobalExceptionHandler gère les 5 types requis
□ ApiResponse a les 4 méthodes statiques (ok, created, error, paginated)
□ Tous les Controllers retournent ResponseEntity<ApiResponse<T>>
□ Aucun import direct entre packages modules (user.* n'importe pas village.*)
□ docker-compose.dev.yml a les 4 services avec healthchecks
□ .env.example a toutes les variables de ARCHITECTURE.md
□ .idea/runConfigurations/ contient les 5 fichiers XML
□ backend/http/ contient les 4 fichiers .http

## ÉTAPE 3 — COMMANDES DE DÉMARRAGE

Affiche exactement:

```bash
# 1. Configurer l'environnement
cp backend/.env.example backend/.env

# 2. Démarrer les services Docker
docker-compose -f docker-compose.dev.yml up -d

# 3. Attendre que les services soient prêts
sleep 30

# 4. Démarrer le backend
cd backend && mvn spring-boot:run -Dspring-boot.run.profiles=dev

# 5. Vérifier (dans un autre terminal)
curl -s http://localhost:8080/actuator/health
# Résultat attendu: {"status":"UP","components":{...}}

# 6. Ouvrir Swagger
open http://localhost:8080/swagger-ui.html
```

## RÉCAPITULATIF FINAL

```
╔═══════════════════════════════════════════════════════════╗
║           GWANG MEU — Environnement prêt ✅               ║
╠═══════════════════════════════════════════════════════════╣
║  Backend   Spring Boot 3.3 / Java 21 / Spring Modulith    ║
║  Modules   user · village · geo · feed (Phase 1)          ║
║  Port      8080                                           ║
╠═══════════════════════════════════════════════════════════╣
║  📚 SWAGGER   http://localhost:8080/swagger-ui.html       ║
║  📋 API DOCS  http://localhost:8080/v3/api-docs           ║
║  ❤️  HEALTH   http://localhost:8080/actuator/health       ║
╠═══════════════════════════════════════════════════════════╣
║  🗄️  PostgreSQL   localhost:5432   (PostGIS activé)       ║
║  ⚡ Redis         localhost:6379                          ║
║  🕸️  Neo4j        localhost:7474 (UI) / 7687 (bolt)      ║
║  🔍 Meilisearch   localhost:7700                          ║
╠═══════════════════════════════════════════════════════════╣
║  🚀 CI/CD                                                 ║
║     ci.yml          → tests automatiques sur chaque PR    ║
║     deploy-staging  → deploy Railway auto sur main        ║
║     deploy-prod     → deploy sur tag v*.*.*               ║
╠═══════════════════════════════════════════════════════════╣
║  🔧 IntelliJ   5 run configs prêtes à l'emploi           ║
║     🐳 Docker Dev Stack                                   ║
║     🚀 GwangMeu Backend (Dev)                             ║
║     🔒 GwangMeu Backend (Prod local)                      ║
║     🧪 Tests — All                                        ║
║     🧪 Tests — Phase 1                                    ║
╠═══════════════════════════════════════════════════════════╣
║  📌 PROCHAINE ÉTAPE                                       ║
║     1. Renseigner backend/.env avec tes vraies clés       ║
║     2. make dev && make run                               ║
║     3. http://localhost:8080/swagger-ui.html → 🎉         ║
╚═══════════════════════════════════════════════════════════╝
```

---

## ══════════════════════════════════════════════
## ORDRE D'EXÉCUTION — RÉSUMÉ
## ══════════════════════════════════════════════

```
1.  Créer le repo GitHub (main + develop)
2.  git clone + cd gwangmeu
3.  Placer ARCHITECTURE.md à la racine
4.  Ouvrir Claude Code dans le terminal à la racine
5.  Coller PROMPT 1 → projet généré
6.  Coller PROMPT 2 → CI/CD configuré
7.  Coller PROMPT 3 → IntelliJ configuré
8.  Coller PROMPT 4 → validation + correction automatique
9.  git add . && git commit -m "feat: initial setup phase 1" && git push
    → GitHub Actions CI se déclenche automatiquement ✅
10. Ouvrir IntelliJ → backend/pom.xml → installer EnvFile
11. Run "🐳 Docker Dev Stack" puis "🚀 GwangMeu Backend (Dev)"
12. http://localhost:8080/swagger-ui.html → 🎉
```
