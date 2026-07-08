# ADR-002 — Web Services de vérification pour services publics / organisations

> **Statut : FONDATION (à poser, pas à construire maintenant).**
> Décision : concevoir et réserver l'espace technique d'une API partenaire de
> vérification généalogique, **sans exposer d'endpoint** tant qu'un partenaire
> réel et un cadre RGPD/consentement validé juridiquement n'existent pas.
> Exposer des données de filiation à des tiers est le point le plus sensible
> du produit — on n'ouvre rien avant que *consentement + audit + minimisation*
> soient en place.

Date : 2026-07-08. Issu d'une étude dédiée (état de l'art + standards).

---

## 1. Cas d'usage (B2B / secteur public)

| Partenaire | Vérification | Réponse attendue |
|---|---|---|
| Mairie / état civil | Filiation pour acte de notoriété, succession | `VERIFIED` / `NOT_VERIFIED` / `INSUFFICIENT_CONSENT` |
| Consulat / immigration | Nationalité par ascendance | booléen + degré de chaîne, **sans** exposer les identités |
| Notaire | Existence/validité d'une union, dévolution successorale | booléen + statut de conformité |
| Autorité coutumière / clan | Appartenance à un clan / totem | booléen strict |
| Organisme culturel | Existence d'un acte de dot (patrimoine) | booléen (jamais le montant ni les témoins) |

**Principe** : renvoyer *« vérifié / non vérifié »* plutôt que des données brutes.

---

## 2. Architecture cible

- **Module backend dédié et isolé** : `com.gwangmeu.partner` (⚠️ **ne pas**
  l'appeler `verification` — un module `frontend/lib/features/genealogy/verification/`
  existe déjà pour un tout autre usage : la confirmation de suggestion IA vers
  l'arbre. Éviter la collision conceptuelle).
- Le module consomme `genealogy` **en lecture seule** et réutilise
  `PrivacyFilter` (déjà en place, cf. ADR filiation privée) comme moteur de
  minimisation : un partenaire = un `ViewerContext` borné au strict scope consenti.
- **2ᵉ chaîne de sécurité** `SecurityFilterChain @Order(1)` sur `/api/partner/**`,
  distincte de la chaîne JWT Supabase existante.
- `ApiResponse<T>` réutilisé pour l'uniformité ; groupe OpenAPI séparé
  `partner-api` dans `SwaggerConfig`.
- **Numérotation Flyway réservée : V41+** (les migrations sont déjà à V40 après
  le lot polygamie ; l'étude initiale citait « V20 », périmé).

## 3. Sécurité (défense en profondeur)

1. **Transport** — mTLS obligatoire sur `/api/partner/**`, certificat client
   épinglé (thumbprint sur `Partner`).
2. **Authentification** — OAuth2 *client-credentials* (token court 5–15 min, lié
   au certificat : *certificate-bound token*). Bootstrap possible via **API key
   hashée (argon2/bcrypt)** avec préfixe visible non secret ; **jamais** la clé
   en clair en base.
3. **Autorisation** — scopes granulaires par clé : `filiation:verify`,
   `union:verify`, `dot:verify`, `nationality:verify`, `clan:verify`,
   `consent:request`. Vérifiés via `@PreAuthorize` (rôle `API` de `GwangMeuRole`,
   déjà présent). Aucun accès en écriture au graphe.
4. **Quotas & rate-limiting** — sur Redis (déjà configuré) : quota mensuel par
   clé + rate-limit par minute → `429` au dépassement.
5. **Minimisation (RGPD art. 5.1.c)** — réponses booléennes par défaut ; jamais
   l'arbre, jamais les identités de la chaîne, jamais le montant de dot. Personnes
   **vivantes sans consentement** → `INSUFFICIENT_CONSENT`.

## 4. Consentement (RGPD art. 6/7, retrait art. 7.3, transparence art. 13-15)

- La personne concernée **autorise explicitement** chaque vérification :
  `VerificationConsent { personId, partnerId, scope, purpose, grantedAt, expiresAt, proofChannel }`.
- **Horodatage de bout en bout** : octroi, chaque vérification, révocation —
  journal *append-only* formant la piste d'audit.
- **Révocation immédiate** côté membre (`DELETE /consents/{id}`) → effet instantané.
- **Transparence** : le membre consulte ses consentements + le journal des
  vérifications effectuées sur ses données (`GET /consents`).
- **Base légale** : consentement pour les vivants ; pour les personnes décédées
  (mémoire généalogique partagée), intérêt légitime encadré **à valider par un
  juriste par finalité**.

## 5. Endpoints (par ordre de valeur, quand le module démarrera)

Côté **partenaire** (`/api/partner/v1/**`, mTLS + OAuth2) :
- `POST /verify/filiation` — « X est-il enfant de Y ? » → booléen *(à livrer en premier)*
- `POST /verify/union` — existence/validité d'une union → booléen + conformité
- `POST /verify/dot` — existence d'un acte de dot → booléen *(différenciateur culturel)*
- `POST /verify/nationality` — nationalité par ascendance → booléen + degré
- `POST /verify/clan-membership` — appartenance clan/totem → booléen
- `POST /consent/requests` — demande de consentement adressée à la personne
- `GET /consent/{id}` — statut d'un consentement

Côté **membre** (chaîne JWT Supabase existante) :
- `POST /api/v1/genealogy/consents` — accorder un consentement (scope, finalité, durée)
- `DELETE /api/v1/genealogy/consents/{id}` — révoquer (droit de retrait)
- `GET /api/v1/genealogy/consents` — mes consentements + journal d'accès

Côté **admin** (`SUPER_ADMIN`) :
- `POST /api/partner/admin/partners` — onboarding partenaire (KYC), clés scoped, quotas
- `DELETE /api/partner/admin/keys/{id}` — révocation de clé

## 6. Extension différée — Verifiable Credentials

Interface `VerifiableCredentialIssuer` + endpoint `POST /credentials/issue`
**en `501 Not Implemented`** derrière un feature-flag : à terme, émettre une
**W3C Verifiable Credential 2.0 à divulgation sélective (SD-JWT)** consommable
par un *EUDI Wallet* (aligné **eIDAS 2.0**), pour que la personne détienne et
re-présente ses attestations sans interroger systématiquement GWANG MEU.
**À ne pas prototyper** tant que `/verify/filiation` et `/verify/union` n'ont
pas prouvé un usage réel.

## 7. Pré-requis avant tout développement

1. Un **premier partenaire concret** engagé (mairie / consulat / notaire / clan).
2. Un **avis juridique** sur la base légale (surtout personnes décédées) et le
   libellé de consentement, par finalité.
3. Le **PrivacyFilter** de filiation en production (déjà livré) comme socle de
   minimisation.
4. Décision produit : périmètre géographique et **disclaimer** (cf. lot polygamie).

> Tant que ces conditions ne sont pas réunies, on garde uniquement : le rôle
> `API` existant, `PrivacyFilter` générique, la numérotation Flyway V41+ réservée,
> et le nom de package `partner` retenu.
