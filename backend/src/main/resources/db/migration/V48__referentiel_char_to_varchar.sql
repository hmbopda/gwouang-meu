-- ════════════════════════════════════════════════════════════════
-- V48 : Aligne les colonnes CHAR(2) du referentiel sur VARCHAR(2).
--
-- Les entites JPA mappent ces codes en String → Hibernate attend VARCHAR.
-- Un CHAR(2) faisait echouer la validation Hibernate au demarrage
-- (« wrong column type ... found bpchar, expecting varchar »). On corrige le
-- schema pour qu'il soit coherent (utile si la validation est reactivee et
-- pour un deploiement neuf). Aucune perte de donnees (CHAR→VARCHAR est sur).
-- ════════════════════════════════════════════════════════════════

ALTER TABLE geo_regions          ALTER COLUMN country_iso2 TYPE VARCHAR(2);
ALTER TABLE geo_departments      ALTER COLUMN country_iso2 TYPE VARCHAR(2);
ALTER TABLE geo_arrondissements  ALTER COLUMN country_iso2 TYPE VARCHAR(2);
ALTER TABLE chefferies           ALTER COLUMN country_iso2 TYPE VARCHAR(2);
ALTER TABLE countries            ALTER COLUMN iso2         TYPE VARCHAR(2);
