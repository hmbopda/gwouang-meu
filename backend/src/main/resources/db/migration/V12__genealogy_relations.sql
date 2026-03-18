-- Table de filiation parent-enfant
CREATE TABLE parent_child (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_id   UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
    child_id    UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
    parent_role parent_role_enum NOT NULL,
    parent_type parent_type_enum NOT NULL DEFAULT 'BIOLOGICAL',
    is_adopted  BOOLEAN NOT NULL DEFAULT FALSE,
    confidence  DECIMAL(3,2),
    source      relation_source_enum NOT NULL DEFAULT 'DECLARED',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by  UUID NOT NULL REFERENCES users(id),

    UNIQUE(parent_id, child_id)
);

-- Un enfant ne peut avoir qu'un FATHER et qu'une MOTHER biologiques
CREATE UNIQUE INDEX idx_parent_child_bio_father
  ON parent_child(child_id) WHERE parent_role = 'FATHER' AND parent_type = 'BIOLOGICAL';
CREATE UNIQUE INDEX idx_parent_child_bio_mother
  ON parent_child(child_id) WHERE parent_role = 'MOTHER' AND parent_type = 'BIOLOGICAL';

CREATE INDEX idx_parent_child_parent ON parent_child(parent_id);
CREATE INDEX idx_parent_child_child  ON parent_child(child_id);

-- Table des unions (mariage / dot)
CREATE TABLE unions (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    husband_id       UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
    wife_id          UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
    union_type       union_type_enum NOT NULL,
    union_order      SMALLINT NOT NULL DEFAULT 1,
    start_date       DATE,
    end_date         DATE,
    end_reason       end_reason_enum,
    is_active        BOOLEAN GENERATED ALWAYS AS (end_date IS NULL) STORED,

    -- Dot (bride price)
    is_dot_paid      BOOLEAN NOT NULL DEFAULT FALSE,
    dot_date         DATE,
    dot_paid_by      UUID REFERENCES persons(id) ON DELETE SET NULL,
    dot_description  TEXT,
    dot_witnesses    UUID[],

    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by       UUID NOT NULL REFERENCES users(id)
);

CREATE INDEX idx_unions_husband ON unions(husband_id);
CREATE INDEX idx_unions_wife    ON unions(wife_id);
CREATE INDEX idx_unions_active  ON unions(is_active) WHERE is_active = TRUE;

-- Cache freres/soeurs (table derivee, mise a jour par trigger)
CREATE TABLE siblings (
    person_a_id    UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
    person_b_id    UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
    sibling_type   sibling_type_enum NOT NULL,
    shared_parents SMALLINT NOT NULL DEFAULT 1,
    PRIMARY KEY(person_a_id, person_b_id),
    CHECK(person_a_id < person_b_id)
);

-- Tutelle / Parrainage
CREATE TABLE guardianships (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    guardian_id  UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
    ward_id      UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
    guard_type   guard_type_enum NOT NULL,
    start_date   DATE,
    end_date     DATE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Suggestions Claude AI
CREATE TABLE ai_genealogy_suggestions (
    id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    person_a_id        UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
    person_b_id        UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
    suggested_relation VARCHAR(50) NOT NULL,
    confidence         DECIMAL(3,2) NOT NULL,
    reasons            JSONB,
    status             ai_suggestion_status_enum NOT NULL DEFAULT 'PENDING',
    reviewed_by        UUID REFERENCES users(id),
    reviewed_at        TIMESTAMPTZ,
    expires_at         TIMESTAMPTZ DEFAULT NOW() + INTERVAL '90 days',
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ai_sugg_status ON ai_genealogy_suggestions(status);
CREATE INDEX idx_ai_sugg_person_a ON ai_genealogy_suggestions(person_a_id);
