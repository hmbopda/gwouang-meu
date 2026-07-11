# Référentiel territorial — Cameroun (CM)

Source de données organisée du territoire camerounais pour GWANG MEU : la grappe
administrative officielle **pays → région → département (chef-lieu) → arrondissement/commune**,
et les **chefferies traditionnelles** rattachées.

> Cadre : voir `docs/etude-faisabilite-immersion-culturelle.md` (scénario B) et
> `docs/regles-metier-bantou-bamileke.md` (RM-01 ancrage, RM-07 profils coutumiers).
> Le Cameroun est le premier pays ; le schéma est prévu pour s'étendre à l'Afrique.

## Fichiers

| Fichier | Contenu | Lignes | Statut |
|---|---|---|---|
| `regions.csv` | 10 régions + chef-lieu régional + coordonnées | 10 | ✅ complet, vérifié |
| `departements.csv` | 58 départements + chef-lieu + coordonnées, liés à la région | 58 | ✅ complet, vérifié |
| `arrondissements.csv` | ~360 arrondissements/communes, liés au département | 360 | ✅ complet, vérifié |
| `chefferies/chefferies_1er_degre.csv` | chefferies de 1er degré (nationales) | 79 | ✅ complet, vérifié |
| `chefferies/chefferies_2e_degre.csv` | chefferies de 2e degré (nationales) | 867 | ✅ complet, vérifié |
| `chefferies/chefferies_3e_degre.csv` | chefferies de 3e degré (par région) | 12 244 | ✅ 56/58 dépts, jointure complète |

## Schémas (CSV, séparateur `;`, UTF-8, en-tête inclus)

**regions.csv** — `code;nom;chef_lieu;geonameid;lat;lng`
Le `code` est le code admin1 GeoNames (stable), utilisé comme clé de jointure.

**departements.csv** — `code_region;code;nom;chef_lieu;geonameid;lat;lng`
`code_region` → `regions.code`. Les 58 départements, comptes par région conformes au
découpage officiel (Centre 10, Ouest 8, Nord-Ouest 7, Extrême-Nord 6, Sud-Ouest 6,
Adamaoua 5, Est/Littoral/Nord/Sud 4).

**arrondissements.csv** — `code_region;code_departement;code;nom;geonameid;lat;lng`
`code_departement` → `departements.code`. Ce sont les communes/arrondissements
sélectionnables dans les formulaires (niveau le plus fin de l'administration).

**chefferies/*.csv** — `degre;region;departement;arrondissement;groupement;numero;denomination;acte`
`region`/`departement` en MAJUSCULES telles que publiées par le MINAT ; `numero` = numéro
d'ordre dans la nomenclature (se réinitialise par département en 3e degré) ; `acte` =
arrêté déterminant la chefferie (rempli surtout au 1er degré).

## Intégrité (contrôlée)

- 360/360 arrondissements se rattachent à un département existant (jointure complète).
- 58/58 départements se rattachent à une région existante.
- Aucun mojibake, accents corrects (Extrême-Nord, Ngaoundéré, Ébolowa…), aucun chef-lieu
  ni nom d'arrondissement manquant.
- Chefferies 1er degré : numérotation 1..79 continue, sans trou ni doublon.

## Sources

- **Découpage administratif** : [GeoNames](https://www.geonames.org/) — dump pays `CM`
  (ADM1/ADM2/ADM3), licence **CC-BY 4.0**. Téléchargé le 2026-07-10.
- **Chefs-lieux** : décret n°2008/376 du 12 novembre 2008 portant organisation
  administrative de la République du Cameroun (croisé avec les capitales régionales).
- **Chefferies traditionnelles** : *Nomenclature nationale des chefferies traditionnelles*,
  MINAT (Ministère de l'Administration Territoriale), novembre 2015. 12 PDF officiels
  téléchargés le 2026-07-10 depuis
  [minat.gov.cm/annuaires/chefferies-tradditionnelles](https://minat.gov.cm/annuaires/chefferies-tradditionnelles/).
  Voir `chefferies/README.md` pour les URLs par degré/région.

## Limites connues

- Les noms d'arrondissements de GeoNames sont en graphie ASCII (sans accents) — à
  ré-accentuer lors d'une passe ultérieure.
- Chefferies 2e et 3e degré non encore extraites (voir `chefferies/README.md`).
- Le **nom du chef** de chaque chefferie n'existe dans aucune source officielle ouverte
  et n'est PAS inclus : il sera déclaré par la communauté et validé dans l'application
  (cf. étude, décisions D3/D8 ; RM-77 sur les données personnelles/sensibles).
