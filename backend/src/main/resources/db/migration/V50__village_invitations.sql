-- V50: Invitations a rejoindre un village
-- Un notable/chef invite un utilisateur (par id) ou par email (invited_user_id NULL).
-- Toutes colonnes texte en VARCHAR (jamais CHAR). Audit created_at/updated_at TIMESTAMPTZ.

CREATE TABLE IF NOT EXISTS village_invitations (
    id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    village_id      UUID         NOT NULL,
    invited_user_id UUID,
    invited_email   VARCHAR(200),
    invited_by      UUID         NOT NULL,
    status          VARCHAR(20)  NOT NULL DEFAULT 'PENDING'
                        CHECK (status IN ('PENDING','ACCEPTED','DECLINED','EXPIRED')),
    message         VARCHAR(300),
    decided_at      TIMESTAMPTZ,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_vinv_village    FOREIGN KEY (village_id)      REFERENCES villages(id) ON DELETE CASCADE,
    CONSTRAINT fk_vinv_user       FOREIGN KEY (invited_user_id) REFERENCES users(id)    ON DELETE CASCADE,
    CONSTRAINT fk_vinv_invited_by FOREIGN KEY (invited_by)      REFERENCES users(id)    ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_vinv_user_status    ON village_invitations(invited_user_id, status);
CREATE INDEX IF NOT EXISTS idx_vinv_village_status ON village_invitations(village_id, status);

-- Eviter les doublons d'invitation pour un meme utilisateur (accepte plusieurs invitations par email NULL user)
CREATE UNIQUE INDEX IF NOT EXISTS uq_vinv_village_user
    ON village_invitations(village_id, invited_user_id);
