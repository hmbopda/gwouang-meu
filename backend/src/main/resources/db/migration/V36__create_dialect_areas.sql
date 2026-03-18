-- ==========================================================
-- V36 : Création table dialect_areas
-- Entité DialectArea.java absente des migrations précédentes
-- ==========================================================

CREATE TABLE IF NOT EXISTS dialect_areas (
    id                     UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    name                   VARCHAR(255) NOT NULL UNIQUE,
    description            TEXT,
    speaker_count_estimate INTEGER,
    language_family        VARCHAR(255),
    iso_639_code           VARCHAR(10),
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_dialect_areas_name ON dialect_areas(name);
