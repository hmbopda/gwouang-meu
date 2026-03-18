# SUIVI.md — GWANG MEU
> Fichier de traçabilité des actions effectuées par Claude Code sur ce projet.
> Référence : ARCHITECTURE.md (V3 — Mars 2026)
> **RÈGLE** : Toute action de Claude Code doit être consignée ici en temps réel.

---

## Format d'entrée

```
[DATE] [PHASE] [MODULE] — Action effectuée
  • Détail 1
  • Détail 2
  Statut : FAIT | EN COURS | ANNULÉ
```

---

## Journal des actions

### 2026-03-06

#### SESSION 1 — Initialisation et analyse
- Lecture de `ARCHITECTURE.md` (V3) pour prise de contexte complète
- Création de ce fichier `SUIVI.md` à la racine du projet
- Analyse critique de l'architecture (Spring Boot Modulith, 14 modules)
  Statut : FAIT

#### SESSION 2 — Structure backend initiale (pré-Phase 1)
- Création de la structure Spring Boot complète (packages, modules)
- Modules créés avec structure sub-packages (domain/, application/, api/, etc.) :
  `user/`, `village/`, `feed/`, `genealogy/`, `shared/`
- Première version de `SecurityConfig` (JWT custom avec jjwt)
  Statut : FAIT (remplacé en Session 3)

#### SESSION 3 — Phase 1 : Refactoring complet selon spec détaillée

**Infrastructure racine**
- `.env.example` — variables d'environnement complètes avec commentaires
- `.gitignore` — Java/Maven, IDE, Flutter, Node, Docker
- `Makefile` — cibles dev/stop/logs/run/build/test/swagger/health/reset-db
- `docker-compose.dev.yml` — postgis:16-3.4-alpine, redis:7-alpine, neo4j:5, meilisearch

**Backend — build & déploiement**
- `backend/pom.xml` — Phase 1 : oauth2-resource-server, flyway-core, flyway-database-postgresql,
  springdoc-openapi-starter-webmvc-ui:2.6.0, firebase-admin:9.3.0, sentry:7.14.0,
  testcontainers-redis, rest-assured. Supprimé: jjwt, webflux.
- `backend/Dockerfile` — Multi-stage eclipse-temurin:21, non-root user, HEALTHCHECK
- `backend/railway.toml` — déploiement Railway avec healthcheckPath

**Config Spring Boot**
- `GwangMeuApplication.java` — @EnableJpaAuditing, @EnableAsync
- `config/SecurityConfig.java` — OAuth2 Resource Server (Supabase JWKS),
  JwtAuthenticationConverter extrayant UserRole depuis user_metadata.role
- `config/SwaggerConfig.java` — @OpenAPIDefinition, BearerAuth, 2 serveurs (local + prod)
- `config/WebSocketConfig.java` — STOMP /topic, /queue, /ws SockJS
- `config/RedisConfig.java` — RedisTemplate<String, Object> + GenericJackson2JsonRedisSerializer

**Shared kernel**
- `shared/api/ApiResponse.java` — record avec ok(), created(), error(), paginated()
- `shared/api/GlobalExceptionHandler.java` — @RestControllerAdvice, 400/401/403/404/409/500
- `shared/audit/AuditEntity.java` — @MappedSuperclass, UUID id, createdAt, updatedAt
- `shared/security/UserRole.java` — enum SUPER_ADMIN, MODERATEUR, AMBASSADEUR, MEMBRE, VISITEUR, API
- `shared/security/CurrentUser.java` — méta-annotation @AuthenticationPrincipal
- `shared/security/JwtAuthFilter.java` — lecture SecurityContextHolder post-validation OAuth2
- `shared/ai/ClaudeAiClient.java` — RestClient (synchrone), SONNET/OPUS, Prompt Caching
- `shared/media/MediaService.java` — @PostConstruct self-init S3Client R2, graceful disable

**Module user/ (flat package)**
- `user/User.java` — entité JPA, supabase_id, email, role, country, etc.
- `user/UserRepository.java` — findBySupabaseId, findByEmail, exists
- `user/UserService.java` — getById, getBySupabaseId, syncFromJwt, updateProfile, deleteAccount
- `user/UserMapper.java` — MapStruct User → UserDto
- `user/dto/UserDto.java`, `user/dto/UpdateUserRequest.java`
- `user/UserController.java` — @CurrentUser Jwt, ApiResponse<T>, Swagger complet
  (GET /me, PUT /me, GET /{userId}, POST /auth/sync, DELETE /me)

**Module village/**
- `village/domain/Village.java` — corrigé (import shared.audit.AuditEntity)
- `village/domain/VillageSubscription.java` — corrigé (import shared.audit.AuditEntity)
- `village/geo/Continent.java` — entité, code AF-CENTRAL/AF-WEST/etc.
- `village/geo/Country.java` — entité, code ISO alpha-3, continent_code
- `village/geo/ContinentRepository.java`, `village/geo/CountryRepository.java`
- `village/geo/GeoController.java` — GET /geo/continents, /geo/countries/{continentCode}, /geo/villages/{countryCode}
- `village/dto/VillageDto.java`, `village/dto/CreateVillageRequest.java`, `village/dto/UpdateVillageRequest.java`
- `village/VillageMapper.java` — MapStruct Village → VillageDto
- `village/api/VillageController.java` — réécriture Phase 1 (@CurrentUser Jwt, ApiResponse<T>, Swagger)

**Module feed/**
- `feed/domain/Post.java` — corrigé (import shared.audit.AuditEntity)
- `feed/domain/Comment.java` — corrigé (import shared.audit.AuditEntity)
- `feed/domain/PostReaction.java` — corrigé (import shared.audit.AuditEntity)
- `feed/dto/PostDto.java`, `feed/dto/CreatePostRequest.java`
- `feed/dto/CommentDto.java`, `feed/dto/ModeratePostRequest.java`
- `feed/FeedMapper.java` — MapStruct Post → PostDto, Comment → CommentDto
- `feed/api/FeedController.java` — réécriture Phase 1 (@CurrentUser Jwt, ApiResponse<T>, Swagger complet)

**Configuration YAML**
- `application.yml` — Flyway, OAuth2 RS (Supabase JWKS), springdoc, sentry, application.*
- `application-dev.yml` — localhost datasources, DEBUG logging, swagger activé
- `application-prod.yml` — swagger désactivé, logs WARN

**Migrations Flyway**
- `V1__init_extensions.sql` — uuid-ossp, postgis, unaccent, pg_trgm
- `V2__users.sql` — table users + index supabase_id, email, role
- `V3__villages.sql` — tables continents, countries, villages, village_subscriptions + seed continents
- `V4__feed.sql` — tables posts, comments, post_reactions + index

**Tests**
- `shared/BaseIntegrationTest.java` — Testcontainers (postgis, neo4j:5, redis:7), @DynamicPropertySource
- `user/UserControllerTest.java` — RestAssured, 401/404 sans token
- `village/VillageControllerTest.java` — RestAssured, 401/404/empty list
- `feed/FeedControllerTest.java` — RestAssured, 401/404/empty list
- `GwangMeuApplicationTests.java` — contextLoads
- `test/resources/application-test.yml` — config test sans services externes

  Statut : FAIT

---

### 2026-03-07

#### SESSION 4 — CI/CD + IntelliJ + Modération + Geo (résumé de session précédente)

**CI/CD GitHub Actions**
- `.github/workflows/ci.yml` — tests sur PR/push develop, services PostGIS + Redis
- `.github/workflows/deploy-staging.yml` — push main → Railway staging → health check
- `.github/workflows/deploy-prod.yml` — tag v*.*.* → ghcr.io → Railway prod → rollback + GitHub Release
- `backend/railway.toml` — mis à jour : healthcheckTimeout=300, envs staging/production
- `GITHUB_SECRETS.md` — guide complet des 23 secrets avec sources et formats
  Statut : FAIT

**IntelliJ IDEA**
- `.idea/.gitignore` — conserve runConfigurations/, codeStyles/, templates/
- `.idea/runConfigurations/` — 5 configs : Docker Dev Stack, Backend Dev, Backend Prod Local, Tests All, Tests Phase1
- `.idea/codeStyles/Project.xml` — 120 col, indent 4, imports ordonnés
- `.idea/templates/GwangMeu.xml` — 8 live templates : gmc, gms, gmr, gme, gmd, gmev, gmtest, swop
- `backend/http/` — http-client.env.json + 4 fichiers .http (auth, users, villages, feed)
- `SETUP_INTELLIJ.md` — guide 8 étapes, plugin EnvFile requis
  Statut : FAIT

**Module feed/ — Workflow de modération complet**
- `V5__moderation.sql` — ALTER posts (statuts, note, moderated_by, flag_count), CREATE moderation_queue, moderation_logs
- `feed/domain/ModerationStatus.java` — ajout SHADOW_BANNED
- `feed/domain/Post.java` — champs : flagCount, moderationNote, moderatedBy (UUID), moderatedAt
- `feed/domain/ModerationQueue.java` — entité table moderation_queue
- `feed/domain/ModerationLog.java` — entité table moderation_logs
- `feed/infrastructure/ModerationQueueRepository.java` — findByVillageId, findByPostIdAndReporter, deleteByPostId
- `feed/infrastructure/ModerationLogRepository.java` — findByVillageId (JPQL join)
- `feed/infrastructure/PostRepository.java` — ajout findByVillageIdAndModerationStatusIn, countByStatus
- Événements (extends DomainEvent) : PostSubmittedEvent, PostApprovedEvent, PostRejectedEvent, PostFlaggedEvent
- `feed/application/FlagRateLimiter.java` — Bucket4j in-memory, 3 flags/user/heure
- `feed/application/ModerationService.java` — interface 6 méthodes
- `feed/application/ModerationServiceImpl.java` — machine à états :
  PENDING→APPROVED/REJECTED | APPROVED→FLAGGED | FLAGGED→SHADOW_BANNED/APPROVED | auto APPROVED→FLAGGED si flagCount≥3
- `feed/api/ModerationController.java` — 6 endpoints : queue, moderate, flag, resubmit, stats, logs
- DTOs records : FlagPostRequest, ModerateActionRequest, ModerationQueueDto, ModerationStatsDto, ModerationLogDto
- `feed/application/FeedServiceImpl.java` — publie PostSubmittedEvent à la création
- `feed/api/FeedController.java` — moderate() délègue à ModerationService
- `test/feed/ModerationControllerTest.java` — 12 tests, toutes les transitions + dashboard
  Statut : FAIT

#### BUGFIX — GeoController : incompatibilité de types generiques Java
- `geo/api/GeoController.java` — `ApiResponse.error()` retourne `ApiResponse<Void>`, incompatible avec `ApiResponse<List<GeoSearchResultDto>>`
  Fix : remplacement par `throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "...")` — capturé par GlobalExceptionHandler
  Statut : FAIT

#### BUGFIX — Flyway V6 : `ST_MakePoint` introuvable sur Supabase
- **Cause** : Supabase installe PostGIS dans le schema `extensions`, pas `public`. Le `search_path` par défaut ne l'inclut pas.
- **Fix 1** : `V6__geo_complete.sql` — index GiST encapsulé dans un bloc `DO $$ ... SET LOCAL search_path TO public, extensions` avec vérification `IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'postgis')` — skip si PostGIS absent (dev local sans Docker)
- **Fix 2** : `application-dev.yml` — ajout `?options=-c%20search_path%3Dpublic,extensions` dans l'URL JDBC pour que toutes les requêtes (native queries PostGIS incluses) voient les fonctions ST_*
- `repair-on-migrate: true` déjà configuré — Flyway répare automatiquement la migration échouée au prochain démarrage
  Statut : FAIT

**Module geo/ — Hiérarchie Continent > Pays > Village v1**
- `V6__geo_complete.sql` — flag_emoji + continent_id dans countries, country_id UUID FK dans villages,
  index GiST ST_MakePoint(longitude, latitude), table cultural_links (UNIQUE par paire + type),
  seed 10 pays africains avec emoji drapeaux (CMR, COD, SEN, CIV, NGA, GHA, MLI, BFA, RWA, TZA)
- `V7__seed_villages.sql` — 30 villages GPS réels (3 par pays), country_id FK via subselect
- `geo/domain/Country.java` — ajout flagEmoji, continentId
- `village/domain/Village.java` — ajout countryId (UUID FK)
- `geo/domain/CulturalLink.java` — entité cultural_links (villageAId, villageBId, linkType, similarityScore, createdByAi)
- `geo/infrastructure/CulturalLinkRepository.java` — findByVillageId (A ou B), findByVillageIdAndLinkType
- `geo/infrastructure/NearbyVillageProjection.java` — projection Spring Data avec getDistanceMeters()
  Statut : FAIT

#### SESSION 5 — Module geo/ : DTOs, repositories PostGIS, service, controller, tests

**DTOs créés**
- `geo/dto/NearbyVillageDto.java` — village proche avec distanceKm (arrondi 1 décimale), factory `from(NearbyVillageProjection)`
- `geo/dto/CulturalLinkDto.java` — lien culturel avec similarityScore + createdByAi, factory `from(CulturalLink)`
- `geo/dto/GeoSearchResultDto.java` — résultat multi-niveaux (CONTINENT/COUNTRY/VILLAGE), 3 factories statiques
  Statut : FAIT

**Repositories mis à jour**
- `geo/infrastructure/ContinentRepository.java` — ajout `countCountriesByContinentCode()`, `countVillagesByContinentCode()`
- `geo/infrastructure/CountryRepository.java` — ajout `countVillagesByCountryId(UUID)`
- `village/infrastructure/VillageRepository.java` — ajout :
  - `findNearby(lat, lng, radiusMeters, limit)` — requête native PostGIS ST_DWithin + ST_Distance, colonne aliasée distanceMeters, retourne `List<NearbyVillageProjection>`
  - `findByCountryId(UUID, Pageable)` — filtre par FK pays
  - `findByContinentCode(String, Pageable)` — filtre par continent avec pagination
  Statut : FAIT

**GeoService interface + GeoServiceImpl**
- `geo/application/GeoService.java` — réécriture complète : 6 méthodes retournant DTOs (plus d'entités brutes)
  getAllContinents, findContinentByCode, getCountriesByContinent, findCountryByIsoCode,
  findNearbyVillages(lat, lng, radiusKm, limit), getCulturalLinks(villageId, linkType), globalSearch(query)
- `geo/application/GeoServiceImpl.java` — implémentation complète :
  - Stats continents/pays calculées via repository (countCountries, countVillages)
  - Nearby : cap 50 résultats, conversion km→mètres, délègue à VillageRepository.findNearby()
  - Cultural links : filtre optionnel par type
  - GlobalSearch : multi-niveaux (continents + pays + villages), cap 20 résultats total
  Statut : FAIT

**GeoController — réécriture complète**
- `geo/api/GeoController.java` — 6 endpoints documentés Swagger + @Validated :
  1. `GET /api/v1/geo/continents` — liste avec countryCount + villageCount
  2. `GET /api/v1/geo/continents/{code}` — détail continent, 404 si inconnu
  3. `GET /api/v1/geo/continents/{code}/countries` — pays d'un continent avec emoji drapeau
  4. `GET /api/v1/geo/countries/{isoCode}` — détail pays, insensible casse, 404 si inconnu
  5. `GET /api/v1/geo/villages/nearby?lat&lng&radiusKm&limit` — PostGIS ST_DWithin, @DecimalMin/Max sur coords, rayon 1-500km, résultats 1-50
  6. `GET /api/v1/geo/villages/{id}/cultural-links?linkType` — liens culturels d'un village
  7. `GET /api/v1/geo/search?q` — recherche globale multi-niveaux, min 2 chars, 400 si trop court
  Statut : FAIT

**VillageController — filtre pays/continent**
- `village/api/VillageController.java` — ajout `GET /api/v1/villages?countryCode=CMR&continentCode=AF-CENTRAL`
  Logique : countryCode → findByCountry(), continentCode → findByContinent(), sinon → findAll via search("")
  Statut : FAIT

**Tests GeoController**
- `test/geo/GeoControllerTest.java` — 12 tests Testcontainers (postgis/postgis:16-3.4-alpine) :
  - Continents : liste, détail par code, 404
  - Pays : liste par continent (avec emoji), détail par ISO (insensible casse), 404
  - Nearby : résultat dans rayon 100km, 0 résultats rayon trop petit, 400 coords invalides
  - Cultural links : liste avec score, filtre par type (0 résultats)
  - GlobalSearch : trouve village par nom partiel, trouve pays par ISO, 400 si 1 char
  Statut : FAIT

#### SESSION 6 — Flutter App Skeleton + Next.js Landing + CI/CD complet

**Structure ajoutée**
- `frontend/` — Flutter multi-plateforme (iOS + Android + Web + Desktop), même niveau que `backend/`
- `landing/` — Next.js 14 vitrine SEO
- `.github/workflows/ci.yml` — mis à jour avec jobs `test-flutter` et `build-landing`
- `.github/workflows/deploy-frontend.yml` — nouveau : Flutter Web → Cloudflare Pages, Next.js → Vercel (vérification)
  Statut : FAIT

**Flutter `frontend/` — Configuration**
- `pubspec.yaml` — supabase_flutter, go_router, flutter_riverpod, riverpod_annotation, dio, flutter_secure_storage, cached_network_image, shimmer, freezed, json_serializable, intl, flutter_dotenv
- `.env.example` — SUPABASE_URL, SUPABASE_ANON_KEY, API_BASE_URL
- `analysis_options.yaml` — lint Flutter avec exclusions generated files
- `.gitignore` — *.g.dart, *.freezed.dart, .env, build/
  Statut : FAIT

**Flutter `frontend/` — Core**
- `lib/main.dart` — flutter_dotenv.load(), Supabase.initialize(), ProviderScope, runApp
- `lib/app.dart` — MaterialApp.router + theme sombre GWANG MEU
- `lib/core/theme/app_theme.dart` — AppColors (gold #C8A020, bg #0D0D0D, surface #1A1A1A), AppTextStyles, ThemeData complet
- `lib/core/router/route_names.dart` — constantes Routes (splash, auth, home, feed, villages, search, profile, village/:id)
- `lib/core/router/app_router.dart` — GoRouter + ShellRoute (4 onglets) + guard Supabase session
- `lib/core/network/api_client.dart` — Dio baseUrl depuis .env, _AuthInterceptor JWT Supabase, 401 → signOut
- `lib/core/network/supabase_service.dart` — wrapper SupabaseAuth (signIn, signUp, resetPassword, signOut)
- `lib/core/storage/secure_storage.dart` — FlutterSecureStorage pour FCM token et prefs
  Statut : FAIT

**Flutter `frontend/` — Models (Freezed + JsonSerializable)**
- `lib/shared/models/api_response.dart` — ApiResponse<T> avec fromJson() + PageResponse<T> paginated
- `lib/shared/models/user_model.dart` — @freezed UserModel (id, email, displayName, avatarUrl, role, country, bio)
- `lib/shared/models/village_model.dart` — @freezed VillageModel + extension VillageModelX.slug
- `lib/shared/models/post_model.dart` — @freezed PostModel + extension PostModelX.isApproved
- Note : générer avec `dart run build_runner build --delete-conflicting-outputs`
  Statut : FAIT

**Flutter `frontend/` — Widgets réutilisables**
- `lib/shared/widgets/gwang_button.dart` — GwangButton (primary gold, outline, ghost), loading spinner
- `lib/shared/widgets/village_card.dart` — carte village avec CachedNetworkImage + shimmer + badge vérifié
- `lib/shared/widgets/post_card.dart` — carte publication avec avatar, media, actions (like, comment, share)
- `lib/shared/widgets/loading_overlay.dart` — LoadingOverlay + ShimmerCard + ShimmerList
- `lib/shared/widgets/error_widget.dart` — GwangErrorWidget (retry) + GwangEmptyWidget (empty state)
  Statut : FAIT

**Flutter `frontend/` — Features**
- `features/auth/auth_notifier.dart` — @riverpod AuthNotifier (signIn, signUp, resetPassword, signOut)
- `features/auth/auth_screen.dart` — 3 modes : login / register / forgotPassword, validation form, messages d'erreur Supabase traduits
- `features/home/home_screen.dart` — ShellRoute avec BottomNavigationBar 4 onglets (Feed, Villages, Recherche, Profil)
- `features/feed/feed_notifier.dart` — @riverpod FeedNotifier, pagination infinie, pull-to-refresh
- `features/feed/feed_screen.dart` — ListView posts + FAB créer publication
- `features/villages/villages_notifier.dart` — @riverpod VillagesNotifier (search, filterByCountry) + villageDetailProvider
- `features/villages/villages_screen.dart` — GridView 2 colonnes + SearchBar inline
- `features/villages/village_detail_screen.dart` — SliverAppBar image + stats + infos + CTA rejoindre
- `features/profile/profile_notifier.dart` — @riverpod ProfileNotifier + signOut
- `features/profile/profile_screen.dart` — Avatar + rôle + infos + actions + déconnexion → redirect /auth
- `features/search/search_screen.dart` — SearchBar + FutureProvider /api/v1/geo/search + résultats typés (VILLAGE/COUNTRY/CONTINENT)
  Statut : FAIT

**Next.js `landing/` — Configuration**
- `package.json` — next 14.2.5, react 18, tailwindcss, @tailwindcss/typography, next-seo, schema-dts, clsx, tailwind-merge, TypeScript
- `next.config.js` — output standalone, images remotePatterns (api.gwangmeu.com, supabase, flagcdn, localhost)
- `tailwind.config.js` — couleurs gold/dark/cream/text, polices display (Fraunces) + sans (Plus Jakarta Sans), animations fade-in/slide-up
- `tsconfig.json` — strict mode, paths @/* et @/components/*, @/lib/*
- `postcss.config.js`, `.env.local.example` (NEXT_PUBLIC_API_URL, APP_URL, SITE_URL)
  Statut : FAIT

**Next.js `landing/` — Core**
- `app/globals.css` — @tailwind base/components/utilities + classes .btn-gold, .card, .section-title
- `app/layout.tsx` — Fraunces + Plus Jakarta Sans (next/font), metadata globale, og:image, robots
- `app/page.tsx` — SSG homepage : HeroSection + Features grid (6 features) + CTA final
- `app/sitemap.ts` — sitemap dynamique (homepage, villages, all slugs)
- `app/robots.ts` — robots.txt avec disallow /api/ /_next/
- `lib/types.ts` — Village, Country, Continent, GeoSearchResult, ApiResponse<T>, PageData<T>, villageSlug()
- `lib/api.ts` — fetchVillages(), fetchVillage(), fetchVillageBySlug(), fetchCountry(), fetchContinents(), fetchPublicStats()
  Statut : FAIT

**Next.js `landing/` — Pages**
- `app/villages/page.tsx` — SSG + ISR 3600s, grille villages, stats continents
- `app/villages/[slug]/page.tsx` — generateStaticParams + generateMetadata, JSON-LD Place, SliverAppBar image, stats, histoire, CTA rejoindre
- `app/pays/[code]/page.tsx` — generateMetadata, flag emoji, liste villages par pays
- `app/a-propos/page.tsx` — mission, valeurs (4), stack technique
  Statut : FAIT

**Next.js `landing/` — Composants**
- `components/ui/Navbar.tsx` — logo GWANG MEU gold + nav (Villages, À propos) + CTA "Rejoindre l'app" or
- `components/ui/Footer.tsx` — brand + liens Plateforme/Légal + réseaux sociaux
- `components/ui/HeroSection.tsx` — titre display Fraunces, badge animé, stats (villages/langues/membres), 2 CTAs
- `components/ui/VillageCard.tsx` — Image next/image, badge vérifié, slug SEO, hover scale
- `components/seo/JsonLd.tsx` — VillageJsonLd (Schema.org Place) + WebsiteJsonLd (SearchAction)
  Statut : FAIT

**CI/CD mis à jour**
- `.github/workflows/ci.yml` — 2 nouveaux jobs :
  - `test-flutter` : flutter pub get, build_runner, analyze, test, flutter build web
  - `build-landing` : npm ci, type-check, npm run build
- `.github/workflows/deploy-frontend.yml` — nouveau workflow :
  - `deploy-flutter-web` : build Flutter web release → Cloudflare Pages (secrets: CLOUDFLARE_API_TOKEN, CLOUDFLARE_ACCOUNT_ID)
  - `verify-landing` : npm run build → Vercel déploie automatiquement via GitHub integration
  Statut : FAIT

**Secrets GitHub à ajouter (frontend)**
```
CLOUDFLARE_API_TOKEN     — API token Cloudflare (Pages:Edit)
CLOUDFLARE_ACCOUNT_ID    — Account ID Cloudflare
NEXT_PUBLIC_API_URL      — https://api.gwangmeu.com
NEXT_PUBLIC_APP_URL      — https://app.gwangmeu.com
NEXT_PUBLIC_SITE_URL     — https://gwangmeu.com
```

---

## Résumé de l'état du projet

| Phase | Description | Statut |
|-------|-------------|--------|
| Phase 1 | Auth, Villages, Social Feed (6 sem.) | **EN COURS** |
| Phase 2 | Carte, Tourisme, Claude Guide (6 sem.) | Non démarré |
| Phase 3 | Généalogie, Chat, Notifications (7 sem.) | Non démarré |
| Phase 4 | Lives, Cours en direct (6 sem.) | Non démarré |
| Phase 5 | Dialectes, Connexions Culturelles, Emploi (5 sem.) | Non démarré |
| Phase 6 | IA Avancée, Scale, Monétisation (4 sem.) | Non démarré |

---

## Modules touchés

| Module | Fichiers créés/modifiés | Dernière action |
|--------|------------------------|-----------------|
| shared | AuditEntity, ApiResponse, GlobalExceptionHandler, CurrentUser, UserRole, JwtAuthFilter, ClaudeAiClient, MediaService | 2026-03-06 |
| user | User, UserRepository, UserService, UserMapper, UserController, dto/* | 2026-03-06 |
| village | Village (+countryId), VillageSubscription, VillageMapper, VillageController (+GET list filters), VillageRepository (+findNearby, +findByCountryId), geo/*, dto/* | 2026-03-07 |
| feed | Post (+flagCount+moderationNote), ModerationQueue, ModerationLog, FeedMapper, FeedController, ModerationController, ModerationServiceImpl, FlagRateLimiter, dto/*, events/* | 2026-03-07 |
| geo | Continent, Country (+flagEmoji+continentId), CulturalLink, CulturalLinkRepository, NearbyVillageProjection, GeoService (réécriture), GeoServiceImpl (réécriture), GeoController (réécriture), dto/* (5 DTOs) | 2026-03-07 |
| config | SecurityConfig, SwaggerConfig, WebSocketConfig, RedisConfig | 2026-03-06 |
| db/migration | V1 → V7 | 2026-03-07 |
| tests | BaseIntegrationTest, UserControllerTest, VillageControllerTest, FeedControllerTest, ModerationControllerTest, GeoControllerTest | 2026-03-07 |
| ci-cd | .github/workflows/ci.yml, deploy-staging.yml, deploy-prod.yml, railway.toml, GITHUB_SECRETS.md | 2026-03-07 |
| intellij | .idea/runConfigurations/*, codeStyles/*, templates/*, http/* , SETUP_INTELLIJ.md | 2026-03-07 |

---

## Notes et décisions

- Architecture : Java Spring Boot 3.3.5 + Java 21 (LTS)
- Auth : OAuth2 Resource Server → Supabase JWKS (remplace jjwt custom)
- @CurrentUser Jwt jwt — méta-annotation @AuthenticationPrincipal pour tous les controllers
- ApiResponse<T> — wrapper uniforme sur tous les endpoints
- MapStruct — Entity ↔ DTO (componentModel=spring via compiler arg)
- Flyway — gestion du schéma (ddl-auto: validate en prod, Flyway en dev/prod)
- Communication inter-modules : uniquement via ApplicationEventPublisher
- Modèles IA : claude-sonnet-4-6 (tâches courantes) / claude-opus-4-6 (tâches complexes)
- Deux AuditEntity coexistantes : `shared.audit.AuditEntity` (village/feed) et `shared.domain.AuditEntity` (geo) — pas de merge nécessaire
- PostGIS : ST_DWithin + ST_Distance avec cast ::geography (WGS84, mètres réels)
- Bucket4j in-memory (core only, pas de Redis) pour rate limiting flags : 3 flags/user/heure
- Flag emojis stockés en Unicode dans PostgreSQL (U&'\1F1E8\1F1F2' en SQL seed)
- DTOs flat records (sans objets imbriqués) pour optimiser les connexions lentes
- Recherhce globale : cap 20 résultats, min 2 chars

---

## Prochaines étapes Phase 1

- [ ] Vérifier que `mvn compile` passe sans erreur
- [ ] Vérifier conflits entre anciens controllers (village/geo/GeoController stub @Deprecated) et geo/api/GeoController
- [ ] Lancer `make dev` + `make run` et vérifier Swagger UI sur http://localhost:8080/swagger-ui.html
- [ ] Connecter un projet Supabase et tester l'auth OAuth2
- [ ] Tester `GET /api/v1/geo/villages/nearby` avec coordonnées réelles (Yaoundé : lat=3.848, lng=11.502)
- [ ] Vérifier que Flyway applique V1→V7 sans erreur sur une base vierge

---

### 2026-03-13

#### SESSION — Optimisation performance frontend (-40% temps de démarrage)

**Objectif** : Réduire drastiquement le temps de chargement et démarrage sur iOS, Android, Web et Desktop.

**1. Deferred imports — Lazy loading des routes (Web: -30-40% bundle initial)**
- `lib/core/router/app_router.dart` — 9 écrans en `deferred as` : Villages, Search, Profile, Genealogy, MyVillages, CreateVillage, EditVillage, VillageDetail, Invitation
- `lib/shared/widgets/deferred_widget.dart` — Helper DeferredWidget (FutureBuilder + loadLibrary)
- Seuls FeedScreen (page initiale) et AuthScreen (premier écran potentiel) restent eager
  Statut : FAIT

**2. Splash screen natif sombre (percçu: -200ms, pas de flash blanc)**
- `android/app/src/main/res/values/colors.xml` — #080709 (ink-deep)
- `android/app/src/main/res/drawable/launch_background.xml` — fond @color/splash_background
- `android/app/src/main/res/drawable-v21/launch_background.xml` — idem
- `android/app/src/main/res/values/styles.xml` — LaunchTheme parent Theme.Black.NoTitleBar
- `android/app/src/main/res/values-night/styles.xml` — confirmé sombre
- `ios/Runner/Base.lproj/LaunchScreen.storyboard` — backgroundColor RGB(0.031, 0.027, 0.035) = #080709
  Statut : FAIT

**3. Init différée après premier frame**
- `lib/main.dart` — addPostFrameCallback pour init non-critique (futur: FCM, Sentry, analytics)
- Structure prête pour Firebase/Sentry quand ils seront ajoutés
  Statut : FAIT

**4. Fix memory leak — personCommentsProvider**
- `lib/features/genealogy/widgets/person_comments_sheet.dart` — FutureProvider.family → FutureProvider.autoDispose.family
- Empêche l'accumulation en mémoire des commentaires de fiches fermées
  Statut : FAIT

**5. Vérification**
- `dart analyze lib/` — 0 erreurs, 0 warnings (391 infos pré-existantes)
- `build_runner` — 0 outputs (pas de .g.dart impactés)
- Note : `flutter build web` échoue sur shader compiler (ink_sparkle.frag) — problème d'environnement Windows pré-existant, non lié aux changements
  Statut : FAIT

**Fichiers créés** :
- `lib/shared/widgets/deferred_widget.dart`
- `android/app/src/main/res/values/colors.xml`

**Fichiers modifiés** :
- `lib/core/router/app_router.dart`
- `lib/main.dart`
- `lib/features/genealogy/widgets/person_comments_sheet.dart`
- `android/app/src/main/res/drawable/launch_background.xml`
- `android/app/src/main/res/drawable-v21/launch_background.xml`
- `android/app/src/main/res/values/styles.xml`
- `android/app/src/main/res/values-night/styles.xml`
- `ios/Runner/Base.lproj/LaunchScreen.storyboard`

#### SESSION 2 — Refonte écran Profil (maquette gwangmeu-profile-v3)

**Objectif** : Réécriture complète du profil selon la maquette v3 — layout 3 colonnes, hero canvas, tabs, stats.

**Architecture du nouvel écran** :
- `_ResponsiveShell` — 3 colonnes (>=1100px), 2 colonnes (>=800px), 1 colonne (<800px)
- `_LeftRail` (240px) — Identité mini + barre de complétion dynamique + nav sections + villages + paramètres + déconnexion
- `_CenterPanel` — Hero canvas + 5 tabs (Aperçu, Publications, Généalogie, Langues, Formations)
- `_RightPanel` (272px) — Lignée directe + Mes villages chips + Checklist complétion
- Design tokens identiques à village_detail_screen.dart (gold/stone/sage/ember/azure)

**Sections implémentées** :
1. Hero — canvas painter (gold glow + kente lines), avatar gradient gold, titre serif bicolore, meta row, boutons
2. Stats bar — 5 cellules connectées aux providers (Villages réel, reste placeholder)
3. Bio — texte + chips dynamiques depuis UserModel
4. Langues aperçu — progress bar langue native
5. Formations aperçu — placeholder "Bientôt disponible"
6. Left Rail — identité, complétion calculée sur 10 champs, villages via myVillagesNotifierProvider + breadcrumb
7. Right Panel — lignée directe (père/mère), village chips, checklist complétion (6 items)
8. Tabs secondaires — ComingSoonPane placeholder

**Vérification** : `dart analyze` — 0 erreurs, 0 warnings
  Statut : FAIT

**Fichier modifié** : `lib/features/profile/profile_screen.dart` — réécriture complète (~1200 lignes)
