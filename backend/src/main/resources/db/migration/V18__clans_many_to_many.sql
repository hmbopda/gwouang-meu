-- ════════════════════════════════════════════════════════════════
-- V18 : Table clans (grandes familles) + relation M:N person_clans
-- Une personne peut appartenir a 0..N clans
-- Un clan peut contenir 1..N personnes
-- Un clan est rattache a un village
-- ════════════════════════════════════════════════════════════════

-- 1. Table clans
CREATE TABLE clans (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(100) NOT NULL,
    village_id  UUID NOT NULL REFERENCES villages(id) ON DELETE CASCADE,
    description TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_clan_name_village UNIQUE (name, village_id)
);

CREATE INDEX idx_clans_village ON clans(village_id);
CREATE INDEX idx_clans_name ON clans(name);

-- 2. Table de jointure person_clans (M:N)
CREATE TABLE person_clans (
    person_id  UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
    clan_id    UUID NOT NULL REFERENCES clans(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (person_id, clan_id)
);

CREATE INDEX idx_person_clans_clan ON person_clans(clan_id);
CREATE INDEX idx_person_clans_person ON person_clans(person_id);

-- 3. Migration des donnees existantes : persons.clan → clans + person_clans
-- Pour chaque combinaison (clan, village) existante, creer le clan
-- puis lier la personne
DO $$
DECLARE
    r RECORD;
    v_clan_id UUID;
BEGIN
    FOR r IN
        SELECT DISTINCT p.clan AS clan_name, pv.village_id
        FROM persons p
        JOIN person_villages pv ON pv.person_id = p.id
        WHERE p.clan IS NOT NULL AND p.clan <> ''
    LOOP
        -- Upsert clan
        INSERT INTO clans (name, village_id)
        VALUES (r.clan_name, r.village_id)
        ON CONFLICT (name, village_id) DO NOTHING
        RETURNING id INTO v_clan_id;

        -- Si pas d'insert (deja existant), recuperer l'id
        IF v_clan_id IS NULL THEN
            SELECT id INTO v_clan_id FROM clans WHERE name = r.clan_name AND village_id = r.village_id;
        END IF;

        -- Lier toutes les personnes qui ont ce clan dans ce village
        INSERT INTO person_clans (person_id, clan_id)
        SELECT p.id, v_clan_id
        FROM persons p
        JOIN person_villages pv ON pv.person_id = p.id
        WHERE p.clan = r.clan_name AND pv.village_id = r.village_id
        ON CONFLICT DO NOTHING;
    END LOOP;

    RAISE NOTICE 'Migration clans terminee';
END $$;

-- 4. RLS sur clans et person_clans (meme politique que persons)
ALTER TABLE clans ENABLE ROW LEVEL SECURITY;
ALTER TABLE person_clans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "clans_read_all" ON clans FOR SELECT USING (true);
CREATE POLICY "clans_insert_auth" ON clans FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "person_clans_read_all" ON person_clans FOR SELECT USING (true);
CREATE POLICY "person_clans_insert_auth" ON person_clans FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
