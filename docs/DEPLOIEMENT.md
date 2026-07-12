# GWANG MEU — Runbook de mise en production

> **Objectif** : déployer définitivement le backend Spring Boot sur Railway et
> basculer le frontend, en ne fournissant **que des tokens/valeurs** — toute la
> mécanique (workflows, Dockerfile, health checks) est déjà prête.
>
> Dernière mise à jour : 2026-07-07.

---

## 0. Décision de plateforme : Railway

**Choix retenu : Railway.** Justification :

| Critère | Détail |
|---|---|
| Déjà scripté | `deploy-staging.yml` et `deploy-prod.yml` ciblent Railway ; `backend/Dockerfile` prêt |
| Compatibilité Supabase | `application-prod.yml` est déjà calibré pour Railway (pooler Supavisor IPv4, PgBouncer sans prepared statements) |
| Redis | Plugin Redis natif en 1 clic → `REDIS_URL` fourni par la plateforme (l'ancien Upstash a été supprimé) |
| Coût | Plan Hobby ≈ 5 $/mois (inclut ~5 $ d'usage). Pas de plan gratuit pérenne. |

**Alternatives si le coût est bloquant** : Koyeb (free tier 1 service web, mais pas de
Redis managé gratuit) ou Render (free tier avec mise en veille ~15 min d'inactivité +
Redis « Key Value » gratuit 25 Mo). Dans les deux cas il faudrait réécrire les steps de
déploiement des workflows — Railway reste le chemin le plus court.

### Architecture cible

```
GitHub (hmbopda/gwouang-meu, branche main)
 ├─ push main  → deploy-staging.yml → Railway (staging, OPTIONNEL)
 ├─ tag v*.*.* → deploy-prod.yml    → tests → image GHCR → Railway (prod) → health check → release
 └─ push main (frontend/**) → deploy-frontend.yml → Cloudflare Pages « gwangmeu-app »

Railway (service gwangmeu-backend-prod, Root Directory = backend)
 ├─ PostgreSQL  : Supabase (pooler aws-1-eu-west-2.pooler.supabase.com — externe)
 ├─ Redis       : plugin Railway (REDIS_URL fourni) ← l'Upstash historique est SUPPRIMÉ
 └─ Neo4j       : AuraDB (externe — instance probablement en pause, à réactiver)
```

---

## 1. Prérequis — pousser les workflows corrigés

Les corrections de `.github/workflows/*` sont **locales et non commitées** (le token
git/gh actuel n'a pas le scope `workflow`). À faire :

```bash
# 1) Ajouter le scope workflow au token gh (ouvre le navigateur)
gh auth refresh -h github.com -s workflow

# 2) Vérifier que git utilise bien les credentials gh
gh auth setup-git

# 3) Committer les workflows corrigés
git add .github/workflows/ci.yml .github/workflows/deploy-staging.yml \
        .github/workflows/deploy-prod.yml .github/workflows/deploy-frontend.yml
git commit -m "ci: workflows Railway (railway up, health checks paramétrés, GITHUB_TOKEN, Flutter 3.41.x)"

# 4) Pousser — ATTENTION : les déclencheurs sont sur la branche main,
#    le travail local est sur master
git push origin master
git push origin master:main
```

Corrections apportées localement aux workflows (résumé) :

- `railway deploy` → **`railway up --service <nom> --ci`** (`railway deploy` sert à
  provisionner des *templates*, pas à déployer le code ; `--ci` attend la fin du build).
- Le **token projet** Railway étant scopé projet + environnement, les secrets
  `RAILWAY_PROJECT_ID_STAGING` / `RAILWAY_PROJECT_ID_PROD` **ne servent plus** —
  remplacés par deux tokens distincts `RAILWAY_TOKEN_STAGING` / `RAILWAY_TOKEN_PROD`.
- Health checks : les domaines inexistants `*.gwouangmeu.com` sont remplacés par les
  secrets **`APP_HEALTH_URL_STAGING`** / **`APP_HEALTH_URL_PROD`** (URL complète,
  `.../actuator/health`), avec boucle de retry 30 × 10 s. Si le secret est absent, le
  check est ignoré avec un warning (utile au tout premier déploiement, avant de
  connaître l'URL).
- `railway rollback` supprimé (la commande n'existe pas dans la CLI) → rollback manuel
  via le dashboard (Deployments → déploiement précédent → Redeploy).
- GHCR et release GitHub utilisent le **`GITHUB_TOKEN` intégré** (bloc `permissions:`)
  → **le secret `GHCR_TOKEN` n'est plus nécessaire**.
- `ci.yml` : Flutter épinglé **3.41.x** (le code exige > 3.22) ; Java 21 déjà correct.
- `deploy-staging.yml` : devient **no-op silencieux** tant que `RAILWAY_TOKEN_STAGING`
  n'est pas défini (les push sur main ne passeront plus au rouge) + déclenchement
  manuel `workflow_dispatch` ajouté.

---

## 2. Services cloud à (ré)activer

| Service | État | Action |
|---|---|---|
| **Supabase** (projet `objlxdxzpqhrekpqxgab`) | Actif | Rien. Utiliser le pooler `aws-1-eu-west-2.pooler.supabase.com` (IPv4, port 5432, `sslmode=require`) — Railway ne résout pas l'hôte direct IPv6. |
| **Redis** | **Upstash SUPPRIMÉ** (`outgoing-condor-64822.upstash.io` ne résout plus) | **Option A (recommandée)** : plugin Redis Railway — clic droit sur le canvas du projet → *Database* → *Add Redis*. Puis dans les variables du service backend : `REDIS_URL = ${{Redis.REDIS_URL}}` (référence de variable Railway). **Option B** : recréer une base sur upstash.com → copier l'URL `rediss://...` (double « s » = TLS). ⚠️ `REDIS_URL` est **obligatoire** : sans elle l'application ne démarre pas. |
| **Neo4j AuraDB** (`83496284.databases.neo4j.io`) | Probablement **en pause** (les instances gratuites se mettent en pause après inactivité) | console.neo4j.io → *Resume* sur l'instance. Le backend tolère un Neo4j indisponible au démarrage (timeout 10 s) mais le health check `/actuator/health` sera DOWN tant que Neo4j ne répond pas. |
| **Firebase** (push FCM) | Clé de service disponible localement | Minifier le JSON du service account **sur une seule ligne** et le coller dans la variable Railway `FIREBASE_SERVICE_ACCOUNT_JSON`. Le fichier local `serviceAccountKey.json` n'est jamais copié dans l'image (exclu par `.dockerignore` + `rm` défensif dans le Dockerfile). |

---

## 3. Création du service Railway (une seule fois)

1. Créer un compte sur [railway.com](https://railway.com) (login GitHub recommandé) et un
   projet, p. ex. `gwangmeu`.
2. Dans le projet : **+ New → Empty Service**, renommer en **`gwangmeu-backend-prod`**
   (le nom doit correspondre au flag `--service` du workflow).
3. Service → **Settings** :
   - **Root Directory** = `backend` (le Dockerfile `backend/Dockerfile` sera détecté
     automatiquement comme builder).
   - **Networking → Generate Domain** → noter l'URL publique, du type
     `https://gwangmeu-backend-prod-production.up.railway.app`. Port cible : **8080**
     (Railway injecte `PORT`, l'application écoute dessus).
4. **+ New → Database → Add Redis** dans le même projet.
5. Service backend → **Variables** → saisir les variables du §4 (les vraies valeurs sont
   dans votre fichier local `backend/prod.md`, non versionné).
6. Projet → **Settings → Tokens** → créer un token scopé à l'environnement
   `production` → c'est la valeur de `RAILWAY_TOKEN_PROD`.
7. *(Optionnel, plus tard)* : créer un environnement `staging`, un service
   `gwangmeu-backend-staging` identique et un second token → `RAILWAY_TOKEN_STAGING`.

---

## 4. Variables Railway (service backend)

> Les valeurs se trouvent dans votre `backend/prod.md` **local** (jamais dans Git).
> Ne recopier ici aucune valeur secrète.

### Obligatoires (l'app ne démarre pas sans)

| Variable | Contenu / format |
|---|---|
| `SPRING_PROFILES_ACTIVE` | `prod` |
| `SUPABASE_DB_URL` | `jdbc:postgresql://aws-1-eu-west-2.pooler.supabase.com:5432/postgres?sslmode=require` |
| `SUPABASE_DB_USER` | `postgres.<project-ref>` (format pooler) |
| `SUPABASE_DB_PASSWORD` | mot de passe DB Supabase |
| `SUPABASE_URL` | `https://<project-ref>.supabase.co` |
| `SUPABASE_ANON_KEY` | Supabase Studio → Settings → API |
| `SUPABASE_SERVICE_KEY` | Supabase Studio → Settings → API |
| `SUPABASE_JWT_ISSUER_URI` | `https://<project-ref>.supabase.co/auth/v1` |
| `SUPABASE_JWKS_URI` | `https://<project-ref>.supabase.co/auth/v1/.well-known/jwks.json` |
| `JWT_SECRET` | secret ≥ 32 caractères |
| `REDIS_URL` | **Correction** : `${{Redis.REDIS_URL}}` (plugin Railway) **ou** nouvelle URL Upstash `rediss://...` — l'ancienne URL Upstash de `prod.md` est morte |
| `NEO4J_URI` | `neo4j+s://<id>.databases.neo4j.io` |
| `NEO4J_USERNAME` / `NEO4J_PASSWORD` | credentials AuraDB |
| `APP_BASE_URL` | l'URL publique Railway générée au §3.3 |

### Optionnelles (fonctionnalités dégradées si absentes)

| Variable | Fonctionnalité |
|---|---|
| `MAIL_HOST`, `MAIL_PORT`, `MAIL_USERNAME`, `MAIL_PASSWORD`, `MAIL_FROM` | envoi d'e-mails (SMTP Gmail actuel) |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | notifications push FCM (JSON minifié sur une ligne) |
| `ANTHROPIC_API_KEY` | IA généalogie |
| `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_ACCOUNT_ID`, `R2_BUCKET_NAME`, `R2_PUBLIC_URL` | stockage médias Cloudflare R2 |
| `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`, `LIVEKIT_WS_URL` | appels vidéo |
| `SENTRY_DSN` | monitoring d'erreurs |
| `RESEND_API_KEY` | e-mails via Resend (alternative SMTP) |

---

## 5. Secrets GitHub Actions à créer

Repo → **Settings → Secrets and variables → Actions → New repository secret**
(ou `gh secret set NOM` en CLI).

| Secret | Utilisé par | Où obtenir la valeur |
|---|---|---|
| `RAILWAY_TOKEN_PROD` | deploy-prod | Railway → Projet → Settings → Tokens (scope environnement `production`) |
| `APP_HEALTH_URL_PROD` | deploy-prod | URL Railway du §3.3 + `/actuator/health` (à créer **après** le 1er déploiement ; sans lui le check est simplement ignoré) |
| `SUPABASE_URL` | deploy-frontend | `https://objlxdxzpqhrekpqxgab.supabase.co` |
| `SUPABASE_ANON_KEY` | deploy-frontend | Supabase Studio → Settings → API |
| `API_BASE_URL` | deploy-frontend | URL publique Railway du backend (sans `/actuator/health`) |
| `CLOUDFLARE_API_TOKEN` | deploy-frontend | dash.cloudflare.com → My Profile → API Tokens → template « Cloudflare Pages : Edit » |
| `CLOUDFLARE_ACCOUNT_ID` | deploy-frontend | Dashboard Cloudflare → barre latérale (ou dans l'URL du dashboard) |
| `RAILWAY_TOKEN_STAGING` *(optionnel)* | deploy-staging | Railway → Tokens (scope environnement `staging`). Tant qu'absent, le job staging est ignoré proprement |
| `APP_HEALTH_URL_STAGING` *(optionnel)* | deploy-staging | URL Railway staging + `/actuator/health` |

**Ne sont plus nécessaires** : `GHCR_TOKEN` (remplacé par le `GITHUB_TOKEN` intégré),
`RAILWAY_PROJECT_ID_PROD`, `RAILWAY_PROJECT_ID_STAGING` (implicites dans les tokens projet).

En CLI :

```bash
gh secret set RAILWAY_TOKEN_PROD
gh secret set APP_HEALTH_URL_PROD
gh secret set SUPABASE_URL
gh secret set SUPABASE_ANON_KEY
gh secret set API_BASE_URL
gh secret set CLOUDFLARE_API_TOKEN
gh secret set CLOUDFLARE_ACCOUNT_ID
```

---

## 6. Premier déploiement backend (séquence)

1. **Railway prêt** : service `gwangmeu-backend-prod` (Root Directory `backend`),
   plugin Redis ajouté, variables du §4 saisies, domaine généré (§3).
2. **Secrets GitHub** : au minimum `RAILWAY_TOKEN_PROD` (§5).
3. **Workflows poussés** sur `main` (§1).
4. **Pousser un tag** :

   ```bash
   git tag v0.1.0
   git push origin v0.1.0
   ```

5. Suivre le run **Deploy — Production** (`gh run watch` ou onglet Actions) :
   tests (Postgres + Redis éphémères) → image GHCR `ghcr.io/hmbopda/gwangmeu-backend`
   → `railway up` → health check → release GitHub.
6. Après le premier déploiement réussi : créer `APP_HEALTH_URL_PROD` avec
   `https://<domaine-railway>/actuator/health` pour activer le gate de santé des
   déploiements suivants.
7. Vérification manuelle :

   ```bash
   curl https://<domaine-railway>/actuator/health   # {"status":"UP"}
   ```

   Si `DOWN` : composant en cause probable = Neo4j en pause (§2) ou `REDIS_URL` absente.

**Rollback** : dashboard Railway → service → Deployments → déploiement précédent →
**Redeploy** (pas de commande CLI).

---

## 7. Bascule du frontend

### Étape 1 — immédiat : GitHub Pages pointe vers Railway

Le déploiement provisoire (repo public `hmbopda/gwangmeu-app`) remplace le tunnel
trycloudflare par l'URL Railway :

```bash
cd frontend
# .env : API_BASE_URL=https://<domaine-railway>
flutter build web --release --base-href /gwangmeu-app/ --no-tree-shake-icons
# puis publier build/web dans le repo hmbopda/gwangmeu-app comme d'habitude
```

CORS : `https://hmbopda.github.io` est déjà autorisé côté backend.

### Étape 2 — cible : Cloudflare Pages via le workflow

1. Créer le projet Pages **`gwangmeu-app`** (Dashboard Cloudflare → Workers & Pages →
   Create → Pages → *Direct Upload* ; le nom doit correspondre au `projectName` du
   workflow). Alternative CLI : `npx wrangler pages project create gwangmeu-app`.
2. Renseigner les secrets `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`,
   `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `API_BASE_URL` (§5).
3. Pousser sur `main` un commit touchant `frontend/**` (ou lancer manuellement
   **Deploy Frontend** via *workflow_dispatch*). Build Flutter 3.41.x avec
   `--base-href /` puis upload sur Pages.
4. CORS : `https://gwangmeu-app.pages.dev` et ses previews sont autorisés côté backend
   (SecurityConfig). Si un domaine custom est ajouté plus tard, l'ajouter aussi dans
   `SecurityConfig.corsConfigurationSource()`.

---

## 8. Ce qui reste à votre charge (résumé)

1. `gh auth refresh -h github.com -s workflow` puis commit + push des workflows (§1).
2. Créer le projet/service Railway + plugin Redis + coller les variables (§3–4).
3. Réactiver Neo4j AuraDB (Resume) ; décider Redis Railway vs nouvel Upstash (§2).
4. Créer les secrets GitHub (§5) — au minimum `RAILWAY_TOKEN_PROD`.
5. Pousser le tag `v0.1.0` (§6) puis créer `APP_HEALTH_URL_PROD`.
6. Rebuilder GitHub Pages avec la nouvelle `API_BASE_URL`, puis créer le projet
   Cloudflare Pages `gwangmeu-app` (§7).

---

## Annexe — dépannage

| Symptôme | Cause probable | Correctif |
|---|---|---|
| L'app ne démarre pas, erreur placeholder `REDIS_URL` | Variable absente (aucune valeur par défaut dans `application.yml`) | Ajouter `REDIS_URL` (plugin Railway ou Upstash) |
| `prepared statement "S_1" already exists` | Pooler Supavisor en mode transaction | Déjà géré (`prepareThreshold=0` dans `application-prod.yml`) — vérifier que le profil `prod` est actif |
| Connexion DB impossible depuis Railway | Hôte direct `db.*.supabase.co` = IPv6 only | Utiliser le pooler `aws-1-eu-west-2.pooler.supabase.com` + user `postgres.<ref>` |
| `/actuator/health` DOWN, composant `neo4j` | AuraDB en pause | console.neo4j.io → Resume |
| Health check du workflow échoue mais l'app est UP | `APP_HEALTH_URL_*` erroné (oubli du chemin `/actuator/health` ?) | Corriger le secret |
| Push FCM inactifs | `FIREBASE_SERVICE_ACCOUNT_JSON` vide | Coller le JSON minifié (l'app loggue « FCM disabled » et continue) |
| L'image locale contient la clé Firebase | Build antérieur au `.dockerignore` | Rebuilder : le contexte exclut `src/main/resources/firebase/` et le Dockerfile fait un `rm -f` défensif |
