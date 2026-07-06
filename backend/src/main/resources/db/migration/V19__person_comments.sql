-- ═══════════════════════════════════════════════════════════════
-- V19 : Commentaires / notes sur une fiche personne (genealogie)
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS person_comments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id       UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
    author_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content         TEXT NOT NULL,
    parent_comment_id UUID REFERENCES person_comments(id) ON DELETE CASCADE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_person_comments_person_id ON person_comments(person_id);
CREATE INDEX idx_person_comments_author_id ON person_comments(author_id);

-- RLS
ALTER TABLE person_comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "person_comments_select" ON person_comments
    FOR SELECT USING (true);

CREATE POLICY "person_comments_insert" ON person_comments
    FOR INSERT WITH CHECK (true);

-- auth.uid() n'existe que sur Supabase ; en CI (Postgres nu) ces politiques sont sans objet
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'auth') THEN
        EXECUTE 'CREATE POLICY "person_comments_update" ON person_comments
            FOR UPDATE USING (author_id = auth.uid())';
        EXECUTE 'CREATE POLICY "person_comments_delete" ON person_comments
            FOR DELETE USING (author_id = auth.uid())';
    END IF;
END $$;
