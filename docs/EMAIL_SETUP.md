# Emails GWANG MEU — moteur unique (Resend)

Objectif : **un seul moteur transactionnel (Resend) + un seul domaine vérifié**, utilisé aux
deux endroits qui envoient des emails :

1. **Backend Spring Boot** (`EmailService`) → invitations, bienvenue, unions, dissolutions,
   associations d'enfant, invitation village.
2. **Supabase Auth** (Custom SMTP) → confirmation d'inscription, réinitialisation de mot de
   passe, magic link.

```
 Emails AUTH  (Supabase) ──┐
                           ├── Resend (domaine vérifié : SPF / DKIM / DMARC) ──▶ boîte de réception
 Emails APP   (backend)  ──┘
```

> Tant que < 3 000 emails/mois et < 100/jour : **gratuit** (Resend free tier + Supabase free).

---

## 1. Créer / vérifier le domaine dans Resend

1. Posséder un domaine (ex. `gwouangmeu.com`). Recommandé : **Cloudflare Registrar** (tu es déjà
   sur Cloudflare pour Pages → DNS au même endroit, prix coûtant).
2. [Resend](https://resend.com) → **Domains → Add Domain** → saisir le domaine.
3. Resend affiche 3 enregistrements DNS à créer chez ton registrar (Cloudflare DNS) :
   - **SPF** (TXT sur `send.` ou racine) — autorise Resend à envoyer pour le domaine.
   - **DKIM** (TXT/CNAME `resend._domainkey`) — signature cryptographique.
   - **DMARC** (TXT `_dmarc`) — politique recommandée : `v=DMARC1; p=none; rua=mailto:...`.
4. Coller les enregistrements → **Verify** (propagation quelques minutes).
5. **API Keys → Create API Key** (scope *Sending*) → copier `re_...` (secret, une seule fois).

> Sans domaine vérifié, Resend force l'expéditeur `onboarding@resend.dev` **et** ne livre
> qu'à l'adresse propriétaire du compte (mode test). Le domaine est donc requis pour la prod.

---

## 2. Backend (Cloud Run) — variables d'environnement

Le backend est déjà configuré pour Resend (`application-prod.yml` + `application.yml`).
Définir sur le service Cloud Run :

| Variable | Valeur | Note |
|---|---|---|
| `MAIL_FROM` | `noreply@gwouangmeu.com` | adresse **du domaine vérifié** |
| `MAIL_PASSWORD` | `re_xxx` | la clé API Resend |
| `MAIL_HOST` | `smtp.resend.com` | (défaut, sinon inutile) |
| `MAIL_PORT` | `465` | (défaut) |
| `MAIL_USERNAME` | `resend` | (défaut) |
| `APP_BASE_URL` | `https://gwouangmeu.com` | base des liens dans les emails |

### Option robuste : API HTTP au lieu du SMTP (recommandé sur Cloud Run)

Cloud Run peut restreindre le SMTP sortant. Pour utiliser l'**API HTTP Resend** (aucun port
SMTP) au lieu du transport SMTP :

| Variable | Valeur |
|---|---|
| `MAIL_PROVIDER` | `resend-api` |
| `RESEND_API_KEY` | `re_xxx` |
| `MAIL_FROM` | `noreply@gwouangmeu.com` |

Le code choisit automatiquement le bon transport (`EmailSender` : `SmtpEmailSender` par
défaut, `ResendApiEmailSender` si `MAIL_PROVIDER=resend-api`).

> Chaque envoi est tracé dans la table `email_logs` (destinataire, type, sujet, provider,
> succès, erreur) — utile pour diagnostiquer les non-livraisons.

---

## 3. Supabase Auth — Custom SMTP (emails de vérification / reset)

Par défaut Supabase envoie via son propre service (bridé ~2–4/h, domaine partagé → spam).
Pour router ces emails via **ton** Resend :

**Dashboard Supabase → Project Settings → Authentication → SMTP Settings → Enable Custom SMTP**

| Champ | Valeur |
|---|---|
| Host | `smtp.resend.com` |
| Port | `465` |
| Username | `resend` |
| Password | `re_xxx` (clé API Resend) |
| Sender email | `noreply@gwouangmeu.com` |
| Sender name | `Gwang Meu` |

### Templates (Authentication → Email Templates)

Personnaliser au minimum **Confirm signup** et **Reset password** aux couleurs Gwang Meu
(or `#D4A017`, fond crème). Garder les variables Supabase `{{ .ConfirmationURL }}`.

### Redirect URLs (Authentication → URL Configuration)

Autoriser les URL de retour utilisées par l'app (deep links P2) :

- **Site URL** : `https://gwouangmeu.com`
- **Redirect URLs** (ajouter chacune) :
  - `https://gwouangmeu.com/auth-callback`
  - `io.supabase.gwangmeu://auth-callback` *(mobile)*
  - `http://localhost:*/auth-callback` *(dev web)*

---

## 4. Vérification

- [ ] Domaine « Verified » dans Resend (SPF/DKIM/DMARC verts).
- [ ] Backend : créer un compte test → email **de bienvenue** reçu ; inviter dans un village →
      email **invitation village** reçu ; ligne(s) correspondante(s) dans `email_logs` (`success=true`).
- [ ] Supabase : inscription → email de **confirmation** reçu depuis `noreply@gwouangmeu.com` (pas
      Supabase) → clic → retour dans l'app (`/auth-callback`).
- [ ] Reset mot de passe → email reçu → clic → écran « nouveau mot de passe » dans l'app.
- [ ] Vérifier la **délivrabilité** (pas en spam) — [mail-tester.com](https://www.mail-tester.com).

---

## Récap des emails couverts

| Email | Émetteur | Déclencheur |
|---|---|---|
| Confirmation d'inscription | Supabase (SMTP Resend) | signUp |
| Réinitialisation mot de passe | Supabase (SMTP Resend) | resetPassword |
| Bienvenue | Backend | `UserCreatedEvent` |
| Invitation arbre (généalogie) | Backend | `PersonInvitationService` |
| Invitation village | Backend | `VillageInvitationService` |
| Union / Divorce / Décès / Association enfant | Backend | événements généalogie |
