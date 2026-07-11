-- ════════════════════════════════════════════════════════════════
-- V52 : Pont référentiel → communauté
--
-- Permet de matérialiser une chefferie du référentiel (chefferies) en
-- communauté de village (villages) : « fonder / rejoindre Bandenkop ».
-- Le lien chefferie_id sert de clé de dédoublonnage — une chefferie ne
-- se matérialise qu'une seule fois, quel que soit le nombre de membres.
-- ════════════════════════════════════════════════════════════════

ALTER TABLE villages ADD COLUMN IF NOT EXISTS chefferie_id UUID;

-- Dédoublonnage : au plus une communauté par chefferie.
CREATE UNIQUE INDEX IF NOT EXISTS ux_villages_chefferie_id
    ON villages (chefferie_id) WHERE chefferie_id IS NOT NULL;

COMMENT ON COLUMN villages.chefferie_id IS
    'Chefferie du référentiel (chefferies.id) matérialisée en communauté — clé de dédoublonnage';
