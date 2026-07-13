-- V56: Entrees patrimoniales generiques d'un village — traditions, lieux sacres, calendrier
-- traditionnel. Un seul modele porte par la colonne kind (TRADITION | SACRED_PLACE | CALENDAR).
-- Donnees editables par super-admin, chef (createur) ou delegue portant EDIT_VILLAGE
-- (cf VillagePermissionService). Colonnes texte VARCHAR (jamais CHAR). Audit created_at/updated_at
-- TIMESTAMPTZ, coherent avec les types JPA (ddl-auto validate).

CREATE TABLE IF NOT EXISTS village_heritage_entries (
    id          UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    village_id  UUID          NOT NULL REFERENCES villages(id) ON DELETE CASCADE,
    kind        VARCHAR(20)   NOT NULL,
    title       VARCHAR(200)  NOT NULL,
    subtitle    VARCHAR(200),
    description TEXT,
    detail      TEXT,
    ordinal     INT           NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_heritage_kind CHECK (kind IN ('TRADITION', 'SACRED_PLACE', 'CALENDAR'))
);
CREATE INDEX IF NOT EXISTS idx_heritage_entries_village_kind
    ON village_heritage_entries(village_id, kind);
