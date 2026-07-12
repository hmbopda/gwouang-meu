# Branchement du domaine `gwouangmeu.com` (Cloudflare)

Domaine acheté chez **Cloudflare** → DNS **et** hébergement de l'app (Pages) au même endroit.
Le code/config est déjà aligné sur `gwouangmeu.com` (fait). Il reste des actions **dans tes
dashboards** (comptes authentifiés) — dans cet ordre.

Cible des sous-domaines :

| Sous-domaine | Pointe vers | Service |
|---|---|---|
| `gwouangmeu.com` | Landing (Next.js) | Vercel |
| `gwouangmeu.com` | App Flutter Web | Cloudflare Pages (`gwangmeu-app`) |
| `api.gwouangmeu.com` | Backend Spring | Cloud Run |
| `media.gwouangmeu.com` | Médias | Cloudflare R2 |
| *(envoi email)* | `send`, `resend._domainkey`, `_dmarc` | Resend (DNS Cloudflare) |

---

## 1. Email — Resend (priorité : c'est le but initial)

1. **Resend → Domains → Add Domain** : `gwouangmeu.com`. Resend affiche ~3 enregistrements :
   - `MX` sur `send.gwouangmeu.com` (+ `TXT` SPF `send`)
   - `TXT`/`CNAME` DKIM `resend._domainkey`
   - `TXT` DMARC `_dmarc` (reco `v=DMARC1; p=none;`)
2. **Cloudflare → gwouangmeu.com → DNS → Records** : ajouter chaque enregistrement Resend
   **à l'identique**. ⚠️ Mettre ces enregistrements en **DNS only** (nuage gris, pas orange).
3. Resend → **Verify** (quelques minutes).
4. **Resend → API Keys → Create** (scope *Sending*) → copier `re_...`.

> Colle-moi les valeurs DNS que Resend affiche : je te les remets formatées exactement pour Cloudflare.

---

## 2. Backend Cloud Run — variables

Définir sur le service `gwangmeu-backend` (region `europe-west1`). Recommandé : **API HTTP**
(pas de souci de port SMTP sur Cloud Run) :

```bash
# clé Resend en secret (recommandé)
printf '%s' 'REMPLACER_PAR_re_xxx' | gcloud secrets create resend-api-key --data-file=- \
  || printf '%s' 'REMPLACER_PAR_re_xxx' | gcloud secrets versions add resend-api-key --data-file=-

gcloud run services update gwangmeu-backend --region europe-west1 \
  --update-env-vars MAIL_PROVIDER=resend-api,MAIL_FROM=noreply@gwouangmeu.com,APP_BASE_URL=https://gwouangmeu.com \
  --update-secrets RESEND_API_KEY=resend-api-key:latest
```

*(Variante SMTP : `MAIL_PROVIDER=smtp`, `MAIL_PASSWORD` = la clé Resend, `MAIL_USERNAME=resend`,
`MAIL_HOST=smtp.resend.com`, `MAIL_PORT=465`.)*

---

## 3. Supabase Auth — Custom SMTP + redirections

**Dashboard Supabase → Project Settings → Authentication → SMTP** → *Enable Custom SMTP* :

| Champ | Valeur |
|---|---|
| Host / Port | `smtp.resend.com` / `465` |
| Username / Password | `resend` / `re_...` |
| Sender | `noreply@gwouangmeu.com` — `Gwang Meu` |

**Authentication → URL Configuration** :
- Site URL : `https://gwouangmeu.com`
- Redirect URLs : `https://gwouangmeu.com/auth-callback`, `io.supabase.gwangmeu://auth-callback`,
  `http://localhost:*/auth-callback`

**Authentication → Email Templates** : personnaliser *Confirm signup* + *Reset password*
(or `#D4A017`), garder `{{ .ConfirmationURL }}`.

---

## 4. App Flutter → `gwouangmeu.com` (Cloudflare Pages)

**Cloudflare → Workers & Pages → `gwangmeu-app` → Custom domains → Set up a custom domain**
→ `gwouangmeu.com`. Même compte Cloudflare → le CNAME est créé automatiquement.
*(Rien à changer côté code : `--base-href "/"` est déjà OK pour un domaine racine de sous-domaine.)*

---

## 5. Backend → `api.gwouangmeu.com` (optionnel, sinon l'URL run.app marche)

**Cloud Run → gwangmeu-backend → Manage custom domains → Add mapping** → `api.gwouangmeu.com`
→ Google fournit un enregistrement (CNAME `ghs.googlehosted.com`) → l'ajouter dans Cloudflare
(**DNS only**, nuage gris). Puis mettre `API_BASE_URL=https://api.gwouangmeu.com` dans le secret
GitHub + l'env Cloudflare Pages du build Flutter.

---

## 6. Landing → `gwouangmeu.com` (Vercel)

**Vercel → projet landing → Settings → Domains → Add** `gwouangmeu.com` (+ `www`).
Vercel donne un enregistrement (A `76.76.21.21` ou CNAME) → l'ajouter dans Cloudflare.
Mettre `NEXT_PUBLIC_SITE_URL=https://gwouangmeu.com`, `NEXT_PUBLIC_APP_URL=https://gwouangmeu.com`
dans les env Vercel.

---

## 7. Médias → `media.gwouangmeu.com` (optionnel)

**Cloudflare → R2 → bucket `gwangmeu-media` → Settings → Custom Domains → Connect** `media.gwouangmeu.com`.
Puis `R2_PUBLIC_URL=https://media.gwouangmeu.com` sur Cloud Run.

---

## Vérification finale

- [ ] Resend « Verified ». Test d'inscription → email confirmation depuis `noreply@gwouangmeu.com`.
- [ ] `gwouangmeu.com` ouvre l'app ; reset mot de passe → retour dans l'app.
- [ ] Table `email_logs` : lignes `success=true`.
- [ ] [mail-tester.com](https://www.mail-tester.com) ≥ 9/10.

> Voir aussi `docs/EMAIL_SETUP.md` (détail moteur email).
