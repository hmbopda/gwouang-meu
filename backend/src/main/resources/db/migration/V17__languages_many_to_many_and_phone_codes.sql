-- V17: Refactoring langues -> relation M:N avec pays + indicatifs telephoniques

-- ════════════════════════════════════════════════════════════════
-- 1. Ajouter phone_code aux pays
-- ════════════════════════════════════════════════════════════════
ALTER TABLE countries ADD COLUMN IF NOT EXISTS phone_code VARCHAR(6);

UPDATE countries SET phone_code = CASE code
    WHEN 'CMR' THEN '+237'
    WHEN 'SEN' THEN '+221'
    WHEN 'CIV' THEN '+225'
    WHEN 'COD' THEN '+243'
    WHEN 'NGA' THEN '+234'
    WHEN 'GHA' THEN '+233'
    WHEN 'MLI' THEN '+223'
    WHEN 'BFA' THEN '+226'
    WHEN 'RWA' THEN '+250'
    WHEN 'TZA' THEN '+255'
    ELSE phone_code
END
WHERE phone_code IS NULL;

-- ════════════════════════════════════════════════════════════════
-- 2. Table de jonction country_languages (M:N)
-- ════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS country_languages (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    language_id UUID        NOT NULL,
    country_id  UUID        NOT NULL REFERENCES countries(id) ON DELETE CASCADE,
    is_official BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_country_language UNIQUE (language_id, country_id)
);

CREATE INDEX IF NOT EXISTS idx_country_languages_country ON country_languages(country_id);
CREATE INDEX IF NOT EXISTS idx_country_languages_language ON country_languages(language_id);

-- ════════════════════════════════════════════════════════════════
-- 3. Migrer les donnees existantes : deduplication des langues
--    Une seule entree par nom de langue, puis liens M:N
-- ════════════════════════════════════════════════════════════════

-- 3a. Creer une table temporaire avec les langues uniques
CREATE TEMP TABLE temp_unique_languages AS
SELECT DISTINCT ON (LOWER(name))
    gen_random_uuid() AS new_id,
    name,
    name_local
FROM languages
ORDER BY LOWER(name), created_at ASC;

-- 3b. Inserer les liens M:N depuis les anciennes donnees
INSERT INTO country_languages (language_id, country_id, is_official)
SELECT tul.new_id, l.country_id, l.is_official
FROM languages l
JOIN temp_unique_languages tul ON LOWER(tul.name) = LOWER(l.name)
ON CONFLICT (language_id, country_id) DO NOTHING;

-- 3c. Sauvegarder et reconstruire la table languages
-- Supprimer l'ancienne contrainte et colonne
ALTER TABLE languages DROP CONSTRAINT IF EXISTS uq_language_country;
ALTER TABLE languages DROP COLUMN IF EXISTS country_id;
ALTER TABLE languages DROP COLUMN IF EXISTS is_official;

-- Vider et re-inserer les langues dedupliquees
DELETE FROM languages;
INSERT INTO languages (id, name, name_local)
SELECT new_id, name, name_local FROM temp_unique_languages;

-- Ajouter la FK sur country_languages
ALTER TABLE country_languages
    ADD CONSTRAINT fk_country_languages_language
    FOREIGN KEY (language_id) REFERENCES languages(id) ON DELETE CASCADE;

-- Contrainte d'unicite sur le nom de la langue
ALTER TABLE languages ADD CONSTRAINT uq_language_name UNIQUE (name);

DROP TABLE temp_unique_languages;

-- ════════════════════════════════════════════════════════════════
-- 4. Seed : langues supplementaires du Cameroun (test)
-- ════════════════════════════════════════════════════════════════

-- Ajouter des langues camerounaises supplementaires
INSERT INTO languages (name, name_local) VALUES
    ('Mengaka',     'Mengaka'),
    ('Bandjoun',    'Bandjoun'),
    ('Bafoussam',   'Bafoussam'),
    ('Bangangte',   'Bangangte'),
    ('Dschang',     'Dschang'),
    ('Fongondeng',  'Fongondeng'),
    ('Ngomba',      'Ngomba'),
    ('Mbouda',      'Mbouda'),
    ('Mankon',      'Mankon'),
    ('Nso',         'Lamnso'''),
    ('Aghem',       'Aghem'),
    ('Kom',         'Itanghi-kom'),
    ('Bafut',       'Bafut'),
    ('Kenyang',     'Kenyang'),
    ('Ejagham',     'Ejagham')
ON CONFLICT (name) DO NOTHING;

-- Lier ces nouvelles langues au Cameroun
INSERT INTO country_languages (language_id, country_id, is_official)
SELECT l.id, c.id, FALSE
FROM languages l
CROSS JOIN countries c
WHERE c.code = 'CMR'
  AND l.name IN (
    'Mengaka', 'Bandjoun', 'Bafoussam', 'Bangangte', 'Dschang',
    'Fongondeng', 'Ngomba', 'Mbouda', 'Mankon', 'Nso',
    'Aghem', 'Kom', 'Bafut', 'Kenyang', 'Ejagham'
  )
ON CONFLICT (language_id, country_id) DO NOTHING;

-- Lier les langues partagees entre plusieurs pays
-- Francais -> CMR, SEN, CIV, COD, MLI, BFA, RWA (deja fait par migration)
-- Swahili -> COD, RWA, TZA (deja fait par migration)
-- Fulfulde -> CMR, NGA, MLI, BFA, SEN (ajouter les liens manquants)
INSERT INTO country_languages (language_id, country_id, is_official)
SELECT l.id, c.id, FALSE
FROM languages l, countries c
WHERE l.name = 'Fulfulde' AND c.code IN ('CMR', 'NGA', 'MLI', 'BFA', 'SEN')
ON CONFLICT (language_id, country_id) DO NOTHING;

-- Dioula -> CIV, BFA, MLI
INSERT INTO country_languages (language_id, country_id, is_official)
SELECT l.id, c.id, FALSE
FROM languages l, countries c
WHERE l.name = 'Dioula' AND c.code IN ('CIV', 'BFA', 'MLI')
ON CONFLICT (language_id, country_id) DO NOTHING;

-- Soninke -> SEN, MLI
INSERT INTO country_languages (language_id, country_id, is_official)
SELECT l.id, c.id, FALSE
FROM languages l, countries c
WHERE l.name = 'Soninke' AND c.code IN ('SEN', 'MLI')
ON CONFLICT (language_id, country_id) DO NOTHING;
