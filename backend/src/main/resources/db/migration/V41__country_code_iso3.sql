-- V41 : reconciliation des codes pays ISO-2 (referentiel) / ISO-3 (table countries)
-- Le formulaire d'union envoie le code de la table `countries` (ISO-3, ex "CMR"),
-- or `unions.legal_country` etait en varchar(2) (ISO-2) -> "value too long" (409).
-- On elargit la colonne et on ajoute l'ISO-3 au referentiel pour que la regle
-- de polygamie s'applique quel que soit le format du code recu.

-- 1) La colonne accepte desormais l'ISO-3
ALTER TABLE unions ALTER COLUMN legal_country TYPE varchar(3);

-- 2) Colonne ISO-3 sur le referentiel
ALTER TABLE country_marriage_rules ADD COLUMN IF NOT EXISTS iso3 varchar(3);

-- 3) Mapping explicite ISO-2 -> ISO-3 pour les 18 pays seedes (V40)
UPDATE country_marriage_rules AS r SET iso3 = m.iso3 FROM (VALUES
  ('CM','CMR'),('SN','SEN'),('ML','MLI'),('GA','GAB'),('CG','COG'),('TD','TCD'),
  ('BF','BFA'),('NE','NER'),('NG','NGA'),('CI','CIV'),('CD','COD'),('FR','FRA'),
  ('BE','BEL'),('CH','CHE'),('CA','CAN'),('US','USA'),('GB','GBR'),('DE','DEU')
) AS m(iso2, iso3) WHERE r.iso2 = m.iso2;

CREATE INDEX IF NOT EXISTS idx_country_marriage_rules_iso3 ON country_marriage_rules (iso3);
