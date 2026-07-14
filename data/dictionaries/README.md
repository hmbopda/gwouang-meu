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
| `moye-bandenkop.json` | Mə̀yú' Bandenkop (Bandenkop, Ouest) | corps (+ formes tonalisées du schéma), mets, boissons, maison, moments de la journée, 8 jours de la semaine ; grammaire : pronoms personnels/possessifs, adjectifs possessifs, verbe « être » (6 temps) ; quartiers (~230 paires, leçons 2–11) |
