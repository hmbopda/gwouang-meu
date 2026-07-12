# Domaines, DNS & sécurité — GWOUANG MEU

Domaine **canonique** : **`gwouangmeu.com`** (enregistré chez Cloudflare — registrar
+ DNS au même endroit). Tout passe par ce domaine et ses sous-domaines.

Domaines secondaires (`.fr`, `.org`, `.cm`, `gwouang-meu.com`) : **non achetés pour
l'instant**. Le jour où tu en prends, tu les ajoutes comme zone Cloudflare et ils
redirigent (301) vers le canonique — l'outillage est déjà prêt (`REDIRECT_DOMAINS`).

> ⚠️ Ton code applicatif pointe encore vers `gwangmeu.com` (sans « ou », sans tiret).
> Voir **« Bascule du code »** en bas — à faire pour que l'app réponde sur le nouveau
> domaine.

---

## 1. Ce qu'il te reste à faire (≈ 10 min)

Tu as déjà acheté le domaine. Il reste 3 étapes :

1. **Créer un API Token** : Cloudflare → *My Profile → API Tokens → Create Token*.
   Permissions : `Zone:Read`, `DNS:Edit`, `Zone Settings:Edit`, `DNSSEC:Edit`,
   `Dynamic Redirect:Edit`, toutes sur la zone `gwouangmeu.com`.
2. **Configurer et lancer les scripts** :
   ```bash
   cd infra/dns
   cp config.example.env config.env      # colle ton token + cibles Railway/Pages
   ./setup-cloudflare-dns.sh             # crée les enregistrements DNS
   ./harden-cloudflare.sh                # applique la sécurité (SSL, HSTS, DNSSEC…)
   ```
3. **Cocher 3 réglages** dans le dashboard (voir §3, non exposés par l'API en plan gratuit).

> Je n'ai pas accès à ton compte Cloudflare (et tu ne dois jamais me confier ton token).
> Ces scripts font le travail à ta place, tu ne fais que les lancer.

---

## 2. Enregistrements DNS (`gwouangmeu.com`)

Adapte les cibles `⟨…⟩` : Railway/Pages/R2/Vercel te donnent la valeur exacte quand tu
« connectes » le domaine dans leur interface.

| Type | Nom | Contenu | Proxy | Rôle |
|------|-----|---------|-------|------|
| A | `@` | `76.76.21.21` | 🔘 DNS only | Landing (Vercel, apex) |
| CNAME | `www` | `cname.vercel-dns.com` | 🔘 DNS only | Landing www (Vercel) |
| CNAME | `app` | `⟨projet⟩.pages.dev` | 🟠 Proxied | App Flutter Web (Cloudflare Pages) |
| CNAME | `api` | `⟨service-prod⟩.up.railway.app` | 🔘 DNS only | API backend (Railway prod) |
| CNAME | `staging-api` | `⟨service-staging⟩.up.railway.app` | 🔘 DNS only | API backend (Railway staging) |
| CNAME | `media` | *(créé par R2 « Custom Domain »)* | 🟠 Proxied | Médias (Cloudflare R2) |
| TXT | `@` | `v=spf1 -all` | — | SPF — **anti-usurpation** (personne n'envoie encore) |
| TXT | `_dmarc` | `v=DMARC1; p=reject; rua=mailto:dmarc@gwouangmeu.com` | — | DMARC — rejette les emails frauduleux |

### Connexions à faire dans chaque service (créent le record pour toi)
- **Vercel** : *Project → Domains* → ajoute `gwouangmeu.com` + `www`. Garde-les **DNS only**.
- **Cloudflare Pages** : *ton projet → Custom domains* → `app.gwouangmeu.com`.
- **Railway** : *service → Settings → Networking → Custom Domain* → il affiche le CNAME
  exact (à mettre **DNS only**).
- **R2** : *bucket → Settings → Custom Domains → Connect* → `media.gwouangmeu.com`.
- **Email entrant (plus tard)** : *Cloudflare → Email → Email Routing* (gratuit, transfère
  vers ta Gmail). Quand tu enverras via **Resend**, bascule SPF/DMARC + ajoute la DKIM
  (voir commentaires dans `config.example.env`).

---

## 3. Protection du domaine (`harden-cloudflare.sh` + dashboard)

Le script `harden-cloudflare.sh` applique automatiquement :

| Réglage | Valeur | Pourquoi |
|---------|--------|----------|
| SSL/TLS | **Full (Strict)** | chiffrement de bout en bout, pas de MITM |
| Always Use HTTPS | ON | tout HTTP → HTTPS |
| Automatic HTTPS Rewrites | ON | corrige les liens `http://` |
| Min TLS | **1.2** | refuse TLS 1.0/1.1 obsolètes |
| TLS 1.3 | ON | dernier protocole |
| HSTS | 1 an, sous-domaines inclus | force HTTPS côté navigateur |
| Security level | medium | filtrage des menaces |
| **DNSSEC** | active | **signe la zone — anti-empoisonnement DNS** |

À **cocher à la main** (non pilotables par l'API en plan gratuit) :

- **Registrar → Auto-renew : ON** — que le domaine n'expire jamais (la 1ʳᵉ protection).
- **Registrar → Domain Lock** (`clientTransferProhibited`) : ON — souvent déjà par défaut.
- **Registrar → WHOIS redaction** : ON — confidentialité, gratuit chez Cloudflare.
- **Security → Bots → Bot Fight Mode** : ON — gratuit, bloque les bots basiques.
- **(Plus tard) HSTS Preload** : ON une fois que 100 % du site est en HTTPS (peu réversible).

---

## 4. Automatisation — les deux options

Les deux ont besoin du même API Token (voir §1).

- **Scripts shell** (recommandé) : `setup-cloudflare-dns.sh` (DNS + redirections) et
  `harden-cloudflare.sh` (sécurité). Idempotents, relançables.
- **Terraform** : `cloudflare.tf` + `variables.tf`. Voir l'en-tête de `cloudflare.tf`
  pour la version du provider (v4 vs v5).

Fichiers :

| Fichier | Rôle |
|---------|------|
| `setup-cloudflare-dns.sh` | Crée les enregistrements DNS + redirections 301 |
| `harden-cloudflare.sh` | Applique SSL/TLS, HSTS, DNSSEC, sécurité |
| `cloudflare.tf` / `variables.tf` | Équivalent Terraform (optionnel) |
| `config.example.env` | Gabarit à copier en `config.env` |
| `terraform.tfvars.example` | Gabarit Terraform |

---

## 5. Bascule du code vers `gwouangmeu.com`

Le dépôt référence encore `gwangmeu.com`. À mettre à jour :

- **Backend** `application.yml` / `application-prod.yml` : `CORS_ALLOWED_ORIGINS`,
  `application.base-url`, `application.mail-from`, `application.r2.public-url`.
- **Backend** `SwaggerConfig.java` : URL du serveur.
- **Landing** `next.config.js` : `images.remotePatterns`, et `NEXT_PUBLIC_*` de déploiement.
- **CI** `.github/workflows/*` : URLs de healthcheck + nom du projet Pages.
- **Mobile** `.env` : `API_BASE_URL`.

> Demande « migre le code vers gwouangmeu.com » et je fais tout d'un coup sur la branche.
