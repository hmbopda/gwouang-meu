-- ════════════════════════════════════════════════════════════════
-- V51 : Origine référentielle sur users + recherche chefferie floue
--
-- 1) Le profil (users) peut désormais ancrer sa lignée sur le RÉFÉRENTIEL
--    territorial (région → département → commune → chefferie), aligné sur
--    OriginSelection (front) et sur persons (V43). L'origine est l'ancre
--    de la lignée ; la résidence (residence_*) reste l'évolution.
-- 2) La recherche de chefferie devient GLOBALE (sans dérouler la cascade)
--    et TOLÉRANTE aux accents/fautes de frappe : « Bandenkop » comme
--    « Badenkop » ramènent « Chefferie BANDENKOP ». unaccent (accents) +
--    pg_trgm (similarité) — activés ici, portables et idempotents.
-- ════════════════════════════════════════════════════════════════

-- ── Extensions : accent-insensibilité + recherche floue ──────────
-- Idempotent (IF NOT EXISTS) et portable (déploiement neuf ailleurs).
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ── USERS : origine = ancre de la lignée (noms du référentiel) ────
ALTER TABLE users ADD COLUMN IF NOT EXISTS origin_country        VARCHAR(2);
ALTER TABLE users ADD COLUMN IF NOT EXISTS origin_region         VARCHAR(150);
ALTER TABLE users ADD COLUMN IF NOT EXISTS origin_department     VARCHAR(150);
ALTER TABLE users ADD COLUMN IF NOT EXISTS origin_arrondissement VARCHAR(150);
ALTER TABLE users ADD COLUMN IF NOT EXISTS origin_village        VARCHAR(150);

COMMENT ON COLUMN users.origin_country IS
    'Pays d''origine, ISO-3166 alpha-2 — ancre de la lignée';
COMMENT ON COLUMN users.origin_region IS
    'Région d''origine (nom référentiel) — ancre de la lignée';
COMMENT ON COLUMN users.origin_department IS
    'Département d''origine (nom référentiel)';
COMMENT ON COLUMN users.origin_arrondissement IS
    'Commune / arrondissement d''origine (nom référentiel, optionnel)';
COMMENT ON COLUMN users.origin_village IS
    'Chefferie / village d''origine (dénomination référentiel) — ancre de la lignée';
