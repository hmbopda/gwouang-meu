-- ════════════════════════════════════════════════════════════════
-- V40 : Referentiel « regles de mariage par pays »
--
-- Table de reference (lecture seule cote appli, cache memoire) servant
-- a evaluer la conformite au droit civil du pays de residence/
-- celebration d'une union. Les pays absents sont traites UNKNOWN a
-- l'execution.
--
-- polygamy ∈ {ALLOWED, CONDITIONAL, FORBIDDEN}
--   ALLOWED      : polygamie legalement admise
--   CONDITIONAL  : admise sous condition (declaration a l'etat civil,
--                  option de regime, etc.)
--   FORBIDDEN    : une 2e union civile/monogamique active est interdite
--
-- is_advisory=TRUE : information indicative, pas un avis juridique.
-- ════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS country_marriage_rules (
    iso2         VARCHAR(2)  PRIMARY KEY,
    country_name VARCHAR(100),
    polygamy     VARCHAR(20) NOT NULL,
    regimes      TEXT,
    legal_basis  TEXT,
    source_url   TEXT,
    is_advisory  BOOLEAN     DEFAULT TRUE,
    updated_at   TIMESTAMPTZ DEFAULT now()
);

-- ── SEED : pays coeur de la diaspora, fonde sur le droit reel ──────
INSERT INTO country_marriage_rules (iso2, country_name, polygamy, regimes, legal_basis, source_url, is_advisory) VALUES
    ('CM', 'Cameroun', 'CONDITIONAL', 'MONOGAMY,POLYGAMY,CUSTOMARY',
        'Ordonnance n°81-02 du 29 juin 1981, art. 49 : les epoux declarent a l''etat civil l''option monogamie ou polygamie au moment du mariage.',
        'https://www.prc.cm/fr/actualites/actes/ordonnances', TRUE),
    ('SN', 'Senegal', 'CONDITIONAL', 'MONOGAMY,POLYGAMY',
        'Code de la famille (loi n°72-61), art. 133 : option de polygamie declaree lors de la celebration ; a defaut, monogamie.',
        'https://www.jo.gouv.sn', TRUE),
    ('ML', 'Mali', 'CONDITIONAL', 'MONOGAMY,POLYGAMY',
        'Code des personnes et de la famille (loi n°2011-087), art. 307 : option monogamie/polygamie declaree au mariage.',
        'https://sgg-mali.ml', TRUE),
    ('CI', 'Cote d''Ivoire', 'FORBIDDEN', 'MONOGAMY',
        'Loi n°2019-570 du 26 juin 2019 relative au mariage : la monogamie est le seul regime, la polygamie est abolie.',
        'https://www.gouv.ci', TRUE),
    ('GA', 'Gabon', 'CONDITIONAL', 'MONOGAMY,POLYGAMY',
        'Code civil gabonais : option monogamie/polygamie declaree a la celebration du mariage.',
        'https://www.legigabon.com', TRUE),
    ('CD', 'RD Congo', 'FORBIDDEN', 'MONOGAMY',
        'Code de la famille (loi n°87-010), art. 330 : le mariage est monogamique.',
        'https://www.leganet.cd', TRUE),
    ('CG', 'Congo', 'CONDITIONAL', 'MONOGAMY,POLYGAMY',
        'Code de la famille (loi n°073-84) : option monogamie/polygamie declaree au mariage.',
        'https://www.sgg.cg', TRUE),
    ('TD', 'Tchad', 'CONDITIONAL', 'MONOGAMY,POLYGAMY,CUSTOMARY',
        'Ordonnance n°03/INT/SUR de 1961 et droit coutumier : polygamie admise, option declaree.',
        'https://www.presidence.td', TRUE),
    ('BF', 'Burkina Faso', 'CONDITIONAL', 'MONOGAMY,POLYGAMY',
        'Code des personnes et de la famille (zatu an VII-13), art. 232 : option monogamie/polygamie declaree au mariage.',
        'https://www.legiburkina.bf', TRUE),
    ('NE', 'Niger', 'CONDITIONAL', 'MONOGAMY,POLYGAMY,CUSTOMARY',
        'Coutumes et droit musulman reconnus : polygamie admise selon le statut personnel choisi.',
        'https://www.gouv.ne', TRUE),
    ('NG', 'Nigeria', 'CONDITIONAL', 'MONOGAMY,POLYGAMY,CUSTOMARY',
        'Marriage Act (mariage civil monogamique) coexistant avec le droit coutumier et la charia (Etats du Nord) admettant la polygamie ; selon l''Etat et le type de mariage.',
        'https://www.nass.gov.ng', TRUE),
    ('FR', 'France', 'FORBIDDEN', 'MONOGAMY',
        'Code civil, art. 147 : on ne peut contracter un second mariage avant la dissolution du premier (bigamie interdite, art. 433-20 code penal).',
        'https://www.legifrance.gouv.fr', TRUE),
    ('BE', 'Belgique', 'FORBIDDEN', 'MONOGAMY',
        'Code civil belge, art. 147 : nul ne peut contracter un nouveau mariage avant la dissolution du precedent.',
        'https://www.ejustice.just.fgov.be', TRUE),
    ('CH', 'Suisse', 'FORBIDDEN', 'MONOGAMY',
        'Code civil suisse, art. 96 : un nouveau mariage suppose la dissolution ou l''annulation du precedent.',
        'https://www.fedlex.admin.ch', TRUE),
    ('CA', 'Canada', 'FORBIDDEN', 'MONOGAMY',
        'Code criminel, art. 290-293 : la polygamie et la bigamie sont des infractions.',
        'https://laws-lois.justice.gc.ca', TRUE),
    ('US', 'Etats-Unis', 'FORBIDDEN', 'MONOGAMY',
        'La polygamie est interdite dans l''ensemble des Etats (bigamie prohibee par les codes penaux etatiques).',
        'https://www.usa.gov', TRUE),
    ('GB', 'Royaume-Uni', 'FORBIDDEN', 'MONOGAMY',
        'Matrimonial Causes Act 1973 : un mariage polygame celebre au Royaume-Uni est nul ; bigamie interdite.',
        'https://www.legislation.gov.uk', TRUE),
    ('DE', 'Allemagne', 'FORBIDDEN', 'MONOGAMY',
        'Burgerliches Gesetzbuch (BGB), §1306 : un mariage ne peut etre contracte s''il en existe deja un.',
        'https://www.gesetze-im-internet.de', TRUE)
ON CONFLICT (iso2) DO NOTHING;
