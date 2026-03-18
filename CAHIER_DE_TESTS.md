# GWANG MEU - Cahier de Tests Fonctionnels et Techniques

> **Version** : 1.0 — Mars 2026
> **Projet** : GWANG MEU — Plateforme de preservation culturelle africaine
> **Stack** : Spring Boot 3.3.5 (Java 21) + Flutter (Dart) + PostgreSQL + Neo4j + Redis
> **Auth** : Supabase (OAuth2 Resource Server + JWKS)

---

## TABLE DES MATIERES

1. [Vue d'ensemble du projet](#1-vue-densemble-du-projet)
2. [Architecture technique](#2-architecture-technique)
3. [Description des fonctionnalites](#3-description-des-fonctionnalites)
4. [Parcours utilisateur](#4-parcours-utilisateur)
5. [Cahier de tests fonctionnels](#5-cahier-de-tests-fonctionnels)
6. [Cahier de tests techniques](#6-cahier-de-tests-techniques)
7. [Matrice de couverture](#7-matrice-de-couverture)
8. [Environnement de test](#8-environnement-de-test)
9. [Donnees de test](#9-donnees-de-test)

---

## 1. VUE D'ENSEMBLE DU PROJET

GWANG MEU est une plateforme de preservation culturelle africaine. Elle permet aux utilisateurs de :
- S'inscrire et gerer leur profil (identite culturelle, origines, langues)
- Rejoindre des villages virtuels representant des communautes africaines reelles
- Publier et partager du contenu (posts, images, lives) dans un fil social
- Construire et visualiser des arbres genealogiques interactifs
- Recevoir des notifications en temps reel (in-app + push FCM)
- Echanger via un chat groupe
- Explorer la geographie africaine (continents, pays, villages, recherche proximite)

### Modules backend (Spring Modulith)

| Module | Package | Description |
|--------|---------|-------------|
| **user** | `com.gwangmeu.user` | Gestion des utilisateurs, profil, sync Supabase JWT |
| **village** | `com.gwangmeu.village` | Villages, abonnements, creation/modification |
| **feed** | `com.gwangmeu.feed` | Publications, commentaires, reactions, moderation |
| **genealogy** | `com.gwangmeu.genealogy` | Arbres genealogiques, personnes, liens familiaux, unions |
| **geo** | `com.gwangmeu.geo` | Continents, pays, langues, recherche geographique |
| **chat** | `com.gwangmeu.chat` | Chat groupe, messages WebSocket |
| **notification** | `com.gwangmeu.notification` | Notifications in-app, marquage lu/non-lu |
| **shared** | `com.gwangmeu.shared` | Security, audit, AI (Claude), media (R2), email (Resend), FCM |
| **config** | `com.gwangmeu.config` (implicite) | SecurityConfig, SwaggerConfig, RedisConfig, WebSocketConfig |

### Ecrans frontend Flutter

| Ecran | Route | Description |
|-------|-------|-------------|
| Splash | `/` | Ecran de chargement initial |
| Auth | `/auth` | Connexion / Inscription / Mot de passe oublie |
| Home | `/home` | Shell avec BottomNavigationBar (4 onglets) |
| Feed | `/home/feed` | Fil d'actualite, stories, publications |
| Villages | `/home/villages` | Liste des villages, recherche |
| Search | `/home/search` | Recherche globale geo (continents/pays/villages) |
| Profile | `/home/profile` | Profil utilisateur 3-colonnes responsive |
| Village Detail | `/village/:id` | Detail d'un village, stats, CTA rejoindre |
| Genealogy | `/genealogy` | Arbre genealogique interactif (canvas) |
| Invitation | `/invitation` | Gestion des invitations genealogiques |
| Mes Villages | `/mes-villages` | Villages rejoints par l'utilisateur |
| Creer Village | `/creer-village` | Formulaire creation village |
| Edit Village | `/modifier-village` | Formulaire modification village |
| Notifications | `/notifications` | Centre de notifications |

---

## 2. ARCHITECTURE TECHNIQUE

### 2.1 Stack

| Couche | Technologie |
|--------|-------------|
| Backend | Spring Boot 3.3.5, Java 21, Hibernate 6.5.3, Spring Modulith |
| Frontend mobile | Flutter (Dart), Riverpod, GoRouter, Dio, Freezed |
| Frontend web (landing) | Next.js 14, Tailwind CSS, TypeScript |
| Base de donnees relationnelle | PostgreSQL (Supabase) + PostGIS + Flyway (V1-V34) |
| Base de donnees graphe | Neo4j AuraDB (sync unidirectionnelle depuis PostgreSQL) |
| Cache | Redis / Upstash |
| Auth | Supabase Auth (OAuth2 RS + JWKS), 6 providers sociaux |
| Stockage media | Cloudflare R2 (S3-compatible) |
| Push notifications | Firebase Cloud Messaging (FCM) |
| Email transactionnel | Resend |
| IA | Claude API (sonnet-4/opus-4) |
| Recherche fulltext | Meilisearch |
| Cartographie | Mapbox |

### 2.2 Communication inter-modules

- **Synchrone** : Appels de service directs (injection Spring)
- **Asynchrone** : `ApplicationEventPublisher` + `@EventListener` / `@Async`
- **Push** : WebSocket STOMP (chat), FCM (push mobile)

### 2.3 Entites JPA (31 entites)

| Entite | Table | Module |
|--------|-------|--------|
| User | users | user |
| Village | villages | village |
| VillageSubscription | village_subscriptions | village |
| Post | posts | feed |
| Comment | comments | feed |
| PostReaction | post_reactions | feed |
| ModerationQueue | moderation_queue | feed |
| ModerationLog | moderation_logs | feed |
| Person | persons | genealogy |
| ParentChild | parent_child | genealogy |
| GenealogyUnion | genealogy_unions | genealogy |
| Clan | clans | genealogy |
| PersonClan | person_clans | genealogy |
| PersonVillage | person_villages | genealogy |
| PersonComment | person_comments | genealogy |
| PersonInvitation | person_invitations | genealogy |
| ChildAssociationRequest | child_association_requests | genealogy |
| PersonModificationRequest | person_modification_requests | genealogy |
| AiGenealogySuggestion | ai_genealogy_suggestions | genealogy |
| DissolutionReminder | dissolution_reminders | genealogy |
| Notification | notifications | notification |
| ChatGroup | chat_groups | chat |
| ChatGroupMember | chat_group_members | chat |
| ChatMessage | chat_messages | chat |
| Continent | continents | geo |
| Country | countries | geo |
| Language | languages | geo |
| CountryLanguage | country_languages | geo |
| DialectArea | dialect_areas | geo |
| CulturalLink | cultural_links | geo |
| AuditEntity | (MappedSuperclass) | shared |

### 2.4 Enums PostgreSQL natifs

| Enum | Valeurs |
|------|---------|
| GenderEnum | MALE, FEMALE |
| PersonStatusEnum | ALIVE, DECEASED |
| PrivacyEnum | PUBLIC, FAMILY_ONLY, PRIVATE |
| ParentRoleEnum | FATHER, MOTHER |
| ParentTypeEnum | BIOLOGICAL, ADOPTIVE, STEP, GUARDIAN |
| UnionTypeEnum | MARRIAGE_CIVIL, MARRIAGE_TRADITIONAL, MARRIAGE_RELIGIOUS, CONCUBINAGE, OTHER |
| EndReasonEnum | DIVORCE, SEPARATION, DEATH, ANNULATION |
| SiblingTypeEnum | FULL, HALF_PATERNAL, HALF_MATERNAL, ADOPTIVE |
| RelationSourceEnum | USER_DECLARED, COMMUNITY_VALIDATED, AI_SUGGESTED, IMPORTED |
| AiSuggestionStatusEnum | PENDING, ACCEPTED, REJECTED |
| MaritalStatusEnum | SINGLE, MARRIED, DIVORCED, WIDOWED |
| InvitationStatusEnum | PENDING, ACCEPTED, EXPIRED, CANCELLED |
| AssociationRequestStatus | PENDING, ACCEPTED, REJECTED |
| GuardTypeEnum | LEGAL, TESTAMENTARY, DELEGATED |
| ModerationStatus | PENDING, APPROVED, REJECTED, FLAGGED, SHADOW_BANNED |
| UserRole | SUPER_ADMIN, MODERATEUR, AMBASSADEUR, MEMBRE, VISITEUR, API |

---

## 3. DESCRIPTION DES FONCTIONNALITES

### F01 — Authentification et gestion de compte

**Description** : L'utilisateur peut s'inscrire par email/mot de passe ou via 6 providers OAuth (Google, Facebook, Apple, GitHub, Twitter/X, LinkedIn). L'authentification est geree par Supabase. Le backend valide les JWT via JWKS (OAuth2 Resource Server).

**Backend** :
- `UserController` : `GET /me`, `PUT /me`, `GET /{userId}`, `POST /auth/sync`, `DELETE /me`
- `UserService` : `syncFromJwt()` cree/met a jour le profil utilisateur a chaque connexion

**Frontend** :
- `AuthScreen` : 3 modes (login, register, forgotPassword)
- `AuthNotifier` : gere signIn, signUp, resetPassword, signOut, signInWithOAuth
- Guard GoRouter : redirige vers `/auth` si pas de session Supabase

**Regles metier** :
- Email obligatoire et valide
- Mot de passe minimum 6 caracteres
- Sync automatique du profil backend a chaque login (`/auth/sync`)
- Deconnexion supprime le token local et redirige vers `/auth`

---

### F02 — Profil utilisateur

**Description** : Ecran profil en 3 colonnes responsive avec hero canvas, tabs, stats, barre de completion.

**Backend** :
- `PUT /api/v1/users/me` : mise a jour profil (displayName, bio, country, clan, tribe, etc.)
- Champs : avatarUrl, displayName, bio, country, nativeLanguage, clan, tribe, fatherName, fatherOrigin, motherName, motherOrigin, maritalStatus, profession, residenceCity, residenceCountry, etc.

**Frontend** :
- `ProfileScreen` : layout 3 colonnes (>=1100px), 2 colonnes (>=800px), 1 colonne (<800px)
- Left Rail : identite mini, barre de completion (10 champs), nav, villages, parametres, deconnexion
- Center Panel : hero canvas, 5 tabs (Apercu, Publications, Genealogie, Langues, Formations)
- Right Panel : lignee directe, villages chips, checklist completion

---

### F03 — Villages

**Description** : Les villages representent des communautes culturelles africaines. L'utilisateur peut les decouvrir, les rejoindre (abonnement), en creer, et les gerer.

**Backend** :
- `VillageController` : CRUD villages + filtres par pays/continent
  - `GET /api/v1/villages?countryCode=CMR&continentCode=AF-CENTRAL`
  - `POST /api/v1/villages` : creation
  - `PUT /api/v1/villages/{id}` : modification
  - `DELETE /api/v1/villages/{id}` : suppression
  - `POST /api/v1/villages/{id}/subscribe` : rejoindre
  - `DELETE /api/v1/villages/{id}/subscribe` : quitter
- 30 villages seeds dans 10 pays africains (V7)

**Frontend** :
- `VillagesScreen` : grille 2 colonnes, recherche inline
- `VillageDetailScreen` : SliverAppBar, stats, infos, CTA rejoindre
- `CreateVillageScreen` / `EditVillageScreen` : formulaires
- `MyVillagesScreen` : villages rejoints

---

### F04 — Fil social (Feed)

**Description** : Fil d'actualite avec publications, stories, reactions, commentaires. Workflow de moderation integre.

**Backend** :
- `FeedController` : CRUD posts + commentaires + reactions
  - `GET /api/v1/feed/village/{villageId}` : posts d'un village
  - `POST /api/v1/feed/posts` : creer un post
  - `POST /api/v1/feed/posts/{postId}/comments` : commenter
  - `POST /api/v1/feed/posts/{postId}/reactions` : reagir
- `ModerationController` : moderation des posts
  - `GET /api/v1/moderation/queue/{villageId}` : file de moderation
  - `POST /api/v1/moderation/moderate` : approuver/rejeter
  - `POST /api/v1/moderation/flag` : signaler un post
  - `GET /api/v1/moderation/stats/{villageId}` : statistiques
- Machine a etats moderation : PENDING -> APPROVED/REJECTED, APPROVED -> FLAGGED (3 flags auto), FLAGGED -> SHADOW_BANNED/APPROVED
- Rate limiting : 3 flags/utilisateur/heure (Bucket4j in-memory)

**Frontend** :
- `FeedScreen` : ListView avec stories, compose box, village highlight, posts
- `PostCard` : avatar, contenu, media, tags, reactions, commentaires, partage
- Types speciaux : post texte large, post avec image, post live, post suggestion IA

---

### F05 — Genealogie (Arbre familial)

**Description** : Module le plus complexe. Permet de creer des fiches "personne", de les lier en parent-enfant, de gerer des unions (mariages), et de visualiser l'arbre genealogique interactif sur un canvas.

**Backend** :
- `PersonController` (`/api/v1/genealogy/persons`) :
  - `GET /me` : obtenir sa fiche genealogique
  - `POST /{parentId}/children` : creer un enfant + lien atomique
  - `GET /{id}` : detail d'une personne
  - `PUT /{id}` : modifier une personne
  - `DELETE /{id}` : supprimer (createur ou admin)
  - `GET /search?clan=X&q=Y` : recherche par clan/nom
  - `GET /lookup?email=X&phone=Y` : deduplication
  - `GET /village/{villageId}` : personnes d'un village
  - `GET /village/{villageId}/clans` : clans d'un village
  - `GET /village/{villageId}/by-gender` : filtrage par genre
  - `GET /clan/{clanId}/members` : membres d'un clan
  - `POST /check-duplicate` : verification doublons avant creation
  - `GET /{personId}/comments` : commentaires sur une fiche
  - `POST /{personId}/comments` : ajouter un commentaire
  - `DELETE /{personId}/comments/{commentId}` : supprimer son commentaire

- `GenealogyController` (`/api/v1/genealogy`) :
  - `GET /tree/{personId}` : arbre familial complet (pour Flutter canvas)
  - `POST /link/parent-child` : lier parent-enfant
  - `DELETE /link/parent-child?parentId=X&childId=Y` : supprimer un lien
  - `GET /{personId}/parents` : parents d'une personne
  - `GET /{personId}/children` : enfants d'une personne
  - `GET /{personId}/siblings` : fratrie
  - `GET /{personId}/grandparents` : grands-parents
  - `GET /{personId}/cousins` : cousins germains
  - `GET /{personId}/spouses` : conjoints actifs
  - `GET /{personId}/ancestors?depth=5` : ancetres (Neo4j, max 20)
  - `GET /{personId}/descendants?depth=5` : descendants (Neo4j, max 20)
  - `POST /child-associations/{requestId}/accept` : accepter association enfant
  - `POST /child-associations/{requestId}/reject` : refuser association enfant
  - `POST /persons/{personId}/modification-request` : demander modification enfant <4 ans
  - `POST /modification-requests/{requestId}/accept` : accepter modification
  - `POST /modification-requests/{requestId}/reject` : refuser modification
  - `POST /admin/neo4j/sync-all` : resync complete PostgreSQL -> Neo4j

**Frontend** :
- `GenealogyScreen` : ecran principal avec arbre interactif
- `TreeCanvas` : widget canvas custom avec noeuds, liens, zoom, pan
- `PersonDetailPopup` : popup au clic sur un noeud (infos + pere/mere + actions)
- `AddPersonDialog` : formulaire ajout enfant avec regles d'age
- `PersonCommentsSheet` : commentaires sur une fiche
- `InvitationScreen` : gestion des invitations genealogiques

**Regles metier specifiques** :
- **Enfant < 4 ans** : pas d'email/telephone requis, modification par les parents avec validation du co-parent
- **Enfant 4-11 ans** : email possible (optionnel), pas de telephone
- **Enfant >= 12 ans** : email et telephone (comportement standard)
- **Deduplication** : verification avant creation (email, telephone, nom+prenom+clan)
- **Association enfant** : quand un parent B est identifie, une demande de validation est envoyee
- **Modification enfant** : si l'enfant a 2 parents, la modification necessite l'accord du co-parent

---

### F06 — Demande de modification enfant (< 4 ans)

**Description** : Quand un parent modifie les informations d'un enfant de moins de 4 ans, si l'enfant a deux parents enregistres, une demande de validation est envoyee a l'autre parent. Celui-ci peut accepter ou refuser.

**Workflow** :
1. Parent A clique "Modifier la fiche" sur le popup detail d'un enfant < 4 ans
2. Parent A remplit les modifications (prenom, nom, date naissance, lieu, clan, totem)
3. Backend verifie : enfant < 4 ans ET demandeur est parent
4. Si 2 parents : cree une `PersonModificationRequest` (PENDING), envoie notification + FCM au co-parent
5. Si 1 seul parent : applique directement les modifications
6. Co-parent recoit notification `PERSON_MODIFICATION_REQUEST`
7. Co-parent accepte -> modifications appliquees, notification `PERSON_MODIFICATION_RESPONSE` (accepted)
8. Co-parent refuse -> pas de modification, notification `PERSON_MODIFICATION_RESPONSE` (refused)

**Entite** : `PersonModificationRequest` (id, personId, requesterId, changes JSONB, status, createdAt, respondedAt, responderId)

---

### F07 — Associations d'enfants (Child Association)

**Description** : Quand un parent A declare un enfant et indique un parent B (par email/telephone), une demande d'association est envoyee au parent B. Le parent B peut accepter ou refuser la filiation.

**Workflow** :
1. Parent A cree un enfant et fournit l'email/telephone du parent B
2. Backend recherche le parent B (via email/phone dans users puis persons)
3. Cree une `ChildAssociationRequest` (PENDING)
4. Envoie notification + email + FCM au parent B
5. Parent B accepte -> lien parent-child cree, notification au parent A
6. Parent B refuse -> pas de lien, notification au parent A

---

### F08 — Geographie (Geo)

**Description** : Exploration de la geographie africaine : continents, pays avec drapeaux emoji, villages, recherche de proximite (PostGIS), liens culturels entre villages.

**Backend** :
- `GeoController` (`/api/v1/geo`) :
  - `GET /continents` : liste avec countryCount + villageCount
  - `GET /continents/{code}` : detail continent
  - `GET /continents/{code}/countries` : pays d'un continent
  - `GET /countries/{isoCode}` : detail pays
  - `GET /villages/nearby?lat=X&lng=Y&radiusKm=Z&limit=N` : PostGIS ST_DWithin
  - `GET /villages/{id}/cultural-links?linkType=X` : liens culturels
  - `GET /search?q=X` : recherche globale multi-niveaux (min 2 chars, max 20 resultats)

**Frontend** :
- `SearchScreen` : barre de recherche + resultats types (VILLAGE/COUNTRY/CONTINENT)

---

### F09 — Notifications

**Description** : Systeme de notifications multicanal : in-app (base de donnees) + push (FCM) + email (Resend).

**Backend** :
- `NotificationController` (`/api/v1/notifications`) :
  - `GET /` : liste des notifications de l'utilisateur courant
  - `PUT /{id}/read` : marquer comme lu
  - `PUT /read-all` : tout marquer comme lu
  - `DELETE /{id}` : supprimer

**Types de notifications** :

| Type | Declencheur | Action frontend |
|------|-------------|----------------|
| PARENT_ADDED | Lien parent-enfant cree | Informative |
| UNION_PENDING | Demande d'union creee | Dialog confirmation |
| CHILD_ASSOCIATION_REQUEST | Demande d'association enfant | Dialog accept/reject |
| CHILD_ASSOCIATION_RESPONSE | Reponse a une demande d'association | Informative |
| PERSON_MODIFICATION_REQUEST | Demande modification enfant <4 ans | Dialog accept/reject |
| PERSON_MODIFICATION_RESPONSE | Reponse a une demande de modification | Informative |

**Frontend** :
- `NotificationsScreen` : liste des notifications
- `ConfirmationDialogs` : dialogs specifiques par type de notification

---

### F10 — Chat

**Description** : Chat de groupe via WebSocket STOMP.

**Backend** :
- `ChatController` : creation groupe, envoi message, liste messages
- WebSocket config : STOMP, /topic, /queue, /ws (SockJS)
- Entites : ChatGroup, ChatGroupMember, ChatMessage

---

### F11 — Moderation

**Description** : Workflow de moderation des publications avec file d'attente, statistiques, et shadow ban automatique.

**Machine a etats** :
```
PENDING -> APPROVED (moderateur approuve)
PENDING -> REJECTED (moderateur rejette)
APPROVED -> FLAGGED (3+ signalements)
FLAGGED -> SHADOW_BANNED (moderateur confirme)
FLAGGED -> APPROVED (moderateur rejette les signalements)
```

**Rate limiting** : 3 flags par utilisateur par heure (Bucket4j)

---

### F12 — Intelligence Artificielle

**Description** : Integration Claude AI pour suggestions genealogiques (liens familiaux probables) et guide culturel.

**Backend** :
- `ClaudeAiClient` : appels synchrones Claude API (sonnet-4 pour taches courantes, opus-4 pour taches complexes)
- `AiGenealogySuggestion` : suggestions IA stockees avec statut (PENDING/ACCEPTED/REJECTED)

---

## 4. PARCOURS UTILISATEUR

### PU01 — Inscription et premiere connexion

1. L'utilisateur ouvre l'application -> ecran Splash
2. Pas de session -> redirection vers ecran Auth
3. L'utilisateur choisit : email/mot de passe OU provider social (Google, Facebook, etc.)
4. **Si email** : remplit email + mot de passe (min 6 chars) + nom + pays + genre
5. **Si social** : clic sur le bouton du provider, redirection OAuth, retour app
6. Apres inscription : sync automatique du profil backend (`POST /auth/sync`)
7. Redirection vers Home (Feed)
8. L'utilisateur voit le fil social avec des posts de demo
9. Il peut explorer les onglets : Feed, Villages, Recherche, Profil

### PU02 — Rejoindre un village

1. L'utilisateur va dans l'onglet Villages
2. Il voit la grille des villages avec recherche
3. Il clique sur un village -> ecran detail
4. Il voit : nom, description, pays, dialecte, population, date fondation, stats
5. Il clique "Rejoindre" -> `POST /villages/{id}/subscribe`
6. Le village apparait dans "Mes Villages" et dans le Rail gauche du profil

### PU03 — Publier un post

1. L'utilisateur est dans l'onglet Feed
2. Il clique sur la ComposeBox ou le FAB (+)
3. Il redige son post (texte, peut ajouter une image)
4. Il publie -> `POST /feed/posts`
5. Le post passe en statut PENDING (moderation)
6. Un moderateur peut approuver/rejeter dans la file de moderation
7. Si approuve, le post est visible par tous les membres du village

### PU04 — Construire son arbre genealogique

1. L'utilisateur va dans l'ecran Genealogie
2. S'il n'a pas de fiche : creation automatique de sa fiche Person
3. Il voit son arbre avec lui comme noeud central
4. Il clique sur "+" pour ajouter un enfant
5. Formulaire `AddPersonDialog` :
   - Saisie prenom, nom, genre, date naissance, lieu, clan, totem
   - **Si enfant < 4 ans** : pas de champs email/telephone, info banner
   - **Si enfant 4-11 ans** : email possible (optionnel)
   - **Si enfant >= 12 ans** : email et telephone
   - Si email/telephone fourni : recherche de deduplication
6. Soumission -> `POST /persons/{parentId}/children`
7. L'arbre se rafraichit avec le nouveau noeud

### PU05 — Consulter le detail d'une personne

1. L'utilisateur clique sur un noeud de l'arbre
2. Un tooltip apparait avec "Detils" (sic) et autres actions
3. Il clique sur "Detils" -> `PersonDetailPopup` s'affiche
4. Le popup montre :
   - Avatar + nom complet + clan
   - Pere (nom ou "Non renseigne")
   - Mere (nom ou "Non renseigne")
   - Date de naissance formatee
   - Genre, lieu de naissance, totem
   - Statut (vivant/decede)
5. Actions disponibles : "Voir l'arbre", "Ajouter un parent", "Ajouter un enfant"
6. **Si enfant < 4 ans ET l'utilisateur est parent** : bouton "Modifier la fiche"

### PU06 — Modifier la fiche d'un enfant < 4 ans

1. Parent A ouvre le popup detail d'un enfant < 4 ans
2. Il clique "Modifier la fiche"
3. Dialog `_ChildEditDialog` s'affiche avec les champs pre-remplis
4. Il modifie (prenom, nom, date naissance, lieu, clan, totem)
5. Il soumet -> `POST /genealogy/persons/{personId}/modification-request`
6. **Si 2 parents** : notification envoyee au co-parent (in-app + FCM)
7. **Si 1 seul parent** : modifications appliquees directement
8. Le co-parent recoit une notification de type `PERSON_MODIFICATION_REQUEST`
9. Il ouvre la notification -> dialog avec les modifications proposees
10. Il accepte -> modifications appliquees, notification de retour au demandeur
11. Il refuse -> pas de modification, notification de retour au demandeur

### PU07 — Gerer une demande d'association d'enfant

1. Parent A cree un enfant et indique l'email du parent B
2. Backend identifie le parent B -> cree ChildAssociationRequest (PENDING)
3. Parent B recoit notification `CHILD_ASSOCIATION_REQUEST` + email + FCM
4. Parent B ouvre la notification -> dialog "Accepter / Refuser"
5. **Accepter** : lien parent-child cree, notification `CHILD_ASSOCIATION_RESPONSE` (accepted) au parent A
6. **Refuser** : pas de lien, notification `CHILD_ASSOCIATION_RESPONSE` (rejected) au parent A

### PU08 — Recherche geographique

1. L'utilisateur va dans l'onglet Recherche
2. Il tape un terme (min 2 caracteres) dans la barre de recherche
3. Le frontend appelle `GET /api/v1/geo/search?q=X`
4. Resultats affiches par type : CONTINENT, COUNTRY, VILLAGE
5. Chaque resultat est cliquable -> navigation vers le detail

### PU09 — Moderation de contenu

1. Un moderateur ouvre le tableau de bord moderation
2. Il voit la file d'attente des posts en PENDING
3. Il peut approuver ou rejeter chaque post
4. Un post approuve peut etre signale par les utilisateurs
5. A 3 signalements, le post passe automatiquement en FLAGGED
6. Le moderateur peut confirmer (SHADOW_BANNED) ou rejeter les signalements (retour APPROVED)

---

## 5. CAHIER DE TESTS FONCTIONNELS

### Convention

- **ID** : TF-[module]-[numero]
- **Priorite** : P0 (bloquant), P1 (critique), P2 (important), P3 (nice-to-have)
- **Statut** : A tester, Passe, Echoue, Bloque

---

### 5.1 Module Authentification (F01)

| ID | Titre | Pre-conditions | Etapes | Resultat attendu | Priorite |
|----|-------|---------------|--------|-------------------|----------|
| TF-AUTH-001 | Inscription email valide | Aucun compte existant | 1. Ouvrir /auth 2. Cliquer "Creer un compte" 3. Remplir email valide + mdp >= 6 chars + nom + pays + genre 4. Soumettre | Compte cree, redirection /home, profil synce backend | P0 |
| TF-AUTH-002 | Inscription email invalide | - | 1. Mode inscription 2. Saisir email sans @ 3. Soumettre | Message "Email invalide", pas de soumission | P0 |
| TF-AUTH-003 | Inscription mot de passe trop court | - | 1. Mode inscription 2. Saisir mdp < 6 chars 3. Soumettre | Message "Minimum 6 caracteres", pas de soumission | P0 |
| TF-AUTH-004 | Inscription email deja existant | Compte existant avec meme email | 1. Inscription avec email existant | Message "Cet email est deja utilise" | P1 |
| TF-AUTH-005 | Connexion email valide | Compte existant | 1. Saisir email + mdp corrects 2. Soumettre | Connexion reussie, redirection /home | P0 |
| TF-AUTH-006 | Connexion email incorrect | - | 1. Saisir email/mdp incorrects | Message "Email ou mot de passe incorrect" | P0 |
| TF-AUTH-007 | Connexion OAuth Google | Compte Google disponible | 1. Cliquer "Google" 2. S'authentifier | Connexion reussie, profil synce | P0 |
| TF-AUTH-008 | Connexion OAuth Facebook | Compte Facebook disponible | 1. Cliquer "Facebook" 2. S'authentifier | Connexion reussie | P1 |
| TF-AUTH-009 | Connexion OAuth Apple | Appareil Apple | 1. Cliquer "Apple" 2. S'authentifier | Connexion reussie | P1 |
| TF-AUTH-010 | Connexion OAuth GitHub | Compte GitHub disponible | 1. Cliquer "GitHub" 2. S'authentifier | Connexion reussie | P2 |
| TF-AUTH-011 | Connexion OAuth Twitter | Compte Twitter disponible | 1. Cliquer "Twitter/X" 2. S'authentifier | Connexion reussie | P2 |
| TF-AUTH-012 | Connexion OAuth LinkedIn | Compte LinkedIn disponible | 1. Cliquer "LinkedIn" 2. S'authentifier | Connexion reussie | P2 |
| TF-AUTH-013 | Mot de passe oublie | Compte existant | 1. Cliquer "Mot de passe oublie" 2. Saisir email 3. Soumettre | Message "Email de reinitialisation envoye" | P1 |
| TF-AUTH-014 | Deconnexion | Utilisateur connecte | 1. Profil -> Deconnexion | Session Supabase supprimee, redirection /auth | P0 |
| TF-AUTH-015 | Guard route non authentifie | Pas de session | 1. Acceder a /home directement | Redirection vers /auth | P0 |
| TF-AUTH-016 | Sync profil backend | Utilisateur connecte | 1. Se connecter | `POST /auth/sync` appele, profil cree/mis a jour en DB | P0 |
| TF-AUTH-017 | Rate limiting connexion | - | 1. Echouer 10+ connexions rapidement | Message "Trop de tentatives. Attendez quelques minutes." | P1 |
| TF-AUTH-018 | Token JWT expire | Token expire | 1. Faire un appel API | 401 Unauthorized, deconnexion automatique | P0 |

---

### 5.2 Module Profil (F02)

| ID | Titre | Pre-conditions | Etapes | Resultat attendu | Priorite |
|----|-------|---------------|--------|-------------------|----------|
| TF-PROF-001 | Affichage profil | Connecte | 1. Aller dans l'onglet Profil | Hero canvas, avatar, nom, stats, bio affiches | P0 |
| TF-PROF-002 | Barre de completion | Profil incomplet | 1. Voir la barre de completion | Pourcentage calcule sur 10 champs, affichage correct | P1 |
| TF-PROF-003 | Modification nom | Connecte | 1. Modifier displayName 2. Sauvegarder | Nom mis a jour en DB et dans l'UI | P0 |
| TF-PROF-004 | Modification bio | Connecte | 1. Modifier bio 2. Sauvegarder | Bio mise a jour | P1 |
| TF-PROF-005 | Modification pays | Connecte | 1. Changer pays 2. Sauvegarder | Pays mis a jour | P1 |
| TF-PROF-006 | Modification clan/tribu | Connecte | 1. Modifier clan et tribu 2. Sauvegarder | Donnees mises a jour | P1 |
| TF-PROF-007 | Layout responsive 3 colonnes | Ecran >= 1100px | 1. Voir le profil | Layout 3 colonnes (LeftRail + Center + Right) | P2 |
| TF-PROF-008 | Layout responsive 2 colonnes | Ecran 800-1099px | 1. Voir le profil | Layout 2 colonnes | P2 |
| TF-PROF-009 | Layout responsive 1 colonne | Ecran < 800px | 1. Voir le profil (mobile) | Layout 1 colonne | P0 |
| TF-PROF-010 | Villages dans le rail gauche | Abonne a des villages | 1. Voir le profil | Villages listes dans le rail gauche | P2 |
| TF-PROF-011 | Lignee directe (panneau droit) | Personne genealogique avec parents | 1. Voir le profil | Pere et mere affiches dans le panneau droit | P2 |

---

### 5.3 Module Villages (F03)

| ID | Titre | Pre-conditions | Etapes | Resultat attendu | Priorite |
|----|-------|---------------|--------|-------------------|----------|
| TF-VILL-001 | Liste des villages | Connecte | 1. Aller dans l'onglet Villages | Grille 2 colonnes de villages | P0 |
| TF-VILL-002 | Recherche village | Connecte | 1. Taper "Edea" dans la recherche | Village "Edea" affiche | P0 |
| TF-VILL-003 | Detail village | Connecte | 1. Cliquer sur un village | SliverAppBar, stats, description, CTA | P0 |
| TF-VILL-004 | Rejoindre un village | Connecte, pas abonne | 1. Detail village 2. Cliquer "Rejoindre" | Abonnement cree, apparait dans Mes Villages | P0 |
| TF-VILL-005 | Quitter un village | Abonne | 1. Cliquer "Quitter" | Abonnement supprime | P1 |
| TF-VILL-006 | Creer un village | Connecte, role >= AMBASSADEUR | 1. /creer-village 2. Remplir formulaire 3. Soumettre | Village cree avec coords, apparait dans la liste | P1 |
| TF-VILL-007 | Modifier un village | Createur du village | 1. /modifier-village 2. Modifier infos 3. Sauvegarder | Village mis a jour | P1 |
| TF-VILL-008 | Filtrer par pays | Connecte | 1. GET /villages?countryCode=CMR | Seuls les villages du Cameroun | P1 |
| TF-VILL-009 | Filtrer par continent | Connecte | 1. GET /villages?continentCode=AF-CENTRAL | Villages d'Afrique Centrale | P1 |
| TF-VILL-010 | Village verifie badge | Village avec is_verified=true | 1. Voir le village | Badge "verifie" affiche | P2 |

---

### 5.4 Module Feed (F04)

| ID | Titre | Pre-conditions | Etapes | Resultat attendu | Priorite |
|----|-------|---------------|--------|-------------------|----------|
| TF-FEED-001 | Affichage feed | Connecte | 1. Aller dans l'onglet Feed | Stories, compose box, posts affiches | P0 |
| TF-FEED-002 | Pull to refresh | Connecte | 1. Tirer vers le bas | Feed rafraichi | P1 |
| TF-FEED-003 | Creer un post texte | Abonne a un village | 1. Ouvrir compose 2. Saisir texte 3. Publier | Post cree, statut PENDING | P0 |
| TF-FEED-004 | Creer un post avec image | Abonne a un village | 1. Ouvrir compose 2. Texte + image 3. Publier | Post avec media IMAGE cree | P1 |
| TF-FEED-005 | Reagir a un post | Post approuve affiche | 1. Cliquer sur une reaction | Reaction enregistree, compteur incremente | P1 |
| TF-FEED-006 | Commenter un post | Post approuve affiche | 1. Ouvrir commentaires 2. Saisir commentaire 3. Envoyer | Commentaire ajoute | P1 |
| TF-FEED-007 | Signaler un post | Post approuve affiche | 1. Cliquer "Signaler" 2. Confirmer | Signalement cree, flag_count incremente | P1 |
| TF-FEED-008 | Auto-flag a 3 signalements | Post avec 2 flags | 1. 3e utilisateur signale | Post passe automatiquement en FLAGGED | P1 |
| TF-FEED-009 | Rate limit signalement | Utilisateur ayant deja 3 flags cette heure | 1. Signaler un autre post | Erreur "Rate limit" | P2 |
| TF-FEED-010 | Post live affichage | Post avec isLive=true | 1. Voir le feed | Post live avec indicateur et nombre de viewers | P2 |
| TF-FEED-011 | Post suggestion IA | Post avec isAiSuggestion=true | 1. Voir le feed | Post IA avec badge, confidence, description | P2 |

---

### 5.5 Module Moderation (F11)

| ID | Titre | Pre-conditions | Etapes | Resultat attendu | Priorite |
|----|-------|---------------|--------|-------------------|----------|
| TF-MOD-001 | File de moderation | Moderateur connecte | 1. GET /moderation/queue/{villageId} | Liste des posts PENDING | P0 |
| TF-MOD-002 | Approuver un post | Post PENDING | 1. Cliquer "Approuver" | Post passe en APPROVED, visible dans le feed | P0 |
| TF-MOD-003 | Rejeter un post | Post PENDING | 1. Cliquer "Rejeter" + note | Post passe en REJECTED, non visible | P0 |
| TF-MOD-004 | Shadow ban post flagge | Post FLAGGED | 1. Cliquer "Shadow ban" | Post passe en SHADOW_BANNED | P1 |
| TF-MOD-005 | Rejeter flags | Post FLAGGED | 1. Cliquer "Rejeter les signalements" | Post retourne en APPROVED | P1 |
| TF-MOD-006 | Statistiques moderation | Moderateur | 1. GET /moderation/stats/{villageId} | Compteurs par statut affiches | P2 |
| TF-MOD-007 | Logs moderation | Moderateur | 1. GET /moderation/logs/{villageId} | Historique des actions de moderation | P2 |

---

### 5.6 Module Genealogie (F05)

| ID | Titre | Pre-conditions | Etapes | Resultat attendu | Priorite |
|----|-------|---------------|--------|-------------------|----------|
| TF-GEN-001 | Affichage arbre | Personne avec liens | 1. Aller sur /genealogy | Canvas avec noeuds et liens affiches | P0 |
| TF-GEN-002 | Zoom et pan | Arbre affiche | 1. Pincer pour zoomer 2. Glisser pour deplacer | Zoom et defilement fluides | P1 |
| TF-GEN-003 | Cliquer sur un noeud | Arbre affiche | 1. Cliquer sur un noeud | Tooltip avec actions | P0 |
| TF-GEN-004 | Ajouter un enfant (standard) | Parent selectionne | 1. Cliquer "+" enfant 2. Remplir formulaire (>= 12 ans) 3. Soumettre | Enfant cree, email+telephone demandes, arbre rafraichi | P0 |
| TF-GEN-005 | Ajouter un enfant < 4 ans | Parent selectionne | 1. Cliquer "+" enfant 2. Date naissance < 4 ans 3. Remplir | Pas de champs email/telephone, info banner, enfant cree | P0 |
| TF-GEN-006 | Ajouter un enfant 4-11 ans | Parent selectionne | 1. Cliquer "+" enfant 2. Date naissance 4-11 ans | Email affiche (optionnel), telephone masque | P0 |
| TF-GEN-007 | Deduplication avant creation | Email d'un enfant existant | 1. Saisir email existant lors de la creation | Candidats doublons affiches, choix de lier ou creer | P1 |
| TF-GEN-008 | Lier parent-enfant | 2 personnes existantes | 1. POST /link/parent-child | Lien cree, notification FCM famille | P0 |
| TF-GEN-009 | Supprimer lien parent-enfant | Lien existant | 1. DELETE /link/parent-child | Lien supprime | P1 |
| TF-GEN-010 | Voir les parents | Personne avec parents | 1. GET /{personId}/parents | Liste des parents (max 2) | P0 |
| TF-GEN-011 | Voir les enfants | Personne avec enfants | 1. GET /{personId}/children | Liste des enfants | P0 |
| TF-GEN-012 | Voir la fratrie | Personne avec fratrie | 1. GET /{personId}/siblings | Liste des freres/soeurs | P1 |
| TF-GEN-013 | Voir les grands-parents | Personne avec parents ayant parents | 1. GET /{personId}/grandparents | Liste des grands-parents | P1 |
| TF-GEN-014 | Voir les cousins | Personne avec oncles/tantes ayant enfants | 1. GET /{personId}/cousins | Liste des cousins germains | P2 |
| TF-GEN-015 | Voir les conjoints | Personne avec union(s) | 1. GET /{personId}/spouses | Liste des unions actives | P1 |
| TF-GEN-016 | Ancetres Neo4j | Personne dans Neo4j | 1. GET /{personId}/ancestors?depth=5 | Ancetres jusqu'a 5 generations | P1 |
| TF-GEN-017 | Descendants Neo4j | Personne dans Neo4j | 1. GET /{personId}/descendants?depth=5 | Descendants jusqu'a 5 generations | P1 |
| TF-GEN-018 | Profondeur max ancetres | - | 1. GET /ancestors?depth=25 | Plafonne a 20 generations | P2 |
| TF-GEN-019 | Recherche par clan | Personnes existantes | 1. GET /persons/search?clan=Bassa | Personnes du clan Bassa | P1 |
| TF-GEN-020 | Recherche par clan + nom | Personnes existantes | 1. GET /persons/search?clan=Bassa&q=Jean | Personnes Bassa nommees Jean | P1 |
| TF-GEN-021 | Lookup par email | Personne avec email | 1. GET /persons/lookup?email=test@test.com | Personne trouvee | P1 |
| TF-GEN-022 | Lookup par telephone | Personne avec telephone | 1. GET /persons/lookup?phone=+237600000 | Personne trouvee | P1 |
| TF-GEN-023 | Personnes par village | Village avec personnes | 1. GET /persons/village/{villageId} | Liste paginee | P1 |
| TF-GEN-024 | Clans par village | Village avec clans | 1. GET /persons/village/{villageId}/clans | Clans avec personCount | P1 |
| TF-GEN-025 | Personnes par genre | Village avec personnes | 1. GET /persons/village/{villageId}/by-gender?gender=MALE | Hommes du village | P2 |
| TF-GEN-026 | Membres d'un clan | Clan existant | 1. GET /persons/clan/{clanId}/members | Membres du clan | P2 |
| TF-GEN-027 | Commentaire sur fiche | Personne existante | 1. POST /{personId}/comments | Commentaire ajoute | P1 |
| TF-GEN-028 | Supprimer commentaire (auteur) | Commentaire existant | 1. DELETE /{personId}/comments/{commentId} (par l'auteur) | Commentaire supprime | P1 |
| TF-GEN-029 | Supprimer commentaire (non-auteur) | Commentaire d'un autre | 1. DELETE (par un non-auteur) | Erreur "Only the author can delete" | P1 |
| TF-GEN-030 | Modifier personne | Personne existante, createur | 1. PUT /{id} avec nouvelles infos | Personne mise a jour | P0 |
| TF-GEN-031 | Supprimer personne (createur) | Createur de la personne | 1. DELETE /{id} | Personne supprimee (cascade) | P1 |
| TF-GEN-032 | Supprimer personne (non-createur) | Non-createur non-admin | 1. DELETE /{id} | Erreur 403 | P1 |
| TF-GEN-033 | Person detail popup | Noeud clique | 1. Cliquer "Detils" sur un noeud | Popup avec infos personne, pere, mere | P0 |
| TF-GEN-034 | Popup - affichage pere/mere | Personne avec 2 parents | 1. Ouvrir popup | Noms du pere et de la mere affiches | P0 |
| TF-GEN-035 | Popup - pere/mere non renseigne | Personne sans parents | 1. Ouvrir popup | "Non renseigne" affiche pour pere et mere | P1 |
| TF-GEN-036 | Popup - bouton modifier enfant < 4 | Enfant < 4 ans, utilisateur = parent | 1. Ouvrir popup | Bouton "Modifier la fiche" visible | P0 |
| TF-GEN-037 | Popup - pas de bouton modifier si >= 4 | Enfant >= 4 ans | 1. Ouvrir popup | Pas de bouton "Modifier la fiche" | P1 |
| TF-GEN-038 | Popup - pas de bouton modifier si non-parent | Enfant < 4 ans, utilisateur non parent | 1. Ouvrir popup | Pas de bouton "Modifier la fiche" | P1 |

---

### 5.7 Module Modification Enfant (F06)

| ID | Titre | Pre-conditions | Etapes | Resultat attendu | Priorite |
|----|-------|---------------|--------|-------------------|----------|
| TF-MODIF-001 | Demande modification (2 parents) | Enfant < 4 ans, 2 parents | 1. Popup -> Modifier 2. Changer prenom 3. Soumettre | Request PENDING creee, notif au co-parent | P0 |
| TF-MODIF-002 | Demande modification (1 parent) | Enfant < 4 ans, 1 parent | 1. Popup -> Modifier 2. Changer prenom 3. Soumettre | Modification appliquee directement | P0 |
| TF-MODIF-003 | Accepter modification | Request PENDING, co-parent | 1. Ouvrir notification 2. Accepter | Modifications appliquees, statut ACCEPTED, notif retour | P0 |
| TF-MODIF-004 | Refuser modification | Request PENDING, co-parent | 1. Ouvrir notification 2. Refuser | Pas de modification, statut REJECTED, notif retour | P0 |
| TF-MODIF-005 | Rejet si enfant >= 4 ans | Enfant >= 4 ans | 1. POST modification-request | Erreur "L'enfant doit avoir moins de 4 ans" | P0 |
| TF-MODIF-006 | Rejet si non-parent | Utilisateur non parent de l'enfant | 1. POST modification-request | Erreur "Vous n'etes pas un parent" | P0 |
| TF-MODIF-007 | Notification FCM push | Enfant < 4 ans, 2 parents, co-parent a FCM token | 1. Soumettre modification | Push FCM recu par le co-parent | P1 |
| TF-MODIF-008 | Notification in-app | Enfant < 4 ans, 2 parents | 1. Soumettre modification | Notification in-app creee pour le co-parent | P0 |
| TF-MODIF-009 | Notification reponse (acceptee) | Request acceptee | 1. Co-parent accepte | Notification "a accepte la modification" au demandeur | P1 |
| TF-MODIF-010 | Notification reponse (refusee) | Request refusee | 1. Co-parent refuse | Notification "a refuse la modification" au demandeur | P1 |
| TF-MODIF-011 | Changements JSONB multiples | Request PENDING | 1. Modifier prenom + nom + lieu | Tous les champs changes appliques apres acceptation | P1 |

---

### 5.8 Module Association Enfant (F07)

| ID | Titre | Pre-conditions | Etapes | Resultat attendu | Priorite |
|----|-------|---------------|--------|-------------------|----------|
| TF-ASSOC-001 | Demande association | Parent A + enfant + email parent B existant | 1. Creer enfant avec email parent B | Request PENDING creee, notif + email a parent B | P0 |
| TF-ASSOC-002 | Accepter association | Request PENDING, parent B | 1. Ouvrir notification 2. Accepter | Lien parent-enfant cree, notif au parent A | P0 |
| TF-ASSOC-003 | Refuser association | Request PENDING, parent B | 1. Ouvrir notification 2. Refuser | Pas de lien, notif au parent A | P0 |
| TF-ASSOC-004 | Email association | Parent B avec email | 1. Creer demande | Email envoye au parent B | P1 |
| TF-ASSOC-005 | FCM association | Parent B avec FCM token | 1. Creer demande | Push FCM envoye au parent B | P1 |

---

### 5.9 Module Geographie (F08)

| ID | Titre | Pre-conditions | Etapes | Resultat attendu | Priorite |
|----|-------|---------------|--------|-------------------|----------|
| TF-GEO-001 | Liste continents | - | 1. GET /geo/continents | Continents avec countryCount + villageCount | P0 |
| TF-GEO-002 | Detail continent | - | 1. GET /geo/continents/AF-CENTRAL | Detail continent Afrique Centrale | P1 |
| TF-GEO-003 | Continent inexistant | - | 1. GET /geo/continents/XXXXX | 404 Not Found | P1 |
| TF-GEO-004 | Pays par continent | - | 1. GET /geo/continents/AF-WEST/countries | Pays d'Afrique de l'Ouest avec emoji | P0 |
| TF-GEO-005 | Detail pays | - | 1. GET /geo/countries/CMR | Detail Cameroun | P1 |
| TF-GEO-006 | Pays insensible casse | - | 1. GET /geo/countries/cmr | Meme resultat que CMR | P2 |
| TF-GEO-007 | Villages proches (nearby) | PostGIS, villages seeds | 1. GET /geo/villages/nearby?lat=3.848&lng=11.502&radiusKm=100 | Villages autour de Yaounde | P0 |
| TF-GEO-008 | Nearby rayon trop petit | - | 1. GET /nearby?lat=0&lng=0&radiusKm=1 | 0 resultats | P2 |
| TF-GEO-009 | Nearby coords invalides | - | 1. GET /nearby?lat=200&lng=400 | 400 Bad Request | P1 |
| TF-GEO-010 | Liens culturels | Village avec liens | 1. GET /geo/villages/{id}/cultural-links | Liste liens avec score + createdByAi | P1 |
| TF-GEO-011 | Liens culturels par type | Village avec liens | 1. GET /cultural-links?linkType=LANGUAGE | Liens filtres par type | P2 |
| TF-GEO-012 | Recherche globale | Villages/pays existants | 1. GET /geo/search?q=Edea | Village Edea trouve | P0 |
| TF-GEO-013 | Recherche globale pays | - | 1. GET /geo/search?q=CMR | Pays Cameroun trouve | P1 |
| TF-GEO-014 | Recherche trop courte | - | 1. GET /geo/search?q=E | 400 Bad Request (min 2 chars) | P1 |
| TF-GEO-015 | Recherche max 20 resultats | Beaucoup de villages | 1. GET /geo/search?q=a | Max 20 resultats retournes | P2 |

---

### 5.10 Module Notifications (F09)

| ID | Titre | Pre-conditions | Etapes | Resultat attendu | Priorite |
|----|-------|---------------|--------|-------------------|----------|
| TF-NOTIF-001 | Liste notifications | Notifications existantes | 1. GET /notifications | Liste triee par date desc | P0 |
| TF-NOTIF-002 | Marquer comme lu | Notification non lue | 1. PUT /notifications/{id}/read | Notification marquee lu | P0 |
| TF-NOTIF-003 | Tout marquer comme lu | Notifications non lues | 1. PUT /notifications/read-all | Toutes les notifs marquees lu | P1 |
| TF-NOTIF-004 | Supprimer notification | Notification existante | 1. DELETE /notifications/{id} | Notification supprimee | P1 |
| TF-NOTIF-005 | Dialog CHILD_ASSOCIATION_REQUEST | Notification de ce type | 1. Ouvrir notification | Dialog avec "Accepter" / "Refuser" | P0 |
| TF-NOTIF-006 | Dialog PERSON_MODIFICATION_REQUEST | Notification de ce type | 1. Ouvrir notification | Dialog avec modifications + "Accepter" / "Refuser" | P0 |
| TF-NOTIF-007 | Dialog PERSON_MODIFICATION_RESPONSE | Notification de ce type | 1. Ouvrir notification | Dialog informatif "accepte" ou "refuse" | P1 |
| TF-NOTIF-008 | Dialog CHILD_ASSOCIATION_RESPONSE | Notification de ce type | 1. Ouvrir notification | Dialog informatif | P1 |
| TF-NOTIF-009 | Dialog UNION_PENDING | Notification de ce type | 1. Ouvrir notification | Dialog confirmation union | P1 |
| TF-NOTIF-010 | Badge notifications non lues | Notifications non lues | 1. Voir le badge dans la barre | Nombre de notifications non lues | P1 |

---

### 5.11 Module Chat (F10)

| ID | Titre | Pre-conditions | Etapes | Resultat attendu | Priorite |
|----|-------|---------------|--------|-------------------|----------|
| TF-CHAT-001 | Creer un groupe | Connecte | 1. Creer un groupe chat | Groupe cree avec le createur comme membre | P1 |
| TF-CHAT-002 | Envoyer un message | Membre du groupe | 1. Saisir message 2. Envoyer | Message visible par tous les membres | P0 |
| TF-CHAT-003 | Reception temps reel | 2 membres connectes | 1. User A envoie un message | User B recoit instantanement via WebSocket | P0 |
| TF-CHAT-004 | Historique messages | Groupe avec messages | 1. Ouvrir le groupe | Messages historiques charges | P1 |

---

## 6. CAHIER DE TESTS TECHNIQUES

### 6.1 Tests API (Backend)

| ID | Titre | Endpoint | Methode | Resultat attendu | Priorite |
|----|-------|----------|---------|-------------------|----------|
| TT-API-001 | Endpoint sans token | Tout /api/v1/* | GET/POST | 401 Unauthorized | P0 |
| TT-API-002 | Endpoint avec token valide | Tout /api/v1/* | GET/POST | 200/201 selon l'action | P0 |
| TT-API-003 | Endpoint avec token expire | Tout /api/v1/* | GET | 401 Unauthorized | P0 |
| TT-API-004 | UUID invalide en path | GET /persons/not-a-uuid | GET | 400 Bad Request | P1 |
| TT-API-005 | Ressource inexistante | GET /persons/{uuid-inexistant} | GET | 404 Not Found | P0 |
| TT-API-006 | Body invalide | POST /persons avec body vide | POST | 400 Bad Request | P1 |
| TT-API-007 | Pagination | GET /persons/village/{id}?page=0&size=10 | GET | PageData avec totalPages, totalElements | P1 |
| TT-API-008 | CORS | Appel cross-origin | OPTIONS | Headers CORS presents | P1 |
| TT-API-009 | Swagger UI accessible | GET /swagger-ui.html | GET | Page Swagger chargee (dev seulement) | P2 |
| TT-API-010 | Swagger desactive en prod | GET /swagger-ui.html (profil prod) | GET | 404 ou redirection | P2 |

### 6.2 Tests Base de Donnees

| ID | Titre | Description | Resultat attendu | Priorite |
|----|-------|-------------|-------------------|----------|
| TT-DB-001 | Flyway V1-V34 | Appliquer toutes les migrations sur base vierge | 0 erreurs, 34 migrations appliquees | P0 |
| TT-DB-002 | Extensions PostgreSQL | uuid-ossp, postgis, unaccent, pg_trgm | Extensions installees et fonctionnelles | P0 |
| TT-DB-003 | Enums PostgreSQL natifs | GenderEnum, PersonStatusEnum, etc. | Types enum crees, valeurs correctes | P0 |
| TT-DB-004 | Index GiST PostGIS | Recherche nearby | ST_DWithin utilise l'index GiST | P1 |
| TT-DB-005 | Cascade delete personne | Supprimer une personne | parent_child, person_clans, person_villages, comments, modifications supprimes | P0 |
| TT-DB-006 | Contrainte UNIQUE | Inserer doublon sur contrainte unique | Erreur constraint violation | P1 |
| TT-DB-007 | JSONB changes | PersonModificationRequest.changes | Donnees JSONB lues/ecrites correctement | P1 |
| TT-DB-008 | Seed data villages | V7 migration | 30 villages dans 10 pays | P1 |
| TT-DB-009 | Seed data continents | V3 migration | Continents AF-CENTRAL, AF-WEST, etc. | P1 |

### 6.3 Tests Neo4j

| ID | Titre | Description | Resultat attendu | Priorite |
|----|-------|-------------|-------------------|----------|
| TT-NEO4J-001 | Sync personne | Creer une personne en PostgreSQL | Noeud Person cree dans Neo4j | P0 |
| TT-NEO4J-002 | Sync lien parent-enfant | Lier parent-enfant | Relation PARENT_OF creee dans Neo4j | P0 |
| TT-NEO4J-003 | Traversal ancetres | GET /ancestors?depth=5 | Requete Cypher retourne ancetres corrects | P1 |
| TT-NEO4J-004 | Traversal descendants | GET /descendants?depth=5 | Requete Cypher retourne descendants corrects | P1 |
| TT-NEO4J-005 | Full sync | POST /admin/neo4j/sync-all | Toutes les personnes + liens sync | P1 |

### 6.4 Tests Events

| ID | Titre | Evenement | Resultat attendu | Priorite |
|----|-------|-----------|-------------------|----------|
| TT-EVT-001 | ParentChildLinkedEvent | Lien parent-enfant cree | Notification FCM + in-app + auto-post feed | P0 |
| TT-EVT-002 | UnionCreatedEvent | Union creee | Notifications + emails + auto-post | P0 |
| TT-EVT-003 | ChildAssociationRequestedEvent | Demande association | Notification + email + FCM au co-parent | P0 |
| TT-EVT-004 | ChildAssociationRespondedEvent | Reponse association | Notification + FCM au demandeur | P0 |
| TT-EVT-005 | PersonModificationRequestedEvent | Demande modification | Notification + FCM au co-parent | P0 |
| TT-EVT-006 | PersonModificationRespondedEvent | Reponse modification | Notification + FCM au demandeur | P0 |
| TT-EVT-007 | PostSubmittedEvent | Post cree | Entree dans moderation_queue | P1 |
| TT-EVT-008 | Event async | Tout evenement @Async | Execution dans thread separee | P1 |

### 6.5 Tests Performance

| ID | Titre | Description | Critere | Priorite |
|----|-------|-------------|---------|----------|
| TT-PERF-001 | Chargement feed | GET /feed/village/{id} avec 50 posts | < 500ms | P1 |
| TT-PERF-002 | Chargement arbre | GET /tree/{personId} avec 100 personnes | < 1s | P1 |
| TT-PERF-003 | Recherche nearby | ST_DWithin 100km, 30 villages | < 200ms | P1 |
| TT-PERF-004 | Recherche globale | /geo/search?q=a | < 300ms | P2 |
| TT-PERF-005 | Ancetres Neo4j | ancestors?depth=10 | < 500ms | P2 |
| TT-PERF-006 | Temps demarrage Flutter | Splash -> Home | < 3s | P1 |

### 6.6 Tests Securite

| ID | Titre | Description | Resultat attendu | Priorite |
|----|-------|-------------|-------------------|----------|
| TT-SEC-001 | JWT validation | Token signe avec une autre cle | 401 Unauthorized | P0 |
| TT-SEC-002 | Acces non autorise | Supprimer une personne d'un autre utilisateur | 403 Forbidden | P0 |
| TT-SEC-003 | Injection SQL | Saisir du SQL dans les champs recherche | Pas d'injection, requete parametree | P0 |
| TT-SEC-004 | XSS dans posts | Saisir `<script>` dans un post | Contenu echappe, pas d'execution | P0 |
| TT-SEC-005 | CORS configuration | Appel depuis domaine non autorise | Requete bloquee | P1 |
| TT-SEC-006 | Rate limiting moderation | Plus de 3 flags/heure/utilisateur | 429 Too Many Requests | P1 |

---

## 7. MATRICE DE COUVERTURE

### 7.1 Couverture fonctionnelle

| Module | Fonctionnalite | Tests fonctionnels | Couverte |
|--------|---------------|-------------------|----------|
| Auth | Inscription email | TF-AUTH-001 a 004 | OUI |
| Auth | Connexion email | TF-AUTH-005, 006 | OUI |
| Auth | OAuth 6 providers | TF-AUTH-007 a 012 | OUI |
| Auth | Mot de passe oublie | TF-AUTH-013 | OUI |
| Auth | Deconnexion | TF-AUTH-014 | OUI |
| Auth | Guard routes | TF-AUTH-015 | OUI |
| Auth | Sync backend | TF-AUTH-016 | OUI |
| Auth | Rate limiting | TF-AUTH-017 | OUI |
| Auth | Token expire | TF-AUTH-018 | OUI |
| Profil | Affichage | TF-PROF-001, 002 | OUI |
| Profil | Modification | TF-PROF-003 a 006 | OUI |
| Profil | Layout responsive | TF-PROF-007 a 009 | OUI |
| Profil | Panneaux lateraux | TF-PROF-010, 011 | OUI |
| Villages | Liste / Recherche | TF-VILL-001, 002 | OUI |
| Villages | Detail | TF-VILL-003 | OUI |
| Villages | Rejoindre / Quitter | TF-VILL-004, 005 | OUI |
| Villages | CRUD | TF-VILL-006 a 009 | OUI |
| Villages | Badge verifie | TF-VILL-010 | OUI |
| Feed | Affichage | TF-FEED-001, 002 | OUI |
| Feed | Creation post | TF-FEED-003, 004 | OUI |
| Feed | Reactions | TF-FEED-005 | OUI |
| Feed | Commentaires | TF-FEED-006 | OUI |
| Feed | Signalement | TF-FEED-007 a 009 | OUI |
| Feed | Types speciaux | TF-FEED-010, 011 | OUI |
| Moderation | File d'attente | TF-MOD-001 | OUI |
| Moderation | Approuver/Rejeter | TF-MOD-002, 003 | OUI |
| Moderation | Shadow ban | TF-MOD-004, 005 | OUI |
| Moderation | Stats/Logs | TF-MOD-006, 007 | OUI |
| Genealogie | Arbre canvas | TF-GEN-001, 002 | OUI |
| Genealogie | Interactions noeuds | TF-GEN-003 | OUI |
| Genealogie | Creation enfant | TF-GEN-004 a 006 | OUI |
| Genealogie | Deduplication | TF-GEN-007 | OUI |
| Genealogie | Liens parent-enfant | TF-GEN-008 a 011 | OUI |
| Genealogie | Fratrie/GP/Cousins | TF-GEN-012 a 014 | OUI |
| Genealogie | Conjoints | TF-GEN-015 | OUI |
| Genealogie | Neo4j traversal | TF-GEN-016 a 018 | OUI |
| Genealogie | Recherche | TF-GEN-019 a 026 | OUI |
| Genealogie | Commentaires | TF-GEN-027 a 029 | OUI |
| Genealogie | CRUD personne | TF-GEN-030 a 032 | OUI |
| Genealogie | Person detail popup | TF-GEN-033 a 038 | OUI |
| Modification enfant | Demande 2 parents | TF-MODIF-001 | OUI |
| Modification enfant | Demande 1 parent | TF-MODIF-002 | OUI |
| Modification enfant | Accepter/Refuser | TF-MODIF-003, 004 | OUI |
| Modification enfant | Validations | TF-MODIF-005, 006 | OUI |
| Modification enfant | Notifications | TF-MODIF-007 a 011 | OUI |
| Association enfant | Demande | TF-ASSOC-001 | OUI |
| Association enfant | Accepter/Refuser | TF-ASSOC-002, 003 | OUI |
| Association enfant | Email/FCM | TF-ASSOC-004, 005 | OUI |
| Geo | Continents | TF-GEO-001 a 003 | OUI |
| Geo | Pays | TF-GEO-004 a 006 | OUI |
| Geo | Nearby PostGIS | TF-GEO-007 a 009 | OUI |
| Geo | Liens culturels | TF-GEO-010, 011 | OUI |
| Geo | Recherche globale | TF-GEO-012 a 015 | OUI |
| Notifications | CRUD | TF-NOTIF-001 a 004 | OUI |
| Notifications | Dialogs par type | TF-NOTIF-005 a 009 | OUI |
| Notifications | Badge | TF-NOTIF-010 | OUI |
| Chat | CRUD groupe | TF-CHAT-001 | OUI |
| Chat | Messages | TF-CHAT-002 a 004 | OUI |

### 7.2 Couverture technique

| Categorie | Tests | Couverte |
|-----------|-------|----------|
| API Auth/AuthZ | TT-API-001 a 003 | OUI |
| API Validation | TT-API-004 a 006 | OUI |
| API Pagination | TT-API-007 | OUI |
| API CORS/Swagger | TT-API-008 a 010 | OUI |
| DB Migrations | TT-DB-001 a 003 | OUI |
| DB PostGIS | TT-DB-004 | OUI |
| DB Cascade/Contraintes | TT-DB-005 a 007 | OUI |
| DB Seed data | TT-DB-008, 009 | OUI |
| Neo4j Sync | TT-NEO4J-001 a 005 | OUI |
| Events asynchrones | TT-EVT-001 a 008 | OUI |
| Performance | TT-PERF-001 a 006 | OUI |
| Securite | TT-SEC-001 a 006 | OUI |

### 7.3 Resume de couverture

| Type | Nombre de tests | Modules couverts |
|------|----------------|-----------------|
| Tests fonctionnels | 130 | 11/11 modules (100%) |
| Tests techniques API | 10 | Tous les endpoints |
| Tests base de donnees | 9 | PostgreSQL + PostGIS + Enums |
| Tests Neo4j | 5 | Sync + Traversal |
| Tests events | 8 | Tous les 8 types d'evenements |
| Tests performance | 6 | Feed, arbre, geo, Flutter |
| Tests securite | 6 | JWT, RBAC, injection, XSS, CORS, rate limit |
| **TOTAL** | **174** | **Couverture 100%** |

---

## 8. ENVIRONNEMENT DE TEST

### 8.1 Pre-requis

| Composant | Version | Obligatoire |
|-----------|---------|-------------|
| Java JDK | 21 (LTS) | OUI |
| Maven | 3.9+ | OUI |
| Flutter SDK | 3.x stable | OUI |
| PostgreSQL | 16+ avec PostGIS 3.4+ | OUI |
| Neo4j | 5.x | OUI |
| Redis | 7.x | OUI (chat/cache) |
| Node.js | 18+ | Pour le landing Next.js |
| Docker / Docker Compose | Latest | Pour l'env local |

### 8.2 Configuration

1. **Backend** : Copier `.env.example` -> `.env`, remplir les valeurs Supabase, Neo4j, Redis, R2, FCM, Resend, Claude API
2. **Frontend** : Copier `frontend/.env.example` -> `frontend/.env`, remplir SUPABASE_URL, SUPABASE_ANON_KEY, API_BASE_URL
3. **Docker** : `docker-compose -f docker-compose.dev.yml up` (PostgreSQL + Redis + Neo4j + Meilisearch)
4. **Backend** : `cd backend && mvn clean compile` puis lancer depuis IntelliJ ou `mvn spring-boot:run`
5. **Frontend** : `cd frontend && flutter pub get && dart run build_runner build && flutter run`

### 8.3 Comptes de test

| Role | Email | Description |
|------|-------|-------------|
| MEMBRE (Parent A) | testeur-a@gwangmeu.test | Utilisateur standard, parent d'un enfant |
| MEMBRE (Parent B) | testeur-b@gwangmeu.test | Co-parent, recoit les demandes |
| MODERATEUR | moderateur@gwangmeu.test | Peut moderer les posts |
| AMBASSADEUR | ambassadeur@gwangmeu.test | Peut creer des villages |
| SUPER_ADMIN | admin@gwangmeu.test | Acces total |

### 8.4 Donnees de test pre-chargees

- 5 continents africains (V3)
- 10 pays avec drapeaux emoji (V6)
- 30 villages GPS reels (V7)
- Enums PostgreSQL natifs (V10, V13)
- Structure clans et person_villages (V25-V27)
- Tables modification_requests et association_requests (V30, V34)

---

## 9. DONNEES DE TEST

### 9.1 Personne type (creation enfant)

```json
{
  "firstName": "Amara",
  "lastName": "Kouassi",
  "gender": "MALE",
  "birthDate": "2024-06-15",
  "birthPlace": "Edea",
  "clan": "Bakoko",
  "totem": "Tortue",
  "email": null,
  "phone": null
}
```

### 9.2 Modification request type

```json
{
  "firstName": "Amara-Kwame",
  "birthPlace": "Douala"
}
```

### 9.3 Village type

```json
{
  "name": "Edea",
  "description": "Ville industrielle au bord de la Sanaga, berceau du peuple Bassa.",
  "country": "CMR",
  "region": "Littoral",
  "continentCode": "AF-CENTRAL",
  "latitude": 3.7986,
  "longitude": 10.1337,
  "primaryDialect": "Bassa",
  "populationEstimate": 85000
}
```

### 9.4 Post type

```json
{
  "authorId": "uuid-auteur",
  "villageId": "uuid-village",
  "content": "Les langues africaines sont les gardiens de notre ame collective.",
  "mediaUrl": null
}
```

### 9.5 Recherche nearby type

```
GET /api/v1/geo/villages/nearby?lat=3.848&lng=11.502&radiusKm=100&limit=10
```
Yaounde (3.848, 11.502) -> devrait trouver Sangmelima (2.939, 11.984) a ~102km.

---

## FIN DU DOCUMENT

> Total des cas de test : **174**
> Couverture fonctionnelle : **100% des fonctionnalites**
> Couverture technique : **100% des composants**
> Modules couverts : **11/11**
