-- V49: Socle de gouvernance de village
-- Roles delegues, demandes d'adhesion (auto/valides), validations culturelles/successorales.
-- Toutes colonnes texte/codes/labels en VARCHAR (jamais CHAR). Audit created_at/updated_at TIMESTAMPTZ.

-- 1. Roles delegues par village (notable, moderateur...) avec permissions CSV
CREATE TABLE IF NOT EXISTS village_member_roles (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    village_id  UUID         NOT NULL,
    user_id     UUID         NOT NULL,
    title       VARCHAR(80)  NOT NULL,
    permissions VARCHAR(300) NOT NULL,
    granted_by  UUID         NOT NULL,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_vmr_village_user UNIQUE (village_id, user_id),
    CONSTRAINT fk_vmr_village    FOREIGN KEY (village_id) REFERENCES villages(id) ON DELETE CASCADE,
    CONSTRAINT fk_vmr_user       FOREIGN KEY (user_id)    REFERENCES users(id)    ON DELETE CASCADE,
    CONSTRAINT fk_vmr_granted_by FOREIGN KEY (granted_by) REFERENCES users(id)    ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_vmr_village_id ON village_member_roles(village_id);

-- 2. Demandes d'adhesion (auto-approuvees via genealogie, ou validees par un notable)
CREATE TABLE IF NOT EXISTS village_join_requests (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    village_id  UUID         NOT NULL,
    user_id     UUID         NOT NULL,
    status      VARCHAR(20)  NOT NULL
                    CHECK (status IN ('PENDING','AUTO_APPROVED','APPROVED','REJECTED')),
    reason      VARCHAR(300),
    auto_reason VARCHAR(200),
    decided_by  UUID,
    decided_at  TIMESTAMPTZ,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_vjr_village_user UNIQUE (village_id, user_id),
    CONSTRAINT fk_vjr_village    FOREIGN KEY (village_id) REFERENCES villages(id) ON DELETE CASCADE,
    CONSTRAINT fk_vjr_user       FOREIGN KEY (user_id)    REFERENCES users(id)    ON DELETE CASCADE,
    CONSTRAINT fk_vjr_decided_by FOREIGN KEY (decided_by) REFERENCES users(id)    ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_vjr_village_status ON village_join_requests(village_id, status);

-- 3. Validations culturelles / successorales (clan, chefferie, ligne de chefs, succession)
CREATE TABLE IF NOT EXISTS village_validations (
    id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    village_id   UUID         NOT NULL,
    kind         VARCHAR(20)  NOT NULL
                     CHECK (kind IN ('CLAN','CHEFFERIE','CHIEF_LINE','SUCCESSION')),
    title        VARCHAR(160) NOT NULL,
    detail       TEXT,
    submitted_by UUID         NOT NULL,
    status       VARCHAR(20)  NOT NULL DEFAULT 'PENDING'
                     CHECK (status IN ('PENDING','APPROVED','REJECTED')),
    decided_by   UUID,
    decided_at   TIMESTAMPTZ,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_vval_village      FOREIGN KEY (village_id)   REFERENCES villages(id) ON DELETE CASCADE,
    CONSTRAINT fk_vval_submitted_by FOREIGN KEY (submitted_by) REFERENCES users(id)    ON DELETE CASCADE,
    CONSTRAINT fk_vval_decided_by   FOREIGN KEY (decided_by)   REFERENCES users(id)    ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_vval_village_status ON village_validations(village_id, status);
