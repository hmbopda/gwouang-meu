-- Relation N:N entre persons et villages
CREATE TABLE person_villages (
    person_id  UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
    village_id UUID NOT NULL REFERENCES villages(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (person_id, village_id)
);

CREATE INDEX idx_pv_person  ON person_villages(person_id);
CREATE INDEX idx_pv_village ON person_villages(village_id);

-- Migrer les donnees existantes
INSERT INTO person_villages (person_id, village_id)
SELECT id, village_id FROM persons WHERE village_id IS NOT NULL
ON CONFLICT DO NOTHING;

-- Supprimer l'ancienne colonne et son index
DROP INDEX IF EXISTS idx_persons_village;
ALTER TABLE persons DROP COLUMN IF EXISTS village_id;
