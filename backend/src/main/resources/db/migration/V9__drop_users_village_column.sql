-- V9: Suppression de la colonne village de la table users
-- La relation User <-> Village est geree via village_subscriptions (N:N)
ALTER TABLE users DROP COLUMN IF EXISTS village;
