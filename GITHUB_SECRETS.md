# Configuration des Secrets GitHub — GWANG MEU

Aller dans : **GitHub repo → Settings → Secrets and variables → Actions → New repository secret**

---

## Secrets Railway

| Secret | Ou le trouver | Format attendu |
|--------|--------------|----------------|
| `RAILWAY_TOKEN` | railway.app → Account (haut à droite) → Tokens → New Token | `railway_token_xxxxxxxxxxxx` |
| `RAILWAY_PROJECT_ID_STAGING` | Dashboard Railway → projet staging → Settings → General → Project ID | UUID `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `RAILWAY_PROJECT_ID_PROD` | Dashboard Railway → projet prod → Settings → General → Project ID | UUID `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |

---

## Secrets Supabase

| Secret | Ou le trouver | Format attendu |
|--------|--------------|----------------|
| `SUPABASE_URL` | Supabase → Project Settings → API → Project URL | `https://xxxxxxxxxxxx.supabase.co` |
| `SUPABASE_SERVICE_KEY` | Supabase → Project Settings → API → Project API keys → `service_role` (secret) | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` |
| `SUPABASE_DB_URL` | Supabase → Project Settings → Database → Connection string → JDBC | `jdbc:postgresql://db.xxxx.supabase.co:5432/postgres` |

---

## Secret Anthropic

| Secret | Ou le trouver | Format attendu |
|--------|--------------|----------------|
| `ANTHROPIC_API_KEY` | console.anthropic.com → API Keys → Create Key | `sk-ant-api03-xxxxxxxxxxxx` |

---

## Secrets Neo4j AuraDB

| Secret | Ou le trouver | Format attendu |
|--------|--------------|----------------|
| `NEO4J_URI` | Neo4j Aura → votre instance → Connect → Connection URI | `neo4j+s://xxxxxxxx.databases.neo4j.io` |
| `NEO4J_USERNAME` | Toujours `neo4j` (valeur fixe AuraDB) | `neo4j` |
| `NEO4J_PASSWORD` | Neo4j Aura → votre instance → créé à la création de l'instance (à sauvegarder à ce moment-là) | Chaîne alphanumérique générée |

---

## Secret Redis (Upstash)

| Secret | Ou le trouver | Format attendu |
|--------|--------------|----------------|
| `REDIS_URL` | Upstash → votre database → Details → Endpoint | `rediss://default:xxxx@xxxx.upstash.io:6379` |

---

## Secrets LiveKit

| Secret | Ou le trouver | Format attendu |
|--------|--------------|----------------|
| `LIVEKIT_API_KEY` | livekit.io → Dashboard → votre projet → Settings → Keys | `APIxxxxxxxxxx` |
| `LIVEKIT_API_SECRET` | livekit.io → Dashboard → votre projet → Settings → Keys (même ligne) | Chaîne base64 ~40 caractères |

---

## Secret Mapbox

| Secret | Ou le trouver | Format attendu |
|--------|--------------|----------------|
| `MAPBOX_ACCESS_TOKEN` | mapbox.com → Account → Tokens → votre token (ou créer un token avec scopes `styles:read`, `tiles:read`) | `pk.eyJ1Ijoixxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` |

---

## Secrets Meilisearch

| Secret | Ou le trouver | Format attendu |
|--------|--------------|----------------|
| `MEILISEARCH_HOST` | meilisearch.com → votre projet → Overview → Host | `https://ms-xxxx-xxxx.sfo.meilisearch.io` |
| `MEILISEARCH_API_KEY` | meilisearch.com → votre projet → API Keys → Master Key | Chaîne hex 64 caractères |

---

## Secrets Cloudflare R2

| Secret | Ou le trouver | Format attendu |
|--------|--------------|----------------|
| `R2_ACCESS_KEY_ID` | Cloudflare → R2 → Manage R2 API Tokens → Create API Token → `Access Key ID` | `xxxxxxxxxxxxxxxxxxxx` |
| `R2_SECRET_ACCESS_KEY` | Cloudflare → R2 → Manage R2 API Tokens → Create API Token → `Secret Access Key` (affiché une seule fois) | Chaîne base64 ~40 caractères |
| `R2_BUCKET_NAME` | Valeur fixe | `gwangmeu-media` |
| `R2_ACCOUNT_ID` | Cloudflare → colonne de droite de n'importe quelle page → Account ID | Chaîne hex 32 caractères |

---

## Secret Resend

| Secret | Ou le trouver | Format attendu |
|--------|--------------|----------------|
| `RESEND_API_KEY` | resend.com → API Keys → Create API Key | `re_xxxxxxxxxxxxxxxxxxxxxxxxxxxx` |

---

## Secret Sentry

| Secret | Ou le trouver | Format attendu |
|--------|--------------|----------------|
| `SENTRY_DSN_JAVA` | sentry.io → votre projet Java → Settings → Client Keys (DSN) | `https://xxxx@oxxxx.ingest.sentry.io/xxxx` |

---

## Secret JWT

| Secret | Ou le trouver | Format attendu |
|--------|--------------|----------------|
| `JWT_SECRET` | Générer localement avec : `openssl rand -hex 32` | Chaîne hex 64 caractères |

---

## Secret GitHub Container Registry

| Secret | Ou le trouver | Format attendu |
|--------|--------------|----------------|
| `GHCR_TOKEN` | GitHub → Settings → Developer Settings → Personal access tokens → Tokens (classic) → Generate new token → scopes : `write:packages`, `read:packages`, `delete:packages` | `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` |

---

## Environments GitHub

Pour isoler les secrets staging/prod, configurer deux **Environments** dans GitHub :

1. **staging** — GitHub repo → Settings → Environments → New environment → `staging`
2. **production** — idem → `production`

Puis ajouter les secrets propres a chaque env (`RAILWAY_PROJECT_ID_STAGING`, `RAILWAY_PROJECT_ID_PROD`) dans leur environment respectif plutot qu'au niveau repository.

---

## Recap — Ordre de configuration recommande

1. `JWT_SECRET` (generer en premier : `openssl rand -hex 32`)
2. `RAILWAY_TOKEN` + `RAILWAY_PROJECT_ID_STAGING` + `RAILWAY_PROJECT_ID_PROD`
3. `SUPABASE_URL` + `SUPABASE_SERVICE_KEY` + `SUPABASE_DB_URL`
4. `ANTHROPIC_API_KEY`
5. `NEO4J_URI` + `NEO4J_USERNAME` + `NEO4J_PASSWORD`
6. `REDIS_URL`
7. `LIVEKIT_API_KEY` + `LIVEKIT_API_SECRET`
8. `MAPBOX_ACCESS_TOKEN`
9. `MEILISEARCH_HOST` + `MEILISEARCH_API_KEY`
10. `R2_ACCESS_KEY_ID` + `R2_SECRET_ACCESS_KEY` + `R2_BUCKET_NAME` + `R2_ACCOUNT_ID`
11. `RESEND_API_KEY`
12. `SENTRY_DSN_JAVA`
13. `GHCR_TOKEN`
