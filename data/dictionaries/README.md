# Dictionnaires des langues

Dictionnaires bilingues **français ⇄ langue native**, source de vérité pour la
traduction (injectés en contexte au LLM) et la prononciation.

## Format

Un fichier JSON par langue : `<code-langue>.json` (ex. `moye-bandenkop.json`).
Structure : voir `moye-bandenkop.json`.

- `language` : `code`, `name` (endonyme), `frenchName`, `group`, `region`, éventuels `quartiers`.
- `meta` : source, avertissements (transcription, tons), notes.
- `categories` : entrées lexicales groupées par thème ; chaque entrée `{ "fr": …, "mo": … }`
  (`fr` = français, `mo` = langue native, variantes séparées par « / »).
- `grammaire` : pronoms, conjugaisons (chaque forme `{ "fr", "mo" }`).
- `phrases` : exemples de phrases alignées (précieux pour le LLM).

## Règles

- **Transcription fidèle** de la source (ne rien inventer). Marquer les incertitudes.
- Conserver l'orthographe, les tons et l'occlusive glottale (`'`) tels quels.
- Enrichir de façon **additive** (ajouter des entrées/pages sans écraser les existantes).

## Langues

| Fichier | Langue | Couverture actuelle |
|---|---|---|
| `moye-bandenkop.json` | Mə̀yú' Bandenkop (Bandenkop, Ouest) | salutations (matin/soir/tout moment), personnes/parenté, corps (+ formes tonalisées), mets, boissons, maison, moments de la journée, 8 jours de la semaine, **nombres 0→100**, chefferie & notables, ustensiles, interdits ; grammaire : pronoms personnels/possessifs, adjectifs possessifs, verbe « être » (6 temps) ; **alphabet AGLC** (consonnes + mots-exemples tonalisés) ; quartiers (~440 paires). **16/25 leçons** — voir `meta.lecons` (`couvert: true/false`) |

> Le manuel source compte **25 leçons** ; l'index complet est dans `meta.lecons` du JSON avec un drapeau `couvert`. Restent à transcrire (photos à venir) : matériaux de construction (12), oiseaux (13), animaux (14), attitudes en public (19), arbres fruitiers (20), remerciements (21), chants (22), tons (23), voyelles (24). Section `phonologie` = alphabet/prononciation (leçon 25) ; à compléter avec tons (23) et voyelles (24).
