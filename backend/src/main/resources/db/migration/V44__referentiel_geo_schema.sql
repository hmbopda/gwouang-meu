-- ════════════════════════════════════════════════════════════════
-- V44 : Referentiel territorial (schema) — pays / region / departement /
-- arrondissement (commune) + chefferies traditionnelles.
--
-- Grappe administrative officielle et chefferies du MINAT. Country ISO-2
-- ('CM'), pense multi-pays (extension Afrique). Ce schema + les seeds V45/V46
-- constituent une SAUVEGARDE redeployable : tout Postgres rejoue ces
-- migrations et reconstruit le referentiel a l'identique.
-- Sources : GeoNames (CC-BY), decret 2008/376, Nomenclature MINAT nov. 2015.
-- Voir data/referentiels/cm/README.md.
-- ════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS geo_regions (
    id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    country_iso2  CHAR(2)      NOT NULL DEFAULT 'CM',
    code          VARCHAR(10)  NOT NULL,
    name          VARCHAR(150) NOT NULL,
    chief_town    VARCHAR(150),
    lat           DOUBLE PRECISION,
    lng           DOUBLE PRECISION,
    CONSTRAINT uq_geo_region UNIQUE (country_iso2, code)
);

CREATE TABLE IF NOT EXISTS geo_departments (
    id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    country_iso2  CHAR(2)      NOT NULL DEFAULT 'CM',
    code          VARCHAR(20)  NOT NULL,
    region_code   VARCHAR(10)  NOT NULL,
    name          VARCHAR(150) NOT NULL,
    chief_town    VARCHAR(150),
    lat           DOUBLE PRECISION,
    lng           DOUBLE PRECISION,
    CONSTRAINT uq_geo_department UNIQUE (country_iso2, code)
);

CREATE TABLE IF NOT EXISTS geo_arrondissements (
    id               UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    country_iso2     CHAR(2)      NOT NULL DEFAULT 'CM',
    code             VARCHAR(30)  NOT NULL,
    department_code  VARCHAR(20)  NOT NULL,
    name             VARCHAR(150) NOT NULL,
    lat              DOUBLE PRECISION,
    lng              DOUBLE PRECISION,
    CONSTRAINT uq_geo_arrondissement UNIQUE (country_iso2, code)
);

CREATE TABLE IF NOT EXISTS chefferies (
    id                   UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    country_iso2         CHAR(2)      NOT NULL DEFAULT 'CM',
    degre                SMALLINT     NOT NULL,
    region_name          VARCHAR(150) NOT NULL,
    department_name      VARCHAR(150),
    department_code      VARCHAR(20),
    numero               INTEGER,
    denomination         VARCHAR(250) NOT NULL,
    acte                 VARCHAR(500)
);

CREATE INDEX IF NOT EXISTS idx_geo_dept_region   ON geo_departments(country_iso2, region_code);
CREATE INDEX IF NOT EXISTS idx_geo_arr_dept      ON geo_arrondissements(country_iso2, department_code);
CREATE INDEX IF NOT EXISTS idx_chefferies_dept   ON chefferies(country_iso2, department_code);
CREATE INDEX IF NOT EXISTS idx_chefferies_region ON chefferies(country_iso2, region_name);

-- Recherche typeahead : trigram sur les denominations (si pg_trgm dispo).
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_trgm') THEN
        EXECUTE 'CREATE INDEX IF NOT EXISTS idx_chefferies_denom_trgm ON chefferies USING GIN (denomination gin_trgm_ops)';
        EXECUTE 'CREATE INDEX IF NOT EXISTS idx_geo_arr_name_trgm ON geo_arrondissements USING GIN (name gin_trgm_ops)';
    END IF;
END $$;
