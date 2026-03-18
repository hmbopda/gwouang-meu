-- Statut d'union : ACTIVE, DIVORCE_PENDING, DIVORCED, DEATH_PENDING, ENDED_DEATH, DISPUTE
ALTER TABLE unions ADD COLUMN status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE';

-- Dissolution details
ALTER TABLE unions ADD COLUMN dissolution_type VARCHAR(20);          -- DIVORCE ou DEATH
ALTER TABLE unions ADD COLUMN dissolution_doc_url VARCHAR(500);      -- URL du document (R2)
ALTER TABLE unions ADD COLUMN dissolution_requested_by UUID;         -- Qui a fait la demande
ALTER TABLE unions ADD COLUMN dissolution_requested_at TIMESTAMPTZ;
ALTER TABLE unions ADD COLUMN dissolution_confirmed_at TIMESTAMPTZ;
ALTER TABLE unions ADD COLUMN dispute_reason TEXT;

CREATE INDEX idx_unions_status ON unions(status);

-- Table de suivi des relances (email J+0, SMS J+10, auto J+30)
CREATE TABLE dissolution_reminders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    union_id UUID NOT NULL REFERENCES unions(id) ON DELETE CASCADE,
    reminder_type VARCHAR(20) NOT NULL,  -- INITIAL_EMAIL, SMS_REMINDER, AUTO_VALIDATE, MANUAL_REVIEW
    channel VARCHAR(20) NOT NULL,        -- EMAIL, SMS, IN_APP, SYSTEM
    sent_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    notes TEXT
);

CREATE INDEX idx_dissolution_reminders_union ON dissolution_reminders(union_id);
