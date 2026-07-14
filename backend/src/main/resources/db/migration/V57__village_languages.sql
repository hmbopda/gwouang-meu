-- V57: Association N:N village <-> langues.
-- Un village parle UNE OU PLUSIEURS langues ; l'une est marquee « principale »
-- (is_primary = langue native par defaut pour la traduction).
--
-- Le referentiel `languages` existe DEJA (V16/V17, deja seede avec les langues
-- majeures du Cameroun) : on l'ENRICHIT de facon additive (code, nom francais,
-- ISO 639-3, region, actif) sans casser le module geo qui l'utilise.
-- Colonnes texte VARCHAR (jamais CHAR). Audit created_at/updated_at TIMESTAMPTZ.

-- ── 1. Enrichissement ADDITIF du referentiel des langues ──────────────
ALTER TABLE languages ADD COLUMN IF NOT EXISTS code        VARCHAR(30);
ALTER TABLE languages ADD COLUMN IF NOT EXISTS french_name VARCHAR(100);
ALTER TABLE languages ADD COLUMN IF NOT EXISTS iso639_3    VARCHAR(3);
ALTER TABLE languages ADD COLUMN IF NOT EXISTS region      VARCHAR(120);
ALTER TABLE languages ADD COLUMN IF NOT EXISTS active      BOOLEAN NOT NULL DEFAULT TRUE;

-- Unicite du slug `code` quand il est renseigne (les lignes historiques restent NULL).
CREATE UNIQUE INDEX IF NOT EXISTS ux_languages_code ON languages(code) WHERE code IS NOT NULL;

-- Enrichit les langues camerounaises majeures deja presentes (UPDATE par nom).
UPDATE languages SET code='basaa',     french_name='Bassa',      iso639_3='bas', region='Centre / Littoral'  WHERE code IS NULL AND LOWER(name) IN ('bassa','basaa');
UPDATE languages SET code='duala',     french_name='Douala',     iso639_3='dua', region='Littoral'           WHERE code IS NULL AND LOWER(name) IN ('douala','duala');
UPDATE languages SET code='ewondo',    french_name='Ewondo',     iso639_3='ewo', region='Centre'             WHERE code IS NULL AND LOWER(name)='ewondo';
UPDATE languages SET code='bulu',      french_name='Boulou',     iso639_3='bum', region='Sud'                WHERE code IS NULL AND LOWER(name)='bulu';
UPDATE languages SET code='medumba',   french_name='Medumba',    iso639_3='byv', region='Ouest (Bangangte)'  WHERE code IS NULL AND LOWER(name)='medumba';
UPDATE languages SET code='yemba',     french_name='Yemba',      iso639_3='ybb', region='Ouest (Dschang)'    WHERE code IS NULL AND LOWER(name)='yemba';
UPDATE languages SET code='ngiemboon', french_name='Ngiemboon',  iso639_3='nnh', region='Ouest'              WHERE code IS NULL AND LOWER(name)='ngiemboon';
UPDATE languages SET code='feefee',    french_name='Fe''efe''e', iso639_3='fmp', region='Ouest (Bafang)'     WHERE code IS NULL AND LOWER(name)='fe''efe''e';
UPDATE languages SET code='bamun',     french_name='Bamoun',     iso639_3='bax', region='Ouest (Foumban)'    WHERE code IS NULL AND LOWER(name) IN ('bamoun','bamun');
UPDATE languages SET code='fulfulde',  french_name='Foulfoulde', iso639_3='fub', region='Adamaoua / Nord'    WHERE code IS NULL AND LOWER(name)='fulfulde';
UPDATE languages SET code='aghem',     french_name='Aghem',      iso639_3='agq', region='Nord-Ouest (Wum)'   WHERE code IS NULL AND LOWER(name)='aghem';
UPDATE languages SET code='kom',       french_name='Kom',        iso639_3='bkm', region='Nord-Ouest'         WHERE code IS NULL AND LOWER(name)='kom';
UPDATE languages SET code='bafut',     french_name='Bafut',      iso639_3='bfd', region='Nord-Ouest'         WHERE code IS NULL AND LOWER(name)='bafut';
UPDATE languages SET code='kenyang',   french_name='Kenyang',                    region='Sud-Ouest'          WHERE code IS NULL AND LOWER(name)='kenyang';
UPDATE languages SET code='ejagham',   french_name='Ejagham',    iso639_3='etu', region='Sud-Ouest'          WHERE code IS NULL AND LOWER(name)='ejagham';
UPDATE languages SET code='lamnso',    french_name='Lamnso''',   iso639_3='lns', region='Nord-Ouest (Kumbo)' WHERE code IS NULL AND LOWER(name) IN ('nso','lamnso''');
UPDATE languages SET code='ngomba',    french_name='Ngomba',                     region='Ouest'              WHERE code IS NULL AND LOWER(name)='ngomba';

-- Ajoute quelques langues majeures absentes du referentiel (name est UNIQUE).
INSERT INTO languages (name, name_local, code, french_name, iso639_3, region) VALUES
    ('Ghomala''',          'Ghomala''', 'ghomala', 'Ghomala''',           'bbj', 'Ouest (Bamileke)'),
    ('Mungaka',            'Mungaka',   'mungaka', 'Mungaka',             'mhk', 'Nord-Ouest (Bali)'),
    ('Mundani',            'Mundani',   'mundani', 'Mundani',             NULL,  'Sud-Ouest'),
    ('Fang',               'Fang',      'fang',    'Fang',                'fan', 'Sud'),
    ('Pidgin camerounais', 'Pidgin',    'pidgin',  'Pidgin camerounais',  'wes', 'Zones anglophones')
ON CONFLICT (name) DO NOTHING;

-- ── 2. Table de jonction N:N village <-> langue ──────────────────────
CREATE TABLE IF NOT EXISTS village_languages (
    village_id   UUID        NOT NULL,
    language_id  UUID        NOT NULL,
    is_primary   BOOLEAN     NOT NULL DEFAULT FALSE,
    ordinal      INTEGER     NOT NULL DEFAULT 0,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (village_id, language_id),
    CONSTRAINT fk_vlang_village  FOREIGN KEY (village_id)  REFERENCES villages(id)  ON DELETE CASCADE,
    CONSTRAINT fk_vlang_language FOREIGN KEY (language_id) REFERENCES languages(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_vlang_village ON village_languages(village_id);
