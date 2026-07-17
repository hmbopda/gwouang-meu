-- V59 : FONDATION de la gouvernance dynamique — méta-modèle générique panafricain.
--
-- La gouvernance traditionnelle devient une DONNÉE (templates par aire culturelle),
-- jamais du code. Bamiléké = 1er template seedé, pas un cas codé en dur. Le jour où
-- le Ghana ou le Nigeria arrive, c'est un INSERT de template, pas une refonte.
-- Spec : docs/architecture-gouvernance-panafricaine.md (§3 A, §5, §8).
--
-- PUREMENT ADDITIF : aucune table existante n'est modifiée ici. La liaison chefferie
-- (V60) et les instances vivantes par village (V61) suivront en lockstep avec leurs
-- entités. Boot-safe sous ddl-auto=validate :
--   • UUID PK (gen_random_uuid)          • VARCHAR partout (jamais CHAR — cf. convention iso2)
--   • INTEGER (jamais SMALLINT)          • JSONB via @JdbcTypeCode(SqlTypes.JSON)
--   • enums = VARCHAR + CHECK nommée     • pg_trgm déjà actif (V1/V44/V51) → index GIN labels

-- ─────────────────────────────────────────────────────────────────────────────
-- 1) role_kinds — vocabulaire de FONCTIONS, extensible par INSERT (jamais une enum Java).
--    Le code Java branche sur les flags de comportement, pas sur des noms de culture.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE role_kinds (
    code            VARCHAR(40) PRIMARY KEY,
    is_executive    BOOLEAN NOT NULL DEFAULT FALSE,
    is_ceremonial   BOOLEAN NOT NULL DEFAULT FALSE,
    is_apex_capable BOOLEAN NOT NULL DEFAULT FALSE,
    is_regulatory   BOOLEAN NOT NULL DEFAULT FALSE
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 2) governance_models — catalogue de TEMPLATES partagés par aire culturelle.
--    Structure O(templates), jamais O(chefferies) : chaque chefferie ne stocke qu'une FK.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE governance_models (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code             VARCHAR(80)  NOT NULL,
    model_version    INTEGER      NOT NULL DEFAULT 1,
    scope_type       VARCHAR(20)  NOT NULL DEFAULT 'GLOBAL',
    scope_key        VARCHAR(80),
    country_iso2     VARCHAR(2),
    authority_model  VARCHAR(20)  NOT NULL DEFAULT 'MONOCEPHALIC',
    head_cardinality INTEGER      NOT NULL DEFAULT 1,
    sacrality        VARCHAR(20)  NOT NULL DEFAULT 'RESPECT',
    honorific_style  VARCHAR(20)  NOT NULL DEFAULT 'RESPECT',
    lineality        VARCHAR(20)  NOT NULL DEFAULT 'PATRILINEAL',
    revocable        BOOLEAN      NOT NULL DEFAULT FALSE,
    access_mediated  BOOLEAN      NOT NULL DEFAULT FALSE,
    regalia_key      VARCHAR(40)  NOT NULL DEFAULT 'none',
    theme_token      VARCHAR(40)  NOT NULL DEFAULT 'gov.neutral',
    rotation_years   INTEGER,
    status           VARCHAR(16)  NOT NULL DEFAULT 'PUBLISHED',
    is_default       BOOLEAN      NOT NULL DEFAULT FALSE,
    config           JSONB        NOT NULL DEFAULT '{}'::jsonb,
    checksum         VARCHAR(64)  NOT NULL DEFAULT '',
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_gov_model UNIQUE (code, model_version),
    CONSTRAINT ck_gov_authority CHECK (authority_model IN
        ('MONOCEPHALIC','DYARCHIC','COLLEGIAL','ROTATING','ACEPHALOUS')),
    CONSTRAINT ck_gov_scope CHECK (scope_type IN ('ETHNIC','COUNTRY','REGION','GLOBAL')),
    CONSTRAINT ck_gov_status CHECK (status IN ('DRAFT','PUBLISHED','DEPRECATED')),
    CONSTRAINT ck_gov_sacrality CHECK (sacrality IN
        ('SACRED','ROYAL','RELIGIOUS','RESPECT','CIVIL','NONE','POLITICAL')),
    CONSTRAINT ck_gov_honorific CHECK (honorific_style IN
        ('NONE','RESPECT','ROYAL','RELIGIOUS','IMPERIAL')),
    CONSTRAINT ck_gov_lineality CHECK (lineality IN
        ('PATRILINEAL','MATRILINEAL','BILATERAL','COGNATIC'))
);
-- Au plus UN défaut par pays (et un seul défaut GLOBAL où country_iso2 IS NULL).
CREATE UNIQUE INDEX ux_gov_model_default
    ON governance_models (COALESCE(country_iso2, '~~'))
    WHERE is_default AND status = 'PUBLISHED';

-- Libellés i18n des modèles (galerie du wizard, multilingue).
CREATE TABLE governance_model_labels (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id    UUID NOT NULL REFERENCES governance_models(id) ON DELETE CASCADE,
    locale      VARCHAR(20)  NOT NULL,
    label       VARCHAR(120) NOT NULL,
    description VARCHAR(500),
    CONSTRAINT uq_gov_model_label UNIQUE (model_id, locale)
);
CREATE INDEX idx_gmodel_label_trgm ON governance_model_labels USING GIN (label gin_trgm_ops);

-- ─────────────────────────────────────────────────────────────────────────────
-- 3) governance_titles — LE CŒUR : la structure de leadership, en lignes.
--    « Chef ou pas », rangs, notables, fonctions spécialisées = des lignes, pas des if.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE governance_titles (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id               UUID NOT NULL REFERENCES governance_models(id) ON DELETE CASCADE,
    code                   VARCHAR(60) NOT NULL,
    role_kind              VARCHAR(40) NOT NULL REFERENCES role_kinds(code),
    tier                   INTEGER NOT NULL DEFAULT 0,   -- 0 apex, 1 haut conseil, 2 notables…
    rank                   INTEGER NOT NULL DEFAULT 100, -- préséance intra-tier
    is_apex                BOOLEAN NOT NULL DEFAULT FALSE,
    card_min               INTEGER NOT NULL DEFAULT 0,
    card_max               INTEGER,                      -- 1 = siège unique ; NULL = illimité
    gender_rule            VARCHAR(10) NOT NULL DEFAULT 'ANY',
    mediates_head          BOOLEAN NOT NULL DEFAULT FALSE, -- canal d'accès obligatoire (okyeame)
    succession             VARCHAR(24),
    designating_title_code VARCHAR(60),                  -- QUI désigne (reine-mère, kingmakers…)
    regalia_key            VARCHAR(40),                  -- insigne = donnée, pas 👑 codé
    perm_bundle            VARCHAR(300) NOT NULL DEFAULT '',
    config                 JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_gov_title UNIQUE (model_id, code),
    CONSTRAINT ck_gtitle_gender CHECK (gender_rule IN ('ANY','MALE','FEMALE')),
    CONSTRAINT ck_gtitle_succession CHECK (succession IS NULL OR succession IN
        ('HEREDITARY_PATRILINEAL','HEREDITARY_MATRILINEAL','DESIGNATED','ELECTED',
         'DIVINED','ROTATING','APPOINTED'))
);
CREATE INDEX idx_gtitle_model ON governance_titles(model_id, tier, rank);
-- Au plus un sommet par modèle (acéphale = zéro apex, invariant garanti).
CREATE UNIQUE INDEX ux_gtitle_apex ON governance_titles(model_id) WHERE is_apex;

-- Libellés i18n des titres + typeahead multilingue accent-insensible.
CREATE TABLE governance_title_labels (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title_id    UUID NOT NULL REFERENCES governance_titles(id) ON DELETE CASCADE,
    locale      VARCHAR(20)  NOT NULL,   -- BCP-47 : 'fr','en','bbj','yo','ha','ff'…
    label       VARCHAR(120) NOT NULL,   -- 'Fɔ'','Oba','Laamiiɗo','Chef supérieur'
    honorific   VARCHAR(120),            -- 'Sa Majesté' | 'Notable' | NULL (défaut neutre)
    description VARCHAR(500),
    CONSTRAINT uq_gtitle_label UNIQUE (title_id, locale)
);
CREATE INDEX idx_gtitle_label_trgm ON governance_title_labels USING GIN (label gin_trgm_ops);

-- ═════════════════════════════════════════════════════════════════════════════
-- SEEDS — les archétypes en DONNÉES. Bamiléké (grassfields_fondom) = la 1re ligne.
--   Fidélité : rien n'est fabriqué ; les titres EXACTS d'une chefferie donnée
--   (ex. les Pkem de Bandenkop) relèveront de l'instance/surcharge, pas du template.
-- ═════════════════════════════════════════════════════════════════════════════

-- 3.1) Vocabulaire de fonctions.
INSERT INTO role_kinds (code, is_executive, is_ceremonial, is_apex_capable, is_regulatory) VALUES
    ('HEAD',          TRUE,  TRUE,  TRUE,  FALSE),
    ('CO_HEAD',       TRUE,  TRUE,  TRUE,  FALSE),
    ('REGENT',        TRUE,  FALSE, TRUE,  FALSE),
    ('QUEEN_MOTHER',  TRUE,  TRUE,  FALSE, FALSE),
    ('NOTABLE',       TRUE,  FALSE, FALSE, FALSE),
    ('COUNCIL_ELDER', TRUE,  FALSE, FALSE, FALSE),
    ('SPOKESPERSON',  FALSE, TRUE,  FALSE, FALSE),
    ('WAR_LEADER',    TRUE,  FALSE, FALSE, FALSE),
    ('REGULATORY',    FALSE, TRUE,  FALSE, TRUE ),
    ('WOMEN_LEADER',  TRUE,  FALSE, FALSE, FALSE),
    ('PRIEST',        FALSE, TRUE,  FALSE, FALSE),
    ('HERALD',        FALSE, TRUE,  FALSE, FALSE),
    ('TITLE_HOLDER',  FALSE, TRUE,  FALSE, FALSE);

-- 3.2) Templates (UUID fixes pour référence par les titres/labels).
INSERT INTO governance_models
    (id, code, scope_type, scope_key, country_iso2, authority_model, head_cardinality,
     sacrality, honorific_style, lineality, revocable, access_mediated, regalia_key,
     theme_token, rotation_years, is_default) VALUES
    ('11111111-1111-1111-1111-111111111111', 'generic_council',   'GLOBAL', NULL,        NULL, 'ACEPHALOUS',   0, 'CIVIL',     'RESPECT',   'BILATERAL',   FALSE, FALSE, 'none',    'gov.neutral',   NULL, TRUE ),
    ('22222222-2222-2222-2222-222222222222', 'grassfields_fondom','ETHNIC', 'bamileke',  NULL, 'MONOCEPHALIC', 1, 'SACRED',    'ROYAL',     'PATRILINEAL', FALSE, TRUE,  'beaded_crown', 'gov.royal',  NULL, FALSE),
    ('33333333-3333-3333-3333-333333333333', 'fulani_lamidat',    'ETHNIC', 'fulani',    NULL, 'MONOCEPHALIC', 1, 'RELIGIOUS', 'RELIGIOUS', 'PATRILINEAL', FALSE, TRUE,  'turban',  'gov.religious', NULL, FALSE),
    ('44444444-4444-4444-4444-444444444444', 'yoruba_obaship',    'ETHNIC', 'yoruba',    NULL, 'MONOCEPHALIC', 1, 'SACRED',    'ROYAL',     'PATRILINEAL', FALSE, TRUE,  'beaded_crown', 'gov.royal',  NULL, FALSE),
    ('55555555-5555-5555-5555-555555555555', 'akan_stool',        'ETHNIC', 'akan',      NULL, 'MONOCEPHALIC', 1, 'ROYAL',     'ROYAL',     'MATRILINEAL', TRUE,  TRUE,  'golden_stool', 'gov.stool',  NULL, FALSE),
    ('66666666-6666-6666-6666-666666666666', 'igbo_council',      'ETHNIC', 'igbo',      NULL, 'ACEPHALOUS',   0, 'CIVIL',     'RESPECT',   'PATRILINEAL', FALSE, FALSE, 'none',    'gov.neutral',   NULL, FALSE),
    ('77777777-7777-7777-7777-777777777777', 'bamoun_sultanate',  'ETHNIC', 'bamoun',    'CM', 'MONOCEPHALIC', 1, 'ROYAL',     'ROYAL',     'PATRILINEAL', FALSE, TRUE,  'beaded_crown', 'gov.royal',  NULL, FALSE);

-- 3.3) Libellés des modèles (galerie du wizard, décrits en clair pour le fondateur).
INSERT INTO governance_model_labels (model_id, locale, label, description)
SELECT m.id, v.locale, v.label, v.description
FROM governance_models m
JOIN (VALUES
    ('generic_council',    'fr', 'Conseil d''anciens (sans chef unique)', 'Autorité collégiale, pas de chef unique. Défaut sûr et neutre.'),
    ('grassfields_fondom', 'fr', 'Chefferie à chef sacré + notables (Grassfields)', 'Chef sacré (Fɔ'') entouré de notables hiérarchisés, reine-mère et société régulatrice.'),
    ('fulani_lamidat',     'fr', 'Lamidat / Émirat', 'Chef religieux (Lamido) et cour de titres.'),
    ('yoruba_obaship',     'fr', 'Royauté Oba (Yoruba)', 'Roi (Oba) désigné par un collège de faiseurs de rois.'),
    ('akan_stool',         'fr', 'Royauté du tabouret (Akan)', 'Chef intronisé sur le tabouret, succession matrilinéaire, reine-mère qui désigne, porte-parole obligatoire.'),
    ('igbo_council',       'fr', 'Société sans chef (Igbo)', 'Conseil d''anciens, pas de chef unique (« Igbo enwe eze »).'),
    ('bamoun_sultanate',   'fr', 'Sultanat Bamoun', 'Sultan (Mfon) à la tête d''un royaume centralisé.')
) AS v(model_code, locale, label, description) ON v.model_code = m.code;

-- 3.4) Titres (structure de leadership) par template.
--      is_apex UNIQUE par modèle ; acéphales = aucun apex.
INSERT INTO governance_titles
    (model_id, code, role_kind, tier, rank, is_apex, card_min, card_max, gender_rule,
     mediates_head, succession, designating_title_code, regalia_key, perm_bundle)
SELECT m.id, v.code, v.role_kind, v.tier, v.rank, v.is_apex, v.card_min, v.card_max,
       v.gender_rule, v.mediates_head, v.succession, v.designating_title_code, v.regalia_key, ''
FROM governance_models m
JOIN (VALUES
    -- generic_council (acéphale) : un conseil d'anciens, pas d'apex.
    ('generic_council',    'elder',        'COUNCIL_ELDER', 1, 100, FALSE, 0, NULL,  'ANY',    FALSE, 'ELECTED',                 NULL,          NULL),
    -- grassfields_fondom (Bamiléké) : Fɔ' sacré + reine-mère + société régulatrice + notables.
    ('grassfields_fondom', 'head',         'HEAD',          0,   0, TRUE,  1, 1,     'MALE',   FALSE, 'HEREDITARY_PATRILINEAL',  NULL,          'beaded_crown'),
    ('grassfields_fondom', 'queen_mother', 'QUEEN_MOTHER',  1,  10, FALSE, 0, 1,     'FEMALE', FALSE, 'DESIGNATED',              'head',        NULL),
    ('grassfields_fondom', 'kwifon',       'REGULATORY',    1,  20, FALSE, 0, 1,     'ANY',    FALSE, NULL,                      NULL,          NULL),
    ('grassfields_fondom', 'notable',      'NOTABLE',       2, 100, FALSE, 0, NULL,  'ANY',    FALSE, 'APPOINTED',               'head',        NULL),
    -- fulani_lamidat : Lamido religieux + notables de cour.
    ('fulani_lamidat',     'head',         'HEAD',          0,   0, TRUE,  1, 1,     'MALE',   FALSE, 'DESIGNATED',              NULL,          'turban'),
    ('fulani_lamidat',     'notable',      'NOTABLE',       2, 100, FALSE, 0, NULL,  'ANY',    FALSE, 'APPOINTED',               'head',        NULL),
    -- yoruba_obaship : Oba désigné par kingmakers + Iyalode (cheffe des femmes).
    ('yoruba_obaship',     'head',         'HEAD',          0,   0, TRUE,  1, 1,     'MALE',   FALSE, 'DESIGNATED',              'kingmaker',   'beaded_crown'),
    ('yoruba_obaship',     'kingmaker',    'NOTABLE',       1,  10, FALSE, 0, NULL,  'ANY',    FALSE, 'APPOINTED',               NULL,          NULL),
    ('yoruba_obaship',     'women_leader', 'WOMEN_LEADER',  1,  20, FALSE, 0, 1,     'FEMALE', FALSE, 'APPOINTED',               NULL,          NULL),
    -- akan_stool : chef destituable, succession matrilinéaire, reine-mère désigne, okyeame médiatise.
    ('akan_stool',         'head',         'HEAD',          0,   0, TRUE,  1, 1,     'MALE',   FALSE, 'HEREDITARY_MATRILINEAL',  'queen_mother','golden_stool'),
    ('akan_stool',         'queen_mother', 'QUEEN_MOTHER',  1,  10, FALSE, 0, 1,     'FEMALE', FALSE, 'HEREDITARY_MATRILINEAL',  NULL,          NULL),
    ('akan_stool',         'spokesperson', 'SPOKESPERSON',  1,  20, FALSE, 0, 1,     'ANY',    TRUE,  'APPOINTED',               'head',        NULL),
    -- igbo_council (acéphale) : conseil d'anciens, pas d'apex.
    ('igbo_council',       'elder',        'COUNCIL_ELDER', 1, 100, FALSE, 0, NULL,  'ANY',    FALSE, 'ELECTED',                 NULL,          NULL),
    -- bamoun_sultanate : Sultan (Mfon).
    ('bamoun_sultanate',   'head',         'HEAD',          0,   0, TRUE,  1, 1,     'MALE',   FALSE, 'HEREDITARY_PATRILINEAL',  NULL,          'beaded_crown'),
    ('bamoun_sultanate',   'notable',      'NOTABLE',       2, 100, FALSE, 0, NULL,  'ANY',    FALSE, 'APPOINTED',               'head',        NULL)
) AS v(model_code, code, role_kind, tier, rank, is_apex, card_min, card_max, gender_rule,
        mediates_head, succession, designating_title_code, regalia_key)
  ON v.model_code = m.code;

-- 3.5) Libellés i18n des titres (fr + forme native attestée quand connue).
INSERT INTO governance_title_labels (title_id, locale, label, honorific)
SELECT t.id, v.locale, v.label, v.honorific
FROM governance_titles t
JOIN governance_models m ON m.id = t.model_id
JOIN (VALUES
    ('generic_council',    'elder',        'fr',  'Aîné du conseil',   'Aîné'),
    ('grassfields_fondom', 'head',         'fr',  'Chef supérieur',    'Sa Majesté'),
    ('grassfields_fondom', 'head',         'bbj', 'Fɔ''',              'Mfɔ''nde'),
    ('grassfields_fondom', 'queen_mother', 'fr',  'Reine-mère',        'Mafo'),
    ('grassfields_fondom', 'kwifon',       'fr',  'Société régulatrice', 'Kwifɔ'''),
    ('grassfields_fondom', 'notable',      'fr',  'Notable',           'Notable'),
    ('fulani_lamidat',     'head',         'fr',  'Lamido',            'Laamiiɗo'),
    ('fulani_lamidat',     'notable',      'fr',  'Dignitaire de cour', 'Notable'),
    ('yoruba_obaship',     'head',         'fr',  'Oba',               'Kabiyesi'),
    ('yoruba_obaship',     'kingmaker',    'fr',  'Faiseur de roi',    'Notable'),
    ('yoruba_obaship',     'women_leader', 'fr',  'Cheffe des femmes', 'Iyalode'),
    ('akan_stool',         'head',         'fr',  'Chef (Nana)',       'Nana'),
    ('akan_stool',         'queen_mother', 'fr',  'Reine-mère',        'Ohemaa'),
    ('akan_stool',         'spokesperson', 'fr',  'Porte-parole',      'Okyeame'),
    ('igbo_council',       'elder',        'fr',  'Aîné (Ndichie)',    'Aîné'),
    ('bamoun_sultanate',   'head',         'fr',  'Sultan',            'Mfon'),
    ('bamoun_sultanate',   'notable',      'fr',  'Notable de cour',   'Notable')
) AS v(model_code, title_code, locale, label, honorific)
  ON v.model_code = m.code AND v.title_code = t.code;
