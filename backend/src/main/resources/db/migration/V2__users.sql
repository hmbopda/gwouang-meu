-- V2: Table des utilisateurs
CREATE TABLE IF NOT EXISTS users (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    supabase_id VARCHAR(255) NOT NULL UNIQUE,
    email       VARCHAR(255) NOT NULL UNIQUE,
    display_name VARCHAR(100),
    role        VARCHAR(20)  NOT NULL DEFAULT 'MEMBRE'
                    CHECK (role IN ('SUPER_ADMIN','MODERATEUR','AMBASSADEUR','MEMBRE','VISITEUR','API')),
    country     VARCHAR(3),
    native_language VARCHAR(20),
    bio         TEXT,
    avatar_url  VARCHAR(500),
    origin_village_id UUID,
    fcm_token   VARCHAR(500),
    is_active   BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_supabase_id ON users(supabase_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
