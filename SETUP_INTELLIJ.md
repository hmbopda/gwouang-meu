# Demarrer GWANG MEU dans IntelliJ — 10 minutes

## Prerequis

- IntelliJ IDEA 2024.x (Ultimate ou Community)
- Java 21 JDK Temurin — https://adoptium.net
- Docker Desktop en cours d'execution
- Maven 3.9+

---

## Etape 1 — Cloner et configurer

```bash
git clone https://github.com/TON_ORG/gwangmeu.git
cd gwangmeu
cp backend/.env.example backend/.env
# Edite backend/.env (les valeurs locales suffisent pour demarrer)
```

---

## Etape 2 — Ouvrir dans IntelliJ

`File` → `Open` → selectionner `backend/pom.xml` → **"Open as Project"**

Attendre l'indexation Maven (~2 min premiere fois).

---

## Etape 3 — Installer EnvFile (OBLIGATOIRE)

`Settings` → `Plugins` → `Marketplace` → rechercher **"EnvFile"** → `Install` → `Restart IDE`

> Sans ce plugin, les variables de `backend/.env` ne seront pas chargees dans la run config.

---

## Etape 4 — Verifier EnvFile dans la run config

`Run` → `Edit Configurations` → selectionner **"🚀 GwangMeu Backend (Dev)"**

Onglet **"EnvFile"** → cocher **Enable EnvFile** → verifier que `backend/.env` est liste.

---

## Etape 5 — Lancer !

1. `Run` → **"🐳 Docker Dev Stack"** — demarre PostgreSQL + PostGIS, Redis, Neo4j, Meilisearch
2. Attendre ~30 secondes que les containers soient healthy
3. `Run` → **"🚀 GwangMeu Backend (Dev)"**
4. Attendre le message : `Started GwangMeuApplication in X.XXX seconds`

---

## Etape 6 — Verifier

| Endpoint | Attendu |
|----------|---------|
| http://localhost:8080/actuator/health | `{"status":"UP"}` |
| http://localhost:8080/swagger-ui.html | Interface Swagger UI |
| http://localhost:8080/v3/api-docs | JSON OpenAPI spec |

---

## Etape 7 — Tester les APIs

1. Ouvrir `backend/http/01_auth.http` dans IntelliJ
2. Selectionner l'environnement **"dev"** (menu deroulant en haut a droite de l'editeur HTTP)
3. Coller ton token Supabase dans `http-client.env.json` → champ `jwt`
4. Cliquer sur le bouton ▶ a gauche de chaque requete

---

## Etape 8 — Lancer les tests

- **Tous les tests** : `Run` → **"🧪 Tests — All (Testcontainers)"**
- **Phase 1 seulement** : `Run` → **"🧪 Tests — Phase 1"**

Testcontainers demarre automatiquement les containers de test isoles — Docker doit etre en cours d'execution.

---

## Plugins recommandes

| Plugin | Utilite |
|--------|---------|
| **EnvFile** | Charge `.env` dans les run configs — OBLIGATOIRE |
| **MapStruct Support** | Autocompletion MapStruct dans les mappers |
| **Docker** | Gestion des containers directement dans l'IDE |
| **SonarLint** | Analyse qualite du code en temps reel |
| **GitToolBox** | Annotations Git inline dans l'editeur |

---

## Raccourcis utiles

| Raccourci | Action |
|-----------|--------|
| `Ctrl+Shift+F10` | Lancer la configuration courante |
| `Ctrl+F9` | Recompiler (hot reload avec Spring DevTools) |
| `gmc` + `Tab` | Live template — Controller Spring Boot |
| `gms` + `Tab` | Live template — Service |
| `gmr` + `Tab` | Live template — Repository JPA |
| `gme` + `Tab` | Live template — Entity JPA |
| `gmd` + `Tab` | Live template — DTO record |
| `gmev` + `Tab` | Live template — Domain Event |
| `gmtest` + `Tab` | Live template — Test d'integration |
| `swop` + `Tab` | Live template — Swagger @Operation |

---

## Connexion BDD locale (IntelliJ Ultimate uniquement)

`View` → `Tool Windows` → `Database` → `+` → `Data Source`

**PostgreSQL**
- Host: `localhost`
- Port: `5432`
- Database: `gwangmeu_dev`
- User: `postgres`
- Password: valeur `POSTGRES_PASSWORD` dans `backend/.env`

**Neo4j**
- URL: `bolt://localhost:7687`
- User: `neo4j`
- Password: valeur `NEO4J_PASSWORD` dans `backend/.env`

---

## Troubleshooting

**"EnvFile tab not visible"** → Le plugin EnvFile n'est pas installe. Voir Etape 3.

**"Port already in use"** → Un container precedent tourne encore. Executer :
```bash
docker-compose -f docker-compose.dev.yml down
```
puis relancer "🐳 Docker Dev Stack".

**"com.gwangmeu.GwangMeuApplication not found"** → Maven n'a pas encore indexe le projet. Attendre la fin de l'indexation ou cliquer sur `Maven` → `Reload All Maven Projects`.

**Tests qui echouent avec "Cannot connect to Docker"** → Docker Desktop n'est pas lance. Demarrer Docker Desktop puis relancer les tests.
