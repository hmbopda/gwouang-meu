-- ==========================================================
-- V31 : Module Chat — groupes, membres, messages
-- ==========================================================

CREATE TABLE chat_groups (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    village_id      UUID NOT NULL REFERENCES villages(id) ON DELETE CASCADE,
    name            VARCHAR(100) NOT NULL,
    description     TEXT,
    type            VARCHAR(20) NOT NULL DEFAULT 'GENERAL',
    created_by      UUID NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE chat_group_members (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id    UUID NOT NULL REFERENCES chat_groups(id) ON DELETE CASCADE,
    user_id     UUID NOT NULL REFERENCES users(id),
    role        VARCHAR(20) NOT NULL DEFAULT 'MEMBER',
    joined_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(group_id, user_id)
);

CREATE TABLE chat_messages (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id    UUID NOT NULL REFERENCES chat_groups(id) ON DELETE CASCADE,
    sender_id   UUID NOT NULL REFERENCES users(id),
    content     TEXT NOT NULL,
    type        VARCHAR(20) NOT NULL DEFAULT 'TEXT',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes pour la performance
CREATE INDEX idx_chat_group_village   ON chat_groups(village_id);
CREATE INDEX idx_chat_member_group    ON chat_group_members(group_id);
CREATE INDEX idx_chat_member_user     ON chat_group_members(user_id);
CREATE INDEX idx_chat_msg_group_date  ON chat_messages(group_id, created_at DESC);
CREATE INDEX idx_chat_msg_sender      ON chat_messages(sender_id);
