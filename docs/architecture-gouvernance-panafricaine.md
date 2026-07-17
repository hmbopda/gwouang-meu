# Architecture — Leadership & notabilité des chefferies (panafricain)

> Spec de conception (workflow multi-experts, 2026-07-16). Source de vérité pour l'implémentation de la fondation dynamique (migrations V59+). Ne pas coder en dur de titre/culture : tout est data-driven.

---

# Architecture cible — Leadership & notabilité des chefferies
## Modèle générique, dynamique et performant pour toute l'Afrique

> **Note de réconciliation (vérifiée sur le schéma réel).** Les quatre conceptions convergent à ~85 %. Là où elles divergeaient, j'ai tranché sur le code : dans ce dépôt **toutes les PK sont `UUID DEFAULT gen_random_uuid()`** (`villages`, `users`, `chefferies`, `village_chiefs`, `village_member_roles` — vérifié V3/V44/V49/V53). Donc **on écrit tout en UUID** — le `BIGSERIAL`/`BIGINT` de deux propositions est écarté. `CHAR(2)` est réservé au seul `country_iso2`, VARCHAR partout ailleurs. Les migrations existantes vont jusqu'à **V58** → la première libre est **V59**. Et un blocage concret confirmé : `chefferies.degre` est `SMALLINT NOT NULL` (V44:50) — infranchissable pour tout pays hors Cameroun.

---

## 1. Le principe

La gouvernance traditionnelle est une **donnée configurable, jamais du code**. On cesse de modéliser « un chef » (couronne + or + « Sa Majesté » par défaut = ethnocentrisme codé en dur) pour modéliser **une institution politique qui instancie un archétype de gouvernance et se peuple de détentions de charges**. Le code Java/Dart ne connaît que des **attributs de comportement** (`is_apex`, `authority_model`, `head_cardinality`) — jamais un nom de culture ni une énumération de titres. Neutralité culturelle **et** performance viennent de la même idée : la structure est partagée par **archétype** (quelques centaines de templates pour tout le continent), pas dupliquée par chefferie (des centaines de milliers).

---

## 2. Le méta-modèle — les dimensions qui varient

Toute la diversité observée (Bamiléké : Fɔ' sacré + notables *mkem* + société régulatrice *kwifɔ* qui **limite** le chef + reine-mère *mafo* ; Yoruba : Oba + collège de faiseurs de rois + *Iyalode* ; Akan : chef **destituable** intronisé sur le tabouret d'or, porte-parole *okyeame* obligatoire, reine-mère qui **désigne** en régime **matrilinéaire** ; Sahel : *Lamido/Sultan* + cour de titres ; Igbo **acéphale** : « *Igbo enwe eze* », conseil d'anciens ; Oromo *Gada* : pouvoir **rotatif tous les 8 ans** ; Swazi : **dyarchie** roi + reine-mère) se ramène à un jeu **fini** de dimensions. Chacune est une **colonne ou une ligne**, jamais un `if`.

| Dimension | Valeurs | Où c'est stocké |
|---|---|---|
| **D1 — Cardinalité de la tête** | 0 (acéphale), 1 (monarchie), 2 (dyarchie genrée) | `governance_models.head_cardinality` |
| **D2 — Modèle d'autorité** | `MONOCEPHALIC`, `DYARCHIC`, `COLLEGIAL`, `ROTATING`, `ACEPHALOUS` | `governance_models.authority_model` |
| **D3 — Registre de sacralité / honorifique** | `SACRED`, `ROYAL`, `RELIGIOUS`, `RESPECT`, `CIVIL`, `NONE` | `governance_models.sacrality` + `honorific_style` |
| **D4 — Chef ou pas** | présence/absence d'une charge `is_apex` | `governance_titles.is_apex` (0 → conseil rendu comme autorité 1ʳᵉ classe) |
| **D5 — Titres multilingues + forme d'adresse** | « Fɔ' », « Oba », « Lamiiɗo », « Nana »… | `governance_title_labels(locale, label, honorific)` |
| **D6 — Notables & rangs** | hiérarchie ordonnée / conseil égalitaire / « les 9 notables » | `governance_titles.rank` + `card_min/card_max` |
| **D7 — Fonctions spécialisées** | porte-parole, chef de guerre, gardien, société de régulation, cheffe des femmes | `governance_titles.role_kind` → `role_kinds` |
| **D8 — Succession** | patrilinéaire, **matrilinéaire**, désignation, élection collégiale, divination, **rotation**, nomination | `governance_titles.succession` + `designating_title_code` |
| **D9 — Révocabilité / contre-pouvoirs** | destitution akan, sanction du *kwifon* vs absolutisme | `governance_models.revocable` + charge `role_kind=REGULATORY` |
| **D10 — Accès** | médiatisé (porte-parole obligatoire) vs direct | `governance_titles.mediates_head` |
| **D11 — Genre** | charge réservée F / M / ouverte ; charges féminines parallèles | `governance_titles.gender_rule` |
| **D12 — Lignéarité** | patrilinéaire, **matrilinéaire**, bilatérale, cognatique | `governance_models.lineality` (remplace le figement de `VillageValidationKind`) |
| **D13 — Regalia** | couronne perlée, **tabouret d'or**, turban, peau de léopard, aucune | `governance_models.regalia_key` → token de rendu |
| **D14 — Temporalité du mandat** | à vie, durée fixe (Gada 8 ans), révocable | `village_office_holders.term_start/term_end` + `rotation_years` |
| **D15 — Aire culturelle ≠ frontière** | Yoruba (NG+BJ+TG), Akan (GH+CI), Peul (Sahel) | `governance_models.scope_type=ETHNIC` prime sur `country_iso2` |
| **D16 — Provenance** | coutumier attesté, inféré, déclaré-communauté, **fabriqué colonial** | `source` sur chefferie/titulaires (jamais faire passer inféré pour attesté) |

---

## 3. Le schéma de données

Trois étages : **(A) référentiel/template** partagé par aire culturelle (curé, quasi-immuable) → **(B) liaison + surcharge** par chefferie/village → **(C) instances vivantes** (sièges + titulaires) éditables. Migrations **V59 → V63**.

### Règle normalisé vs JSONB
- **Tables normalisées** pour tout ce qui est **joint, contraint ou recherché** : identité, hiérarchie, rangs, titulaires, permissions, **et les libellés i18n**.
- **`config JSONB`** (natif Hibernate 6.5 via `@JdbcTypeCode(SqlTypes.JSON)`, aucune lib) pour la **longue traîne hétérogène lue en bloc** : détail des règles de succession, tabous, composition du conseil, classification nationale brute (MINAT `degre`/`acte`).
- **i18n = table `*_labels(entity_id, locale, …)`, PAS une map JSONB.** Motif tranché : réutilise l'index **GIN trigram** déjà en place (V44:64-71) pour un typeahead multilingue accent-insensible (« fon », « lamido », « oba »), garde l'intégrité FK, et ajouter une langue = un `INSERT`, pas un `ALTER`.

### A. Le catalogue de templates (V59) — le socle réutilisable

```sql
-- V59__governance_meta_model.sql
-- Vocabulaire de fonctions = TABLE extensible (jamais une enum Java) :
-- ajouter « Abba Gada » oromo = un INSERT. Le Java branche sur les flags, pas le code.
CREATE TABLE role_kinds (
    code             VARCHAR(40) PRIMARY KEY,   -- HEAD, CO_HEAD, REGENT, SPOKESPERSON, COUNCIL_ELDER,
    is_executive     BOOLEAN NOT NULL DEFAULT FALSE, -- NOTABLE, QUEEN_MOTHER, WAR_LEADER, REGULATORY,
    is_ceremonial    BOOLEAN NOT NULL DEFAULT FALSE, -- HERALD, PRIEST, WOMEN_LEADER, TITLE_HOLDER…
    is_apex_capable  BOOLEAN NOT NULL DEFAULT FALSE,
    is_regulatory    BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE governance_models (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code             VARCHAR(80) NOT NULL,           -- 'grassfields_fondom','fulani_lamidat','yoruba_obaship',
    version          INTEGER NOT NULL DEFAULT 1,      -- 'akan_stool','igbo_council','gada_generational','generic_council'
    scope_type       VARCHAR(20) NOT NULL,           -- ETHNIC | COUNTRY | REGION | GLOBAL
    scope_key        VARCHAR(80),                    -- 'bamileke' | 'CM' | 'Grassfields'…
    country_iso2     CHAR(2),                        -- NULL = transnational (aire culturelle)
    authority_model  VARCHAR(20) NOT NULL DEFAULT 'MONOCEPHALIC',
    head_cardinality SMALLINT   NOT NULL DEFAULT 1,  -- 0 = ACÉPHALE (défaut sûr)
    sacrality        VARCHAR(20) NOT NULL DEFAULT 'POLITICAL',
    honorific_style  VARCHAR(20) NOT NULL DEFAULT 'RESPECT', -- NONE|RESPECT|ROYAL|RELIGIOUS|IMPERIAL
    lineality        VARCHAR(20) NOT NULL DEFAULT 'PATRILINEAL',
    revocable        BOOLEAN NOT NULL DEFAULT FALSE,
    access_mediated  BOOLEAN NOT NULL DEFAULT FALSE,
    regalia_key      VARCHAR(40) NOT NULL DEFAULT 'none',
    theme_token      VARCHAR(40) NOT NULL DEFAULT 'gov.neutral',
    rotation_years   SMALLINT,                       -- Gada = 8 ; NULL = à vie
    status           VARCHAR(16) NOT NULL DEFAULT 'PUBLISHED', -- DRAFT|PUBLISHED|DEPRECATED
    is_default       BOOLEAN NOT NULL DEFAULT FALSE,
    config           JSONB NOT NULL DEFAULT '{}'::jsonb,  -- succession détaillée, tabous, conseil…
    checksum         VARCHAR(64) NOT NULL,           -- sha256(config) → clé de cache + ETag
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_gov_model UNIQUE (code, version)
);
-- Un seul défaut par pays (et un seul défaut GLOBAL où country_iso2 IS NULL) :
CREATE UNIQUE INDEX ux_gov_model_default
    ON governance_models (COALESCE(country_iso2,'~~'))
    WHERE is_default AND status='PUBLISHED';

-- LE CŒUR : la structure de leadership, en lignes.
CREATE TABLE governance_titles (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id       UUID NOT NULL REFERENCES governance_models(id) ON DELETE CASCADE,
    code           VARCHAR(60) NOT NULL,             -- 'head','queen_mother','spokesperson','notable',
    role_kind      VARCHAR(40) NOT NULL REFERENCES role_kinds(code), -- 'council_elder','regulatory_society'…
    tier           SMALLINT NOT NULL DEFAULT 0,      -- 0 apex, 1 haut conseil, 2 notables…
    rank           SMALLINT NOT NULL DEFAULT 100,    -- préséance intra-tier
    is_apex        BOOLEAN NOT NULL DEFAULT FALSE,
    card_min       SMALLINT NOT NULL DEFAULT 0,
    card_max       SMALLINT,                         -- 1 = siège unique ; NULL = illimité (classe de notables)
    gender_rule    VARCHAR(10) NOT NULL DEFAULT 'ANY' CHECK (gender_rule IN ('ANY','MALE','FEMALE')),
    mediates_head  BOOLEAN NOT NULL DEFAULT FALSE,   -- canal d'accès obligatoire (okyeame)
    succession     VARCHAR(24),                      -- HEREDITARY_PATRILINEAL|HEREDITARY_MATRILINEAL|
                                                     -- DESIGNATED|ELECTED|DIVINED|ROTATING|APPOINTED
    designating_title_code VARCHAR(60),              -- QUI désigne (queen_mother, kingmakers…)
    regalia_key    VARCHAR(40),                      -- insigne (donnée, pas 👑 codé)
    perm_bundle    VARCHAR(300) NOT NULL DEFAULT '', -- CSV de VillagePermission par défaut
    config         JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_gov_title UNIQUE (model_id, code)
);
CREATE INDEX idx_gtitle_model ON governance_titles(model_id, tier, rank);
CREATE UNIQUE INDEX ux_gtitle_apex ON governance_titles(model_id) WHERE is_apex; -- au plus un sommet/modèle

-- i18n NORMALISÉE + typeahead multilingue.
CREATE TABLE governance_title_labels (
    title_id  UUID NOT NULL REFERENCES governance_titles(id) ON DELETE CASCADE,
    locale    VARCHAR(20) NOT NULL,                  -- BCP-47 : 'bbj','yo','ha','ff','fr','en'
    label     VARCHAR(120) NOT NULL,                 -- 'Fɔ'','Oba','Laamiiɗo','Chef supérieur'
    honorific VARCHAR(120),                          -- 'Sa Majesté' | 'Notable' | NULL (défaut neutre)
    description TEXT,
    PRIMARY KEY (title_id, locale)
);
CREATE INDEX idx_gtitle_label_trgm ON governance_title_labels USING GIN (label gin_trgm_ops);
```
> `governance_models` a sa propre table `governance_model_labels(model_id, locale, label)` sur le même patron.

### B. Extraction du titre + liaison chefferie (V60) — décomposer `denomination`

La regex figée `ChefferieDto.java:33-35` (qui **jette** « Lamidat de », « Sultanat », « Canton ») devient une **table seedée** — et le préfixe est capturé comme **titre de tête inféré**, jamais perdu.

```sql
-- V60__title_lexicon_and_chefferie_link.sql
CREATE TABLE title_lexicon (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    country_iso2   CHAR(2) NOT NULL,
    match_kind     VARCHAR(8) NOT NULL DEFAULT 'PREFIX' CHECK (match_kind IN ('PREFIX','SUFFIX','REGEX','EXACT')),
    pattern        VARCHAR(200) NOT NULL,            -- 'lamidat de','sultanat de','canton','groupement'…
    infers_title   VARCHAR(60),                      -- titre de tête déduit : 'lamido','sultan','fon','oba'
    model_code     VARCHAR(80),                      -- template suggéré
    priority       INTEGER NOT NULL DEFAULT 100      -- plus long/spécifique d'abord
);
CREATE INDEX idx_title_lexicon_country ON title_lexicon(country_iso2, priority DESC);

-- Liaison + décomposition ADDITIVE (on ne supprime rien : provenance MINAT conservée).
ALTER TABLE chefferies
  ADD COLUMN governance_model_id UUID REFERENCES governance_models(id),
  ADD COLUMN apex_title_code     VARCHAR(60),        -- titre STRUCTURÉ (fini la regex runtime)
  ADD COLUMN proper_name         VARCHAR(250),       -- 'Tibati' (dénomination sans le titre)
  ADD COLUMN admin_level         SMALLINT,           -- rang générique multi-pays (remplace le concept 'degre')
  ADD COLUMN classification      JSONB NOT NULL DEFAULT '{}'::jsonb, -- {minat:{degre,acte}} — brut national
  ADD COLUMN department_id       UUID REFERENCES geo_departments(id), -- vraie FK (jointure indexée)
  ADD COLUMN region_id           UUID REFERENCES geo_regions(id),
  ADD COLUMN source              VARCHAR(32),        -- 'MINAT-CM','NG-NASS'…
  ADD COLUMN source_ref          VARCHAR(120),       -- clé naturelle du dataset → import idempotent
  ADD COLUMN title_source        VARCHAR(16);        -- IMPORTED|INFERRED|MANUAL
ALTER TABLE chefferies ALTER COLUMN degre DROP NOT NULL;  -- ⚠ DÉBLOQUE l'import non-CM
CREATE UNIQUE INDEX ux_chefferies_source ON chefferies(country_iso2, source, source_ref) WHERE source_ref IS NOT NULL;
CREATE INDEX idx_chefferies_model ON chefferies(governance_model_id);
```
> Entité `Chefferie.java` : `degre` → `nullable = true`, `classification` mappée `@JdbcTypeCode(SqlTypes.JSON)`. Colonnes MINAT (`degre`, `acte`, `region_name`) **conservées** = provenance.

### C. Instances vivantes par village (V61) — généralise `village_chiefs`

`village_chiefs` (V53) est propre mais **plafonné à la seule tête**. On le généralise à **n'importe quelle charge** (Fɔ', Mafo, les 9 notables, okyeame), chacune avec **son propre invariant « un titulaire courant »**.

```sql
-- V61__village_governance_instances.sql
CREATE TABLE village_governance (               -- en-tête d'instance (surcharge locale du template)
    village_id       UUID PRIMARY KEY REFERENCES villages(id) ON DELETE CASCADE,
    model_id         UUID REFERENCES governance_models(id),  -- template adopté (NULL = sur-mesure)
    authority_model  VARCHAR(20) NOT NULL,
    locale_primary   VARCHAR(20) NOT NULL DEFAULT 'fr',      -- langue des titres de CETTE chefferie
    honorific_style  VARCHAR(20) NOT NULL DEFAULT 'RESPECT',
    theme_token      VARCHAR(40) NOT NULL DEFAULT 'gov.neutral',
    version          INTEGER NOT NULL DEFAULT 1,             -- bumpé à chaque écriture → clé de cache
    is_published     BOOLEAN NOT NULL DEFAULT FALSE,
    updated_by       UUID, updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE village_offices (                  -- sièges matérialisés depuis le template, puis éditables
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    village_id    UUID NOT NULL REFERENCES villages(id) ON DELETE CASCADE,
    title_id      UUID REFERENCES governance_titles(id) ON DELETE SET NULL, -- soft-ref au catalogue
    office_key    VARCHAR(60) NOT NULL,          -- 'head','queen_mother','notable'…
    label_override VARCHAR(120),                 -- surcharge par chefferie
    tier          SMALLINT NOT NULL DEFAULT 0,
    rank          SMALLINT NOT NULL DEFAULT 100,
    is_apex       BOOLEAN NOT NULL DEFAULT FALSE,
    card_min      SMALLINT NOT NULL DEFAULT 0,
    card_max      SMALLINT,                       -- 1 = trône ; NULL = classe de notables
    perm_bundle   VARCHAR(300) NOT NULL DEFAULT '',
    succession    VARCHAR(24),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_voffice_village ON village_offices(village_id, tier, rank);
CREATE UNIQUE INDEX ux_voffice_apex ON village_offices(village_id) WHERE is_apex;

-- Titulaires : généralise village_chiefs (le chef courant = titulaire du siège apex) ET les notables.
CREATE TABLE village_office_holders (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    office_id     UUID NOT NULL REFERENCES village_offices(id) ON DELETE CASCADE,
    village_id    UUID NOT NULL REFERENCES villages(id) ON DELETE CASCADE, -- dénormalisé (requête directe)
    user_id       UUID REFERENCES users(id) ON DELETE SET NULL,  -- NULL = titulaire historique sans compte
    display_name  VARCHAR(200) NOT NULL,
    title_label   VARCHAR(120),                   -- snapshot du libellé résolu → historique stable
    gender        VARCHAR(12),                    -- rend visibles les titulaires femmes
    term_start    INTEGER, term_end INTEGER,      -- ex-reign_* (règne OU mandat)
    is_current    BOOLEAN NOT NULL DEFAULT FALSE,
    ordinal       INTEGER NOT NULL DEFAULT 0,     -- « 12ᵉ du nom »
    avatar_url    VARCHAR(500), note TEXT,
    source        VARCHAR(20) NOT NULL DEFAULT 'HERITAGE_CURATED', -- vs COMMUNITY_DECLARED / COLONIAL_APPOINTED
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_voh_village ON village_office_holders(village_id, is_current);
-- Généralise ux_vchief_current : au plus un titulaire courant PAR SIÈGE.
CREATE UNIQUE INDEX ux_voh_current ON village_office_holders(office_id) WHERE is_current;

-- village_member_roles.title (texte libre, acquis à garder) devient OPTIONNELLEMENT typé :
ALTER TABLE village_member_roles ADD COLUMN title_id UUID REFERENCES governance_titles(id);
```

### D. Snapshot dénormalisé sur `villages` (le levier perf n°1)

```sql
ALTER TABLE villages
  ADD COLUMN gov_authority_model  VARCHAR(20),
  ADD COLUMN gov_apex_holder      VARCHAR(200),   -- nom du titulaire apex courant (NULL = vacant)
  ADD COLUMN gov_apex_title       VARCHAR(120),   -- titre résolu en locale_primary ('Fɔ'','Laamiiɗo')
  ADD COLUMN gov_apex_user_id     UUID,
  ADD COLUMN gov_apex_avatar      VARCHAR(500),
  ADD COLUMN gov_theme_token      VARCHAR(40),
  ADD COLUMN gov_honorific        VARCHAR(60),
  ADD COLUMN gov_apex_is_vacant   BOOLEAN NOT NULL DEFAULT TRUE;
```
Maintenu à l'écriture d'un titulaire apex (même patron que `member_count`), via trigger ou service. Toute liste de villages renvoie le chef **inline, 0 requête** → le N+1 `chief()` disparaît.

---

## 4. Performance à l'échelle du continent

1. **Indirection par template = déduplication massive.** 13 190 chefferies CM → ~15 templates ; tout le continent → ~200-400. La structure est **O(templates)**, jamais O(chefferies) ; chaque chefferie ne stocke qu'une FK.
2. **Snapshot `villages.gov_apex_*` (gain dominant).** Listes/feed/hub avec le chef en **une requête indexée**, zéro jointure de gouvernance, N+1 HTTP éliminé.
3. **Cache — activer Redis sur la gouvernance** (aujourd'hui `@EnableCaching` **absent**, cache limité à traduction + rate-limit). Ajouter **Caffeine** (1 dépendance) en L1 in-JVM + garder **Redis Upstash** en L2 inter-pods :
   - `@Cacheable` sur les couches quasi-immuables : `governance_models`, `governance_titles`, `governance_title_labels`, `title_lexicon`, `role_kinds` (TTL heures).
   - `GovernanceView` caché par clé **`gov:{villageId}:{version}:{locale}`** ; on **bumpe `version`** à chaque écriture → l'ancienne clé devient orpheline et expire (invalidation sans course, **sans fan-out** sur 13k lignes).
   - Édition de template : incrémente `version`, recalcule `checksum` ; les entrées résolues sont **clefées par checksum** → miss naturel, **aucune boucle d'éviction par chefferie**.
   - `@Cacheable(sync=true)` anti-stampede sur les templates chauds ; cache `villagePerms(villageId,userId)` TTL 60 s → supprime la relecture par action gatée.
4. **Batch anti-N+1** (remplace le `FutureProvider.family` de `village_governance_service.dart:448-451`) : `POST /api/v1/villages/governance/summary:batch {ids[]}` → `Map<villageId, ApexSummary>` en **un** `WHERE village_id IN (:ids) AND is_current` + `findAllById(users)`.
5. **Compteurs atomiques.** Remplacer le read-modify-write de `member_count` (`VillageServiceImpl:172`, perte de MAJ concurrente) par `UPDATE villages SET member_count = member_count + 1 WHERE id = :id`. Idem tout compteur de titulaires.
6. **Pagination keyset partout** (`list`, `search`, `members`, lignées) : `WHERE (rank,id) > (:last) ORDER BY rank,id LIMIT :n` — pas d'OFFSET. Recherche trigram bornée `LIMIT 20`.
7. **Jointures indexées.** Les nouvelles FK `chefferies.department_id/region_id` remplacent la jointure lâche par chaîne (`region_name`/`department_code`).
8. **Recherche cross-lingue** via GIN trigram sur `governance_title_labels.label` (réutilise `pg_trgm`/`unaccent`, V44) ; la **regex quitte le chemin requête** — classification faite **à l'import** (`title_lexicon`), plus jamais O(rows) au runtime.

---

## 5. Migration depuis l'existant — Bamiléké devient le PREMIER template seedé

**Additive, sans casse, en lockstep migration + entité** (obligatoire sous `ddl-auto: validate`, sinon crash boot Cloud Run).

- **V59** : schéma templates + titres + labels + `role_kinds`. **Seeds livrés en données, jamais en code** : `generic_council` (**GLOBAL, ACÉPHALE**, défaut sûr), `grassfields_fondom` (apex `fon`/`Fɔ'`, notables `nji`/`mkam`, reine-mère `mafo`, société `kwifon` en `REGULATORY`, honorific `RESPECT`), `bamoun_sultanate` (`sultan`/`mfon`), `fulani_lamidat` (`lamido`, honorific « Laamiiɗo », `RELIGIOUS`), `yoruba_obaship`, `akan_stool` (succession **matrilinéaire**), `igbo_council` (acéphale). **Bamiléké = la première ligne, pas un `if` codé.**
- **V60** : `title_lexicon` seedé = l'**ancienne regex décomposée** (`'lamidat de'→lamido/fulani_lamidat`, `'sultanat de'→sultan`, `'canton'→canton_chief`, `'groupement'→group_head`…). Backfill one-shot (13k lignes = un `UPDATE…FROM`) : `denomination` → `(apex_title_code, proper_name)`, `degre` → `admin_level` + `classification.minat`, matching flou → `department_id/region_id`. Non reconnu → `proper_name = denomination` + tag curation.
- **V61** : instances ; **migration douce** `village_chiefs` → `village_office_holders` du siège apex (mêmes champs `display_name/reign_*/is_current/ordinal/user_id`, `office_key='head'`) ; garder `village_chiefs` en lecture le temps de basculer `VillageController.chief()` → `governance()`.
- **Dual-read** : `ChefferieDto` cesse de stripper au runtime et lit `apex_title_code`/`proper_name` (auto-réparation write-behind si NULL).
- **Route** : `/geo/cm` → `/geo/{country}` (path var), constante `CM` de `ReferentielServiceImpl:27` → paramètre validé contre `countries` ; **`/geo/cm` gardé en alias déprécié** (aucun client cassé). `COALESCE(:country, country_iso2)` dans les requêtes natives (piège param NULL Postgres).
- **`VillageValidationKind`** (CLAN/CHIEF_LINE/SUCCESSION, biais patrilinéaire V49:49) → piloté par `governance_models.lineality`, l'enum ne restant que le défaut.

---

## 6. L'UI générique

### Un composant unique piloté par config — `GovernanceView`
Remplace le bloc codé en dur `village_detail_screen.dart:3940-3983` (`isRealChief → 👑 + or`). **Aucune branche `if royal`** : la topologie choisit le **layout**, le registre choisit le **thème**.

```
GovernanceView(config)
 ├─ switch config.authorityModel            // ← LAYOUT, pas de culture
 │   MONOCEPHALIC → GovernanceHero(apex) + SeatSections(tiers 1..n)
 │   DYARCHIC     → Row[ Hero(seatA), Hero(seatB) ]     // co-souverains (roi + reine-mère)
 │   COLLEGIAL/ACEPHALOUS → CouncilGrid(seats)          // cartes ÉGALES, pas de héros
 │   ROTATING     → Hero + bandeau « mandat en cours (classe d'âge X) »
 ├─ SeatCard(office, holders)
 │     title   = i18n(viewerLocale → locale_primary → label générique)  // JAMAIS le code brut
 │     holder  = HolderChip | VacancyState(« Siège vacant / succession en cours »)  // n'invente rien
 │     meta    = « 12ᵉ du nom · 1994– »
 └─ theme = ThemeResolver(theme_token, honorific_style)
       gov.royal     → couronne + or (GwTokens.gold*) + « Sa Majesté »   // UN thème parmi N
       gov.respect   → portrait neutre, « Notable/Aîné »                  // DÉFAUT
       gov.religious → registre sobre, accent vert, « Lamido/Sultan »
       gov.stool     → glyphe tabouret, « intronisé/e »
       gov.neutral   → aucun ornement
```
Forme d'adresse depuis `honorific` (« Mfon », « Nana ») — **jamais « Sa Majesté » codé**. Reine-mère / cheffe des femmes = **charges propres**, côte à côte en dyarchie.

### Le flux admin — `GovernanceSetupWizard`
Gate : nouvelle capacité **`MANAGE_GOVERNANCE`** (ajout à l'enum `VillagePermission`), accordée au **régisseur/fondateur de la page ≠ chef traditionnel** (casse `VillagePermissionService.isChief` = créateur = autorité pleine), déléguable, auditée (`updated_by`).

1. **Point de départ** — galerie de `governance_models` rangée par `region_hint`/pays, décrite en clair (« Chef unique + conseil de notables », « Conseil d'anciens, pas de chef unique », « Émirat », « Je pars de zéro »). **Tous disponibles, aucun auto-appliqué.** La sélection **copie** les sièges du template dans l'instance (*copy-on-adopt* : éditer un village ne mute jamais le template ni les autres).
2. **Structure & registre** — confirmer `authority_model` ; choisir `honorific_style` + `theme_token` avec **aperçu live**. Défaut neutre : une culture qui refuse « Sa Majesté » garde `RESPECT`.
3. **Langue des titres** — `locale_primary` (+ script Ajami/N'Ko si besoin).
4. **Éditeur de sièges** (cœur) — arbre réordonnable : ajouter un siège (palette de clés neutres + « sur-mesure »), cardinalité (`1` = trône, `illimité` = classe de notables), tier/rang, permissions portées par le siège, succession, labels par langue.
5. **Titulaires** — courants + historiques ; compte OU nom libre ; **la vacance est de première classe** (généralise le 204 honnête de `VillageController:308-313` — jamais de chef inventé).
6. **Revue & publication** → `is_published=true`.

---

## 7. Plan par étapes

### MVP « dynamic-ready » (maintenant — pour ne PAS se coincer, court)
Objectif : **tuer les hypothèses figées** sans construire tout l'éditeur.
- **V59** minimal : `governance_models` + `governance_titles` + `governance_title_labels` + `role_kinds` + seeds `generic_council` (défaut acéphale) + `grassfields_fondom` + `fulani_lamidat`.
- **V60** : `title_lexicon` seedé (regex décomposée) + colonnes chefferie + **`degre DROP NOT NULL`** + backfill.
- **V61** : `village_office_holders` généralisant `village_chiefs` (office `head`) + colonnes `villages.gov_apex_*`.
- **Front** : `GovernanceView` avec **thème piloté donnée** (couronne conditionnelle, plus par défaut) + honorifique depuis la donnée.
- **Backend** : route `/geo/{country}` + alias `/geo/cm` ; `@EnableCaching`.

### v2 (structurel)
- Éditeur de sièges complet + layouts `COUNCIL`/`ACEPHALOUS`/`DYARCHIC` + `MANAGE_GOVERNANCE` + wizard.
- Cache Caffeine L1 + Redis L2 (checksum-in-key) ; `governance/summary:batch` ; keyset partout ; FK geo `department_id` ; `member_count` atomique.
- `ChefferieDto` lit le champ structuré (regex retirée du runtime).

### v3 (continental)
- ETL importeurs par pays (SPI `CountryReferentialImporter`, upsert idempotent sur `source_ref`) : NG, GH, sahel…
- Versionnement de templates + endossement communautaire (via `village_validations` élargi) ; succession matrilinéaire/rotative rendue ; recherche cross-lingue GIN trgm sur labels ; dépréciation `/geo/cm`.

---

## 8. Recommandation finale

**Commencez par le lot MVP « dynamic-ready » — et rien de plus — en une seule PR de socle.** Concrètement, dans l'ordre :

1. **`chefferies.degre DROP NOT NULL`** (V60) — c'est le blocage dur ; sans lui, aucun pays hors Cameroun n'entre. Trivial, débloque tout le reste.
2. **V59 : `governance_models` + `governance_titles` + labels + `role_kinds`**, avec **Bamiléké (`grassfields_fondom`) comme première ligne seedée** et `generic_council` acéphale comme défaut global. C'est l'acte fondateur : la structure devient donnée.
3. **Généraliser `village_chiefs` → `village_office_holders`** (office `head`) + **snapshot `villages.gov_apex_*`** : un seul geste qui prépare les notables **et** tue le N+1.
4. **`GovernanceView` avec thème piloté par donnée** : la couronne devient **un token parmi N**, défaut neutre. C'est le correctif visible qui incarne la vision devant le fondateur, et il ferme l'ethnocentrisme codé.

Ces quatre pas sont **additifs, testables au boot local avant Cloud Run, et n'exposent aucun changement cassant**. Ils suffisent à garantir qu'aucune décision d'aujourd'hui ne vous enferme demain : le jour où le Ghana ou le Nigeria arrive, c'est **un `INSERT` de template**, pas une refonte. Le reste (éditeur, cache multi-niveaux, ETL multi-pays) s'empile ensuite sans rien réécrire.

**Fichiers d'ancrage** — Migrations neuves : `backend/src/main/resources/db/migration/{V59,V60,V61}`. À faire évoluer : `geo/dto/ChefferieDto.java:33-35` (regex → `title_lexicon`), `geo/api/ReferentielController.java` + `geo/application/ReferentielServiceImpl.java:27` (route/const `CM` → paramètre), `geo/domain/Chefferie.java` (`degre` nullable + `classification` JSONB), `village/api/VillageController.java:293-333` (`chief()` → `governance()`), `village/application/VillagePermissionService.java` (créateur ≠ chef, `MANAGE_GOVERNANCE`), `village/application/VillageServiceImpl.java:172` (`member_count` atomique), `village/domain/{VillagePermission,VillageValidationKind}.java`, `config/RedisConfig.java` (+`@EnableCaching`/Caffeine), `frontend/lib/features/villages/village_detail_screen.dart:3940-3983` (héros → `GovernanceView`), `frontend/lib/features/villages/services/village_governance_service.dart:448-451` (N+1 → batch).