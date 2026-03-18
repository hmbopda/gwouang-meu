-- =====================================================================
-- V21 : Corrections d'integrite pour le module genealogie
-- =====================================================================

-- 1. UNIQUE sur persons.user_id : une Person par User maximum
--    Empeche qu'un seul compte soit lie a plusieurs fiches personne
CREATE UNIQUE INDEX IF NOT EXISTS uq_persons_user_id
    ON persons (user_id) WHERE user_id IS NOT NULL;

-- 2. Fix FK person_invitations.invited_by sans ON DELETE
--    Evite violation FK si un user est supprime
ALTER TABLE person_invitations
    DROP CONSTRAINT IF EXISTS person_invitations_invited_by_fkey;
ALTER TABLE person_invitations
    ADD CONSTRAINT person_invitations_invited_by_fkey
    FOREIGN KEY (invited_by) REFERENCES users(id) ON DELETE SET NULL;

-- Rendre invited_by nullable (pour supporter ON DELETE SET NULL)
ALTER TABLE person_invitations ALTER COLUMN invited_by DROP NOT NULL;

-- 3. Index sur parent_child pour accelerer les requetes genealogiques
CREATE INDEX IF NOT EXISTS idx_parent_child_parent ON parent_child(parent_id);
CREATE INDEX IF NOT EXISTS idx_parent_child_child ON parent_child(child_id);
CREATE INDEX IF NOT EXISTS idx_parent_child_role ON parent_child(child_id, parent_role, parent_type);

-- 4. Index sur persons.user_id pour findByUserId
CREATE INDEX IF NOT EXISTS idx_persons_user_id ON persons(user_id) WHERE user_id IS NOT NULL;

-- 5. Index sur person_invitations pour lookup par token et status
CREATE INDEX IF NOT EXISTS idx_invitations_token ON person_invitations(token);
CREATE INDEX IF NOT EXISTS idx_invitations_person_status ON person_invitations(person_id, status);
