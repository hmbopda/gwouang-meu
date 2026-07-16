-- V58: Rubrique « Vie du village » — étend la table générique village_heritage_entries
-- aux entrées EVENT (événements) et ANNOUNCEMENT (annonces). Aucune nouvelle colonne :
-- on réutilise title/subtitle/description/detail/ordinal. Pour un événement, la DATE se
-- saisit en texte libre dans subtitle (ex. « 15 août 2026 »).
--
-- Boot-safe : la contrainte CHECK ck_heritage_kind est remplacée (DROP puis ADD) par une
-- version à 5 valeurs. Colonne kind inchangée (VARCHAR(20) ; 'ANNOUNCEMENT' = 12 car.),
-- cohérente avec l'enum Java HeritageKind (@Enumerated STRING) sous ddl-auto validate.

ALTER TABLE village_heritage_entries DROP CONSTRAINT IF EXISTS ck_heritage_kind;
ALTER TABLE village_heritage_entries ADD CONSTRAINT ck_heritage_kind
    CHECK (kind IN ('TRADITION', 'SACRED_PLACE', 'CALENDAR', 'EVENT', 'ANNOUNCEMENT'));
