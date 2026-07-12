-- V53: Patrimoine du village — dynastie des chefs (actuel + anciens) et temps forts (jalons).
-- Donnees editables par super-admin, chef (createur) ou delegue portant EDIT_VILLAGE
-- (cf VillagePermissionService). Un chef de la dynastie n'est pas forcement un compte
-- utilisateur (chefs historiques) : nom libre + dates de regne facultatives.
-- Colonnes texte VARCHAR (jamais CHAR). Audit created_at/updated_at TIMESTAMPTZ.

CREATE TABLE IF NOT EXISTS village_chiefs (
    id            UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    village_id    UUID          NOT NULL,
    display_name  VARCHAR(200)  NOT NULL,
    reign_start   INTEGER,
    reign_end     INTEGER,
    is_current    BOOLEAN       NOT NULL DEFAULT FALSE,
    ordinal       INTEGER       NOT NULL DEFAULT 0,
    note          TEXT,
    avatar_url    VARCHAR(500),
    user_id       UUID,
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_vchief_village FOREIGN KEY (village_id) REFERENCES villages(id) ON DELETE CASCADE,
    CONSTRAINT fk_vchief_user    FOREIGN KEY (user_id)    REFERENCES users(id)    ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_vchief_village ON village_chiefs(village_id, ordinal);

-- Invariant SGBD : au plus un chef courant (is_current = TRUE) par village.
-- Le service rétrograde l'ancien chef courant AVANT d'en promouvoir un nouveau.
CREATE UNIQUE INDEX IF NOT EXISTS ux_vchief_current
    ON village_chiefs(village_id) WHERE is_current = TRUE;

CREATE TABLE IF NOT EXISTS village_milestones (
    id            UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    village_id    UUID          NOT NULL,
    event_year    INTEGER,
    date_label    VARCHAR(120),
    title         VARCHAR(200)  NOT NULL,
    description   TEXT,
    ordinal       INTEGER       NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_vmilestone_village FOREIGN KEY (village_id) REFERENCES villages(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_vmilestone_village ON village_milestones(village_id, ordinal);
