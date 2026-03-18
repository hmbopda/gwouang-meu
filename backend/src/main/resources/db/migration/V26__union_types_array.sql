-- Convertir union_type (single enum) en union_types (array d'enum)
-- pour supporter plusieurs types par union (ex: DOT + CIVIL + RELIGIOUS)

ALTER TABLE unions
    ADD COLUMN union_types text[] NOT NULL DEFAULT '{}';

-- Migrer les données existantes
UPDATE unions SET union_types = ARRAY[union_type::text];

-- Supprimer l'ancienne colonne
ALTER TABLE unions DROP COLUMN union_type;
