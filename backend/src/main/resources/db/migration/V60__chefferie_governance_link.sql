-- V60 : Liaison chefferie → gouvernance + DÉBLOCAGE multi-pays.
--
-- Objectif clé (spec §8.1) : `chefferies.degre` était SMALLINT NOT NULL, calqué
-- sur le seul MINAT camerounais → infranchissable pour tout autre pays. On le
-- rend nullable et on ajoute un `admin_level` générique. On rattache chaque
-- chefferie à un template de gouvernance (V59) et on capture le TITRE structuré
-- (fini la regex figée au runtime dans ChefferieDto) via un `title_lexicon` seedé.
--
-- ADDITIF + rétrocompatible : la provenance MINAT (degre, acte, region_name) est
-- CONSERVÉE ; les nouvelles colonnes sont nullable (sauf classification, DEFAULT).
-- Boot-safe (ddl-auto=validate) : lockstep avec l'entité Chefferie ; UUID, VARCHAR,
-- INTEGER (pas SMALLINT), JSONB via @JdbcTypeCode.

-- ─────────────────────────────────────────────────────────────────────────────
-- 1) title_lexicon — l'ancienne regex de ChefferieDto DÉCOMPOSÉE EN DONNÉES.
--    Ajouter un pays = des INSERT, plus jamais une regex Java à rallonge.
--    (Table sans entité JPA pour l'instant : consommée à l'import/backfill.)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE title_lexicon (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    country_iso2  VARCHAR(2)   NOT NULL,
    match_kind    VARCHAR(8)   NOT NULL DEFAULT 'PREFIX',
    pattern       VARCHAR(200) NOT NULL,
    infers_title  VARCHAR(60),                 -- titre de tête déduit : 'lamido','sultan','fon'…
    model_code    VARCHAR(80),                 -- template de gouvernance suggéré (governance_models.code)
    priority      INTEGER      NOT NULL DEFAULT 100,  -- le plus spécifique/long d'abord
    CONSTRAINT ck_title_lexicon_match CHECK (match_kind IN ('PREFIX','SUFFIX','REGEX','EXACT'))
);
CREATE INDEX idx_title_lexicon_country ON title_lexicon(country_iso2, priority DESC);

-- ─────────────────────────────────────────────────────────────────────────────
-- 2) chefferies : liaison + décomposition ADDITIVE + DÉBLOCAGE degre.
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE chefferies
    ADD COLUMN governance_model_id UUID REFERENCES governance_models(id),
    ADD COLUMN apex_title_code     VARCHAR(60),   -- titre STRUCTURÉ (fini la regex runtime)
    ADD COLUMN proper_name         VARCHAR(250),  -- dénomination sans le préfixe ('Bandenkop')
    ADD COLUMN admin_level         INTEGER,       -- rang générique multi-pays (remplace 'degre')
    ADD COLUMN classification      JSONB NOT NULL DEFAULT '{}'::jsonb, -- MINAT brut conservé
    ADD COLUMN department_id       UUID REFERENCES geo_departments(id),
    ADD COLUMN region_id           UUID REFERENCES geo_regions(id),
    ADD COLUMN source              VARCHAR(32),   -- 'MINAT-CM','NG-NASS'…
    ADD COLUMN source_ref          VARCHAR(120),  -- clé naturelle du dataset (import idempotent)
    ADD COLUMN title_source        VARCHAR(16);   -- IMPORTED | INFERRED | MANUAL

-- ⚠ LE DÉBLOCAGE : sans ça, aucun pays hors Cameroun n'entre.
ALTER TABLE chefferies ALTER COLUMN degre DROP NOT NULL;

CREATE INDEX idx_chefferies_model ON chefferies(governance_model_id);
CREATE UNIQUE INDEX ux_chefferies_source
    ON chefferies(country_iso2, source, source_ref) WHERE source_ref IS NOT NULL;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3) Seed title_lexicon (CM) = la regex de ChefferieDto, en lignes ordonnées.
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO title_lexicon (country_iso2, match_kind, pattern, infers_title, model_code, priority) VALUES
    ('CM', 'PREFIX', 'chefferie superieure', 'fon',    'grassfields_fondom', 300),
    ('CM', 'PREFIX', 'chefferie supérieure', 'fon',    'grassfields_fondom', 300),
    ('CM', 'PREFIX', 'lamidat de',           'lamido', 'fulani_lamidat',     260),
    ('CM', 'PREFIX', 'lamidat',              'lamido', 'fulani_lamidat',     255),
    ('CM', 'PREFIX', 'sultanat de',          'sultan', 'bamoun_sultanate',   250),
    ('CM', 'PREFIX', 'sultanat',             'sultan', 'bamoun_sultanate',   245),
    ('CM', 'PREFIX', 'canton',               'canton_chief', NULL,           200),
    ('CM', 'PREFIX', 'groupement',           'group_head',   NULL,           190),
    ('CM', 'PREFIX', 'chefferie',            NULL,     NULL,                 100);

-- ─────────────────────────────────────────────────────────────────────────────
-- 4) Backfill CM (one-shot). NULL-safe : ne casse rien si la table est vide.
-- ─────────────────────────────────────────────────────────────────────────────
-- 4a) Décomposition dénomination → proper_name (préfixe retiré, casse normalisée
--     laissée à l'affichage) ; niveau + classification + provenance.
UPDATE chefferies SET
    proper_name = NULLIF(btrim(regexp_replace(
        denomination,
        '^(chefferie sup[eé]rieure|chefferie|lamidat de|lamidat|sultanat de|sultanat|canton|groupement)\s+',
        '', 'i')), ''),
    admin_level = degre,
    classification = jsonb_strip_nulls(jsonb_build_object(
        'minat', jsonb_strip_nulls(jsonb_build_object(
            'degre', degre, 'acte', acte, 'region', region_name)))),
    source = COALESCE(source, 'MINAT-CM'),
    title_source = 'IMPORTED'
WHERE country_iso2 = 'CM';

-- Si le strip a tout retiré (dénomination = juste un préfixe), retomber sur le brut.
UPDATE chefferies SET proper_name = denomination
    WHERE country_iso2 = 'CM' AND (proper_name IS NULL OR proper_name = '');

-- 4b) Titre de tête + template de gouvernance déduits du lexicon (le plus spécifique).
UPDATE chefferies c SET
    apex_title_code = (
        SELECT l.infers_title FROM title_lexicon l
        WHERE l.country_iso2 = c.country_iso2 AND l.match_kind = 'PREFIX'
          AND l.infers_title IS NOT NULL
          AND lower(c.denomination) LIKE lower(l.pattern) || ' %'
        ORDER BY l.priority DESC LIMIT 1),
    governance_model_id = (
        SELECT gm.id FROM title_lexicon l
        JOIN governance_models gm ON gm.code = l.model_code AND gm.status = 'PUBLISHED'
        WHERE l.country_iso2 = c.country_iso2 AND l.match_kind = 'PREFIX'
          AND l.model_code IS NOT NULL
          AND lower(c.denomination) LIKE lower(l.pattern) || ' %'
        ORDER BY l.priority DESC LIMIT 1)
WHERE c.country_iso2 = 'CM';

-- Marque INFERRED les chefferies dont on a déduit un titre.
UPDATE chefferies SET title_source = 'INFERRED'
    WHERE country_iso2 = 'CM' AND apex_title_code IS NOT NULL;

-- 4c) Rattachement géo par jointure sur les codes (best-effort, NULL sinon).
UPDATE chefferies c SET department_id = d.id
    FROM geo_departments d
    WHERE c.department_id IS NULL
      AND d.country_iso2 = c.country_iso2 AND d.code = c.department_code;

UPDATE chefferies c SET region_id = r.id
    FROM geo_regions r
    WHERE c.region_id IS NULL
      AND r.country_iso2 = c.country_iso2 AND r.name = c.region_name;
