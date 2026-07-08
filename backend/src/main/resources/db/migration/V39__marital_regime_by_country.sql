-- ════════════════════════════════════════════════════════════════
-- V39 : Modele « regime matrimonial par pays »
--
-- On enregistre TOUJOURS le fait genealogique (realite historique/
-- culturelle). Ces colonnes portent la conformite au droit civil du
-- pays de residence/celebration, jamais un jugement de legitimite.
--
-- persons : pays de residence + regime matrimonial declare
-- unions  : regime legal, caractere polygame, pays de celebration,
--           statut de conformite + note explicative
-- ════════════════════════════════════════════════════════════════

-- ── PERSONS ──────────────────────────────────────────────────────
ALTER TABLE persons ADD COLUMN IF NOT EXISTS residence_country VARCHAR(2);
ALTER TABLE persons ADD COLUMN IF NOT EXISTS marital_regime    VARCHAR(20);

-- ── UNIONS ───────────────────────────────────────────────────────
ALTER TABLE unions ADD COLUMN IF NOT EXISTS legal_regime      VARCHAR(30);
ALTER TABLE unions ADD COLUMN IF NOT EXISTS is_polygamous     BOOLEAN DEFAULT FALSE;
ALTER TABLE unions ADD COLUMN IF NOT EXISTS legal_country     VARCHAR(2);
ALTER TABLE unions ADD COLUMN IF NOT EXISTS compliance_status VARCHAR(20);
ALTER TABLE unions ADD COLUMN IF NOT EXISTS compliance_note   TEXT;

-- Backfill is_polygamous : true si le mari porte > 1 union active
-- (une union active = end_date NULL et statut non termine).
UPDATE unions u
SET is_polygamous = TRUE
WHERE u.husband_id IN (
    SELECT husband_id
    FROM unions
    WHERE end_date IS NULL
      AND status IN ('ACTIVE', 'PENDING_APPROVAL', 'DIVORCE_PENDING', 'DEATH_PENDING', 'DISPUTE')
    GROUP BY husband_id
    HAVING COUNT(*) > 1
);
