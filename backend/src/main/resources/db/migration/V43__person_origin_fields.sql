-- ════════════════════════════════════════════════════════════════
-- V43 : Separation ORIGINE / RESIDENCE sur persons
--
-- Une lignee / un arbre S'ANCRE sur l'ORIGINE (village, ville,
-- region, pays d'origine). Le LIEU DE RESIDENCE est distinct : il
-- ne sert qu'a l'EVOLUTION (migration, situation actuelle) et au
-- droit applicable des unions (conformite = droit du pays de
-- RESIDENCE, cf. V39). birth_place reste un FAIT (lieu de
-- naissance), ni origine ni residence. Les colonnes origin_* en
-- texte libre completent le lien structure person_villages.
-- ════════════════════════════════════════════════════════════════

-- ── PERSONS : origine (ancre de la lignee) ───────────────────────
ALTER TABLE persons ADD COLUMN IF NOT EXISTS origin_village VARCHAR(150);
ALTER TABLE persons ADD COLUMN IF NOT EXISTS origin_city    VARCHAR(150);
ALTER TABLE persons ADD COLUMN IF NOT EXISTS origin_region  VARCHAR(150);
ALTER TABLE persons ADD COLUMN IF NOT EXISTS origin_country VARCHAR(2);

-- ── PERSONS : residence (evolution / situation actuelle) ─────────
ALTER TABLE persons ADD COLUMN IF NOT EXISTS residence_city VARCHAR(150);

COMMENT ON COLUMN persons.origin_village IS
    'Village d''origine (texte libre) — ancre de la lignee ; complete le lien structure person_villages';
COMMENT ON COLUMN persons.origin_city IS
    'Ville d''origine — ancre de la lignee';
COMMENT ON COLUMN persons.origin_region IS
    'Region d''origine — ancre de la lignee';
COMMENT ON COLUMN persons.origin_country IS
    'Pays d''origine, ISO-3166 alpha-2 — ancre de la lignee';
COMMENT ON COLUMN persons.residence_city IS
    'Ville de residence actuelle — evolution (migration), jamais une ancre de lignee';
COMMENT ON COLUMN persons.residence_country IS
    'Pays de residence actuelle, ISO-3166 alpha-2 — evolution + droit applicable des unions (V39)';
