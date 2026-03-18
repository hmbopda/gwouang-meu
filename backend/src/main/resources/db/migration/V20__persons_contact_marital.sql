-- V20: Ajout email, telephone et statut matrimonial sur persons
-- Permet au parent invite de completer ses coordonnees et son statut

ALTER TABLE persons ADD COLUMN IF NOT EXISTS email VARCHAR(255);
ALTER TABLE persons ADD COLUMN IF NOT EXISTS phone VARCHAR(30);
ALTER TABLE persons ADD COLUMN IF NOT EXISTS marital_status VARCHAR(30);
