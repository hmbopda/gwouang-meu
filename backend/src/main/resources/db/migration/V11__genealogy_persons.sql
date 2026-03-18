CREATE TABLE persons (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id           UUID REFERENCES users(id) ON DELETE SET NULL,
    village_id        UUID REFERENCES villages(id) ON DELETE SET NULL,

    -- Identite
    first_name        VARCHAR(100) NOT NULL,
    last_name         VARCHAR(100) NOT NULL,
    maiden_name       VARCHAR(100),
    gender            gender_enum NOT NULL,
    birth_date        DATE,
    birth_place       VARCHAR(200),
    death_date        DATE,

    -- Culture
    clan              VARCHAR(100),
    totem             VARCHAR(100),
    native_language   VARCHAR(50),
    religion          VARCHAR(80),
    profession        VARCHAR(120),
    biography         TEXT,
    photo_url         TEXT,

    -- Systeme
    privacy           privacy_enum NOT NULL DEFAULT 'FAMILY_ONLY',
    status            person_status_enum NOT NULL DEFAULT 'PENDING',
    neo4j_node_id     VARCHAR(100) UNIQUE,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by        UUID NOT NULL REFERENCES users(id)
);

CREATE INDEX idx_persons_village ON persons(village_id);
CREATE INDEX idx_persons_user ON persons(user_id);
CREATE INDEX idx_persons_clan ON persons(clan);
CREATE INDEX idx_persons_status ON persons(status);

ALTER TABLE persons ENABLE ROW LEVEL SECURITY;

CREATE POLICY "persons_select" ON persons FOR SELECT
  USING (
    privacy = 'PUBLIC'
    OR (privacy = 'MEMBERS_ONLY' AND current_setting('app.user_id', true) IS NOT NULL)
    OR (privacy = 'FAMILY_ONLY' AND created_by = CAST(current_setting('app.user_id', true) AS UUID))
  );

CREATE POLICY "persons_insert" ON persons FOR INSERT
  WITH CHECK (created_by = CAST(current_setting('app.user_id', true) AS UUID));

CREATE POLICY "persons_update" ON persons FOR UPDATE
  USING (created_by = CAST(current_setting('app.user_id', true) AS UUID));
