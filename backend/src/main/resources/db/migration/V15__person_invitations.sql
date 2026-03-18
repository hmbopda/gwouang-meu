-- Table des invitations pour les personnes encore vivantes
CREATE TABLE person_invitations (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id       UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
    email           VARCHAR(255),
    phone           VARCHAR(30),
    token           VARCHAR(100) UNIQUE NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    invited_by      UUID NOT NULL REFERENCES users(id),
    knows_inviter   BOOLEAN,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at      TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '30 days',
    accepted_at     TIMESTAMPTZ
);

CREATE INDEX idx_pi_token     ON person_invitations(token);
CREATE INDEX idx_pi_person    ON person_invitations(person_id);
CREATE INDEX idx_pi_status    ON person_invitations(status);
