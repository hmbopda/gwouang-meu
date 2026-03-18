# ARCHITECTURE.md — GWANG MEU
> Plateforme de préservation culturelle africaine — Langues · Culture · Futur
> Anciennement : NGOMALA.ACADEMY | Rebranding complet → **GWANG MEU**

---

## 🎯 Vision du projet

GWANG MEU est une plateforme communautaire et culturelle connectant les populations africaines locales et leur diaspora mondiale. Elle permet de :

- Préserver et enseigner les **langues & dialectes africains**
- Documenter les **villages, familles, généalogies** (arbres Neo4j + carte)
- Organiser des **lives culturels, cours en direct, conférences**
- Proposer du **tourisme culturel IA** avec guides personnalisés
- Connecter les **marchés de l'emploi** locaux et diaspora
- Enrichir les **patrimoines culinaires, artistiques et rituels**

**Tagline officielle :** _Langues · Culture · Futur_

---

## 🏗️ Architecture globale

```
Architecture  : Java Spring Boot Modulith (monolithe modulaire)
Pattern       : 14 modules internes isolés → migration microservices possible
Communication : Spring ApplicationEvents (zero appels réseau inter-modules)
Shared Kernel : SecurityContext, VillageContext, GeoContext, AuditEntity,
                DomainEvents, ClaudeAiClient, MediaService, I18nMessages
```

### Vue en couches

```
┌─────────────────────────────────────────────────────────────┐
│  CLIENTS                                                      │
│  Next.js 14 (SEO)  │  Flutter Mobile  │  Flutter Web/Desktop │
└────────────────────────────┬────────────────────────────────┘
                             │ HTTPS / WSS / WebRTC (LiveKit)
┌────────────────────────────▼────────────────────────────────┐
│  GATEWAY & SÉCURITÉ                                          │
│  Spring Boot :8080  │  Supabase Auth  │  Cloudflare CDN/WAF  │
│  Spring Security + JWT  │  Bucket4j Rate Limiting            │
└────────────────────────────┬────────────────────────────────┘
                             │ Spring ApplicationEvents
┌────────────────────────────▼────────────────────────────────┐
│  14 MODULES JAVA ISOLÉS                                       │
│  [voir section modules]                                       │
└────────────────────────────┬────────────────────────────────┘
                             │ Spring Data JPA / Neo4j / SDK
┌────────────────────────────▼────────────────────────────────┐
│  DONNÉES & SERVICES EXTERNES                                  │
│  Supabase PG │ Neo4j AuraDB │ Redis │ Meilisearch │ R2       │
│  Claude API  │ LiveKit Cloud │ Mapbox │ FCM │ Resend         │
└─────────────────────────────────────────────────────────────┘
```

---

## 📦 14 Modules Java

> Chaque module = package Java isolé. Jamais d'appel direct entre modules.
> Toujours passer par `ApplicationEventPublisher` pour communiquer.

### Modules CORE

| Module | Responsabilité | Dépendances clés |
|--------|---------------|-----------------|
| `user-module` | Profils, rôles RBAC (6 rôles), localisation, biographie culturelle | Supabase Auth, JWT |
| `village-module` | Pages villages, groupes, abonnements, hiérarchie géographique | Follow/Join, Multi-pays |
| `feed-module` | Publications, réactions, commentaires, fil personnalisé, modération | Workflow Review, Pinned |
| `geo-module` | Continent→Pays→Région→Village, groupes transversaux dialectes/cuisine | PostGIS, cultural_link |

### Modules SPÉCIALISÉS

| Module | Responsabilité | Dépendances clés |
|--------|---------------|-----------------|
| `genealogy-module` | Arbres familiaux, suggestions IA, plan géo-familles | Neo4j AuraDB, Claude API |
| `language-module` | Cours par dialecte, niveaux, quiz IA, certifications | Claude Quiz, LiveKit |
| `live-module` | Lives cours, conférences culturelles, visites guidées, webinaires village | LiveKit Cloud, Recording |
| `tourism-module` | Carte interactive, POI, guide IA, itinéraires, avis, audio-guide | Mapbox GL, Claude Guide |
| `culture-module` | Art culinaire, rites, musique, histoire, musée virtuel par peuple | Contributions, Claude enrich |

### Modules TRANSVERSAUX

| Module | Responsabilité | Dépendances clés |
|--------|---------------|-----------------|
| `messaging-module` | Chat privé/village/global/thématique, DMs, WebSocket STOMP | Redis Pub/Sub, E2E |
| `jobs-module` | Offres/demandes, annuaire talents, géo-filtres, réseau pro | Meilisearch, Géoloc |
| `notification-module` | Push FCM, email, SMS Orange API Africa, in-app | FCM, Resend |
| `ai-module` | Orchestrateur Claude API : guide, quiz, généalogie, modération | claude-sonnet-4-6, RAG |
| `search-module` | Full-text multi-langues africaines, phonétique, personnes, villages | Meilisearch, Phonétique |

---

## 🌍 Hiérarchie Géographique

```
CONTINENT (Afrique Centrale / Ouest / Est / Diaspora)
    │  page publique · groupes culturels · carte globale · aires linguistiques
    │
    ├── PAYS (Cameroun, Côte d'Ivoire, Sénégal, Congo, Nigeria…)
    │       page pays · groupes pays · tourisme national · peuples & ethnies
    │
    ├── AIRE DIALECTALE (cross-frontières)
    │       groupe dialecte · cours de langue · dictionnaire collaboratif
    │
    ├── VILLAGE
    │       page sociale complète · carte Mapbox · arbre généalogique
    │       guide touristique IA · POI · historique & origines · rites
    │       art culinaire · personnalités notables
    │
    └── FAMILLE
            coordonnées GPS · chef de famille · clan/totem
            lien arbre Neo4j · photos privées · visibilité membres validés
```

### Connexions transversales (cross-pays)
- **Par dialecte** : villages Bassa (Cameroun + diaspora) → cours communs, dictionnaire partagé, lives dialecte
- **Par art culinaire** : recettes communes → aires culinaires, Claude détecte similitudes inter-villages
- **Par histoire & rites** : migrations, rites partagés → détectés par Claude via tags culturels + scoring

---

## 🤖 Claude AI — Architecture d'intégration

### Modèles utilisés
```
claude-sonnet-4-6  →  Tâches courantes (guide, quiz, modération, résumé)
claude-opus-4-6    →  Tâches complexes (enrichissement culturel profond, arbres complexes)
```

### Pipeline RAG en 5 étapes

```
STEP 01 — Context Assembly
  • Profil utilisateur + langue préférée + niveau langue
  • Village(s) associés + historique conversation

STEP 02 — Knowledge Retrieval
  • Fiche village (PostgreSQL) + arbre (Neo4j)
  • Contenus culturels + Meilisearch semantic
  • Historique publié pertinent

STEP 03 — Prompt Engineering
  • System prompt avec rôle défini
  • Context RAG injecté
  • Format de sortie défini (JSON ou texte structuré)
  • Langue cible + Prompt Caching Anthropic activé

STEP 04 — Claude API Call
  • Streaming SSE vers le client
  • Max tokens adapté au cas d'usage
  • Temperature réglée par use case
  • Tool use si besoin (ex: recherche Meilisearch)
  • Timeout géré côté Java

STEP 05 — Output Processing
  • Validation contenu + modération
  • Sauvegarde si pertinent (résumé live, quiz généré)
  • Feedback loop utilisateur
  • Audit log IA + métriques qualité
```

### 8 cas d'usage Claude

| Use Case | Modèle | Coût estimé | System Prompt Pattern |
|----------|--------|-------------|----------------------|
| 🗺️ Guide Touristique | Sonnet 4.6 | ~0.01€/conv | `"Tu es le guide officiel du village {village_name}. Histoire depuis {year}. Réponds en {user_lang} avec mots en {local_lang}."` |
| 🌳 Matching Généalogique | Sonnet 4.6 | ~0.05€/analyse | `"Analyse arbre partiel du village {v}. Identifie liens probables. Score confiance 0-1. Ne jamais affirmer sans preuve."` |
| 🗣️ Quiz Linguistiques | Sonnet 4.6 | ~0.003€/quiz | `"Génère 5 questions niveau {level} en {dialect}. Inclus contexte culturel. Format JSON strict."` |
| 🍲 Enrichissement Culturel | Opus 4.6 | ~0.15€/enrichissement | `"Enrichis la fiche du village {v}. Détecte les liens avec autres cultures africaines."` |
| 🔗 Connexions Culturelles | Sonnet 4.6 | ~0.08€/batch | `"Compare ces {n} fiches. Score similarité par catégorie (dialecte, cuisine, rites, histoire). Justifie."` |
| 🎥 Post-Live Intelligence | Sonnet 4.6 | ~0.02€/live 1h | `"Transcription '{title}'. Génère: résumé 300 mots, chapitrage timestamps, 5 questions."` |
| 🛡️ Modération Contenu | Sonnet 4.6 | ~0.001€/post | `"Modérateur culturel GWANG MEU. Évalue ce post pour {village}. Retourne JSON: {action, score, reason}"` |
| 🏛️ Itinéraires Personnalisés | Sonnet 4.6 | ~0.02€/itinéraire | `"Visiteur {profile} veut découvrir {village} en {days}j. Budget {budget}. Itinéraire POI culturels."` |

> **💡 Optimisation coûts :** Utilise le **Prompt Caching** Anthropic.
> Les system prompts contenant les données village (souvent 1000+ tokens) mis en cache = **-80% à -90% de coût** sur les appels répétitifs.

---

## 🎥 Module Lives — LiveKit Cloud

```
SDK Java      : LiveKit Server SDK (Java)
SDK Flutter   : livekit_client (officiel)
```

### Types de rooms LiveKit
```
live_course_{id}    →  Cours de langue (language-module)
live_conf_{id}      →  Conférence culturelle (village-module)
live_tour_{id}      →  Visite guidée virtuelle (tourism-module)
live_village_{id}   →  Webinaire privé village (village-module)
```

### Fonctionnalités
- **Recording** → Cloudflare R2 → replay HLS dans app
- **RTMP Egress** → YouTube Live + Facebook Live simultané
- **Claude dans les lives** : correction pronunciation, Q&A, résumé live
- **Post-live auto** : chapitrage, quiz, transcription, traduction

---

## 🗺️ Module Tourisme — Mapbox GL

```
Bibliothèque Flutter  : flutter_map (OSM) + Mapbox tiles
Backend               : PostGIS (Supabase) pour géolocalisation familles
RLS                   : Supabase Row Level Security → familles visibles membres validés
```

### Fonctionnalités carte
- POI villages CRUD backend
- Géolocalisation familles (chiffrée, RLS strict)
- Mode "retrouver ma famille" pour la diaspora
- Itinéraires touristiques générés par Claude
- Offline maps via flutter_map cache

---

## 🌳 Module Généalogie — Neo4j AuraDB

```
Base de données  : Neo4j AuraDB Free (200K nœuds)
ORM              : Spring Data Neo4j
Requêtes         : Cypher
Visualisation    : flutter_graph_view (Flutter)
```

### Modèle de graphe
```cypher
(:Person)-[:ENFANT_DE]->(:Person)
(:Person)-[:MARIE_A]->(:Person)
(:Person)-[:MEMBRE_DE]->(:Village)
(:Person)-[:APPARTIENT_AU_CLAN]->(:Clan)
(:Family)-[:LOCALISEE_A {lat, lng}]->(:Village)
```

### Claude + Généalogie
- Analyse arbre partiel → suggère liens manquants avec score de confiance 0-1
- Reconstruction probabiliste ancêtres (Opus 4.6)
- Analytics migrations et patterns familiaux
- Validation humaine **toujours obligatoire** avant enregistrement

---

## 🛠️ Stack technique complète

### Backend
```
Java 21 (LTS)
Spring Boot 3.x
Spring Modulith
Spring Security + JWT
Spring Data JPA
Spring Data Neo4j
Spring WebSocket (STOMP)
Bucket4j (rate limiting)
Maven (build)
```

### Frontend
```
Flutter (iOS + Android + Web + Desktop)
  - Hive (offline storage)
  - flutter_map (cartes)
  - livekit_client (WebRTC)
  - flutter_graph_view (arbre généalogique)

Next.js 14 (vitrine publique SEO)
  - Vercel Free deployment
  - Pages villages publiques
  - SEO optimization
```

### Services Cloud
```
Railway.app       →  Hébergement Spring Boot (Hobby ~5€/mois)
Supabase          →  PostgreSQL + Auth + Storage + Realtime + PostGIS + RLS
Neo4j AuraDB      →  Graphe généalogique (Free 200K nœuds)
Upstash Redis     →  Cache + Sessions + Pub/Sub chat (Free 10K req/j)
Cloudflare R2     →  Médias + tiles cartes + replays lives (Free 10GB)
LiveKit Cloud     →  WebRTC lives (Free 100 participants)
Mapbox            →  Cartes interactives (Free 50K map loads/mois)
Meilisearch Cloud →  Search full-text africain (Free 100K docs)
Vercel            →  Next.js vitrine SEO (Free tier)
```

### Services API
```
Claude API (Anthropic)    →  IA centrale (Sonnet 4.6 + Opus 4.6)
Firebase FCM              →  Push notifications mobile (Free illimité)
Resend.com                →  Emails transactionnels (Free 3K/mois)
Orange API Africa         →  SMS Afrique (Phase 5)
Sentry                    →  Error tracking Java + Flutter (Free tier)
```

---

## 💰 Budget infrastructure MVP

| Service | Usage | Plan | €/mois |
|---------|-------|------|--------|
| Railway.app | Spring Boot 1GB RAM | Hobby $5 | ~5€ |
| Supabase | PostgreSQL + Auth + Storage | Free 500MB | 0€ |
| Neo4j AuraDB | Graphe généalogique | AuraDB Free | 0€ |
| Upstash Redis | Cache + Pub/Sub | Free 10K req/j | 0€ |
| Cloudflare R2 | Médias + replays | Free 10GB | 0€ |
| LiveKit Cloud | Lives cours + conférences | Free 100 participants | 0€ |
| Mapbox | Cartes villages | Free 50K loads/mois | 0€ |
| Claude API | Guide, quiz, généalogie, modération | Pay-per-use Sonnet 4.6 | ~5–10€ |
| Meilisearch | Search africain | Free 100K docs | 0€ |
| Vercel | Next.js vitrine | Free tier | 0€ |
| Firebase FCM | Push notifications | Free illimité | 0€ |
| Resend | Emails | Free 3K/mois | 0€ |
| Sentry | Error tracking | Free tier | 0€ |
| Domaine | gwangmeu.com | ~30€/an | ~2.5€ |

**→ TOTAL MVP : ~15–20€/mois**

### Projection croissance
```
1 000 villages actifs (50K MAU) :
  Railway Pro     ~20€
  Supabase Pro    ~25€
  LiveKit Std     ~29$
  Mapbox          ~50€
  Claude API      ~50€
  ─────────────────────
  TOTAL           ~175€/mois
```

---

## 🗓️ Roadmap — 34 semaines

### Phase 1 — Auth, Villages, Social Feed (6 semaines) `~5€/mois`
- [ ] Spring Boot Modulith setup Maven
- [ ] Supabase Auth → JWT Spring Security
- [ ] `user-module` + `village-module`
- [ ] RBAC 6 rôles (Admin, Modérateur, Ambassadeur, Membre, Visiteur, API)
- [ ] `feed-module` + workflow modération
- [ ] Hiérarchie Continent → Pays → Village v1
- [ ] Flutter app skeleton + navigation
- [ ] Next.js vitrine SEO
- [ ] Railway CI/CD GitHub Actions

### Phase 2 — Carte, Tourisme, Claude Guide (6 semaines) `~15€/mois`
- [ ] `tourism-module` + Mapbox GL
- [ ] POI villages CRUD backend
- [ ] Géolocalisation familles PostGIS + RLS
- [ ] flutter_map offline
- [ ] `culture-module` (fiches, cuisine, rites)
- [ ] `ai-module` — Claude API client + RAG pipeline
- [ ] Guide touristique chatbot streaming SSE
- [ ] Itinéraires personnalisés Claude

### Phase 3 — Généalogie, Chat, Notifications (7 semaines) `~15€/mois`
- [ ] Neo4j AuraDB + Spring Data Neo4j
- [ ] `genealogy-module` CRUD + requêtes Cypher
- [ ] Flutter arbre interactif (flutter_graph_view)
- [ ] Claude suggestions liens + interface validation humaine
- [ ] `messaging-module` WebSocket STOMP
- [ ] Redis Pub/Sub chat temps réel
- [ ] `notification-module` FCM + Resend
- [ ] `search-module` Meilisearch

### Phase 4 — Lives, Cours en direct (6 semaines) `~15€/mois`
- [ ] `live-module` LiveKit Cloud Java SDK
- [ ] livekit_client Flutter intégration
- [ ] Lives cours + conférences + webinaires
- [ ] Visites guidées virtuelles
- [ ] Recording → Cloudflare R2 + HLS replay
- [ ] Claude post-live : résumé + chapitrage + quiz
- [ ] `language-module` cours + niveaux + certifications
- [ ] RTMP Egress YouTube / Facebook

### Phase 5 — Dialectes, Connexions Culturelles, Emploi (5 semaines) `~20€/mois`
- [ ] `geo-module` v2 : aires dialectales cross-pays
- [ ] `cultural_link` table + scoring Claude
- [ ] Groupes transversaux (dialecte, cuisine, rites)
- [ ] Musée virtuel par peuple
- [ ] `jobs-module` offres + annuaire talents
- [ ] SMS notifications Orange API Afrique

### Phase 6 — IA Avancée, Scale, Monétisation (4 semaines) `~25€/mois`
- [ ] Prompt Caching Anthropic (-80% coûts Claude)
- [ ] Reconstruction ancêtres probabiliste (Opus 4.6)
- [ ] Analytics migrations + patterns familiaux
- [ ] API publique chercheurs / linguistes
- [ ] Freemium : villages Premium + lives illimités
- [ ] Multi-langues diaspora (EN, ES, PT)

---

## 📁 Structure du projet recommandée

```
gwangmeu/
├── ARCHITECTURE.md              ← CE FICHIER (référence Claude Code)
├── README.md
├── .env.example
│
├── backend/                     ← Spring Boot Modulith
│   ├── pom.xml
│   ├── src/main/java/com/gwangmeu/
│   │   ├── GwangMeuApplication.java
│   │   ├── shared/              ← shared-kernel (jamais dépendant des modules)
│   │   │   ├── security/        ← SecurityContext, JWT filter
│   │   │   ├── events/          ← DomainEvents base classes
│   │   │   ├── ai/              ← ClaudeAiClient (Anthropic SDK)
│   │   │   ├── media/           ← MediaService (R2 upload)
│   │   │   └── geo/             ← GeoContext, PostGIS utils
│   │   ├── user/                ← user-module
│   │   ├── village/             ← village-module
│   │   ├── feed/                ← feed-module
│   │   ├── geo/                 ← geo-module
│   │   ├── genealogy/           ← genealogy-module (Neo4j)
│   │   ├── language/            ← language-module
│   │   ├── live/                ← live-module (LiveKit)
│   │   ├── tourism/             ← tourism-module (Mapbox)
│   │   ├── culture/             ← culture-module
│   │   ├── messaging/           ← messaging-module (WebSocket)
│   │   ├── jobs/                ← jobs-module
│   │   ├── notification/        ← notification-module
│   │   ├── ai/                  ← ai-module (Claude orchestrateur)
│   │   └── search/              ← search-module (Meilisearch)
│   └── src/test/                ← JUnit 5 + Testcontainers
│
├── mobile/                      ← Flutter (iOS + Android)
│   ├── pubspec.yaml
│   └── lib/
│       ├── main.dart
│       ├── features/            ← une feature = un module backend
│       └── shared/
│
├── web/                         ← Flutter Web (app connectée)
├── desktop/                     ← Flutter Desktop (admin)
└── landing/                     ← Next.js 14 (vitrine SEO)
    ├── package.json
    └── app/
```

---

## 🔐 Sécurité & RBAC

### 6 rôles utilisateur
```
SUPER_ADMIN      →  Accès total plateforme
MODERATEUR       →  Modération contenu multi-villages
AMBASSADEUR      →  Gestion d'un village spécifique
MEMBRE           →  Utilisateur authentifié standard
VISITEUR         →  Utilisateur non-authentifié (lecture publique)
API              →  Chercheurs / intégrations externes
```

### Règles de sécurité
```
- Supabase RLS sur toutes les tables sensibles (familles, géoloc)
- JWT Spring Security côté backend (validation Supabase token)
- Bucket4j rate limiting sur endpoints publics
- Cloudflare WAF en frontal
- Données familles géolocalisées : chiffrées + visibles membres validés uniquement
- Genealogy : validation humaine obligatoire avant tout enregistrement Claude
```

---

## 🧪 Tests

```
Framework     : JUnit 5
Containers    : Testcontainers (PostgreSQL, Redis, Neo4j, Meilisearch)
Mocks Claude  : Anthropic SDK mock pour tests unitaires ai-module
Couverture    : minimum 80% par module avant passage phase suivante
```

> **Règle Claude Code :** Toujours demander les tests JUnit 5 + Testcontainers avec le code produit.
> Les tests documentent le comportement et sécurisent les refactorings.

---

## 💡 Conseils pour travailler avec Claude Code

1. **Toujours référencer ce fichier** en début de session : "Réfère-toi à ARCHITECTURE.md"
2. **Développer un module à la fois** — préciser dans le prompt le module courant et les Spring Events utilisés
3. **Demander systématiquement** les tests JUnit 5 + Testcontainers avec chaque feature
4. **Pour Neo4j** : demander les annotations `@Node`, `@Relationship` et les repository Cypher en même temps que les entités
5. **Pour Claude AI** : toujours préciser le modèle (Sonnet vs Opus), le use case et activer le Prompt Caching
6. **Ordre recommandé** : shared-kernel → user-module → village-module → feed-module → ... (suivre la roadmap phases)
7. **Jamais d'appel direct entre modules** — toujours passer par `ApplicationEventPublisher`
8. **Variables d'environnement** : jamais de clés hardcodées, toujours via `.env` / Railway env vars

---

## 🔑 Variables d'environnement requises

```bash
# Supabase
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_KEY=

# Claude API (Anthropic)
ANTHROPIC_API_KEY=

# Neo4j AuraDB
NEO4J_URI=
NEO4J_USERNAME=
NEO4J_PASSWORD=

# Redis (Upstash)
REDIS_URL=
REDIS_TOKEN=

# LiveKit Cloud
LIVEKIT_API_KEY=
LIVEKIT_API_SECRET=
LIVEKIT_WS_URL=

# Mapbox
MAPBOX_ACCESS_TOKEN=

# Meilisearch
MEILISEARCH_HOST=
MEILISEARCH_API_KEY=

# Cloudflare R2
R2_ACCESS_KEY_ID=
R2_SECRET_ACCESS_KEY=
R2_BUCKET_NAME=
R2_ACCOUNT_ID=

# Firebase FCM
FIREBASE_SERVICE_ACCOUNT_JSON=

# Resend
RESEND_API_KEY=

# Sentry
SENTRY_DSN_JAVA=
SENTRY_DSN_FLUTTER=

# App
JWT_SECRET=
APP_URL=https://app.gwangmeu.com
LANDING_URL=https://gwangmeu.com
```

---

## 📌 Décisions d'architecture importantes

| Décision | Choix | Raison |
|----------|-------|--------|
| Monolithe vs Microservices | **Modulith** | Simplicité MVP, extractible plus tard |
| ORM généalogie | **Spring Data Neo4j** | Natif Neo4j, Cypher type-safe |
| Communication inter-modules | **Spring ApplicationEvents** | Découplage sans réseau |
| Temps réel chat | **WebSocket STOMP + Redis** | Simple, scalable, off-the-shelf |
| IA principale | **Claude Anthropic** | Multilinguisme africain, qualité raisonnement |
| Lives | **LiveKit Cloud** | SDK Flutter officiel, WebRTC managé |
| Recherche | **Meilisearch** | Typo-tolerant, phonétique, gratuit 100K docs |
| Storage médias | **Cloudflare R2** | 0€ egress, compatible S3 |
| Auth | **Supabase Auth** | OAuth2 + Phone + RLS natif |

---

*Dernière mise à jour : Mars 2026*
*Version architecture : V3*
*Projet : GWANG MEU (ex NGOMALA.ACADEMY)*
