-- V54: Journal des emails transactionnels (audit + observabilite du moteur email).
-- Chaque envoi (invitation, bienvenue, dissolution, union, association, invitation village)
-- enregistre une ligne : destinataire, type, sujet, provider, succes, erreur eventuelle.
-- Best-effort : un echec d'enregistrement ne bloque jamais l'envoi.
-- Colonnes texte VARCHAR (jamais CHAR). Audit created_at/updated_at TIMESTAMPTZ.

CREATE TABLE IF NOT EXISTS email_logs (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient   VARCHAR(320) NOT NULL,
    email_type  VARCHAR(60)  NOT NULL,
    subject     VARCHAR(300),
    provider    VARCHAR(40),
    success     BOOLEAN      NOT NULL DEFAULT FALSE,
    error       TEXT,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_email_logs_recipient ON email_logs(recipient);
CREATE INDEX IF NOT EXISTS idx_email_logs_created ON email_logs(created_at);
