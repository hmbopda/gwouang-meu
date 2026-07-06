-- V6: Geo-module complet — flag_emoji, country_id FK villages, cultural_links, seeds pays

-- 1. Ajouter flag_emoji sur countries (V3 a seulement flag_url)
ALTER TABLE countries ADD COLUMN IF NOT EXISTS flag_emoji VARCHAR(20);

-- 2. Ajouter continent_id UUID FK sur countries (V3 utilise continent_code string)
ALTER TABLE countries ADD COLUMN IF NOT EXISTS continent_id UUID REFERENCES continents(id) ON DELETE SET NULL;

-- 3. Ajouter country_id UUID FK sur villages (V3 utilise country VARCHAR(3))
ALTER TABLE villages ADD COLUMN IF NOT EXISTS country_id UUID REFERENCES countries(id) ON DELETE SET NULL;

-- Index sur la FK
CREATE INDEX IF NOT EXISTS idx_countries_continent_id ON countries(continent_id);
CREATE INDEX IF NOT EXISTS idx_villages_country_id    ON villages(country_id);

-- 4. GiST index pour requetes PostGIS ST_DWithin rapides
--    Supabase installe PostGIS dans le schema "extensions" (pas dans "public").
--    SET LOCAL search_path inclut les deux pour que ST_MakePoint soit resolu.
--    Skip si PostGIS absent (dev local sans Docker).
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'postgis') THEN
        SET LOCAL search_path TO public, extensions;
        EXECUTE 'CREATE INDEX IF NOT EXISTS idx_villages_geo_location
                 ON villages USING GIST ((ST_MakePoint(longitude, latitude)::geography))';
    END IF;
END $$;

-- 5. Table des connexions culturelles transversales (cross-pays)
CREATE TABLE IF NOT EXISTS cultural_links (
    id               UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    village_a_id     UUID         NOT NULL,
    village_b_id     UUID         NOT NULL,
    link_type        VARCHAR(50)  NOT NULL
                         CHECK (link_type IN ('dialect', 'cuisine', 'rites', 'history', 'migration', 'language')),
    similarity_score DECIMAL(3,2) NOT NULL DEFAULT 0.50
                         CHECK (similarity_score >= 0.00 AND similarity_score <= 1.00),
    description      TEXT,
    created_by_ai    BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_cultural_village_a FOREIGN KEY (village_a_id) REFERENCES villages(id) ON DELETE CASCADE,
    CONSTRAINT fk_cultural_village_b FOREIGN KEY (village_b_id) REFERENCES villages(id) ON DELETE CASCADE,
    CONSTRAINT uq_cultural_link      UNIQUE (village_a_id, village_b_id, link_type),
    CONSTRAINT chk_no_self_link      CHECK (village_a_id <> village_b_id)
);

CREATE INDEX IF NOT EXISTS idx_cultural_links_a    ON cultural_links(village_a_id);
CREATE INDEX IF NOT EXISTS idx_cultural_links_b    ON cultural_links(village_b_id);
CREATE INDEX IF NOT EXISTS idx_cultural_links_type ON cultural_links(link_type);

-- 6. Seeds : 10 pays africains (linked to continents by code)
INSERT INTO countries (name, code, flag_emoji, continent_code, continent_id, flag_url)
SELECT 'Cameroun', 'CMR', U&'\1F1E8\1F1F2', 'AF-CENTRAL', c.id, 'https://flagcdn.com/cm.svg'
FROM continents c WHERE c.code = 'AF-CENTRAL'
ON CONFLICT (code) DO UPDATE SET
    flag_emoji   = EXCLUDED.flag_emoji,
    continent_id = EXCLUDED.continent_id;

INSERT INTO countries (name, code, flag_emoji, continent_code, continent_id, flag_url)
SELECT 'Congo (Rep. Dem.)', 'COD', U&'\1F1E8\1F1E9', 'AF-CENTRAL', c.id, 'https://flagcdn.com/cd.svg'
FROM continents c WHERE c.code = 'AF-CENTRAL'
ON CONFLICT (code) DO UPDATE SET flag_emoji = EXCLUDED.flag_emoji, continent_id = EXCLUDED.continent_id;

INSERT INTO countries (name, code, flag_emoji, continent_code, continent_id, flag_url)
SELECT 'Senegal', 'SEN', U&'\1F1F8\1F1F3', 'AF-WEST', c.id, 'https://flagcdn.com/sn.svg'
FROM continents c WHERE c.code = 'AF-WEST'
ON CONFLICT (code) DO UPDATE SET flag_emoji = EXCLUDED.flag_emoji, continent_id = EXCLUDED.continent_id;

INSERT INTO countries (name, code, flag_emoji, continent_code, continent_id, flag_url)
SELECT 'Cote d Ivoire', 'CIV', U&'\1F1E8\1F1EE', 'AF-WEST', c.id, 'https://flagcdn.com/ci.svg'
FROM continents c WHERE c.code = 'AF-WEST'
ON CONFLICT (code) DO UPDATE SET flag_emoji = EXCLUDED.flag_emoji, continent_id = EXCLUDED.continent_id;

INSERT INTO countries (name, code, flag_emoji, continent_code, continent_id, flag_url)
SELECT 'Nigeria', 'NGA', U&'\1F1F3\1F1EC', 'AF-WEST', c.id, 'https://flagcdn.com/ng.svg'
FROM continents c WHERE c.code = 'AF-WEST'
ON CONFLICT (code) DO UPDATE SET flag_emoji = EXCLUDED.flag_emoji, continent_id = EXCLUDED.continent_id;

INSERT INTO countries (name, code, flag_emoji, continent_code, continent_id, flag_url)
SELECT 'Ghana', 'GHA', U&'\1F1EC\1F1ED', 'AF-WEST', c.id, 'https://flagcdn.com/gh.svg'
FROM continents c WHERE c.code = 'AF-WEST'
ON CONFLICT (code) DO UPDATE SET flag_emoji = EXCLUDED.flag_emoji, continent_id = EXCLUDED.continent_id;

INSERT INTO countries (name, code, flag_emoji, continent_code, continent_id, flag_url)
SELECT 'Mali', 'MLI', U&'\1F1F2\1F1F1', 'AF-WEST', c.id, 'https://flagcdn.com/ml.svg'
FROM continents c WHERE c.code = 'AF-WEST'
ON CONFLICT (code) DO UPDATE SET flag_emoji = EXCLUDED.flag_emoji, continent_id = EXCLUDED.continent_id;

INSERT INTO countries (name, code, flag_emoji, continent_code, continent_id, flag_url)
SELECT 'Burkina Faso', 'BFA', U&'\1F1E7\1F1EB', 'AF-WEST', c.id, 'https://flagcdn.com/bf.svg'
FROM continents c WHERE c.code = 'AF-WEST'
ON CONFLICT (code) DO UPDATE SET flag_emoji = EXCLUDED.flag_emoji, continent_id = EXCLUDED.continent_id;

INSERT INTO countries (name, code, flag_emoji, continent_code, continent_id, flag_url)
SELECT 'Rwanda', 'RWA', U&'\1F1F7\1F1FC', 'AF-EAST', c.id, 'https://flagcdn.com/rw.svg'
FROM continents c WHERE c.code = 'AF-EAST'
ON CONFLICT (code) DO UPDATE SET flag_emoji = EXCLUDED.flag_emoji, continent_id = EXCLUDED.continent_id;

INSERT INTO countries (name, code, flag_emoji, continent_code, continent_id, flag_url)
SELECT 'Tanzanie', 'TZA', U&'\1F1F9\1F1FF', 'AF-EAST', c.id, 'https://flagcdn.com/tz.svg'
FROM continents c WHERE c.code = 'AF-EAST'
ON CONFLICT (code) DO UPDATE SET flag_emoji = EXCLUDED.flag_emoji, continent_id = EXCLUDED.continent_id;
