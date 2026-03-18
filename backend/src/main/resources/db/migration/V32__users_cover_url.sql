-- V32 : Ajout photo de couverture au profil utilisateur
ALTER TABLE users ADD COLUMN cover_url VARCHAR(500);
