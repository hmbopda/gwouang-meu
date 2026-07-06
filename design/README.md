# Handoff : Refonte globale des IHM — GWANG MEU

## Vue d'ensemble
Refonte complète de l'interface de GWANG MEU (plateforme communautaire africaine : réseau social, généalogie, villages), issue d'un audit design à 4 experts (UX, UI, accessibilité, marque). Direction retenue : **« Tissage »** — évolution douce du thème or/sombre existant, identité culturelle intégrée, priorité lisibilité multi-générationnelle.

## À propos des fichiers de design
Les fichiers de ce bundle sont des **références de design créées en HTML** (prototypes montrant l'apparence et le comportement attendus), **pas du code de production**. La tâche est de **recréer ces designs dans le codebase Flutter existant** (`frontend/lib/`), en suivant ses patterns établis (Riverpod, GoRouter, widgets partagés dans `lib/shared/widgets/`). Le shell web/desktop suit les mêmes tokens (Next.js pour la landing si besoin).

## Fidélité
**Haute fidélité (hifi)** : couleurs, typographies, espacements et interactions sont finaux. Recréer pixel-perfect avec les bibliothèques du codebase.

## Design tokens — `GwTokens` (remplace AppColors + GwColors + T)
Créer un fichier unique `lib/core/theme/gw_tokens.dart` et **supprimer** `app_theme.dart::AppColors`, `gw_colors.dart` et `tree_tokens.dart::T` après migration.

### Or — un seul
- `gold` : `#C9A84C` (l'ancien `#C8A020` disparaît)
- `goldLight` : `#E8C96A`
- `goldDeep` : `#9A7810` — **texte/actions or sur thème clair (contraste AA)**

### Ink (thème sombre)
- `inkDeep` `#080709` · `ink` `#0C0B0F` (fond) · `inkCard` `#16141B` (cartes) · `inkLift` `#1C1A22` (surfaces interactives) · `inkHigh` `#2E2B3C`
- Texte : `stone` `#F0EBE1` · `stoneMid` `#B8AD9E` · `stoneDim` `#8A8172` (hint — remplace #666, AA) · `stoneFaint` `#7A7268` (méta uniquement, jamais < 12 px)

### Paper (thème clair)
- `paper` `#FAF6EE` (fond) · `paperWarm` `#F5EDDD` · `paperRaise` `#F0E8D8` · cartes `#FFFFFF` · texte `#231F18` · secondaire `#6B6255`

### Sémantiques (identiques sur les deux thèmes)
- `sage` `#2A7A5C` (IA / succès) — texte clair `#70C090` (dark) / `#1E6B4A` (light)
- `ember` `#C4583A` (live / alerte / non-lus) — `#E09080` / `#B04830`
- `azure` `#3A6CB4` (diaspora / info) — `#7AA8E0` / `#2E5A9A`
- Lignée secondaire (arbre) : rose cuivré `#C878A0`

### Typographie — 3 familles, partout (Google Fonts)
- **Fraunces** (serif) : titres, citations, récits, initiales d'avatars. Titres écran 22 px w700, citations 17–19 px italique.
- **Syne** (sans) : interface. Corps 15 px, secondaire 14 px, **minimum absolu 12 px**.
- **JetBrains Mono** : méta, badges, labels de section (10–12 px, letter-spacing 1.5–2.5 px, MAJUSCULES).

### Règles accessibilité (bloquantes)
- Corps ≥ 14 px, méta ≥ 12 px (interdire les 9–11 px actuels)
- Cibles tactiles ≥ 44 px (topbar actuelle : 32 px → 44 px)
- Contraste AA sur tous les textes ; une seule famille d'icônes (Material Symbols Outlined, actif = FILL 1) — **plus d'emoji dans la navigation desktop**
- Rayons : cartes 18–20 px, boutons/inputs 14 px, pilules 99 px. Bande tissée signature : 4 px, `repeating-linear-gradient(90deg, gold 0 28px, sage 28px 40px, gold 40px 68px, ember 68px 80px)` en haut de chaque écran.

## Écrans / Vues (voir fichiers référencés)
1. **Feed mobile** (`Refonte IHM.dc.html` #1a) : header Fraunces + « MBƐ́Ɛ — BIENVENUE » mono ; stories 72 px carrées arrondies (24 px) avec anneau dégradé or/ember/sage ; compose 1 ligne italique ; **gabarits de post différenciés** : citation (barre tissée verticale 5 px + Fraunces italique 19 px), média (image full-bleed + auteur en overlay), encart IA (fond sage 8 %, bordure sage 35 %, label mono « MÉMOIRE FAMILIALE · CONFIANCE 87% », CTA sage + bouton fermer) ; actions en pilules (`inkLift`, 8×14 px, cœur ember) ; bottom nav 5 destinations réelles (Fil, Villages, Lignées, Messages+badge, Profil), actif = pilule 52×32 `gold 16%` + icône remplie + label 12 px.
2. **Villages** (#1e) : recherche permanente + filtres chips ; carte « Mon village » avec bannière motif tissé, badge dialecte, activité live ; rangées découverte avec tuile initiale Fraunces teintée par région, ligne d'activité mono sage, bouton Rejoindre outline 40 px.
3. **Généalogie mobile « Rivière des générations »** (#1d) et **desktop signature** (#2c) : axe vertical or (mobile) / strates horizontales douces par génération (desktop) ; **couleur par lignée, plus par genre** (Mbopda or, Ngo Bassa `#C878A0`) ; ancêtres = bordure `#7A7268` + « ✦ » (jamais de noir « décédé ») ; sujet = carte glow or ; suggestion IA = carte pointillée sage « AFFLUENT · 87% » ; liens = courbes bézier douces 2 px, opacité 30–45 % ; panneau droit desktop = « Récit » (extrait Fraunces italique + lecteur audio + progression « 5/14 récits »).
4. **Messages** (#3a, #3b) : liste avec aperçu, heure mono, badge non-lu ember, tag mono (village · type) ; conversation avec bulles 18 px (reçu : `inkLift`, coin bas-gauche 6 px ; envoyé : `gold 16%` + bordure, coin bas-droit 6 px), rôles inline, message vocal avec forme d'onde, **bouton micro = action primaire** (48 px, or), suggestion IA « Traduire en Bassa » en pilule pointillée sage.
5. **Profil** (#3c) : avatar 96 px anneau dégradé tissé, chips identité (clan or / diaspora azure / langues sage), carte lignée (génération + récits), grille « Mes villages », stats « contribution à la mémoire », CTA « Enregistrer mon récit ».
6. **Onboarding Origines** (#3d) : barre de progression 3 segments, titre Fraunces 28 px, recherche village, cartes sélectionnables (sélectionnée = fond/bordure or + check), preuve sociale mono sage (« 4 familles Mbopda y sont déjà »), chips clan + note de confidentialité, CTA 54 px. **Corriger tous les accents français** de `auth_screen.dart`.
7. **Recherche & notifications** (#3e) : une seule recherche multi-entités avec portées (Tout/Personnes/Villages/Lignées), résultats avec `<mark>` or et badge de provenance (LIGNÉE / IA %) ; notifications groupées par type (Mémoire IA fond sage / Village / Social).
8. **Web desktop** (#2d) : rail 216 px avec labels (remplace le rail emoji 64 px), mêmes 5 destinations que mobile, entrées futures sous « Plus (bientôt) », topbar 60 px avec recherche 44 px, layout 2 colonnes (fil + rail contextuel IA/village). Parité 1:1 des composants.

## Interactions & comportement
Parcours de référence prototypé (`Prototype — Suggestion IA vers Arbre.dc.html`) :
1. Feed → carte IA (pulse doux 2,4 s) → « Explorer le lien »
2. Écran vérification : 2 personnes face à face, 3 correspondances à cocher (toggle → fond/bordure sage), indice « récit d'aîné » ; le CTA reste désactivé (`inkLift`/`stoneFaint`) tant que tout n'est pas validé, libellé dynamique « Validez les N correspondances restantes »
3. Confirmer → navigation vers l'arbre, la branche passe de pointillée « AFFLUENT · 87% » à pleine « BRANCHE CONFIRMÉE » (fade-up 0,5 s), compteur membres 14 → 15, toast sage 3,2 s « Kwame a rejoint la rivière »
- Transitions d'écran : fade + translateY(14 px), 300 ms ease. Rejeter → retour fil.

## Gestion d'état (Flutter)
- `verificationProvider` : `step`, `checks[3]`, `linkConfirmed`, mutation optimiste du `familyTreeProvider` à la confirmation (+ appel API `POST /genealogy/suggestions/{id}/confirm`)
- Toast via `ScaffoldMessenger` stylé GwTokens (fond sage, pilule)
- Navigation : GoRouter — Messages devient une route de premier niveau (`/messages`, `/messages/:groupId`)

## Assets
Aucune image binaire : placeholders = motifs `repeating-linear-gradient` (à remplacer par les photos réelles), icônes = Material Symbols Outlined (variable FILL), fonts Google (Fraunces, Syne, JetBrains Mono).

## Fichiers du bundle
- `Refonte IHM.dc.html` — canvas complet : P4 (écrans restants), P0–P3 (tokens, composants, arbre signature, thèmes/parité), 3 directions initiales
- `Prototype — Suggestion IA vers Arbre.dc.html` — prototype interactif du parcours
- `Audit UX Experts.dc.html` — audit détaillé écran par écran
- `Existant — Recreation.dc.html` — recréation de l'existant (référence avant/après)
- `support.js` — runtime nécessaire pour ouvrir les fichiers .dc.html dans un navigateur
