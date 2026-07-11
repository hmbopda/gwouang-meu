# Chefferies traditionnelles du Cameroun (MINAT)

Extraites de la *Nomenclature nationale des chefferies traditionnelles*, MINAT,
novembre 2015 — 12 PDF officiels téléchargés le 2026-07-10.

## État d'avancement

| Degré | Fichier | Chefferies | Statut |
|---|---|---|---|
| 1er (national) | `chefferies_1er_degre.csv` | 79 | ✅ extrait et vérifié (séquence 1..79) |
| 2e (national) | `chefferies_2e_degre.csv` | 867 | ✅ extrait et vérifié (séquence 1..867, régions contiguës) |
| 3e (par région) | `chefferies_3e_degre.csv` | ~12 000 | ⏳ à extraire |

Total attendu (les 3 degrés) : **≈ 13 500** chefferies (l'étude cite 13 536).

### 2e degré — répartition par région (867 au total)

Centre 181 · Extrême-Nord 166 · Sud 113 · Nord-Ouest 112 · Ouest 107 · Est 55 ·
Littoral 45 · Sud-Ouest 44 · Nord 37 · Adamaoua 7.

**Qualité** : numérotation 1..867 continue sans trou ni doublon ; chaque chefferie
rattachée à un département officiel (jointure complète vers `../departements.csv`) ;
régions en blocs de N° strictement contigus (ordre alphabétique du MINAT), ce qui
valide l'affectation. **25 dénominations (3 %)** proviennent de lignes *doublement
corrompues* dans le PDF source (le nom lui-même a des caractères entrelacés) : leur
numéro, département et région sont exacts, mais l'orthographe du nom est approximative
et à vérifier — N° 123, 144, 196, 199, 206, 232, 233, 290, 291, 383, 411, 412, 419,
420, 433, 453, 469, 642, 676, 677, 693, 747, 775, 853, 861. L'affectation
départementale est dérivée des libellés de colonne du MINAT ; de rares imprécisions de
frontière restent possibles (la région, elle, est vérifiée).

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
coupées par les sauts de page, colonnes arrondissement/canton/groupement variables, et
surtout des libellés de colonne *entrelacés caractère par caractère* dans le mot
« Chefferie » et parfois dans le nom lui-même — corruption présente dans le PDF source,
indépendante du mode d'extraction).

Le **1er degré** (régulier) et le **2e degré** sont faits et vérifiés. Le 2e degré a été
reconstruit par un parseur dédié (ancrage sur le N° continu 1..867 ; désentrelacement du
titre Chefferie/Lawanat/Lamidat/Sultanat/Groupement en le consommant lettre à lettre ;
département dérivé des libellés de colonne officiels avec concaténation des labels sur
2 lignes) puis contrôle d'intégrité (séquence complète, jointure départements, blocs de
région contigus).

**Reste** : le **3e degré** (~12 000 chefferies, un PDF par région, mêmes difficultés)
à extraire par la même méthode, avec QA d'intégrité (séquences `numero` par département,
jointure vers `../arrondissements.csv` quand la granularité le permet).
