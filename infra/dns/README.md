# Domaines & DNS — GWOUANG MEU

Configuration DNS multi-domaines pour la plateforme, centralisée sur **Cloudflare**.

Domaine **canonique** (celui qui fait tourner l'application et ses sous-domaines) :
**`gwouang-meu.com`**. Les autres (`.fr`, `.org`, `.cm`) sont enregistrés en défense de
marque et **redirigent** (301) vers le canonique — c'est ce qui protège la marque tout
en évitant le contenu dupliqué (SEO) et la fragmentation de la config.

> ⚠️ Ton code actuel pointe encore vers `gwangmeu.com` (sans « ou », sans tiret).
> Voir la section **« Changements de code »** en bas : à faire si tu adoptes bien
> `gwouang-meu` comme domaine produit.

---

## 1. Où enregistrer quoi

| TLD | Registrar recommandé | Prix indicatif/an | Pourquoi |
|-----|----------------------|-------------------|----------|
| `.com` | **Cloudflare Registrar** | ~10 € (prix coûtant) | Canonique. Géré de bout en bout chez Cloudflare. |
| `.org` | **Cloudflare Registrar** | ~10 € | Cohérent avec l'angle patrimoine / ONG / secteur public. |
| `.fr`  | Cloudflare **si disponible**, sinon **OVH / Gandi** | ~7-12 € | Cloudflare Registrar ne propose pas toujours `.fr`. Vérifie dans le dashboard ; sinon prends-le ailleurs et délègue le DNS à Cloudflare. |
| `.cm`  | **Netcom.cm** (registrar camerounais) ou revendeur | ~40-100 € | ccTLD Cameroun (ANTIC). **Non géré par Cloudflare.** Peut exiger une présence locale. |

**Principe clé :** peu importe le registrar, tu ajoutes **chaque** domaine comme *zone*
dans Cloudflare (plan gratuit) et tu remplaces ses nameservers par ceux que Cloudflare
te donne. Résultat : **tout le DNS se gère au même endroit**, même si l'achat est réparti.

### Étapes d'enregistrement (dashboard Cloudflare)

1. **Cloudflare → Domain Registration → Register Domains** : cherche `gwouang-meu`, ajoute
   `.com` et `.org` au panier, paie. Les zones sont créées automatiquement.
2. Pour `.fr` et `.cm` enregistrés ailleurs : **Cloudflare → Add a site** → saisis le
   domaine → choisis le plan Free → Cloudflare scanne le DNS et te donne **2 nameservers**.
   Va chez le registrar (OVH/Gandi/Netcom) et remplace les nameservers par ceux-là.
   La propagation prend de quelques minutes à 24 h.
3. Une fois les 4 zones actives dans Cloudflare, lance le script (section 3) ou applique
   le tableau DNS (section 2) à la main.

---

## 2. Enregistrements DNS du domaine canonique (`gwouang-meu.com`)

Adapte les cibles marquées `⟨…⟩` à ton infrastructure réelle (Railway te donne le CNAME
exact quand tu ajoutes un domaine ; Pages/R2/Vercel créent le record automatiquement via
leur « custom domain »).

| Type | Nom | Contenu | Proxy | Rôle |
|------|-----|---------|-------|------|
| A | `@` | `76.76.21.21` | 🔘 DNS only | Landing (Vercel, apex) |
| CNAME | `www` | `cname.vercel-dns.com` | 🔘 DNS only | Landing www (Vercel) |
| CNAME | `app` | `⟨projet⟩.pages.dev` | 🟠 Proxied | App Flutter Web (Cloudflare Pages) |
| CNAME | `api` | `⟨service-prod⟩.up.railway.app` | 🔘 DNS only | API backend (Railway prod) |
| CNAME | `staging-api` | `⟨service-staging⟩.up.railway.app` | 🔘 DNS only | API backend (Railway staging) |
| CNAME | `media` | *(créé par R2 « custom domain »)* | 🟠 Proxied | Médias (Cloudflare R2) |
| TXT | `@` | `v=spf1 include:_spf.resend.com ~all` | — | SPF (envoi via Resend) |
| TXT | `resend._domainkey` | `⟨DKIM fourni par Resend⟩` | — | DKIM (envoi) |
| TXT | `_dmarc` | `v=DMARC1; p=quarantine; rua=mailto:dmarc@gwouang-meu.com` | — | DMARC |
| MX | `@` | *(via Cloudflare Email Routing)* | — | Réception → transfert Gmail |

### Points d'attention par service

- **Vercel (landing)** : ajoute `gwouang-meu.com` et `www` dans *Vercel → Project → Domains*.
  Garde ces records **DNS only** (nuage gris) — Vercel gère son propre certificat.
- **Cloudflare Pages (app)** : le plus simple est *Pages → ton projet → Custom domains →
  Set up a domain* `app.gwouang-meu.com`. Le record est créé pour toi.
- **Railway (api / staging-api)** : *Railway → service → Settings → Networking → Custom
  Domain*. Railway affiche le **CNAME exact** à créer. Laisse-le **DNS only**.
- **R2 (media)** : *R2 → ton bucket → Settings → Custom Domains → Connect Domain*
  `media.gwouang-meu.com`. Record + certificat automatiques.
- **Email** : pour recevoir, active *Cloudflare → Email → Email Routing* (gratuit, transfère
  vers ta Gmail). Pour envoyer, colle les vrais SPF/DKIM que **Resend** te donne
  (le SPF ci-dessus est un modèle).

---

## 3. Automatisation

Deux options, au choix. Les deux ont besoin d'un **API Token Cloudflare** avec les
permissions : `Zone → DNS → Edit`, `Zone → Zone → Read`, et
`Zone → Config Rules/Dynamic Redirect → Edit` (pour les redirections).

### Option A — Script shell (recommandé, zéro dépendance de version)

```bash
cd infra/dns
cp config.example.env config.env
# édite config.env : token, account id, cibles Railway/Pages…
./setup-cloudflare-dns.sh
```

Le script :
- crée tous les enregistrements DNS du domaine canonique,
- pose une **redirection 301** de `.fr`, `.org`, `.cm` (racine + www) vers `gwouang-meu.com`,
- est **idempotent** (relançable sans créer de doublons).

### Option B — Terraform

```bash
cd infra/dns
cp terraform.tfvars.example terraform.tfvars   # remplis les valeurs
terraform init && terraform plan
terraform apply
```

Voir l'en-tête de `cloudflare.tf` pour la version du provider (les noms de ressources ont
changé entre v4 et v5).

---

## 4. Stratégie canonique + redirections

- **`gwouang-meu.com`** : sert la landing, `app.`, `api.`, `media.`, etc.
- **`gwouang-meu.fr` / `.org` / `.cm`** : redirection **301** (permanente) de
  `https://*.<tld>/*` → `https://gwouang-meu.com/$1`, racine **et** `www`.

Pourquoi 301 et pas 4 sites identiques : un seul site à maintenir, pas de pénalité SEO de
contenu dupliqué, et toute la valeur de référencement converge sur le canonique.

---

## 5. Changements de code (si adoption de `gwouang-meu` comme domaine produit)

Ton dépôt référence encore `gwangmeu.com`. À mettre à jour (surtout via variables
d'environnement de déploiement, une partie est déjà pilotée par env) :

- **Backend** `application.yml` / `application-prod.yml` : `CORS_ALLOWED_ORIGINS`,
  `application.base-url`, `application.mail-from`, `application.r2.public-url`.
- **Backend** `SwaggerConfig.java` : URL du serveur `https://api.gwangmeu.com`.
- **Landing** `next.config.js` : `images.remotePatterns` (`api.gwangmeu.com`), et les
  variables `NEXT_PUBLIC_API_URL` / `NEXT_PUBLIC_APP_URL` de déploiement.
- **CI** `.github/workflows/*` : URLs de healthcheck (`staging-api.gwangmeu.com`,
  `api.gwangmeu.com`) et nom du projet Pages.
- **Mobile** `.env` : `API_BASE_URL`.

> Demande-moi « migre le code vers gwouang-meu.com » et je fais toutes ces modifications
> d'un coup sur la branche de travail.
