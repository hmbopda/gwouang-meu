-- Table des demandes d'association d'un enfant a un co-parent
-- Workflow : l'initiateur cree un enfant et demande au co-parent de valider la filiation
CREATE TABLE child_association_requests (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id          UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
    requester_id      UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
    target_parent_id  UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
    status            VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    responded_at      TIMESTAMPTZ,

    CONSTRAINT uq_child_association_request UNIQUE (child_id, target_parent_id)
);

CREATE INDEX idx_car_target_status ON child_association_requests(target_parent_id, status);
CREATE INDEX idx_car_requester ON child_association_requests(requester_id);
CREATE INDEX idx_car_child ON child_association_requests(child_id);
