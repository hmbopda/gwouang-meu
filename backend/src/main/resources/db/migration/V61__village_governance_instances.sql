-- V61 : Instances vivantes de gouvernance par village + snapshot perf.
--
-- Généralise `village_chiefs` (plafonné à la seule tête) à N'IMPORTE QUELLE charge
-- (chef, reine-mère, notables par rang, porte-parole…), chacune avec son invariant
-- « un titulaire courant ». Prépare le contact médiatisé et l'affichage non-ethnocentré.
-- Spec : docs/architecture-gouvernance-panafricaine.md (§3 C, §3 D, §8.3).
--
-- ADDITIF : `village_chiefs` est CONSERVÉ (lecture pendant la transition) ; ses lignes
-- sont COPIÉES en titulaires du siège apex. Boot-safe (ddl-auto=validate) : UUID,
-- VARCHAR, INTEGER, lockstep avec les entités.

-- ─────────────────────────────────────────────────────────────────────────────
-- 0) Correctif d'un bug LATENT pré-existant, sans rapport avec la gouvernance :
--    villages.country était resté VARCHAR(3) (V3) alors que V8 avait élargi la
--    même colonne pour `users`. Créer un village avec un nom de pays complet
--    échouait (« value too long »). Élargissement pur, sans perte.
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE villages ALTER COLUMN country TYPE VARCHAR(100);

-- ─────────────────────────────────────────────────────────────────────────────
-- 1) village_governance — en-tête d'instance (surcharge locale du template).
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE village_governance (
    village_id       UUID PRIMARY KEY REFERENCES villages(id) ON DELETE CASCADE,
    model_id         UUID REFERENCES governance_models(id),
    authority_model  VARCHAR(20)  NOT NULL DEFAULT 'MONOCEPHALIC',
    locale_primary   VARCHAR(20)  NOT NULL DEFAULT 'fr',
    honorific_style  VARCHAR(20)  NOT NULL DEFAULT 'RESPECT',
    theme_token      VARCHAR(40)  NOT NULL DEFAULT 'gov.neutral',
    gov_version      INTEGER      NOT NULL DEFAULT 1,   -- bumpé à chaque écriture → clé de cache
    is_published     BOOLEAN      NOT NULL DEFAULT FALSE,
    updated_by       UUID,
    updated_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_vgov_authority CHECK (authority_model IN
        ('MONOCEPHALIC','DYARCHIC','COLLEGIAL','ROTATING','ACEPHALOUS'))
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 2) village_offices — sièges matérialisés depuis le template, puis éditables.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE village_offices (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    village_id     UUID NOT NULL REFERENCES villages(id) ON DELETE CASCADE,
    title_id       UUID REFERENCES governance_titles(id) ON DELETE SET NULL, -- soft-ref au catalogue
    office_key     VARCHAR(60) NOT NULL,          -- 'head','queen_mother','notable'…
    label_override VARCHAR(120),                  -- surcharge par chefferie
    tier           INTEGER NOT NULL DEFAULT 0,
    rank           INTEGER NOT NULL DEFAULT 100,
    is_apex        BOOLEAN NOT NULL DEFAULT FALSE,
    card_min       INTEGER NOT NULL DEFAULT 0,
    card_max       INTEGER,                        -- 1 = trône ; NULL = classe de notables
    perm_bundle    VARCHAR(300) NOT NULL DEFAULT '',
    succession     VARCHAR(24),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_voffice_village ON village_offices(village_id, tier, rank);
CREATE UNIQUE INDEX ux_voffice_apex ON village_offices(village_id) WHERE is_apex;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3) village_office_holders — titulaires (généralise village_chiefs : chef ET notables).
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE village_office_holders (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    office_id     UUID NOT NULL REFERENCES village_offices(id) ON DELETE CASCADE,
    village_id    UUID NOT NULL REFERENCES villages(id) ON DELETE CASCADE, -- dénormalisé (requête directe)
    user_id       UUID REFERENCES users(id) ON DELETE SET NULL,  -- NULL = titulaire historique sans compte
    display_name  VARCHAR(200) NOT NULL,
    title_label   VARCHAR(120),                   -- snapshot du libellé résolu → historique stable
    gender        VARCHAR(12),                    -- rend visibles les titulaires femmes
    term_start    INTEGER,
    term_end      INTEGER,                        -- règne OU mandat (ex-reign_*)
    is_current    BOOLEAN NOT NULL DEFAULT FALSE,
    ordinal       INTEGER NOT NULL DEFAULT 0,     -- « 12ᵉ du nom »
    avatar_url    VARCHAR(500),
    note          TEXT,
    source        VARCHAR(20) NOT NULL DEFAULT 'HERITAGE_CURATED', -- vs COMMUNITY_DECLARED / COLONIAL_APPOINTED
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_voh_village ON village_office_holders(village_id, is_current);
-- Généralise ux_vchief_current : au plus un titulaire courant PAR SIÈGE.
CREATE UNIQUE INDEX ux_voh_current ON village_office_holders(office_id) WHERE is_current;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4) village_member_roles.title_id — typage optionnel des rôles délégués (notable…).
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE village_member_roles ADD COLUMN title_id UUID REFERENCES governance_titles(id);

-- ─────────────────────────────────────────────────────────────────────────────
-- 5) Snapshot dénormalisé sur villages (levier perf n°1 : chef inline, 0 requête).
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE villages
    ADD COLUMN gov_authority_model VARCHAR(20),
    ADD COLUMN gov_apex_holder     VARCHAR(200),  -- nom du titulaire apex courant (NULL = vacant)
    ADD COLUMN gov_apex_title      VARCHAR(120),  -- titre résolu ('Fɔ'','Laamiiɗo')
    ADD COLUMN gov_apex_user_id    UUID,
    ADD COLUMN gov_apex_avatar     VARCHAR(500),
    ADD COLUMN gov_theme_token     VARCHAR(40),
    ADD COLUMN gov_honorific       VARCHAR(60),
    ADD COLUMN gov_apex_is_vacant  BOOLEAN NOT NULL DEFAULT TRUE;

-- ═════════════════════════════════════════════════════════════════════════════
-- 6) Migration DOUCE village_chiefs → office 'head' + titulaires. Idempotente-safe :
--    ne s'exécute qu'une fois (Flyway). village_chiefs reste lu pendant la bascule.
-- ═════════════════════════════════════════════════════════════════════════════
-- 6a) Un siège apex 'head' par village ayant au moins un chef (title_id résolu plus tard).
INSERT INTO village_offices (village_id, office_key, tier, rank, is_apex, card_min, card_max)
SELECT DISTINCT village_id, 'head', 0, 0, TRUE, 1, 1
FROM village_chiefs;

-- 6b) Chaque chef (courant ou historique) devient titulaire de ce siège.
INSERT INTO village_office_holders
    (office_id, village_id, user_id, display_name, term_start, term_end,
     is_current, ordinal, avatar_url, note, source)
SELECT vo.id, vc.village_id, vc.user_id, vc.display_name, vc.reign_start, vc.reign_end,
       vc.is_current, vc.ordinal, vc.avatar_url, vc.note, 'HERITAGE_CURATED'
FROM village_chiefs vc
JOIN village_offices vo ON vo.village_id = vc.village_id AND vo.office_key = 'head';

-- 6c) Backfill du snapshot depuis le titulaire apex COURANT (tue le N+1 chief()).
UPDATE villages v SET
    gov_apex_holder    = h.display_name,
    gov_apex_user_id   = h.user_id,
    gov_apex_avatar    = h.avatar_url,
    gov_apex_is_vacant = FALSE
FROM village_office_holders h
JOIN village_offices o ON o.id = h.office_id AND o.is_apex
WHERE h.village_id = v.id AND h.is_current;
