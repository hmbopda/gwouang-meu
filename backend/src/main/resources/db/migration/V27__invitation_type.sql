-- Ajout du type d'invitation (PARENT = lien parent-enfant, SPOUSE = lien conjoint)
ALTER TABLE person_invitations ADD COLUMN invitation_type VARCHAR(20) NOT NULL DEFAULT 'PARENT';
