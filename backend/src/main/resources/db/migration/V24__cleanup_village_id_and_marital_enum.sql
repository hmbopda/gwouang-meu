-- =====================================================================
-- V24 : Nettoyage architectural du module genealogie
-- =====================================================================

-- 1. Supprimer la colonne village_id orpheline de persons
--    Depuis V14 (person_villages M:N), cette colonne n'est plus utilisee.
--    L'index idx_persons_village devient aussi inutile.
DROP INDEX IF EXISTS idx_persons_village;
ALTER TABLE persons DROP COLUMN IF EXISTS village_id;

-- 2. Creer le type enum marital_status_enum
--    V20 avait ajoute marital_status comme VARCHAR(30) au lieu d'un enum type.
--    On cree le type et on convertit la colonne.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'marital_status_enum') THEN
        CREATE TYPE marital_status_enum AS ENUM ('SINGLE', 'MARRIED', 'WIDOWED', 'DIVORCED');
    END IF;
END $$;

ALTER TABLE persons
    ALTER COLUMN marital_status TYPE marital_status_enum
    USING marital_status::marital_status_enum;

-- 3. Index sur email pour la deduplication (findByEmailIgnoreCase)
CREATE INDEX IF NOT EXISTS idx_persons_email ON persons(email) WHERE email IS NOT NULL;

-- 4. Index sur unions pour les requetes actives par femme
CREATE INDEX IF NOT EXISTS idx_unions_wife_active
    ON unions(wife_id) WHERE end_date IS NULL;
