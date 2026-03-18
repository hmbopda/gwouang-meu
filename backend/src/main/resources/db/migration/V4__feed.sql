-- V4: Tables du fil d'actualite
CREATE TABLE IF NOT EXISTS posts (
    id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    author_id         UUID        NOT NULL,
    village_id        UUID,
    content           TEXT        NOT NULL,
    media_url         VARCHAR(500),
    moderation_status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
                          CHECK (moderation_status IN ('PENDING','APPROVED','REJECTED','FLAGGED')),
    moderation_reason TEXT,
    moderation_score  DOUBLE PRECISION,
    is_pinned         BOOLEAN     NOT NULL DEFAULT FALSE,
    reaction_count    INT         NOT NULL DEFAULT 0,
    comment_count     INT         NOT NULL DEFAULT 0,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_post_author  FOREIGN KEY (author_id)  REFERENCES users(id)    ON DELETE CASCADE,
    CONSTRAINT fk_post_village FOREIGN KEY (village_id) REFERENCES villages(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_posts_author_id        ON posts(author_id);
CREATE INDEX IF NOT EXISTS idx_posts_village_id       ON posts(village_id);
CREATE INDEX IF NOT EXISTS idx_posts_moderation_status ON posts(moderation_status);
CREATE INDEX IF NOT EXISTS idx_posts_created_at       ON posts(created_at DESC);

CREATE TABLE IF NOT EXISTS comments (
    id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id           UUID        NOT NULL,
    author_id         UUID        NOT NULL,
    content           TEXT        NOT NULL,
    parent_comment_id UUID,
    moderation_status VARCHAR(20) NOT NULL DEFAULT 'APPROVED'
                          CHECK (moderation_status IN ('PENDING','APPROVED','REJECTED','FLAGGED')),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_comment_post   FOREIGN KEY (post_id)           REFERENCES posts(id)    ON DELETE CASCADE,
    CONSTRAINT fk_comment_author FOREIGN KEY (author_id)         REFERENCES users(id)    ON DELETE CASCADE,
    CONSTRAINT fk_comment_parent FOREIGN KEY (parent_comment_id) REFERENCES comments(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_comments_post_id   ON comments(post_id);
CREATE INDEX IF NOT EXISTS idx_comments_author_id ON comments(author_id);

CREATE TABLE IF NOT EXISTS post_reactions (
    id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id    UUID        NOT NULL,
    user_id    UUID        NOT NULL,
    type       VARCHAR(20) NOT NULL DEFAULT 'LIKE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_post_user_reaction UNIQUE (post_id, user_id),
    CONSTRAINT fk_reaction_post FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    CONSTRAINT fk_reaction_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_reactions_post_id ON post_reactions(post_id);
