-- Discussions de FAMILLE (à portée clan/lignée), en plus des groupes de village.
-- Le village devient optionnel ; on ajoute le clan de rattachement.

ALTER TABLE chat_groups ALTER COLUMN village_id DROP NOT NULL;

ALTER TABLE chat_groups ADD COLUMN IF NOT EXISTS family_clan VARCHAR(100);

CREATE INDEX IF NOT EXISTS idx_chat_group_family_clan
    ON chat_groups (family_clan);
