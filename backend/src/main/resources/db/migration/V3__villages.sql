-- V3: Tables geographiques et villages
CREATE TABLE IF NOT EXISTS continents (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    code        VARCHAR(20) NOT NULL UNIQUE,
    name        VARCHAR(100) NOT NULL,
    name_fr     VARCHAR(100),
    description TEXT,
    cover_image_url VARCHAR(500),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS countries (
    id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    code           VARCHAR(3)  NOT NULL UNIQUE,
    name           VARCHAR(100) NOT NULL,
    name_fr        VARCHAR(100),
    continent_code VARCHAR(20) NOT NULL,
    flag_url       VARCHAR(500),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_countries_continent_code ON countries(continent_code);

CREATE TABLE IF NOT EXISTS villages (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    name                VARCHAR(100) NOT NULL,
    description         TEXT,
    country             VARCHAR(3)   NOT NULL,
    region              VARCHAR(100),
    continent_code      VARCHAR(20),
    cover_image_url     VARCHAR(500),
    latitude            DOUBLE PRECISION,
    longitude           DOUBLE PRECISION,
    founded_year        INT,
    population_estimate INT,
    primary_dialect     VARCHAR(50),
    creator_id          UUID,
    is_verified         BOOLEAN     NOT NULL DEFAULT FALSE,
    member_count        INT         NOT NULL DEFAULT 0,
    historical_summary  TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_village_creator FOREIGN KEY (creator_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_villages_country ON villages(country);
CREATE INDEX IF NOT EXISTS idx_villages_continent_code ON villages(continent_code);
CREATE INDEX IF NOT EXISTS idx_villages_name ON villages (name);

CREATE TABLE IF NOT EXISTS village_subscriptions (
    id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID        NOT NULL,
    village_id UUID        NOT NULL,
    type       VARCHAR(20) NOT NULL DEFAULT 'FOLLOW'
                   CHECK (type IN ('FOLLOW','MEMBER','AMBASSADOR')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_user_village UNIQUE (user_id, village_id),
    CONSTRAINT fk_vsub_user    FOREIGN KEY (user_id)    REFERENCES users(id)    ON DELETE CASCADE,
    CONSTRAINT fk_vsub_village FOREIGN KEY (village_id) REFERENCES villages(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_vsub_user_id    ON village_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_vsub_village_id ON village_subscriptions(village_id);

-- Donnees de reference : continents africains + diaspora
INSERT INTO continents (code, name, name_fr) VALUES
    ('AF-CENTRAL', 'Central Africa',     'Afrique Centrale'),
    ('AF-WEST',    'West Africa',        'Afrique de l Ouest'),
    ('AF-EAST',    'East Africa',        'Afrique de l Est'),
    ('AF-NORTH',   'North Africa',       'Afrique du Nord'),
    ('AF-SOUTH',   'Southern Africa',    'Afrique Australe'),
    ('DIASPORA',   'African Diaspora',   'Diaspora Africaine')
ON CONFLICT (code) DO NOTHING;
