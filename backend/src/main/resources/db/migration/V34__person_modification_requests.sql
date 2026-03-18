-- Table des demandes de modification d'une fiche personne (enfant < 4 ans)
-- Workflow : un parent modifie les infos d'un enfant, l'autre parent doit valider
CREATE TABLE person_modification_requests (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id       UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
    requester_id    UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
    changes         JSONB NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    responded_at    TIMESTAMPTZ,
    responder_id    UUID REFERENCES persons(id)
);

CREATE INDEX idx_pmr_person_status ON person_modification_requests(person_id, status);
CREATE INDEX idx_pmr_requester ON person_modification_requests(requester_id);
