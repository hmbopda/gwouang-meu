# GWANG MEU

Plateforme communautaire africaine — réseau social, généalogie, villages.

---

## Stack technique

### Backend
| Outil | Version |
|---|---|
| Java | 17 |
| Spring Boot | 3.3.5 |
| PostgreSQL + PostGIS | 16-3.4 |
| Neo4j | 5 (Community) |
| Redis | 7 |
| Meilisearch | latest |
| Maven | 3.x |
| Spring Security / OAuth2 | (géré par Spring Boot 3.3.5) |
| Spring Data JPA + Flyway | (géré par Spring Boot 3.3.5) |
| SpringDoc OpenAPI | 2.6.0 |
| MapStruct | 1.6.2 |
| AWS SDK (S3 / R2) | 2.28.0 |
| Firebase Admin | 9.3.0 |
| Sentry | 7.14.0 |
| TestContainers | 1.20.4 |

### Frontend (mobile)
| Outil | Version |
|---|---|
| Flutter | ≥ 3.22.0 |
| Dart | ≥ 3.3.0 < 4.0.0 |
| Riverpod | 2.5.0 |
| Supabase Flutter | 2.5.0 |
| Dio (HTTP) | 5.4.0 |
| Go Router | 14.0.0 |
| Freezed | 2.5.0 |
| Flutter Secure Storage | 9.0.0 |

### Landing
| Outil | Version |
|---|---|
| Node.js | ≥ 20 |
| Next.js | 14.2.5 |
| React | 18.3.1 |
| TypeScript | 5.5.2 |
| Tailwind CSS | 3.4.4 |

---

## Prérequis

- **Docker** + **Docker Compose** (pour les services locaux)
- **Java 17** (JDK)
- **Maven 3.x** (`mvn`)
- **Flutter 3.22+** (`flutter`)
- **Node.js 20+** + **npm** (pour la landing)

---

## Lancer le backend

### 1. Configurer les variables d'environnement

```bash
cp .env.example .env
# Editer .env avec tes valeurs (Supabase, Redis, Neo4j, etc.)
```

### 2. Démarrer les services (Docker)

```bash
docker compose -f docker-compose.dev.yml up -d
```

Cela lance :
- PostgreSQL + PostGIS sur le port **5432**
- Redis sur le port **6379**
- Neo4j sur le port **7474** (UI) / **7687** (Bolt)
- Meilisearch sur le port **7700**

### 3. Lancer le serveur Spring Boot

```bash
cd backend
mvn spring-boot:run
```

Le serveur démarre sur **http://localhost:8080**

Documentation Swagger : **http://localhost:8080/swagger-ui.html**

Health check : **http://localhost:8080/actuator/health**

### 4. Lancer les tests backend

```bash
cd backend
mvn test
```

---

## Lancer le frontend (Flutter)

### 1. Configurer les variables d'environnement

```bash
cd frontend
cp .env.example .env
# Renseigner SUPABASE_URL et SUPABASE_ANON_KEY
```

### 2. Installer les dépendances

```bash
flutter pub get
```

### 3. Générer le code (Freezed / Riverpod)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Lancer l'application

```bash
# Sur un émulateur ou appareil connecté
flutter run

# Sur Chrome (web)
flutter run -d chrome

# Sur un appareil spécifique
flutter devices          # lister les appareils disponibles
flutter run -d <id>
```

### 5. Lancer les tests frontend

```bash
flutter test
```

148 tests unitaires (models + services).

### 6. Analyser le code

```bash
flutter analyze
```

---

## Lancer la landing (Next.js)

### 1. Installer les dépendances

```bash
cd landing
npm install
```

### 2. Configurer les variables d'environnement

```bash
cp .env.local.example .env.local
# Renseigner les variables nécessaires
```

### 3. Lancer en développement

```bash
npm run dev
```

La landing est disponible sur **http://localhost:3000**

### 4. Build de production

```bash
npm run build
npm start
```

---

## Structure du projet

```
gwouang-meu/
├── backend/          # API Spring Boot (Java 17)
│   ├── src/
│   ├── pom.xml
│   └── Dockerfile
├── frontend/         # App mobile Flutter
│   ├── lib/
│   ├── test/
│   └── pubspec.yaml
├── landing/          # Site vitrine Next.js
│   ├── app/
│   └── package.json
├── .github/
│   └── workflows/    # CI/CD GitHub Actions
├── docker-compose.dev.yml
├── Makefile
└── .env.example
```

---

## Commandes Make (raccourcis)

```bash
make dev       # Démarre tous les services Docker
make stop      # Arrête les services Docker
make logs      # Affiche les logs des services
make backend   # Lance le backend Spring Boot
```

---

## Variables d'environnement requises

Voir `.env.example` à la racine pour la liste complète.

Les variables indispensables pour démarrer :

| Variable | Description |
|---|---|
| `SUPABASE_URL` | URL de ton projet Supabase |
| `SUPABASE_ANON_KEY` | Clé publique Supabase |
| `SUPABASE_SERVICE_KEY` | Clé service Supabase (backend uniquement) |
| `DB_PASSWORD` | Mot de passe PostgreSQL local |
| `NEO4J_PASSWORD` | Mot de passe Neo4j local |
| `JWT_SECRET` | Secret JWT (min. 32 caractères) |
