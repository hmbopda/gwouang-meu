-- ════════════════════════════════════════════════════════════════
-- V42 : Regle « mariage entre personnes de meme sexe » par pays
--
-- Ajoute la colonne same_sex_allowed au referentiel des regles de
-- mariage. Defaut FALSE : dans la plupart des pays africains cibles
-- (ex. Cameroun), une union unit un HOMME et une FEMME et le mariage
-- meme sexe n'y est pas reconnu. Les pays absents du referentiel sont
-- traites comme heterosexuels par prudence pour ce public.
--
-- Seuls les pays occidentaux du referentiel ou le mariage meme sexe est
-- reconnu passent a TRUE.
--
-- Migration idempotente (ADD COLUMN IF NOT EXISTS + UPDATE cible).
-- ════════════════════════════════════════════════════════════════

ALTER TABLE country_marriage_rules
    ADD COLUMN IF NOT EXISTS same_sex_allowed boolean NOT NULL DEFAULT false;

UPDATE country_marriage_rules
    SET same_sex_allowed = true
    WHERE iso2 IN ('FR', 'BE', 'CA', 'US', 'GB', 'DE', 'CH');
