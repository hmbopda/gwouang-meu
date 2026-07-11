# Chefferies traditionnelles du Cameroun (MINAT)

Extraites de la *Nomenclature nationale des chefferies traditionnelles*, MINAT,
novembre 2015 — 12 PDF officiels téléchargés le 2026-07-10.

## État d'avancement

| Degré | Fichier | Chefferies | Statut |
|---|---|---|---|
| 1er (national) | `chefferies_1er_degre.csv` | 79 | ✅ extrait et vérifié (séquence 1..79) |
| 2e (national) | `chefferies_2e_degre.csv` | 867 | ✅ extrait et vérifié (séquence 1..867, régions contiguës) |
| 3e (par région) | `chefferies_3e_degre.csv` | 12 244 | ✅ extrait (56/58 dépts, jointure complète) |

**Total extrait : 13 190 chefferies** sur ≈ 13 536 estimées par l'étude (~97 %).

### 3e degré — répartition par région (12 244 au total)

Centre 2410 · Extrême-Nord 1759 · Ouest 1394 · Sud 1236 · Nord 1120 · Littoral 1060 ·
Est 1036 · Adamaoua 1011 · Sud-Ouest 811 · Nord-Ouest 407.

**Qualité** : couverture ~98 % des lignes de données des 10 PDF régionaux ; noms propres
(aucune corruption d'entrelacement — les dénominations de 3e degré sont nues, sans titre) ;
chaque chefferie rattachée à un **département officiel** (jointure complète vers
`../departements.csv`), sur **56 des 58 départements**. **Limites** : (1) 2 départements
absents — Nord/Mayo-Rey (source PDF malformée) et Sud-Ouest/Koupé-Manengouba ; (2) le
placement s'arrête au **département** — les colonnes arrondissement/groupement/canton des
PDF ne sont pas extraites (leur découpage positionnel scindait les noms de façon peu
fiable), à enrichir ultérieurement ; (3) la numérotation `numero` est celle du MINAT et se
réinitialise selon les fichiers par département OU par arrondissement (elle n'est donc pas
un identifiant unique — utiliser (région, département, dénomination)).

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

Les **trois degrés** sont extraits et vérifiés :
- **1er degré** : régulier, transcription directe.
- **2e degré** : parseur dédié — ancrage sur le N° continu 1..867 ; désentrelacement du
  titre Chefferie/Lawanat/Lamidat/Sultanat/Groupement en le consommant lettre à lettre ;
  département dérivé des libellés de colonne officiels (concaténation des labels sur
  2 lignes) ; QA séquence + jointure + blocs de région contigus.
- **3e degré** : parseur dédié sur les 10 PDF régionaux — sections
  « 3EME DEGRE DU DEPARTEMENT DE X » (avec gestion des en-têtes coupés sur 2 lignes) ;
  extraction du couple (N°, dénomination) **par adjacence** (le numéro d'ordre est celui
  immédiatement suivi du nom, indépendamment de la position de colonne) ; nettoyage du
  bruit et déduplication exacte. Les dénominations de 3e degré sont nues (pas de titre),
  d'où l'absence de corruption d'entrelacement.

Scripts d'extraction : `parse2e.js`/`finalize2e.js` et `parse3e.js`/`finalize3e.js`
(conservés hors dépôt, dans l'espace de travail de session).
