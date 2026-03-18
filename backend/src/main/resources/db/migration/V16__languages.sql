-- V16: Table des langues par pays
CREATE TABLE IF NOT EXISTS languages (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(100) NOT NULL,
    name_local  VARCHAR(100),
    country_id  UUID         NOT NULL REFERENCES countries(id) ON DELETE CASCADE,
    is_official BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_language_country UNIQUE (name, country_id)
);

CREATE INDEX IF NOT EXISTS idx_languages_country_id ON languages(country_id);

-- Seed : langues du Cameroun
INSERT INTO languages (name, name_local, country_id, is_official)
SELECT l.name, l.name_local, c.id, l.is_official
FROM (VALUES
    ('Francais',    'Francais',    TRUE),
    ('Anglais',     'English',     TRUE),
    ('Bassa',       'Basa''a',     FALSE),
    ('Ewondo',      'Ewondo',      FALSE),
    ('Douala',      'Duala',       FALSE),
    ('Fulfulde',    'Fulfulde',    FALSE),
    ('Bamileke',    'Ghomala''',   FALSE),
    ('Bulu',        'Bulu',        FALSE),
    ('Medumba',     'Medumba',     FALSE),
    ('Ngiemboon',   'Ngiemboon',   FALSE),
    ('Yemba',       'Yemba',       FALSE),
    ('Fe''efe''e',  'Nufi',        FALSE),
    ('Bamoun',      'Shumom',      FALSE),
    ('Tikar',       'Tikar',       FALSE),
    ('Maka',        'Maka',        FALSE),
    ('Gbaya',       'Gbaya',       FALSE),
    ('Massa',       'Massa',       FALSE),
    ('Tupuri',      'Tupuri',      FALSE),
    ('Mundang',     'Mundang',     FALSE),
    ('Guidar',      'Guidar',      FALSE)
) AS l(name, name_local, is_official)
CROSS JOIN countries c WHERE c.code = 'CMR'
ON CONFLICT (name, country_id) DO NOTHING;

-- Seed : langues du Senegal
INSERT INTO languages (name, name_local, country_id, is_official)
SELECT l.name, l.name_local, c.id, l.is_official
FROM (VALUES
    ('Francais',  'Francais',  TRUE),
    ('Wolof',     'Wolof',     FALSE),
    ('Pulaar',    'Pulaar',    FALSE),
    ('Serer',     'Seereer',   FALSE),
    ('Diola',     'Joola',     FALSE),
    ('Mandingue', 'Mandinka',  FALSE),
    ('Soninke',   'Soninke',   FALSE),
    ('Balante',   'Balante',   FALSE)
) AS l(name, name_local, is_official)
CROSS JOIN countries c WHERE c.code = 'SEN'
ON CONFLICT (name, country_id) DO NOTHING;

-- Seed : langues de Cote d'Ivoire
INSERT INTO languages (name, name_local, country_id, is_official)
SELECT l.name, l.name_local, c.id, l.is_official
FROM (VALUES
    ('Francais',  'Francais',  TRUE),
    ('Dioula',    'Dioula',    FALSE),
    ('Baoule',    'Baoule',    FALSE),
    ('Bete',      'Bete',      FALSE),
    ('Senoufo',   'Senoufo',   FALSE),
    ('Yacouba',   'Dan',       FALSE),
    ('Agni',      'Agni',      FALSE),
    ('Guere',     'Guere',     FALSE)
) AS l(name, name_local, is_official)
CROSS JOIN countries c WHERE c.code = 'CIV'
ON CONFLICT (name, country_id) DO NOTHING;

-- Seed : langues du Congo (RDC)
INSERT INTO languages (name, name_local, country_id, is_official)
SELECT l.name, l.name_local, c.id, l.is_official
FROM (VALUES
    ('Francais',   'Francais',   TRUE),
    ('Lingala',    'Lingala',    FALSE),
    ('Swahili',    'Kiswahili',  FALSE),
    ('Kikongo',    'Kikongo',    FALSE),
    ('Tshiluba',   'Tshiluba',   FALSE)
) AS l(name, name_local, is_official)
CROSS JOIN countries c WHERE c.code = 'COD'
ON CONFLICT (name, country_id) DO NOTHING;

-- Seed : langues du Nigeria
INSERT INTO languages (name, name_local, country_id, is_official)
SELECT l.name, l.name_local, c.id, l.is_official
FROM (VALUES
    ('Anglais',  'English',  TRUE),
    ('Hausa',    'Hausa',    FALSE),
    ('Yoruba',   'Yoruba',   FALSE),
    ('Igbo',     'Igbo',     FALSE),
    ('Fulani',   'Fulfulde', FALSE),
    ('Pidgin',   'Pidgin',   FALSE)
) AS l(name, name_local, is_official)
CROSS JOIN countries c WHERE c.code = 'NGA'
ON CONFLICT (name, country_id) DO NOTHING;

-- Seed : langues du Ghana
INSERT INTO languages (name, name_local, country_id, is_official)
SELECT l.name, l.name_local, c.id, l.is_official
FROM (VALUES
    ('Anglais',  'English',  TRUE),
    ('Akan',     'Akan',     FALSE),
    ('Ewe',      'Ewe',      FALSE),
    ('Ga',       'Ga',       FALSE),
    ('Dagbani',  'Dagbani',  FALSE)
) AS l(name, name_local, is_official)
CROSS JOIN countries c WHERE c.code = 'GHA'
ON CONFLICT (name, country_id) DO NOTHING;

-- Seed : langues du Mali
INSERT INTO languages (name, name_local, country_id, is_official)
SELECT l.name, l.name_local, c.id, l.is_official
FROM (VALUES
    ('Francais',   'Francais',   TRUE),
    ('Bambara',    'Bamanankan', FALSE),
    ('Fulfulde',   'Fulfulde',   FALSE),
    ('Songhai',    'Songhai',    FALSE),
    ('Soninke',    'Soninke',    FALSE)
) AS l(name, name_local, is_official)
CROSS JOIN countries c WHERE c.code = 'MLI'
ON CONFLICT (name, country_id) DO NOTHING;

-- Seed : langues du Burkina Faso
INSERT INTO languages (name, name_local, country_id, is_official)
SELECT l.name, l.name_local, c.id, l.is_official
FROM (VALUES
    ('Francais',   'Francais',   TRUE),
    ('Moore',      'Moore',      FALSE),
    ('Dioula',     'Dioula',     FALSE),
    ('Fulfulde',   'Fulfulde',   FALSE),
    ('Bissa',      'Bissa',      FALSE)
) AS l(name, name_local, is_official)
CROSS JOIN countries c WHERE c.code = 'BFA'
ON CONFLICT (name, country_id) DO NOTHING;

-- Seed : langues du Rwanda
INSERT INTO languages (name, name_local, country_id, is_official)
SELECT l.name, l.name_local, c.id, l.is_official
FROM (VALUES
    ('Kinyarwanda', 'Ikinyarwanda', TRUE),
    ('Francais',    'Francais',     TRUE),
    ('Anglais',     'English',      TRUE),
    ('Swahili',     'Kiswahili',    FALSE)
) AS l(name, name_local, is_official)
CROSS JOIN countries c WHERE c.code = 'RWA'
ON CONFLICT (name, country_id) DO NOTHING;

-- Seed : langues de Tanzanie
INSERT INTO languages (name, name_local, country_id, is_official)
SELECT l.name, l.name_local, c.id, l.is_official
FROM (VALUES
    ('Swahili',  'Kiswahili', TRUE),
    ('Anglais',  'English',   TRUE),
    ('Sukuma',   'Sukuma',    FALSE),
    ('Chagga',   'Kichagga',  FALSE),
    ('Haya',     'Haya',      FALSE)
) AS l(name, name_local, is_official)
CROSS JOIN countries c WHERE c.code = 'TZA'
ON CONFLICT (name, country_id) DO NOTHING;
