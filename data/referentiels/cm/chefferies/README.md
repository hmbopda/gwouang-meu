# Chefferies traditionnelles du Cameroun (MINAT)

Extraites de la *Nomenclature nationale des chefferies traditionnelles*, MINAT,
novembre 2015 — 12 PDF officiels téléchargés le 2026-07-10.

## État d'avancement

| Degré | Fichier | Chefferies | Statut |
|---|---|---|---|
| 1er (national) | `chefferies_1er_degre.csv` | 79 | ✅ extrait et vérifié (séquence 1..79) |
| 2e (national) | `chefferies_2e_degre.csv` | ~700–900 | ⏳ à extraire |
| 3e (par région) | `chefferies_3e_degre.csv` | ~12 000 | ⏳ à extraire |

Total attendu (les 3 degrés) : **≈ 13 500** chefferies (l'étude cite 13 536).

## Schéma

`degre;region;departement;arrondissement;groupement;numero;denomination;acte`

- `region`, `departement` : MAJUSCULES telles que publiées (rapprochables des codes de
  `../departements.csv` par normalisation accents/casse).
- `numero` : numéro d'ordre MINAT (se réinitialise par département en 3e degré → sert de
  contrôle d'intégrité : la séquence doit être 1..N sans trou).
- `acte` : arrêté déterminant la chefferie (surtout renseigné au 1er degré).
- Le **nom du chef n'est pas dans la source** et n'est pas collecté ici (déclaration
  communautaire validée dans l'app — RM-77).

## URLs officielles (source de vérité)

Base : `https://minat.gov.cm/wp-content/uploads/2020/07/`

- 1er degré (national) : `Chefferies-du-1er-degre-Cameroun-les-10-Regions.pdf`
- 2e degré (national) : `Chefferies-traditionnelles-du-2eme-Degre-du-Cameroun.pdf`
- 3e degré : `Chefferies-traditionnelles-du-3eme-Degre-<REGION>.pdf` avec `<REGION>` ∈
  { Adamaoua, Centre, Est, Extreme-Nord, Littoral, Nord, Nord-Ouest, Ouest, Sud, Sud-Ouest }

## Extraction : méthode et reste à faire

Les PDF sont extraits en texte via `pdftotext -layout`, puis convertis en CSV.
**Difficulté** : la mise en page est irrégulière (numéros parfois collés au nom, entrées
coupées par les sauts de page, colonnes arrondissement/canton/groupement variables selon
les régions). Un parsing purement positionnel produit trop d'erreurs ; l'extraction fiable
demande une lecture **sémantique** (page par page). Le 1er degré, plus régulier, est fait
et vérifié.

Reste à finaliser (2e degré + 3e degré) par une passe sémantique, puis QA d'intégrité
(séquences `numero` 1..N par département, zéro doublon, jointure `departement` → référentiel
administratif) avant intégration.
