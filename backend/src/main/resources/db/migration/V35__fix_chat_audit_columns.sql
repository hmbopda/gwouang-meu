-- ==========================================================
-- V35 : Correction colonnes audit sur tables chat
-- chat_group_members : joined_at -> created_at + updated_at
-- chat_messages : ajout updated_at
-- ==========================================================

-- chat_group_members : renommer joined_at en created_at + ajouter updated_at
ALTER TABLE chat_group_members
    RENAME COLUMN joined_at TO created_at;

ALTER TABLE chat_group_members
    ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- chat_messages : ajouter updated_at
ALTER TABLE chat_messages
    ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
