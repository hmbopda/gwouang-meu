-- ==========================================================
-- V37 : Correction type colonne union_order dans table unions
-- V12 a créé union_order en SMALLINT mais l'entité GenealogyUnion
-- mappe ce champ en Integer (Types#INTEGER) → schema-validation échoue
-- ==========================================================

ALTER TABLE unions
    ALTER COLUMN union_order TYPE INTEGER USING union_order::INTEGER;
