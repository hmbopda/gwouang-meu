-- Table notifications in-app (style Facebook/Instagram)
CREATE TABLE notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,          -- UNION_REQUEST, PARENT_LINK, CHILD_LINK, INVITATION_ACCEPTED, etc.
    title VARCHAR(200) NOT NULL,
    body TEXT,
    data JSONB,                         -- données contextuelles (personId, unionId, invitationToken, etc.)
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_user_read ON notifications(user_id, is_read);
