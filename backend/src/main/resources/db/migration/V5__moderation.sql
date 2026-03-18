-- V5: Workflow de moderation complet
-- Etend la table posts et ajoute les tables de file d'attente et de logs

-- 1. Etendre le CHECK constraint sur moderation_status pour inclure SHADOW_BANNED
ALTER TABLE posts DROP CONSTRAINT IF EXISTS posts_moderation_status_check;
ALTER TABLE posts ADD CONSTRAINT posts_moderation_status_check
    CHECK (moderation_status IN ('PENDING','APPROVED','REJECTED','FLAGGED','SHADOW_BANNED'));

-- 2. Nouvelles colonnes sur posts (moderation humaine)
ALTER TABLE posts ADD COLUMN IF NOT EXISTS moderation_note  TEXT;
ALTER TABLE posts ADD COLUMN IF NOT EXISTS moderated_by     UUID REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE posts ADD COLUMN IF NOT EXISTS moderated_at     TIMESTAMPTZ;
ALTER TABLE posts ADD COLUMN IF NOT EXISTS flag_count       INT NOT NULL DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_posts_moderated_by ON posts(moderated_by);

-- 3. File d'attente de moderation (signalements)
CREATE TABLE IF NOT EXISTS moderation_queue (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id     UUID        NOT NULL,
    village_id  UUID,
    reason      TEXT,
    reporter_id UUID,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_modqueue_post     FOREIGN KEY (post_id)     REFERENCES posts(id)     ON DELETE CASCADE,
    CONSTRAINT fk_modqueue_village  FOREIGN KEY (village_id)  REFERENCES villages(id)  ON DELETE SET NULL,
    CONSTRAINT fk_modqueue_reporter FOREIGN KEY (reporter_id) REFERENCES users(id)     ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_moderation_queue_post_id    ON moderation_queue(post_id);
CREATE INDEX IF NOT EXISTS idx_moderation_queue_village_id ON moderation_queue(village_id);
CREATE INDEX IF NOT EXISTS idx_moderation_queue_created_at ON moderation_queue(created_at DESC);

-- 4. Logs des decisions de moderation (audit trail immuable)
CREATE TABLE IF NOT EXISTS moderation_logs (
    id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id      UUID        NOT NULL,
    moderator_id UUID,
    action       VARCHAR(20) NOT NULL
                     CHECK (action IN ('APPROVED','REJECTED','FLAGGED','SHADOW_BANNED','PENDING')),
    note         TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_modlog_post      FOREIGN KEY (post_id)      REFERENCES posts(id)  ON DELETE CASCADE,
    CONSTRAINT fk_modlog_moderator FOREIGN KEY (moderator_id) REFERENCES users(id)  ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_moderation_logs_post_id      ON moderation_logs(post_id);
CREATE INDEX IF NOT EXISTS idx_moderation_logs_moderator_id ON moderation_logs(moderator_id);
CREATE INDEX IF NOT EXISTS idx_moderation_logs_created_at   ON moderation_logs(created_at DESC);
