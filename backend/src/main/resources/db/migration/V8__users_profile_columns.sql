-- V8: Ajout des colonnes profil utilisateur manquantes
-- + correction de country VARCHAR(3) -> VARCHAR(100) pour supporter les noms complets

-- Corriger la taille de country
ALTER TABLE users ALTER COLUMN country TYPE VARCHAR(100);

-- Parents
ALTER TABLE users ADD COLUMN IF NOT EXISTS father_name VARCHAR(100);
ALTER TABLE users ADD COLUMN IF NOT EXISTS father_origin VARCHAR(255);
ALTER TABLE users ADD COLUMN IF NOT EXISTS mother_name VARCHAR(100);
ALTER TABLE users ADD COLUMN IF NOT EXISTS mother_origin VARCHAR(255);

-- Famille
ALTER TABLE users ADD COLUMN IF NOT EXISTS marital_status VARCHAR(30);
ALTER TABLE users ADD COLUMN IF NOT EXISTS matrimonial_regime VARCHAR(30);
ALTER TABLE users ADD COLUMN IF NOT EXISTS children_count INTEGER;
ALTER TABLE users ADD COLUMN IF NOT EXISTS diet VARCHAR(30);

-- Origines culturelles
ALTER TABLE users ADD COLUMN IF NOT EXISTS village VARCHAR(255);
ALTER TABLE users ADD COLUMN IF NOT EXISTS tribe VARCHAR(50);
ALTER TABLE users ADD COLUMN IF NOT EXISTS clan VARCHAR(50);

-- Residence & Profession
ALTER TABLE users ADD COLUMN IF NOT EXISTS profession VARCHAR(255);
ALTER TABLE users ADD COLUMN IF NOT EXISTS employer VARCHAR(255);
ALTER TABLE users ADD COLUMN IF NOT EXISTS residence_city VARCHAR(255);
ALTER TABLE users ADD COLUMN IF NOT EXISTS residence_country VARCHAR(255);
