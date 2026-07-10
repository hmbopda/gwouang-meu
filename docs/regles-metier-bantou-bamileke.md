# Référentiel des règles métier — GWANG MEU
## Généalogie bantoue & bamiléké : coutume, droit civil, diaspora

> **Version 1.0 — juillet 2026.** Synthèse arbitrée de trois expertises (anthropologie bamiléké/Grassfields ; sociétés bantoues d'Afrique centrale ; droit de la famille camerounais, africain et international privé) croisées avec l'inventaire d'audit du code (2026-07).

---

## ⚠️ Avertissement de méthode (à lire avant toute implémentation)

1. **Les coutumes varient par chefferie, par lignage et par famille.** Bandjoun ≠ Bangangté ≠ Dschang ; Bamiléké ≠ Beti ≠ Bassa ≠ Duala ≠ Kongo. Figer une coutume locale en règle globale est l'erreur classique des états civils coloniaux : **l'application doit toujours préférer le configurable au figé.** Toute règle coutumière ci-dessous se paramètre via un **profil coutumier** (RM-07), jamais en dur dans le code.
2. **Quatre plans à ne jamais confondre** : le **FAIT** (toujours enregistré), la **VALIDITÉ** (figée au lieu et à la date de célébration), la **RECONNAISSANCE** (variable selon le for et le temps), la **COUTUME** (déclarée par la lignée, jamais imposée).
3. **Tout ce qui est juridique reste `is_advisory`** : information indicative, jamais un avis juridique (doctrine V40 conservée).
4. **Limite d'ordre public non négociable** : aucune configuration, coutumière ou non, ne peut exclure les femmes et les filles d'une désignation, d'un affichage ou d'un calcul (Cour suprême CM, arrêt Zamcho n° 14/L, 04/02/1993 ; Protocole de Maputo art. 21).

### Légende des statuts
- ✅ **déjà couverte** — comportement existant validé, à documenter/verrouiller
- 🔧 **à corriger** — l'existant contredit la règle (fichier concerné indiqué)
- 🆕 **nouvelle** — rien dans le code aujourd'hui

### Les trois règles d'or (doctrine intangible)
| # | Règle | Statut |
|---|---|---|
| OR-1 | **Le fait généalogique est TOUJOURS enregistré.** On parle de « conformité » (au droit civil OU à la coutume déclarée), jamais de « légitimité ». Aucun refus dur hors RM-72 et noyau d'inceste RM-15. S'étend explicitement aux enfants : aucun libellé/badge/tri ne distingue un enfant selon le statut de l'union de ses parents. | ✅ `ComplianceService.java:14-25` — à étendre (javadoc normative dans le service filiation) |
| OR-2 | **Origine = ancre de la lignée ; résidence = évolution ; naissance = fait.** | ✅ V43 — validé par les trois experts |
| OR-3 | **Les défunts sont une mémoire partagée du lignage** (jamais anonymisés pour l'ossature généalogique) — avec la seule exception des champs sacrés/initiatiques (RM-79). | ✅ `PrivacyFilter.java:24-47` — à nuancer |

---

# 1. Ancrage & lignée

**RM-01 — Origine, résidence, naissance : trois notions, plus un historique de migrations.**
- **Énoncé** : conserver la doctrine V43 (OR-2) ; ajouter une table `residence_history` (personne, lieu, de/à, motif) — la biographie bantoue type est migratoire (village → ville → retour rituel) et la mémoire des étapes EST une donnée généalogique.
- **Fondement** : Dongmo, *Le dynamisme bamiléké* (1981) ; virilocalité patrilinéaire.
- **Statut** : ✅ principe (V43) · 🆕 historique de résidences.
- **Implication produit** : table légère ; UI « parcours de vie ».
- **Portée** : universelle.

**RM-02 — Le système de filiation est une propriété du clan/lignage, pas de l'application.**
- **Énoncé** : attribut `descent_system` ∈ {PATRILINEAL, MATRILINEAL, BILINEAR, COGNATIC} porté par le clan/lignage. Toute règle dérivée (transmission du clan, exogamie, succession, village d'origine, oncle maternel) lit ce paramètre au lieu de supposer la ligne paternelle. Défauts suggérés par aire via table `ethnic_group_defaults`, jamais en dur.
- **Fondement** : Duala/Beti/Bassa/Bamiléké patrilinéaires ; Kongo et sud-Gabon matrilinéaires (kanda, ngudi a nkazi) ; traits bilinéaires bamiléké (Hurault 1962 ; Radcliffe-Brown & Forde 1950).
- **Statut** : 🆕 — l'existant présuppose silencieusement le patrilinéaire (`GenealogyServiceImpl.java:598-600` « mari d'abord », R3.1 marquage mari seul).
- **Implication produit** : colonne sur `clans` ; c'est **la variable maîtresse** dont dépendent RM-12, RM-14, RM-45, RM-05.
- **Portée** : configurable par clan/lignée.

**RM-03 — Le lignage est une entité de première classe ; le ndap est son nom-éloge.**
- **Énoncé** : entité `lineages` (fondateur, chefferie d'origine, ndap masculin, ndap féminin, `descent_system`) ; chaque personne rattachée à un lignage (`persons.lineage_id`, hérité selon RM-11) et hérite du ndap de son genre ; la femme mariée GARDE son ndap d'origine. Sert de salutation affichable, de proxy d'exogamie (RM-14) et d'indice IA (RM-87). Le clan M:N existant (V18) reste comme niveau supra-lignager.
- **Fondement** : le ndap identifie publiquement le patrilignage et fonde la reconnaissance de parenté entre inconnus (Feldman-Savelsberg 1999, Bangangté/Medumba) ; équivalents : mvog beti, Bona- duala, Ndog-/Lôg- bassa.
- **Statut** : 🆕 — l'entité manquante la plus structurante : l'app a clan, totem, villages, mais aucun lignage.
- **Implication produit** : `lineages` + `persons.lineage_id` + `lineage_affiliation_basis` (RM-11).
- **Portée** : le nom « ndap » est bamiléké-configurable ; l'entité lignage est universelle.

**RM-04 — Référentiel structuré des chefferies (la'a) à trois degrés.**
- **Énoncé** : table `chiefdoms` (nom, degré 1/2/3, département, chefferie parente, jour de marché RM-08) alimentée du référentiel officiel ; `origin_village` (V43) reçoit une FK optionnelle vers ce référentiel, texte libre conservé en secours ; rapprochement texte→référentiel assisté (suggestion, jamais écrasement). Corriger au passage `normalizeCountryCode` qui tronque un ISO-3 en 2 caractères.
- **Fondement** : décret n° 77-245 du 15/07/1977 (chefferies de 1er/2e/3e degré) ; l'identité bamiléké se décline par chefferie, pas par « village » générique.
- **Statut** : 🔧 — `origin_*` en texte libre sans lien avec `person_villages` (V43) ; bug `GenealogyServiceImpl.normalizeCountryCode:1377-1383`.
- **Implication produit** : référentiel + FK ; base de RM-08 et RM-53.
- **Portée** : référentiel camerounais ; mécanisme universel.

**RM-05 — Villages : des RÔLES typés, une validation lignagère, jamais de saut silencieux.**
- **Énoncé** : qualifier `person_villages` par un rôle ∈ {ORIGIN, BIRTH, RESIDENCE, BURIAL, BY_MARRIAGE}. (a) Un village d'ORIGINE doit venir du **lignage d'affiliation** (paternel en patrilinéaire, maternel en matrilinéaire ou si dot non versée — RM-11), pas de « n'importe quel ancêtre » ; (b) un village de RÉSIDENCE ou BY_MARRIAGE est libre (l'épouse vit au village du mari sans en descendre) ; (c) appliquer la validation aussi à `createPerson`/`createChild` (absente aujourd'hui) ; (d) **Neo4j indisponible → statut `UNVERIFIED` re-validé par job différé, jamais de validation silencieusement sautée.**
- **Fondement** : le village lignager est celui des tombes du lignage de rattachement ; virilocalité (Hurault 1962 ; Dongmo 1981).
- **Statut** : 🔧 — `GenealogyServiceImpl.validateAncestorVillages:1405-1438` (ancêtre quelconque, saut silencieux `:1415-1418`, absente à la création).
- **Implication produit** : colonne rôle + statut de validation + job.
- **Portée** : règle de rattachement configurable par système de filiation (RM-02) ; l'interdiction du saut silencieux est universelle.

**RM-06 — La concession (tsa') : foyer physique du lignage, transmise au successeur.**
- **Énoncé** : entité optionnelle `compounds` (chefferie, quartier, lignage détenteur, détenteur actuel = successeur) rattachant résidences, case des crânes (RM-63) et événements (funérailles RM-59) ; transférée à la confirmation de succession (RM-47). Jamais obligatoire (la diaspora n'en a pas toujours).
- **Fondement** : l'enclos familial bamiléké (cases, greniers, lieu des crânes) est l'unité résidentielle et rituelle indivise du lignage (Hurault 1962).
- **Statut** : 🆕 — le « foyer » actuel (tree_layout) est un pur groupement d'affichage.
- **Implication produit** : table légère + FK optionnelles.
- **Portée** : bamiléké-configurable.

**RM-07 — MÉCANISME CENTRAL : le profil coutumier par lignée/communauté.**
- **Énoncé** : table `community_rules` / `customary_profiles` (communauté/chefferie/lignage → paramètres : `descent_system`, `succession_rule`, `exogamy_scope` et profondeur, activation lévirat/sororat, étapes et items de dot, titres, calendrier, rayon privacy). Un arbre/lignage choisit son profil ; **défaut : profil neutre « droit civil seul »** ; livrer un profil « Bamiléké (générique) » soigné + surcharges par chefferie. Second axe d'évaluation `custom_compliance` ∈ {COMPLIANT, À VÉRIFIER, NON CONFORME À LA COUTUME DÉCLARÉE, UNKNOWN}, parallèle au `compliance_status` légal (V39) : **la coutume ne produit jamais de refus dur**, seulement des signalements doux (ton « À VÉRIFIER » existant).
- **Fondement** : la coutume est plurielle, orale, négociée en conseil ; préambule de la Constitution CM (coutumes conformes aux lois) ; les tribunaux coutumiers appliquent la coutume DES PARTIES.
- **Statut** : 🆕 — l'investissement unique qui dérisque toutes les règles configurables de ce référentiel.
- **Implication produit** : table + résolution de profil dans `ComplianceService` et futur `CustomComplianceService` ; réutiliser bannière/pilule « À VÉRIFIER » existantes.
- **Portée** : mécanisme universel ; contenus par communauté.

**RM-08 — Semaine de huit jours et jour de marché (priorité basse).**
- **Énoncé** : sur `chiefdoms` : jour de grand marché + noms locaux des 8 jours (option) ; étiqueter un événement familial (funérailles, deuil, réunion) avec le jour coutumier en plus de la date grégorienne.
- **Fondement** : calendrier grassfields de huit jours propre à chaque chefferie, jours fastes/néfastes pour les rites.
- **Statut** : 🆕. **Implication** : colonnes + arithmétique modulo 8. **Portée** : strictement configurable par chefferie — ne rien coder en dur.

---

# 2. Filiation & clans

**RM-09 — Un enfant a au plus un père et une mère biologiques.**
- **Énoncé** : double garde existante (index partiels DB + contrôle applicatif) conservée ; types non biologiques (ADOPTIVE, STEP, FOSTER) illimités, voulu.
- **Statut** : ✅ `MIG/V12:17-21`, `GenealogyServiceImpl.linkParentChild:181-189`. **Portée** : universelle.

**RM-10 — Le rôle parental est demandé explicitement, jamais déduit du genre.**
- **Énoncé** : paramètre `role` (MOTHER/FATHER/PARENT) explicite dans `createChild`/`linkParentChild` ; la déduction genre→rôle ne reste qu'un pré-remplissage UI ; supprimer le défaut OTHER→FATHER ; une femme peut être enregistrée « père social »/parent statutaire.
- **Fondement** : maternité/paternité sociales attestées (mariage femme-femme igbo/nandi, attesté aussi dans les Grassfields) ; les index d'unicité (RM-09) portent déjà sur le RÔLE — bonne base.
- **Statut** : 🔧 — `GenealogyServiceImpl.createChild:272-273`, `:905-909`, `:1327-1330`.
- **Portée** : structure universelle ; institutions sociales par communauté.

**RM-11 — RÈGLE MAJEURE : pater ≠ genitor — l'affiliation lignagère des enfants suit la dot.**
- **Énoncé** : distinguer filiation biologique (existante, intouchée) et affiliation LIGNAGÈRE : par défaut l'enfant est affilié au lignage (RM-03) de son père biologique **si la dot de l'union de ses parents est accomplie** ; sinon au lignage de sa mère (grand-père/oncle maternel), avec « rachat » ultérieur possible (dot accomplie tardivement → bascule d'affiliation **proposée, jamais silencieuse ni rétroactive automatique**, historisée). Cette affiliation pilote : ndap hérité, chefferie/villages de rattachement (RM-05), éligibilité successorale (RM-45) — jamais la filiation biologique. `parent_child.parent_type` gagne SOCIAL/LINEAGE ; un enfant peut avoir un genitor ET un pater distincts.
- **Fondement** : règle cardinale des patrilinéaires camerounais : l'enfant né hors dot « appartient » au lignage maternel jusqu'au rachat (Hurault 1962 ; Laburthe-Tolra 1981 ; Brain 1972 ; Feldman-Savelsberg 1999). C'est la raison d'être sociale de la dot — l'app modélise la dot sans son unique effet juridique coutumier.
- **Statut** : 🆕 — et corrige le contresens du rattachement « à défaut » (RM-13).
- **Implication produit** : `persons.lineage_id` + `lineage_affiliation_basis` ∈ {DOT_PAID, MATERNAL_DEFAULT, REDEEMED, MANUAL} ; recalcul proposé quand l'étape REMISE de la dot change.
- **Portée** : configurable (sans objet chez les matrilinéaires : l'enfant est toujours du clan maternel) ; la distinction pater/genitor elle-même est universelle (nécessaire aussi pour le lévirat RM-60).

**RM-12 — Transmission du clan : dérivée, proposée, jamais silencieuse.**
- **Énoncé** : à la création d'un enfant, pré-remplir son clan selon `descent_system` (RM-02) du clan parental ; l'utilisateur corrige librement ; incohérence parent/enfant → avertissement doux, pas de blocage (confiage, réaffiliations existent). Qualifier `person_clans` par `membership_type` ∈ {PATRICLAN, MATRICLAN, ADOPTIVE, HONORARY}. Enrichir l'entité clan : préfixe lignager (Mvog-, Ndog-, Bona-…), totem(s) hérités du clan (surcharge individuelle possible), devise, interdits, villages d'origine, `parent_clan_id` (segmentation).
- **Fondement** : l'appartenance clanique est un statut de naissance, pas un choix ; le totem descend du clan.
- **Statut** : 🔧 — clan saisi librement (`GenealogyServiceImpl:57-59`, `createChild:250-252`), totem attribut plat de la personne.
- **Portée** : mécanisme universel, contenus par communauté.

**RM-13 — Rattachement enfant→union : présomption temporelle, jamais d'affectation silencieuse.**
- **Énoncé** : `resolveUnionId` piloté par les dates : union candidate = celle dont la période [début, fin + 300 jours] couvre la naissance (présomption *pater is est*, C. civ. art. 311-312) ; correspondance exacte père+mère → comportement actuel conservé ; sinon **PROPOSER** l'union temporellement compatible comme suggestion à confirmer — jamais d'affectation silencieuse « à une union active quelconque » (dans un foyer polygame, afficher l'enfant sous la mauvaise co-épouse est une faute grave ; coutumièrement, l'enfant hors dot relève du lignage maternel — RM-11). Persister enfin `parent_child.union_id` (nullable, statut confirmé/suggéré) au lieu de le recalculer à chaque lecture.
- **Fondement** : C. civ. reçu art. 311-312 ; centralité de la maison maternelle dans les foyers polygames.
- **Statut** : 🔧 — `GenealogyServiceImpl.resolveUnionId:959-990` (fallback « à défaut » explicitement dangereux).
- **Portée** : universelle ; exception configurable : enfant du lévirat (RM-60).

**RM-14 — Exogamie lignagère et clanique : détecter et signaler, sévérité configurable, jamais globale.**
- **Énoncé** : à `createUnion`, contrôle en deux étages : (i) comparaison des lignages/clans (`lineage_id`/ndap identique → « NON CONFORME À LA COUTUME DÉCLARÉE » ; clan commun selon `exogamy_scope` du profil ∈ {NONE, CIVIL_ONLY, LINEAGE, CLAN, VILLAGE} + périmètre maternel/grand-maternel configurable) ; (ii) recherche d'ancêtre commun ≤ N générations bilatérales (défaut N=4) via Neo4j. Résultat persisté `kinship_check_result` + note ; **défaut global : information neutre** ; blocage dur optionnel par profil, uniquement pour les unions déclaratives futures.
- **Fondement** : exogamie = fonction juridique première du clan (ayong fang, mvog beti — étendu au mvog maternel —, lôg bassa bilatéral strict, kanda kongo, patrilignage/ndap bamiléké) ; MAIS mariage entre cousins préféré chez les Peuls/Foulbé et licite en droit musulman — un interdit global serait une faute culturelle dans un sens comme dans l'autre.
- **Statut** : 🆕 — `createUnion` ne vérifie AUCUN lien de parenté (simplification transverse n° 6 de l'audit).
- **Implication produit** : `KinshipCheckService` ; repli PostgreSQL pur (comparaison lignages) si Neo4j down + statut UNCHECKED re-vérifié (jamais de saut silencieux) ; injecter dans le prompt IA (RM-87).
- **Portée** : LE cas d'école du configurable (RM-07).

**RM-15 — Noyau dur universel d'inceste : le seul interdit non désactivable.**
- **Énoncé** : union ascendant/descendant directs ou frère/sœur (FULL/HALF détectés dans l'arbre) → **refus dur uniquement pour la création déclarative d'une union civile contemporaine** ; pour les unions historiques ou non civiles : enregistrement (OR-1) avec WARNING fort « prohibée par le droit civil ». Oncle-nièce/tante-neveu → WARNING « prohibée sauf dispense » ; cousins germains → simple information (licite en droit civil ; préférentiel dans certaines traditions).
- **Fondement** : prohibition nucléaire universelle et d'ordre public (C. civ. reçu art. 161-164) ; les degrés au-delà varient (abominés chez les Bassa, valorisés ailleurs).
- **Statut** : 🆕. **Arbitrage signalé** : l'expert droit préconisait « warning seulement, jamais de blocage » ; l'expert bantou un blocage dur du noyau. Tranché : blocage dur limité au déclaratif civil contemporain, warning partout ailleurs — cohérent avec OR-1 et RM-72.
- **Portée** : noyau universel ; degrés dispensables par pays, périmètre coutumier par profil.

**RM-16 — Les affins comptent : parenté par alliance.**
- **Énoncé** : étendre RM-14/15 aux affins directs (ex-conjoint d'un ascendant/descendant, sœur de l'épouse vivante hors sororat consenti) — en avertissement configurable ; le lévirat/sororat (RM-60) est l'exception licite.
- **Statut** : 🆕. **Implication** : chemins Neo4j passant par `unions`. **Portée** : configurable, défaut = avertissement.

**RM-17 — Ajout d'un père à un enfant né hors mariage : consentement de la MÈRE, pas symétrique.**
- **Énoncé** : quand un compte ajoute un lien PÈRE biologique sur un enfant dont il n'est pas la mère, la demande d'association est routée vers la mère (ou l'enfant majeur avec compte) ; l'ajout d'une mère par le père suit le flux actuel.
- **Fondement** : Ord. 81-02 art. 41 (reconnaissance avec consentement de la mère).
- **Statut** : 🔧 — workflow co-parent aujourd'hui symétrique (`createChild:290-310`, V33).
- **Portée** : universelle.

**RM-18 — Remplacer le seuil « 4 ans » par la revendication de fiche.**
- **Énoncé** : les parents modifient la fiche d'un enfant tant qu'elle n'est pas revendiquée par un compte propre (`person.user_id == null`) ; revendication possible à l'âge du consentement numérique du pays (plancher produit : 15 ans) ; la co-validation de l'autre parent (workflow existant) est conservée. Le seuil de 4 ans n'a aucun fondement (un enfant de 6 ans ne peut pas « modifier depuis son propre compte ») ; le blocage total quand la date de naissance manque disparaît avec RM-56.
- **Fondement** : autorité parentale (majorité civile CM : 21 ans) ; RGPD art. 8.
- **Statut** : 🔧 — `GenealogyServiceImpl.requestChildModification:414-425` (seuil 4 ans en dur, blocage si date absente).
- **Portée** : âge de revendication par pays ; principe universel.

**RM-19 — Confiage (fosterage) : lien courant, daté, sans rupture de filiation.**
- **Énoncé** : outiller le type FOSTER existant : dates début/fin sur le lien, tuteur dans `guardianships`, parents biologiques/pater jamais retirés ; UI de premier rang (« élevé par sa grand-mère de 1962 à 1970 »). Ne pas le modéliser pousse les utilisateurs à créer de FAUX liens parentaux.
- **Fondement** : le confiage est massif et normal dans toute l'aire — ni abandon ni adoption.
- **Statut** : ✅ enum FOSTER existe · 🆕 dates + guardianships + UI.
- **Portée** : universelle.

**RM-20 — Jumeaux : gémellité marquée, titres parentaux proposés.**
- **Énoncé** : `twin_group_id` sur persons (rangs d'aînesse ex æquo — ne pas présumer quel jumeau est l'aîné, les traditions divergent) ; à l'enregistrement de jumeaux, **proposer** (jamais imposer) les titres TAGNI/MAGNI (libellés par chefferie : Tagne/Magne, Tanyi/Manyi…) via RM-53 ; indice IA (deux naissances même date + mêmes parents → suggestion de gémellité).
- **Fondement** : dans tout le Grassfields et l'aire côtière, les jumeaux sont des êtres marqués et leurs parents reçoivent des titres à vie.
- **Statut** : 🆕 — le trigger fratries V13 les typerait simplement FULL.
- **Portée** : marquage universel ; titres par communauté.

**RM-21 — Aucun statut d'« illégitimité » pour les enfants, jamais, nulle part.**
- **Énoncé** : extension explicite d'OR-1 : aucun libellé, badge, tri ou filtre ne distingue un enfant selon le statut de l'union de ses parents (hors union, avant dot, union NON_COMPLIANT) ; l'affiliation lignagère (RM-11) est une information de filiation, pas un jugement.
- **Fondement** : « l'enfant n'est jamais un bâtard, il a toujours un lignage » ; égalité des filiations en droit moderne.
- **Statut** : ✅ en creux — à ériger en contrainte de revue produit/UI + javadoc normative + tests UI.
- **Portée** : universelle, NON configurable.

**RM-22 — Le lignage maternel est réel : double ancrage et oncle maternel opérationnel.**
- **Énoncé** : matérialiser le lien de chacun vers son lignage « secondaire » (clan de la mère en zone patrilinéaire) ; calculer et exposer le(s) oncle(s) maternel(s) (frères utérins de la mère) : proposé comme tuteur (`guardianships`, rôle `MATERNAL_UNCLE`), notifié aux événements majeurs (décès — RM-61), bénéficiaire possible de dot (RM-29), successeur potentiel en régime matrilinéaire (RM-45).
- **Fondement** : le neveu utérin a des privilèges chez ses oncles maternels (Laburthe-Tolra 1981) ; chez les matrilinéaires, l'oncle maternel EST l'autorité lignagère (ngudi a nkazi).
- **Statut** : 🆕 — `guardianships` (V12:64-72) existe sans aucun code ; `notifyFamilyOfDeath` ne notifie que parents/enfants.
- **Portée** : universel dans l'aire ; intensité selon RM-02.

**RM-23 — Légitimation par mariage subséquent (mineure).**
- **Énoncé** : si les deux parents biologiques d'un enfant né hors mariage contractent ensuite une union, annoter la filiation « légitimée par mariage » (information dérivée, aucun schéma nouveau).
- **Statut** : 🆕, faible priorité. **Portée** : universelle.

---

# 3. Unions & dot

**RM-24 — Le mariage est un PROCESSUS d'événements datés ; « DOT » sort des types d'union.**
- **Énoncé** : (a) `union_form` ENUM mono-valué {CIVIL, CUSTOMARY_DECLARED, CUSTOMARY_UNDECLARED, RELIGIOUS, DE_FACTO, ENGAGED} remplace le « régime » VARCHAR libre pour la conformité — l'heuristique textuelle `isCivilRegime` (contient "CIVIL"/"MONOG") disparaît ; (b) table `union_events(union_id, type ∈ {PRESENTATION («toquer la porte»), FIANÇAILLES_COUTUMIÈRES, DOT/MARIAGE_COUTUMIER, MARIAGE_CIVIL, MARIAGE_RELIGIEUX}, date, lieu, témoins[])` — chaque étape a sa date et sa valeur probatoire propre ; les types multi-valués actuels deviennent une vue dérivée ; **DOT n'est plus un type d'union** (c'est un processus, RM-27). Une union peut rester des décennies à l'étape coutumière : mariage complet, pas état transitoire. Distinction déclaré/non déclaré : le coutumier transcrit à l'état civil est opposable (Ord. 81-02 art. 81 ; jugement supplétif).
- **Fondement** : Ngoa, *Le mariage chez les Ewondo* (1968) ; Laburthe-Tolra 1981 ; Ord. 81-02 art. 81.
- **Statut** : 🔧 — `MIG/V39:18` (VARCHAR libre), `ComplianceService.isCivilRegime:152-156`, `MIG/V10:7`/`V26` (DOT dans l'enum des types), `add_union_dialog.dart:73-96`.
- **Implication produit** : migration types→forme ; conformité dure appliquée aux seules unions CIVIL ; CUSTOMARY_* et DE_FACTO jamais bloquées.
- **Portée** : structure universelle ; libellés d'étapes par communauté.

**RM-25 — Dégenrer la structure d'union : partner_1/partner_2 + rôles.**
- **Énoncé** : remplacer `husband_id/wife_id` + garde `husband.gender == MALE` par `partner_1/partner_2` + `role ∈ {HUSBAND, WIFE, PARTNER}` ; l'union même sexe n'est acceptée que si `same_sex_allowed` au lieu de CÉLÉBRATION (V42, logique conservée). Les règles genrées (dot, option de polygamie, rang d'épouse) se raccrochent aux RÔLES. Pour toute personne VIVANTE résidant ou originaire d'un pays pénalisant (C. pén. CM art. 347-1) : consentement des deux parties requis + visibilité verrouillée FAMILY_ONLY, exclue du feed, de la recherche et de toute API partenaire (orientation sexuelle = donnée sensible RGPD art. 9).
- **Fondement** : contradiction interne documentée — la garde MALE rend V42 inopérante (seul MALE+MALE passerait) ; les institutions historiques de « mariage de femme à femme » (igbo, nandi, Grassfields) plaident aussi pour des rôles.
- **Statut** : 🔧 — `GenealogyServiceImpl.createUnion:587-613` ; migration lourde mais délimitée.
- **Portée** : reconnaissance par pays (V42) ; protection privacy universelle.

**RM-26 — Consentement des époux : conserver la validation par le conjoint, ajouter le mode HISTORIQUE.**
- **Énoncé** : le workflow « seul le conjoint (jamais le créateur) peut valider, contestation → REJECTED » est la traduction produit exacte de l'exigence de consentement : **le conserver**. Ajouter `record_mode ∈ {DECLARATIVE, HISTORICAL}` : quand les deux parties sont décédées ou sans compte, l'union passe en HISTORICAL avec confirmation communautaire/documentaire au lieu de rester éternellement PENDING_APPROVAL — une app généalogique est composée à 80 % d'unions historiques. Les HISTORICAL non confirmées restent comptées dans le décompte de polygamie (le fait prime).
- **Fondement** : Ord. 81-02 art. 64 ; C. pén. CM art. 356 (mariage forcé) ; Maputo art. 6(a).
- **Statut** : ✅ vivants (`confirmUnion:680-707`) · 🔧 historique (limite R6.1 : union de conjoint sans compte bloquée à vie).
- **Portée** : universelle.

**RM-27 — La dot est un PROCESSUS à étapes, avec contenu et deux lignages — pas un booléen.**
- **Énoncé** : remplacer `is_dot_paid` par `dot_status ∈ {NONE, PROMISED, PARTIAL, PAID, SYMBOLIC, RETURNED}` + `dot_steps` (étapes datées configurables : TOQUER_LA_PORTE, ENQUÊTE_FAMILIALE, REMISE, CÉRÉMONIE) + `dot_items` (nature : chèvres, huile de palme, sel, étoffes, boissons, numéraire — **sans montant obligatoire**, doctrine ADR-002 « jamais le montant »). **Supprimer le forçage UI « type DOT coché ⇒ dot payée »** : la dot promise ou versée par tranches sur des années est la norme sociale (une dot symbolique — 1 franc — est courante dans les familles chrétiennes). Migration : `is_dot_paid=TRUE` → PAID ; badge « DOT » dès PARTIAL (nuance visuelle) ou étape REMISE accomplie.
- **Fondement** : la dot est une chaîne de prestations entre LIGNAGES (Tardits 1960 ; Hurault 1962 ; Brain 1972) ; l'art. 70 de l'Ord. 81-02 vise expressément le « versement partiel ».
- **Statut** : 🔧 — `MIG/V12:38-43` (modèle plat), `add_union_dialog.dart:312-313` (forçage UI).
- **Portée** : structure universelle ; étapes et items par chefferie.

**RM-28 — La dot ne conditionne JAMAIS la validité dans l'app ; sa portée légale est un référentiel par pays.**
- **Énoncé** : (a) ne jamais bloquer/dégrader une union pour dot absente ; aucun couplage dot→`compliance_status` ; (b) colonne `dot_rule ∈ {REQUIRED_FOR_VALIDITY, OPTIONAL, CAPPED, PROHIBITED}` sur `country_marriage_rules`, purement informative : CM = OPTIONAL (art. 70 Ord. 81-02 : versement total, partiel ou nul sans effet sur la validité) ; RDC = REQUIRED (Code de la famille, loi 87-010, art. 361) ; CI = PROHIBITED (lois du 07/10/1964) ; GA = PROHIBITED (loi du 31/05/1963) ; CG = CAPPED (Code de la famille 1984, plafond 50 000 FCFA). Quatre régimes juridiques opposés pour la même institution : preuve définitive que la règle est un référentiel, jamais une constante.
- **Statut** : ✅ l'app n'exige pas la dot · 🆕 référentiel `dot_rule` · 🔧 amalgame UI (couvert par RM-27).
- **Portée** : par pays ET par date (RM-70).

**RM-29 — Parties et témoins de la dot : deux lignages.**
- **Énoncé** : ajouter `dot_recipient_id` (personne recevant au nom du lignage de l'épouse — père, oncle maternel selon RM-02, chef de lignage), symétrique de `dot_paid_by` ; contrôle SOUPLE de complétude : ≥ 1 témoin rattachable au lignage de chaque époux (warning si non satisfait, jamais bloquant — les fiches témoins peuvent manquer).
- **Statut** : 🔧 — le modèle a le payeur mais pas le récipiendaire ; témoins non structurés ni validés (`MIG/V12:38-43`).
- **Portée** : configurable (nombre de témoins par communauté).

**RM-30 — Restitution de la dot : le marqueur du divorce coutumier.**
- **Énoncé** : sur dissolution d'une union coutumière : `dot_status = RETURNED` + date + témoins, proposé automatiquement ; champ déclaratif `dot_settlement ∈ {NON_CONCERNÉ, EN_DISCUSSION, REMBOURSÉE, ABANDONNÉE}` — purement informatif, sans montant ni workflow de paiement ; la restitution totale peut PROPOSER (jamais automatiquement) une bascule d'affiliation des enfants (RM-11).
- **Fondement** : jurisprudence constante des juridictions traditionnelles camerounaises (le remboursement de la dot consacre la dissolution du mariage coutumier ; décret n° 69/DF/544 de 1969) ; contentieux transgénérationnels à consigner comme mémoire.
- **Statut** : 🆕. **Portée** : configurable (certaines communautés ne restituent pas après longue union ou naissance d'enfants).

**RM-31 — Autorisation sur `updateDotStatus` ET `endUnion`.**
- **Énoncé** : `updateDotStatus` réservé aux parties à l'union, au payeur, au récipiendaire ou au créateur de la fiche ; `endUnion` réservé aux parties, au créateur ou à l'admin, motif DEATH interdit par cette voie (passer par le flux décès RM-54/RM-55) ; toute mise à jour journalisée (qui, quand).
- **Fondement** : la dot engage l'honneur de deux lignages ; l'état matrimonial d'autrui ne se modifie pas librement ; RGPD art. 5(1)(d) (exactitude).
- **Statut** : 🔧 — `GenealogyServiceImpl.updateDotStatus:730-749` (`requestedBy` ignoré), `endUnion:751-762` (aucun contrôle) — simplification transverse n° 4 de l'audit.
- **Portée** : universelle.

**RM-32 — Garde-fou absolu : aucune mécanique de « droits sur la personne » adossée à la dot.**
- **Énoncé** : aucune fonctionnalité, jamais, ne lie le paiement d'une dot à des droits sur une personne vivante (sur la femme, sur ses futures filles, sur leur dot). La dot dans l'app = fait d'alliance + pivot d'affiliation des enfants (RM-11), rien d'autre. Javadoc normative comme OR-1 ; revue des futures features dot/API partenaire à cette aune.
- **Fondement** : le système « ta nkap » (créancier de dot détenant des droits sur les filles à naître) a été prohibé dès la période coloniale ; consentement obligatoire (Ord. 81-02 ; C. pén. art. 356).
- **Statut** : 🆕 (préventive — rien dans le code ne le fait, il faut que rien ne le fasse jamais). **Portée** : universelle, NON configurable.

**RM-33 — Âge au mariage : référentiel par pays et par époque, TOUJOURS advisory.**
- **Énoncé** : colonnes `min_age_husband/min_age_wife/dispensation` sur le référentiel versionné (RM-70) ; warning si l'âge d'un époux à `celebration_date` est inférieur — **jamais bloquant, et AUCUN signalement pour les unions historiques** (l'app est un registre de mémoire, pas un juge du passé ; seuil de contemporanéité ~10 ans). CM : 15 ans (fille)/18 ans (garçon), dispense présidentielle (Ord. 81-02 art. 52) — afficher aussi le standard international de 18 ans (Maputo art. 6(b), CDE) : les deux niveaux.
- **Statut** : 🆕. **Portée** : par pays et par époque.

**RM-34 — Délai de viduité : information au remariage précoce.**
- **Énoncé** : union civile d'une femme < 300 jours après dissolution de la précédente, dans un pays maintenant le délai → note informative (présomption de paternité du précédent mari possible sur un enfant à naître). Jamais bloquant. Flag référentiel `viduity_delay_days` (CM : C. civ. art. 228 reçu toujours applicable ; FR : abrogé loi du 26/05/2004 — d'où pays-dépendance) ; croisement avec RM-13.
- **Statut** : 🆕. **Portée** : par pays.

**RM-35 — Le mariage religieux seul est sans effet civil.**
- **Énoncé** : `union_form = RELIGIOUS` sans union civile associée → note informative « célébration religieuse sans effet à l'état civil » ; en France, mention supplémentaire (C. pén. fr. 433-21 : célébration religieuse avant le mariage civil sanctionnée) — information, jamais blocage. Sans objet dans les pays de common law où le célébrant licencié EST officier d'état civil (GB, NG, US).
- **Statut** : 🆕. **Portée** : par pays.

**RM-36 — Non-renouvellement d'alliance entre lignages (option locale).**
- **Énoncé** : contrôle optionnel, **désactivé par défaut** : si une union active ou récente existe déjà entre les deux lignages, information douce « une alliance existe déjà entre ces lignées ; certaines chefferies ne renouvellent pas l'alliance » — jamais bloquant.
- **Fondement** : dispersion voulue des alliances dans plusieurs chefferies bamiléké (Pradelles de Latour 1991) — pratique très variable.
- **Statut** : 🆕. **Portée** : strictement configurable par chefferie, à ne JAMAIS activer par défaut.

---

# 4. Foyers & polygamie

**RM-37 — L'option monogamie/polygamie est un attribut de la PERSONNE, posé au 1er mariage civil.**
- **Énoncé** : `persons.marriage_option ∈ {MONOGAMY, POLYGAMY, LIMITATION(n)}` + date, posé à la première union civile, irrévocable tant qu'une union civile subsiste (modifiable après dissolution de toutes). Une 2e union civile d'un homme n'est conforme (CM) que si son option est POLYGAMY ; option MONOGAMY + 2e union civile = bigamie NON_COMPLIANT (rejet dur seulement dans le cas RM-72). L'actuel « régime » VARCHAR saisi PAR UNION permet de déclarer « Monogamie civile » sur l'union 1 et « Polygamie civile » sur l'union 2 du même homme — exactement ce que l'art. 49 interdit.
- **Fondement** : Ord. 81-02 art. 49 (option déclarée à la célébration, mentionnée à l'acte) ; C. pén. CM art. 359 (bigamie) ; SN Code de la famille 1972 art. 133 (option triple : monogamie / limitation / polygamie ≤ 4).
- **Statut** : 🔧 — `MIG/V39:18` (VARCHAR(30) libre par union), `GenealogyServiceImpl:593-596`.
- **Portée** : pays à `polygamy_mechanism = OPTION_DECLARATION` (RM-74).

**RM-38 — Cameroun : sans option déclarée, le mariage est PRÉSUMÉ POLYGAMIQUE — corriger le message.**
- **Énoncé** : pour le CM, union additionnelle : régime déclaré POLYGAMY → **COMPLIANT** (pas WARNING) ; MONOGAMY déclaré → NON_COMPLIANT (bigamie pour l'époux monogame) ; régime inconnu/coutumier → WARNING avec message corrigé : « au Cameroun, à défaut d'option déclarée à l'état civil, le mariage est présumé polygamique (Ord. 81-02, art. 49) ; vérifiez l'acte ». Le message actuel (« option de polygamie déclarée à l'état civil à vérifier ») laisse croire que le défaut serait la monogamie — c'est l'inverse. Le paramètre `existingActiveUnions`, reçu et ignoré, sert ce raffinement (brancher sur le régime déclaré de la PREMIÈRE union de l'époux).
- **Statut** : 🔧 — `ComplianceService.evaluate:89-132` (messages :114-117).
- **Portée** : CM ; logique déclinable SN/ML/TD (options similaires).

**RM-39 — Polygamie de droit vs polygamie de fait.**
- **Énoncé** : `unions.polygamy_kind ∈ {DE_JURE, DE_FACTO}` : (a) foyer polygame de droit (unions civiles multiples sous option, ou coutumières déclarées) ; (b) polygamie de fait (mariage civil monogame + unions coutumières/de fait parallèles) — cas très répandu, diaspora comprise, **jamais « non conforme » en soi** (le concubinage n'est pas une infraction ; seule une 2e union CIVILE l'est). Les messages NON_COMPLIANT actuels stigmatisent des unions de fait licites.
- **Fondement** : C. pén. 359 ne réprime que la bigamie d'état civil ; sociologie juridique camerounaise constante.
- **Statut** : 🔧 — `ComplianceService:125-127`, marquage `is_polygamous` uniforme (`GenealogyServiceImpl:653-670`).
- **Portée** : universelle.

**RM-40 — Bigamie féminine et polyandrie : branche d'évaluation dédiée, jamais les règles de la polygynie.**
- **Énoncé** : (a) 2e union CIVILE active d'une femme → **NON_COMPLIANT partout, y compris pays CONDITIONAL** (l'option de polygamie ne profite qu'au mari ; aucun État du référentiel n'admet la polyandrie) — le code actuel sortirait un simple WARNING « option de polygamie à vérifier », juridiquement et culturellement faux ; (b) unions DE FAIT multiples d'une femme : enregistrables (OR-1), statut factuel neutre + alerte de saisie « vérifiez les dates de fin : ces unions se chevauchent » (le cas réel est presque toujours une union précédente non soldée dans les données — dot/divorce non enregistrés) ; (c) le mode « foyers » n'est JAMAIS déclenché par les unions d'une femme, la polygynie seule le fait ; (d) symétriser le marquage rétroactif `is_polygamous` (aujourd'hui mari seul) avec la qualification (a)/(b) ; (e) ne pas rendre la polyandrie structurellement irreprésentable (elle existe ailleurs dans le monde) — seulement non conforme selon profil.
- **Fondement** : C. pén. CM art. 359 ; Ord. 81-02 art. 49 (option unilatéralement masculine) ; aucune coutume polyandre dans l'aire.
- **Statut** : 🔧 — `ComplianceService.mustHardReject:140-146` + `GenealogyServiceImpl:616-618,661-670` (polyandrie = mêmes règles que la polygamie, limite explicite de l'audit).
- **Portée** : universelle pour le civil ; le fait reste toujours enregistrable.

**RM-41 — Le rang d'épouse est un fait coutumier HISTORIQUE : immuable après dissolution, mais éditable et ancré sur la date coutumière.**
- **Énoncé** : (a) `union_order` **jamais recompacté** après divorce/décès — une 2e épouse reste « 2e » après le décès de la première : la « limite » relevée par l'audit (R3.2) est en réalité le comportement coutumier CORRECT, à documenter comme intentionnel (test + commentaire) ; (b) rang **éditable** par les parties/la famille avec trace (les familles saisissent dans le désordre : max+1 à l'insertion est fragile face aux saisies rétroactives) ; (c) défaut = tri par date de la REMISE de dot ou de l'union coutumière, pas ordre d'insertion ; (d) les épouses héritées par lévirat (RM-60) n'entrent pas au rang chronologique ordinaire (rang propre, configurable).
- **Fondement** : le rang des co-épouses est un statut d'ancienneté acquis à l'alliance et conservé à vie (Tardits 1960).
- **Statut** : ✅ non-recompaction (à documenter comme voulu) · 🔧 éditabilité + ancrage date (`GenealogyServiceImpl:637`, `UnionRepository:36`).
- **Arbitrage signalé** : l'expert bantou suggérait de « recalculer l'affichage après dissolution » ; les experts bamiléké et droit convergent sur l'immuabilité — tranché : **rang immuable**, seuls les libellés d'affichage peuvent contextualiser.
- **Portée** : quasi universelle dans les foyers polygynes de l'aire.

**RM-42 — La première épouse (« grande épouse ») : statut dérivé, préséance protocolaire.**
- **Énoncé** : marqueur dérivé « première épouse » (rang 1, une seule par foyer) : badge configurable, priorité de notification/consultation dans les workflows familiaux du foyer (validations RM-48). La couleur or du foyer 1 et le badge « 1RE UNION » existent déjà.
- **Fondement** : préséance cérémonielle et autorité d'organisation du foyer, chaque co-épouse gardant sa case et ses champs propres dans la concession (Tardits 1960 ; Hurault 1962).
- **Statut** : ✅ affichage · 🆕 effets fonctionnels légers. **Portée** : configurable.

**RM-43 — Le mode « foyers » reste un rendu de la polygynie ; jamais de hiérarchie entre enfants.**
- **Énoncé** : conserver `_detectFoyerGroups` (rangées de co-épouses, couleurs, boîtes « FOYER X · N ENFANTS », rattachement par unionId) comme **mise en page uniquement** — il ne confère plus aucun titre (RM-44). Les libellés « ÉPOUSE N » restent factuels (rang d'union) sans connotation ; possibilité d'afficher le nom de la maison ; jamais de hiérarchisation visuelle des enfants selon le rang de leur mère (OR-1/RM-21). Dans la terminologie classificatoire, l'enfant désigne les co-épouses de sa mère comme « mères » (RM-68).
- **Fondement** : la maison (cuisine, foyer) de chaque épouse est l'unité résidentielle et affective ; la fraternité utérine structure les solidarités sans créer de rang de dignité.
- **Statut** : ✅ largement couverte (`tree_layout_provider.dart:989-1084`) — à découpler du titre « chef de famille » et compléter par RM-68.
- **Portée** : universelle.

---

# 5. Succession & chefferie

**RM-44 — « Chef de famille » est un RÔLE persisté et attribué, JAMAIS inféré de la polygamie.**
- **Énoncé** : supprimer l'inférence `isChief = homme + ≥2 unions`. Le badge « CHEF DE FAMILLE » (♛) ne s'affiche que si : (a) titre persisté (RM-53) ou rôle `FAMILY_HEAD` déclaré (table dédiée ou `guardianships` enfin activée, portée foyer/lignage/clan, mode d'accession {HÉRITÉ, DÉSIGNÉ, ÉLU_CONSEIL}, dates), ou (b) succession confirmée (RM-47). Un monogame successeur EST chef de famille ; une veuve peut être cheffe de foyer (réalité massive) ; un polygame non-successeur ne l'est pas nécessairement. L'inférence actuelle peut rester un fallback visuel étiqueté « suggéré / non confirmé ».
- **Fondement** : le chef de famille est une INSTITUTION successorale/lignagère (détenteur de la concession et du culte des crânes chez les Bamiléké — Hurault 1962 ; mbombok bassa ; chef de mvog beti ; têtes de « grandes maisons » duala), pas un effet du nombre d'épouses. Contresens anthropologique n° 2 de l'existant. Droit : C. civ. reçu art. 213 contrebalancé par la Constitution 1996 et la CEDEF art. 16.
- **Statut** : 🔧 — `tree_layout_provider.dart:1199-1206` (isChief) ; `guardianships`/`CLAN_CHIEF` (V12:64-72) en schéma sans AUCUN code Java.
- **Implication produit** : activer `guardianships` + table rôle ; la pilule ♛ lit le rôle persisté ; RM-43 conserve la mise en page foyers.
- **Portée** : structure universelle ; modes d'accession par communauté.

**RM-45 — La règle successorale est un PARAMÈTRE DE LIGNÉE ; retirer l'« ordre de succession » par aînesse.**
- **Énoncé** : `succession_rule` par lignage/clan ∈ {DESIGNATED_HEIR (désigné par le titulaire, éventuellement secret), PRIMOGENITURE_MALE, PRIMOGENITURE (tous genres), UTERINE_NEPHEW (frère utérin puis fils de sœur), COUNCIL_ELECTION, CIVIL_EQUAL}. Le panneau actuel (top-3 des enfants par date de naissance intitulé « ORDRE DE SUCCESSION ») est **renommé « ordre d'aînesse » (informatif)** et n'est promu « ordre de succession » que si la lignée a explicitement choisi une stratégie de primogéniture ; en mode DESIGNATED_HEIR, afficher « successeur désigné par le chef — non public de son vivant » ou « successeur non désigné / à déterminer par le conseil de famille » ; en mode UTERINE_NEPHEW, calculer frères utérins puis fils des sœurs. **Aucun affichage prédictif sans profil choisi (défaut : rien).**
- **Fondement** : contradiction culturelle n° 1 de l'existant. Chez les Bamiléké, le successeur est DÉSIGNÉ librement par le père parmi ses fils (rarement l'aîné, précisément pour éviter les attentes), souvent en secret, révélé aux funérailles par les notables (Hurault 1962 ; Tardits 1960 ; Pradelles de Latour 1991) ; Bamoun : le Mfon choisit (Tardits 1980) ; Kom (Grassfields) et matrilinéaires kongo/akan : neveu utérin, jamais le fils ; Beti : primogéniture tempérée (seule coutume validant à peu près l'affichage actuel). Afficher un « top 3 par date de naissance » à un utilisateur bamiléké est factuellement faux et socialement inflammable (les conflits successoraux sont la 1re source de litiges familiaux et sont judiciarisés).
- **Statut** : 🔧 — `genealogy_right_panel.dart:1284-1306` (`_successionOf`, tri chronologique présenté comme ordre successoral).
- **Implication produit** : paramètre de profil (RM-07) + les calculs d'aînesse existants réutilisés comme UNE stratégie parmi d'autres.
- **Portée** : LE cas d'école du configurable — aucun défaut global n'est défendable.

**RM-46 — Désignation successorale : explicite, scellée si secrète, révélée au décès.**
- **Énoncé** : table `succession_designations` (designator, designated, scope : nom/titre/concession/crânes, témoins/dépositaires, statut ∈ {SEALED, REVEALED, CONFIRMED, DISPUTED}) ; **unicité du successeur principal actif par désignateur** ; statut SEALED = visible de PERSONNE (ni famille, ni successeur, ni admin — chiffrement applicatif recommandé) tant que le décès du désignateur n'est pas validé ; à la validation du décès (workflow existant), passage à REVEALED + notification au conseil de famille — traduction numérique exacte de l'institution orale (la révélation se rattache à la sortie de deuil/funérailles, RM-59). Toute personne, homme ou femme, peut désigner ; jamais de restriction de genre du désigné (ordre public, RM-49).
- **Fondement** : le secret est constitutif de l'institution bamiléké (protège le père et l'héritier des jalousies) ; succession féminine parallèle documentée (biens, champs, rôle rituel ; institution de la mafo) — Hurault 1962 ; Pradelles de Latour 1991.
- **Statut** : 🆕 — différenciateur produit majeur.
- **Portée** : le secret est configurable (option « désignation publique » type testament ouvert) ; le mécanisme est universel.

**RM-47 — Successeur unique et total (profil bamiléké) : il « devient » le défunt.**
- **Énoncé** : pour un profil bamiléké, la confirmation de succession déclenche en une transaction orchestrée (`SuccessionConfirmedEvent`) : port du nom (champ « nom porté/succédé »), transfert des titres (RM-53), garde des crânes (RM-63), proposition de rattachement des veuves (RM-60, consentement obligatoire), tutelles des mineurs (RM-50), concession (RM-06). **Ne PAS modéliser de « parts d'héritage » multiples** pour ce profil — et aucune part patrimoniale calculée par l'app dans AUCUN profil : l'app enregistre la mémoire, pas les droits patrimoniaux (disclaimer `is_advisory` ; la dévolution étatique passe par le jugement d'hérédité — l'app peut générer un dossier récapitulatif PDF, forte valeur d'usage diaspora).
- **Fondement** : héritage indivis bamiléké — l'héritier unique reprend nom, titre, concession, veuves et culte des ancêtres (Hurault 1962 ; Dongmo 1981 ; Warnier 1993) ; le droit civil camerounais prévoit au contraire un partage égalitaire : les deux régimes coexistent comme profils.
- **Statut** : 🆕 (l'existant est décoratif).
- **Portée** : configurable par profil ; la neutralité patrimoniale est universelle.

**RM-48 — Transmission validée par le CONSEIL DE FAMILLE (quorum configurable) ; litiges : famille → chefferie → admin.**
- **Énoncé** : remplacer le texte décoratif « la transmission demande la validation de 2 témoins du clan » (institution introuvable — la vraie est le conseil de famille/les notables) par un workflow réel : proposition → validation par N membres qualifiés (N configurable, défaut 2-3 : membres du conseil de famille, porteurs de titre/notables de la chefferie, chef sortant, doyen, oncle maternel chez les matrilinéaires) → transfert avec historique. Un statut DISPUTED route la résolution vers le conseil de famille, puis un référent chefferie s'il est enregistré, **l'admin plateforme n'étant qu'un ultime recours** (subsidiarité — le pattern existant `adminResolveDivorceDispute` saute l'échelon familial).
- **Fondement** : investiture collégiale partout (conseil des neuf notables/kamvu'u, assemblées duala, conseil de lignage beti) ; décret n° 77-245 (chefs désignés par les notables selon la coutume) ; conseil de famille du C. civ. reçu (art. 405 s.).
- **Statut** : 🔧 — `genealogy_right_panel.dart:1033-1187` (bouton « Transmettre le rôle » → `_soon()`, « 2 témoins » = texte).
- **Implication produit** : réutiliser le pattern accept/reject éprouvé (V33) ; tables `succession_validations`, `family_council_members` ; rôle `FAMILY_COUNCIL_MEMBER`.
- **Portée** : quorum et qualités configurables ; subsidiarité universelle.

**RM-49 — Ordre public : jamais d'exclusion des femmes et des filles — la préférence masculine coutumière est une information, jamais une contrainte.**
- **Énoncé** : le produit ne bloque jamais la désignation d'une fille/femme comme successeur ou cheffe ; si le profil coutumier exprime une préférence masculine, l'afficher comme information (« la coutume de cette lignée privilégie habituellement un fils ») sans validation bloquante ; **aucune option produit `MALE_ONLY` pour la succession patrimoniale, même configurable** (la configurabilité de RM-45 concerne la chefferie/désignation, pas l'exclusion patrimoniale). Test de non-régression : désignation féminine acceptée dans tous les profils (le tri actuel incluant les filles est le bon défaut — le préserver lors de la refonte).
- **Fondement** : Cour suprême CM, arrêt Zamcho Florence Lum c. Chibikom (n° 14/L, 04/02/1993) : coutume écartant les femmes de la succession contraire à la loi ; Constitution 1996 ; Maputo art. 21 ; non-discrimination UE (diaspora).
- **Statut** : ✅ par accident (tri mixte) — à verrouiller explicitement.
- **Portée** : universelle, NON configurable — c'est la limite d'ordre public de toute la configurabilité coutumière.

**RM-50 — Le successeur devient tuteur des mineurs ; la veuve devient cheffe de foyer par défaut.**
- **Énoncé** : à la confirmation de succession, PROPOSER la création de `guardianships` (GUARDIAN, CLAN_CHIEF si titre) du successeur vers les enfants mineurs du défunt, acceptation par l'autre parent vivant (workflow co-parent existant) ; au décès validé du chef de famille, SUGGÉRER la veuve (rang 1 en foyer polygame) comme cheffe du foyer et tutrice de ses enfants, sous validation du conseil (RM-48) — **jamais l'inverse : la veuve n'est jamais « transmise »** (RM-60).
- **Fondement** : l'héritier assume la charge des cadets (Hurault 1962) ; Maputo art. 20 (la veuve devient de plein droit tutrice de ses enfants) ; tutelle du conseil de famille (C. civ. reçu).
- **Statut** : 🆕 — cas d'usage exact de la table `guardianships` dormante.
- **Portée** : automatismes configurables ; la tutelle comme objet et le consentement sont universels.

**RM-51 — L'aînesse se déclare quand les dates manquent : `birth_order` explicite.**
- **Énoncé** : rang de naissance SAISISSABLE (par fratrie utérine ET par foyer), prioritaire sur la date de naissance pour tous les tris (aînesse RM-45, boîtes foyer) ; jumeaux ex æquo avec rang gémellaire déclaré (ne pas présumer). Le tri actuel « dates inconnues à la fin » DÉGRADE systématiquement les aînés réels des générations anciennes — inversion perverse de l'aînesse.
- **Fondement** : la mémoire orale connaît l'ordre des naissances sans connaître les dates (état civil généralisé seulement après ~1930-1950).
- **Statut** : 🔧 — `tree_layout_provider.dart:1048-1056`, `genealogy_right_panel.dart:1297-1304`.
- **Portée** : universelle.

**RM-52 — Non-successeurs (« cadets ») : aucune part automatique, mémoire égale.**
- **Énoncé** : aucune notion de « parts » pour les enfants non désignés (profil bamiléké) ; en revanche, égalité absolue de traitement généalogique (fiche, visibilité, liens). Documenter comme choix (javadoc normative type OR-1), pas comme manque.
- **Statut** : ✅ implicite — à documenter. **Portée** : universelle (neutralité patrimoniale).

**RM-53 — Les titres coutumiers sont des attributs de première classe, acquis par événement, jamais inférés.**
- **Énoncé** : table `person_titles` (personne, type, chefferie émettrice, date/événement d'attribution, prédécesseur, statut). Types de base : FO/FON (chef), MAFO (reine-mère), NKEM/KAM (notable), FONTE (sous-chef), TAGNI/MAGNI (parents de jumeaux, RM-20), SUCCESSEUR (héritier confirmé) + types libres par profil. Les pilules d'arbre (♛) lisent cette table. Le titre est public par nature (il se proclame), SAUF titres de sociétés fermées (RM-85).
- **Fondement** : société à titres (fo, mafo, kamvu'u, titres achetés/hérités — Tardits 1960 ; Notué & Triaca) ; les titres se transmettent avec la succession (RM-47) ; nomenclature variable (fo/fon/fə ; tagni/tagne/tanyi).
- **Statut** : 🆕 — pendant que `CLAN_CHIEF` dort en base, le front invente des chefs.
- **Portée** : mécanisme universel ; nomenclature par chefferie.

---

# 6. Décès, veuvage & mémoire des ancêtres

**RM-54 — La date de décès est la date RÉELLE du décès, jamais la date de validation admin.**
- **Énoncé** : `declareDeath` collecte une `declared_death_date` (approximative admise : année seule, cf. RM-56) ; `adminValidateDeath` VALIDE cette date et la pose, en journalisant séparément `validated_at`. Toute la ritualité (deuil, funérailles différées, commémorations) et toute la généalogie (âges, veuvage RM-34, successions, présomption de paternité RM-13) dépendent de la date réelle : l'écraser par la date de traitement est une corruption de la mémoire que l'app promet de garder.
- **Fondement** : RGPD art. 5(1)(d) (exactitude) ; convergence des trois experts.
- **Statut** : 🔧 — `DissolutionService.adminValidateDeath:227-264` (death_date = jour de validation).
- **Portée** : universelle.

**RM-55 — Décès jamais auto-validé : conserver, mais validation par les AYANTS QUALITÉ familiaux d'abord.**
- **Énoncé** : conserver « jamais d'auto-validation, contestation possible par l'intéressé » (culturellement et juridiquement juste : annoncer à tort une mort est une offense grave, et le décès fait tomber les protections privacy — il doit rester le statut le plus difficile à établir). MAIS la validation doit pouvoir être portée par des ayants qualité FAMILIAUX (conjoint, enfants majeurs, chef de famille persisté RM-44, oncle maternel RM-22) avec quorum configurable, l'admin plateforme restant l'ultime recours en litige — un « admin » anonyme n'a aucune qualité coutumière pour dire la mort de quelqu'un.
- **Statut** : ✅ non-auto-validation (`DissolutionService:224`) · 🔧 validation admin unique et obligatoire.
- **Portée** : quorum configurable ; principe universel.

**RM-56 — Dates floues de première classe.**
- **Énoncé** : toutes les dates (naissance, décès, dot, unions, événements) portent une précision ∈ {EXACTE, MOIS, ANNÉE, CIRCA±n, INCONNUE} + champ libre « repère » (« avant l'indépendance », « l'année de la grande éclipse ») ; les tris et règles dégradent proprement au lieu de bloquer (le blocage actuel du workflow enfant sans date de naissance disparaît — RM-18). Une app de mémoire africaine qui exige des dates exactes exclut précisément les générations qu'elle veut sauver (état civil généralisé après ~1930-1950).
- **Statut** : 🔧 — dates strictes partout ; `requestChildModification:418-425`.
- **Portée** : universelle, NON configurable.

**RM-57 — DEATH_PENDING = juridiquement vivant : le PrivacyFilter continue de s'appliquer.**
- **Énoncé** : la levée du filtre privacy (« les décédés ne sont jamais filtrés ») ne se déclenche qu'après validation du décès (`death_validated`), jamais sur la simple déclaration — sinon, déclarer faussement quelqu'un mort devient un vecteur de doxxing familial. Verrouiller par un test d'intégration.
- **Fondement** : présomption de vie ; RGPD (la personne est vivante tant que le décès n'est pas établi).
- **Statut** : 🔧/à vérifier — critère exact du `PrivacyFilter` non précisé dans l'audit.
- **Portée** : universelle.

**RM-58 — Données d'un défunt : un workflow de demandes des proches.**
- **Énoncé** : les défunts étant hors RGPD (considérant 27) mais leurs données pouvant atteindre la vie privée des VIVANTS (cause de décès, filiation adultérine — RM-82), créer un workflow « demande des proches » : rectification/retrait de données d'un défunt par conjoint/descendants, arbitré par la modération ; en France, respecter les directives post-mortem si l'utilisateur défunt en avait déposé (loi Informatique et Libertés art. 84-86).
- **Statut** : 🆕 — la doctrine PrivacyFilter est bonne, le workflow manque.
- **Portée** : par juridiction ; le principe mémoriel (OR-3) est le positionnement produit assumé.

**RM-59 — Enterrement ≠ funérailles : deux événements ; le lieu d'inhumation est une ancre.**
- **Énoncé** : modéliser des `life_events` distincts : BURIAL (proche du décès) et FUNERAILLES (célébration différée, parfois des années après, souvent au village d'origine — événement social majeur, sortie des masques, « descente » de la diaspora) ; ajouter `burial_place/burial_village` (lié à `person_villages`, rôle BURIAL — RM-05). La révélation de la désignation scellée (RM-46) se rattache à la sortie de deuil ; certains profils conditionnent la confirmation de titres à la tenue des funérailles. « Où est-il enterré ? » est la question généalogique cardinale, conforme à OR-2.
- **Fondement** : institution centrale des Grassfields (Pradelles de Latour 1991 ; Feldman-Savelsberg) ; dépend de RM-54 (date réelle d'abord).
- **Statut** : 🆕 — le modèle n'a que `death_date`.
- **Portée** : le différé est grassfields-configurable ; l'événementiel funéraire est quasi universel.

**RM-60 — Lévirat et sororat : unions successorales typées, CONSENTEMENT obligatoire, pater configurable.**
- **Énoncé** : types d'union `LEVIRATE` (veuve épousée par un frère/héritier du défunt) et `SORORATE` (sœur remplaçant l'épouse défunte) + lien `succeeds_union_id` vers l'union éteinte. À la confirmation de succession d'un homme marié, proposer pour chaque veuve un choix explicite **consenti par ELLE** : (a) union LEVIRATE avec le successeur (**jamais si le successeur est son fils biologique — interdit absolu**) ; (b) statut « veuve du lignage » (rattachée à la concession sans union conjugale — nouveaux statuts `WIDOWED_INHERITED`/`WIDOW_OF_LINEAGE`) ; (c) départ/liberté (question de dot éventuelle, RM-30). **Aucune option automatique.** Enfants nés ensuite : pater = défunt (lévirat classique) ou = successeur — les deux sont attestés, configurable (cf. RM-11). Le lévirat est l'exception licite à l'interdit d'affinité (RM-16). Sans lui, l'union successeur-veuve créerait de faux signaux de polygamie « ordinaire ».
- **Fondement** : l'héritier « hérite des veuves » hors sa propre mère (Hurault 1962 ; Pradelles de Latour 1991) ; institution en déclin mais omniprésente dans les générations à archiver ; droit : mariage forcé réprimé (C. pén. 2016 art. 356), Maputo art. 20(c) (la veuve se remarie avec la personne DE SON CHOIX).
- **Statut** : 🆕 — les statuts actuels (SINGLE/MARRIED/WIDOWED/DIVORCED) ne peuvent pas représenter cette institution.
- **Portée** : institution configurable par communauté ; le consentement est universel, NON négociable.

**RM-61 — Notification du décès élargie aux ayants qualité.**
- **Énoncé** : `notifyFamilyOfDeath` notifie : conjoint(s), enfants, parents (existant) + chef de famille/lignage persisté (RM-44), membres du conseil de famille (RM-48), oncle(s) maternel(s) (RM-22). Le « chef de famille » actuellement notifié = simplement les parents.
- **Statut** : 🔧 — `DissolutionService.notifyFamilyOfDeath:415-455` (:439-441).
- **Portée** : universelle dans le principe ; liste par profil.

**RM-62 — Modes de fin d'union enrichis ; la répudiation est un fait NON conforme ; J+30 = « déclaré », pas « confirmé ».**
- **Énoncé** : (a) `end_reason` + `REPUDIATION`, `CUSTOMARY_DISSOLUTION` ; sous-type `divorce_type ∈ {JUDICIAL (juridiction, date, référence), CUSTOMARY (conseil/tribunal coutumier), DECLARED (non vérifié)}` ; (b) la répudiation clôt l'union dans l'arbre (fait social réel) avec note « la répudiation n'est pas un mode légal de dissolution ; le lien civil subsiste jusqu'au divorce » — conséquence : une union CIVILE répudiée non divorcée COMPTE ENCORE pour la bigamie (flag `legally_still_bound`) ; (c) l'auto-validation du divorce à J+30 sans réponse (mécanisme J+0/J+10/J+30 conservé, il est bon) produit `divorce_type = DECLARED`, jamais une validation pleine — le silence ne vaut pas acquiescement en matière d'état des personnes.
- **Fondement** : divorce civil judiciaire ; juridictions traditionnelles (décret 69/DF/544) ; jurisprudence refusant effet à la répudiation ; Maputo art. 7.
- **Statut** : 🔧 — `MIG/V10:8`, `DissolutionService.processDissolutionReminders:304-360` (+ remplacer le `findAll()` en mémoire, non scalable).
- **Portée** : structure universelle ; modes reconnus par pays.

**RM-63 — La garde des crânes : charge du successeur, transférable, localisation JAMAIS publique.**
- **Énoncé** : attribut `skull_custody` sur le défunt : qui détient/garde le crâne (en général le successeur) et où (concession/chefferie — localisation restreinte au lignage, catégorie « sacré » RM-79) ; transfert proposé à la succession (RM-47) ; marqueur « crâne non prélevé / rituel non accompli » (fréquent en diaspora, source d'obligations rituelles).
- **Fondement** : culte des crânes bamiléké — crânes des ascendants conservés dans la concession sous la garde de l'héritier qui verse les libations ; un crâne non recueilli expose la famille à l'infortune (Pradelles de Latour 1991 ; Hurault 1962). C'est le cœur de la « mémoire familiale » que l'app revendique.
- **Statut** : 🆕. **Portée** : spécifiquement grassfields-configurable ; ne pas l'afficher pour les profils non concernés.

---

# 7. Noms & doublons

**RM-64 — L'homonymie rituelle est LÉGITIME : un homonyme intra-familial est un indice de NOMINATION, pas de doublon.**
- **Énoncé** : (a) la détection de doublons ne conclut JAMAIS sur (prénom+nom+genre) sans date discriminante quand les deux candidats sont dans la même famille à ≥ 1 génération d'écart — proposer au contraire un lien `named_after_person_id` (« nommé d'après ») ; (b) consigne IA : « un enfant portant le nom d'un grand-parent ou d'un aîné défunt est une pratique normale — ne fusionne jamais des homonymes de générations différentes ; utilise l'homonymie comme indice de lien grand-parental » ; (c) l'email reste le discriminant prioritaire (bon choix existant).
- **Fondement** : donner à l'enfant le nom d'un ascendant est un acte social central (l'enfant « ramène » l'ancêtre ; relation nommée **mbombo** chez les Beti-Bulu) : le même nom revient toutes les deux générations — c'est un PATRON, pas une erreur. Risque actuel : fusions destructrices par l'IA/anti-doublon.
- **Statut** : 🔧 — `GenealogyServiceImpl.findDuplicate:549-565`, `checkDuplicate:317-341` (nom+prénom+date+genre = anti-signal en intra-famille).
- **Portée** : universelle dans l'aire.

**RM-65 — Pas de « nom de famille » présumé : noms multiples typés, patronymie flottante, affichage NOM Prénom.**
- **Énoncé** : (a) ne jamais utiliser l'égalité de `lastName` comme signal de parenté ni son inégalité comme signal de non-parenté ; (b) table `person_names(type, valeur, ordre)` : nom de naissance, élément patronymique (souvent le nom PROPRE du père, changeant à chaque génération — un fils d'Atangana peut s'appeler Essomba Atangana, son fils Owona Essomba), nom d'éloge/ndap, prénom chrétien/musulman, nom d'usage administratif ; (c) affichage NOM Prénom par défaut (usage camerounais), configurable ; (d) indice IA : « le prénom du père devenu nom de l'enfant » est un indice de filiation.
- **Fondement** : le patronyme figé est une importation de l'état civil moderne ; préfixe **Ngo** (« fille de ») + nom du père chez les Bassa (Lemb & de Gastines 1973) ; le ndap identifie la lignée mieux qu'un patronyme.
- **Statut** : 🔧 détection doublons/IA · 🆕 noms typés (modèle actuel = firstName/lastName plat).
- **Portée** : principe universel ; usages par communauté.

**RM-66 — Noms de circonstance : indices généalogiques, jamais des contraintes.**
- **Énoncé** : dictionnaire d'indices IA (pas de contraintes) pour les noms liés aux circonstances de naissance : jumeaux et suivants de jumeaux (RM-20), enfants nés après des décès, naissance par le siège, etc. — ces noms encodent rang et gémellité.
- **Statut** : 🆕. **Portée** : lexiques par communauté.

**RM-67 — Fratries typées : conserver, et refléter la primauté utérine dans les libellés.**
- **Énoncé** : le typage automatique FULL / HALF_PATERNAL / HALF_MATERNAL / STEP (trigger V13) est une excellente base : le conserver. Dans les libellés (RM-68), refléter que les demi-frères UTÉRINS (même mère) sont partout « plus frères » que les consanguins ; jamais de hiérarchie de dignité affichée.
- **Statut** : ✅ `GenealogyServiceImpl.getSiblingsWithType:1024-1085`, `MIG/V13` — à compléter côté libellés.
- **Portée** : universelle.

**RM-68 — Terminologie de parenté CLASSIFICATOIRE : table de rendu par communauté/langue.**
- **Énoncé** : le rendu d'un chemin de parenté (Griot, panneau relations) passe par une table `kinship_terms(communauté/langue, motif de chemin normalisé F/FB/MZ/MB/FBS…, terme, notes)` : frère du père → « père » (petit-père/grand-père selon l'aînesse) ; sœur de la mère → « mère » ; co-épouse de la mère → « mère » ; enfants des « pères » et « mères » → « frères/sœurs » (cousins parallèles) ; oncle MATERNEL → terme spécifique, jamais assimilé au père ; cousins croisés → termes propres. Le terme français générique reste en sous-titre ; fallback français.
- **Fondement** : toutes les terminologies de l'aire sont classificatoires (Radcliffe-Brown & Forde 1950) : dire « cousin » à un Beti pour le fils du frère de son père est une erreur de traduction — c'est son frère ; un moteur qui rend « oncle » indistinctement efface la structure même de la parenté.
- **Statut** : 🆕 — moteur de chemin Neo4j → motif → lookup ; lexiques prioritaires : ewondo, duala, basaa, fe'efe'e/ghomala, lingala/kikongo.
- **Portée** : par langue/communauté.

---

# 8. Droit civil & diaspora

**RM-69 — LE chantier prioritaire : remplacer « droit applicable = résidence » par le triptyque célébration / loi personnelle / for de reconnaissance.**
- **Énoncé** : la règle actuelle (pays fourni, sinon résidence du mari, sinon de la femme) est juridiquement fausse pour la validité. Modèle cible :
  - Union : `celebration_country`, `celebration_date`, `union_form` ; Personne : `nationalities[]` (loi personnelle) + `residence_country` (existant).
  - **ÉTAPE 1 — VALIDITÉ** (évaluée UNE FOIS, à la date de célébration, immuable) : forme selon le pays de célébration (*lex loci celebrationis*) ; fond (capacité, monogamie/option) selon la loi personnelle de CHAQUE époux → `validity ∈ {VALID, VOID_WHERE_CELEBRATED, UNKNOWN}`.
  - **ÉTAPE 2 — RECONNAISSANCE** (recalculable) : pour chaque for pertinent (résidences, autres nationalités) → `union_recognition(union_id, forum_country, status ∈ {RECOGNIZED, RECOGNIZED_LIMITED_EFFECTS, NOT_RECOGNIZED}, note)`.
  - Supprimer l'asymétrie « résidence du mari d'abord » (décalque patrilinéaire non dit) : célébration si connue, sinon résidence COMMUNE, sinon demander. `legal_country` devient un alias déprécié.
- **Fondement** : C. civ. fr. art. 202-1/202-2 ; jurisprudence Rivière (1953), Chemouni (1958), Bendeddouche (1980) ; Code DIP belge 2004 art. 21, 46 ; UK Matrimonial Causes Act 1973 s.11. Un mariage polygamique valablement célébré au Cameroun n'est pas « NON_COMPLIANT » parce que le mari habite Paris.
- **Statut** : 🔧 — `GenealogyServiceImpl.createUnion:598-600` (firstNonBlank résidence mari), `MIG/V39` (colonne unique `legal_country`).
- **Portée** : universelle (DIP standard).

**RM-70 — Temporalité du droit : la conformité s'évalue selon la loi en vigueur À LA DATE de célébration.**
- **Énoncé** : `country_marriage_rules` reçoit `valid_from`/`valid_to` (PK (iso2, valid_from)) ; l'évaluation prend la ligne couvrant `celebration_date` ; union sans date → UNKNOWN ; unions antérieures à l'indépendance → `HISTORICAL_CUSTOMARY` (toujours conforme). Exemple décisif : la Côte d'Ivoire n'interdit la polygamie que depuis la loi n° 64-375 du 07/10/1964 (avec dispositions transitoires) — le mariage polygame du grand-père ivoirien de 1958 est licite, l'app actuelle le marquerait NON_COMPLIANT. Appliquer l'ordonnance de 1981 à l'union des arrière-grands-parents est un anachronisme juridique pur.
- **Statut** : 🔧 — aucune dimension temporelle dans V40 ; évaluation intemporelle (`ComplianceService.evaluate`).
- **Portée** : universelle (non-rétroactivité, C. civ. art. 2).

**RM-71 — Pays FORBIDDEN ≠ néant juridique : reconnaissance à effets atténués.**
- **Énoncé** : une union polygamique VALIDE au lieu de célébration, dont un époux réside dans un pays FORBIDDEN → `RECOGNIZED_LIMITED_EFFECTS` avec note type : « Union valable au lieu de célébration. En France, non transcriptible, n'ouvre pas le regroupement familial pour une épouse supplémentaire, mais peut produire des effets alimentaires et successoraux (ordre public atténué). » Exception Baaziz : si le premier mariage relève de la loi du for (épouse française), ordre public plein → NOT_RECOGNIZED.
- **Fondement** : Chemouni 1958 (aliments), Bendeddouche 1980 (succession), Baaziz 1988 ; CESEDA.
- **Statut** : 🔧 — R1.3/R1.4 assimilent résidence FORBIDDEN à non-conformité.
- **Portée** : principe universel ; notes par pays.

**RM-72 — Restreindre le SEUL rejet dur (HTTP 400) à l'impossibilité matérielle de l'acte.**
- **Énoncé** : rejeter UNIQUEMENT : « union de forme CIVILE dont le pays de CÉLÉBRATION est FORBIDDEN à la date de célébration, alors qu'une union civile du même époux y est active » — un officier d'état civil français ne peut pas avoir célébré ce mariage, l'acte n'existe pas ; proposer la requalification (Coutumier / De fait) dans le message. **Tout scénario fondé sur la résidence ne bloque jamais** (cohérence avec OR-1). Second rejet dur admis : noyau d'inceste en déclaratif civil contemporain (RM-15).
- **Fondement** : C. civ. fr. art. 147, C. pén. fr. 433-20.
- **Statut** : 🔧 — `ComplianceService.mustHardReject:140-146` teste le mauvais pays (résidence via R1.5) avec une heuristique textuelle à remplacer (RM-24).
- **Portée** : universelle.

**RM-73 — Réévaluation sur événement + invalidation du cache référentiel.**
- **Énoncé** : recalculer `union_recognition` (jamais `validity`, acquise une fois pour toutes) quand : la résidence d'un époux change, une union du foyer se dissout, le référentiel est mis à jour. Cache `ComplianceService` : TTL ou éviction sur écriture (aujourd'hui : redémarrage requis). Listeners (`UnionDissolvedEvent`, `PersonResidenceChangedEvent`) + endpoint admin `POST /compliance/reevaluate`.
- **Statut** : 🔧 — évaluation unique à la création (`GenealogyServiceImpl:654-655`) ; cache jamais invalidé (`ComplianceService:34,57-62`).
- **Portée** : universelle.

**RM-74 — Qualifier le MÉCANISME de polygamie par pays, pas seulement ALLOWED/CONDITIONAL/FORBIDDEN.**
- **Énoncé** : colonnes `polygamy_mechanism ∈ {OPTION_DECLARATION, PLURAL_SYSTEM, ISLAMIC_LAW, FORBIDDEN}` et `max_wives INT NULL`. CM/GA/CG/TG : option déclarée ; SN : option triple (monogamie / limitation / polygamie ≤ 4, CF 1972 art. 133) ; ML : plafond 4 (CPF 2011) ; **NG : le message actuel « option déclarée à l'état civil » est FAUX** — c'est le TYPE de mariage qui décide (Marriage Act = monogame ; customary/islamique = polygame) ; NE/TD : statut personnel coutumier/musulman. Messages templatés par mécanisme + warning advisory « 5e épouse » si `max_wives` atteint.
- **Statut** : 🔧 — messages CONDITIONAL uniformes (`ComplianceService:114-117`) inadaptés à NG/NE/TD ; plafond 4 nulle part contrôlé (V40).
- **Portée** : par pays (c'est l'objet même du référentiel).

**RM-75 — Corriger la terminologie « régime matrimonial ».**
- **Énoncé** : en droit, le « régime matrimonial » désigne le régime des BIENS (séparation/communauté, lui aussi déclaré à la célébration au CM, art. 49) — pas monogamie/polygamie. Renommer `marital_regime` → `union_form` (RM-24) / `marriage_option` (RM-37) ; ajouter un champ optionnel `property_regime ∈ {SEPARATION, COMMUNITY, UNKNOWN}` (utile au futur module succession).
- **Statut** : 🔧 — terminologie V39/R8.3. **Portée** : universelle.

**RM-76 — Le référentiel pays reste advisory ; pays inconnu → UNKNOWN, jamais un blocage.**
- **Énoncé** : conserver `is_advisory=TRUE` (« information indicative, pas un avis juridique »), le fallback `UNKNOWN` pour pays absent, la tolérance ISO-2/ISO-3 (à assainir côté front) ; étendre le seed au-delà des 18 pays au fil des besoins, avec base légale citée par ligne.
- **Statut** : ✅ `MIG/V40:18-85`, `GenealogyServiceImpl.getMarriageRule:1249-1255` — doctrine validée par les trois experts.
- **Portée** : par pays.

---

# 9. Confidentialité & sacré

**RM-77 — Clan, totem, langue, village/pays d'ORIGINE = données révélant l'origine ethnique (RGPD art. 9) : masquage par défaut pour toute personne VIVANTE, à tous les niveaux de visibilité.**
- **Énoncé** : pour une personne vivante : clan(s), totem, langue maternelle, `origin_village/city/region/country` ne sont visibles hors du cercle familial QUE sur consentement explicite (`ethnic_data_consent`, horodaté, révocable) — y compris en visibilité PUBLIC (aujourd'hui PUBLIC ne masque que contacts/profession/religion : clan et langue passent, et `origin_*`/`residence_*` sont absents du masquage — deux failles : le village d'origine révèle le lignage, donc ré-identifie). Les DÉFUNTS restent non filtrés pour l'ossature (OR-3), sous réserve RM-79.
- **Fondement** : RGPD art. 9(1) (clan/langue = proxys directs de l'origine ethnique) ; loi camerounaise n° 2024/017 du 23/12/2024 (protection des données) ; Convention de Malabo (UA, en vigueur 2023).
- **Statut** : 🔧 — `PrivacyFilter.java:193-225` (compléter `maskContacts`/`anonymize`).
- **Portée** : universelle (standards art. 9 = Malabo = loi CM 2024).

**RM-78 — La « famille » du PrivacyFilter est lignagère, pas seulement métrique.**
- **Énoncé** : au BFS ≤ 3 degrés (le « 3 » devient un paramètre, défaut prudent conservé), ajouter deux cercles configurables : (a) co-membres du même lignage/clan (simple jointure, moins chère que le BFS — logique déjà admise pour le village dans MEMBERS_ONLY) ; (b) lignage maternel direct (RM-22). Un membre du lignage à 5-6 degrés est « famille » au sens bantou ; borner à 3 degrés est une projection du modèle nucléaire occidental.
- **Statut** : 🔧 — degré 3 en dur (`PrivacyFilter.java:97-115`).
- **Portée** : rayon et cercles configurables ; mécanisme universel.

**RM-79 — Les champs SACRÉS/initiatiques restent restreints MÊME pour les défunts.**
- **Énoncé** : conserver OR-3 pour l'état civil généalogique (noms, dates, filiations, unions, villages), mais créer une catégorie de champs « sacrés » orthogonale à l'axe vivant/décédé : totem, garde et localisation des crânes (RM-63), affiliations initiatiques (RM-85), désignation successorale scellée (RM-46), détails rituels — filtrée pour TOUT non-membre du lignage, y compris post-mortem ; whitelist explicite des champs partagés post-mortem.
- **Fondement** : le savoir totémique et rituel est un savoir lignager fermé (révéler le totem d'autrui ou l'emplacement des crânes est une transgression dangereuse — croyances de sorcellerie associées) ; RGPD art. 9 pour la diaspora (assimilable aux convictions religieuses). Le totem d'un défunt est aujourd'hui exposé à tous.
- **Statut** : 🔧 — `PrivacyFilter.java:24-47` (exemption totale des décédés).
- **Portée** : mécanisme universel ; liste des champs sacrés par profil.

**RM-80 — La mémoire généalogique des défunts est un bien commun lignager : principe à conserver.**
- **Énoncé** : maintenir la non-anonymisation des défunts pour les faits généalogiques — les ancêtres appartiennent à toute la descendance (funérailles, ndap, généalogies récitées) ; hors RGPD (considérant 27). Compléter par le workflow proches (RM-58) et l'exception sacrée (RM-79). Rappel : la levée du filtre exige un décès VALIDÉ (RM-57).
- **Statut** : ✅ `PrivacyFilter.java:24-47` — validé par les trois experts.
- **Portée** : universelle.

**RM-81 — Le sensible successoral et matrimonial n'est jamais public.**
- **Énoncé** : le panneau « GESTION DU FOYER » (ordre d'aînesse, désignations, statut de dot) n'est visible que du cercle familial restreint (RM-78) ; une désignation scellée n'est visible de personne du vivant du titulaire (RM-46) ; appliquer AUSSI en interne la doctrine ADR-002 « jamais le montant ni les témoins ».
- **Fondement** : dot et rang d'épouses sont des affaires de familles, sources de conflits si exposées.
- **Statut** : 🔧 — le panneau actuel s'affiche selon la seule logique d'arbre (`genealogy_right_panel.dart:1033-1187`).
- **Portée** : universelle dans le principe.

**RM-82 — Filiations non confirmées ou adultérines de personnes vivantes : visibles des seules parties.**
- **Énoncé** : un lien de filiation impliquant une personne vivante et NON confirmé (workflow co-parent pending, suggestion IA acceptée d'un seul côté, père « déclaré » unilatéralement) n'est visible QUE des parties (enfant, parents déclarés, déclarant) — jamais dans l'arbre public, le feed, la recherche ni les exports. Publier qu'un homme marié est le père biologique d'un enfant hors mariage expose l'app et le déclarant (vie privée, diffamation). Statut `CONFIRMED/DECLARED/PENDING` sur `parent_child` + filtre dans `PrivacyFilter.filterTree` et le feed.
- **Fondement** : caractère strictement personnel des actions en filiation ; art. 9 RGPD par ricochet ; Ord. 81-02 art. 41.
- **Statut** : 🆕 — le consentement est géré (V33), pas la VISIBILITÉ pendant/à défaut de confirmation.
- **Portée** : universelle.

**RM-83 — Personnes vivantes sans compte : information, opposition, effacement par « pierre tombale ».**
- **Énoncé** : (a) fiche vivante créée avec email/téléphone → notification automatique à l'intéressé (« vous figurez dans l'arbre de X ; voir / limiter / contester ») — le système d'invitations 30 jours existant est le bon véhicule ; sans coordonnées, documenter l'exemption pour effort disproportionné ; (b) droit d'opposition : visibilité minimale sur demande ; (c) droit à l'effacement : dépersonnalisation en conservant la topologie — nœud « personne retirée à sa demande » (sexe et liens conservés ; identifiants, dates, photo, clan supprimés) : arbitrage standard du secteur entre l'art. 17 et le droit des autres membres à documenter leur ascendance.
- **Fondement** : RGPD art. 6(1)(f), 14, 17, 21 ; l'exemption domestique ne s'applique PAS à une plateforme (CJUE Lindqvist C-101/01, Ryneš C-212/13) ; le défaut FAMILY_ONLY existant est une vraie circonstance atténuante (minimisation).
- **Statut** : 🆕 — statut `TOMBSTONED`, endpoint de demande, registre.
- **Portée** : universelle (UE + loi CM 2024 convergent) ; délais par juridiction.

**RM-84 — Droits sur les fiches : conserver, et journaliser.**
- **Énoncé** : conserver : modifier = créateur OU la personne elle-même ; supprimer = créateur ; une fiche personne max par compte. Compléter par les autorisations manquantes (RM-31) et le journal des modifications sensibles (qui, quand).
- **Statut** : ✅ `GenealogyServiceImpl.updatePerson:92-95`, `deletePerson:160-164`, `MIG/V21:5-8` · 🔧 journalisation.
- **Portée** : universelle.

**RM-85 — Sociétés coutumières (la'akam, kuosi, kamvu'u…) : affiliations à visibilité restreinte.**
- **Énoncé** : table `customary_societies` (nom, chefferie, type) + adhésions datées ; visibilité par défaut : membres de la même société et lignage proche uniquement, JAMAIS publiable — l'appartenance au la'akam (initiation du chef) est particulièrement sensible ; catégorie « sacré » (RM-79), y compris post-mortem ; RGPD art. 9 pour la diaspora (cohérent ADR-002).
- **Fondement** : sociétés initiatiques partiellement secrètes (la'akam, kuosi de Bandjoun, conseil des neuf) — en parler hors cadre est une transgression (Tardits 1960 ; Harter).
- **Statut** : 🆕. **Portée** : liste par chefferie ; restriction de visibilité universelle.

**RM-86 — API partenaire de vérification : maintenir le gel, ajouter deux verrous.**
- **Énoncé** : conserver la décision ADR-002 (aucun endpoint sans partenaire réel ; réponses booléennes « vérifié/non vérifié », jamais de données brutes ; vivants sans consentement → INSUFFICIENT_CONSENT ; dot vérifiable en booléen strict, jamais montant ni témoins). Ajouter dès la conception : (a) **aucune donnée art. 9 ne transite JAMAIS, même en booléen quand la question elle-même est sensible** (« est-il du clan X ? » = donnée ethnique — liste noire de prédicats) ; (b) référencer la loi CM n° 2024/017 + Malabo en plus du RGPD.
- **Statut** : ✅ fondation (`docs/ADR-002-web-services-verification.md`) — enrichir l'ADR.
- **Portée** : universelle.

**RM-87 — Injecter la coutume dans l'IA de suggestion ; la revue humaine reste obligatoire.**
- **Énoncé** : conserver : score de confiance, seuil 0.3, expiration 90 jours, PENDING → validation humaine, matérialisation non bloquante. Enrichir prompt et post-filtrage : (a) dévaloriser fortement toute suggestion WIFE/HUSBAND entre porteurs du même lignage/ndap (exogamie RM-14) — l'IA sait « un homme peut avoir plusieurs épouses » mais ignore l'interdit symétrique le plus discriminant ; (b) utiliser ndap, chefferie, titres, gémellité et homonymie (RM-64) comme indices positifs ; (c) ne JAMAIS fusionner des homonymes de générations différentes ; (d) pour les suggestions d'union, préférer le type coutumier avec dot inconnue plutôt que CUSTOMARY sec ; (e) une suggestion de filiation acceptée d'un seul côté reste non publique (RM-82).
- **Statut** : ✅ garde-fous existants (`GenealogyAiService.java:49-53,152-153,167`) · 🔧 enrichissement culturel du prompt et du filtre.
- **Portée** : consignes coutumières via le profil (RM-07).

---

# Contradictions entre experts : arbitrages rendus

| # | Divergence | Arbitrage |
|---|---|---|
| 1 | **Blocage dur de l'inceste** : expert bantou = refus dur du noyau nucléaire partout ; expert droit = warning seulement, jamais de blocage | Tranché (RM-15) : refus dur limité à la **création déclarative d'une union CIVILE contemporaine** ; unions historiques/coutumières toujours enregistrables avec warning fort — cohérent OR-1 et RM-72 |
| 2 | **Rang d'épouse après dissolution** : expert bantou = « recalculer l'affichage » ; experts bamiléké + droit = immuable | Tranché (RM-41) : **rang immuable**, éditable seulement pour corriger une saisie ; libellés d'affichage contextuels |
| 3 | **Rejet dur polygamie** : expert bamiléké conserve un refus type R1.4 (résidence) ; expert droit le déplace sur le pays de CÉLÉBRATION | Tranché (RM-72) : le droit l'emporte — la résidence ne bloque jamais ; l'ancien cas R1.4 devient NON_COMPLIANT + reconnaissance limitée (RM-71) |
| 4 | **Décompte des unions HISTORICAL non confirmées dans la polygamie** | Tranché (RM-26) : elles COMPTENT (le fait prime), recommandation de l'expert droit suivie |
| 5 | **Seuil « moins de 4 ans »** : l'expert bamiléké le signale en dur sans le remplacer ; l'expert droit propose la revendication de fiche | Tranché (RM-18) : revendication de fiche + plancher d'âge pays |
| 6 | **Exogamie même clan** : interdit fort (bantou/bamiléké) vs mariage entre cousins préféré (Peuls, droit musulman) | Tranché (RM-14) : sévérité par profil (RM-07), défaut global = information neutre, jamais d'interdit global |
| 7 | **Succession par défaut** : primogéniture beti « à peu près juste » vs désignation bamiléké vs neveu utérin | Tranché (RM-45) : AUCUN affichage prédictif sans profil choisi ; l'aînesse redevient une information (« ordre d'aînesse ») |

# Règles existantes qui contredisent coutume ou droit (récapitulatif consolidé, par gravité)

1. « ORDRE DE SUCCESSION » = top-3 par date de naissance (→ RM-45, RM-46, RM-51) — contradiction culturelle n° 1.
2. « CHEF DE FAMILLE » = homme + ≥ 2 unions (→ RM-44) — contresens n° 2.
3. Rejet dur et conformité fondés sur la RÉSIDENCE, au référentiel d'AUJOURD'HUI (→ RM-69 à RM-73).
4. 2e union civile d'une FEMME = simple WARNING « option de polygamie » (→ RM-40).
5. `death_date` = date de validation admin (→ RM-54).
6. Type « DOT » coché ⇒ dot payée ; dot booléenne sans récipiendaire ; `updateDotStatus`/`endUnion` sans autorisation (→ RM-27, RM-29, RM-31).
7. Dot sans effet modélisé sur l'affiliation lignagère des enfants ; enfant hors union rattaché « à défaut » à une union active (→ RM-11, RM-13).
8. Message « option de polygamie à vérifier » inversant la présomption camerounaise (→ RM-38) ; messages faux pour NG/NE/TD (→ RM-74).
9. Garde `husband MALE` rendant V42 inopérante ; « résidence du mari d'abord » (→ RM-25, RM-69).
10. Doublon conclu sur prénom+nom+date+genre — anti-signal en intra-famille (→ RM-64).
11. Aucun contrôle d'exogamie/parenté entre conjoints (→ RM-14, RM-15).
12. Totem des défunts public ; clan/langue/origine visibles en PUBLIC pour des vivants ; `origin_*` absents de l'anonymisation (→ RM-77, RM-79).
13. Villages validés par « n'importe quel ancêtre », validation sautée en silence si Neo4j down, absente à la création (→ RM-05).
14. Unions de défunts bloquées en PENDING_APPROVAL à vie (→ RM-26).
15. Seuil « 4 ans » sans fondement + blocage si date de naissance absente (→ RM-18, RM-56).
16. Tri « dates inconnues à la fin » rétrogradant les aînés réels (→ RM-51, RM-56).
17. « 2 témoins du clan » : institution inventée ; litiges tranchés par l'admin sans échelon familial (→ RM-48).
18. **Contre-exemple à préserver** : rang d'épouse jamais recompacté après dissolution — classé « limite » par l'audit, en réalité culturellement CORRECT (→ RM-41).

---

# TOP 10 des règles à implémenter en premier (impact culturel × simplicité)

| # | Règle(s) | Action concrète | Coût |
|---|---|---|---|
| 1 | RM-45 + RM-44 | Renommer « ORDRE DE SUCCESSION » → « ordre d'aînesse (informatif) » et supprimer l'inférence chef = polygame (badge « suggéré » en attendant les rôles persistés) — corrige les 2 contresens les plus visibles, front uniquement | Très faible |
| 2 | RM-54 | `declared_death_date` saisie dans `declareDeath`, validée (pas remplacée) par l'admin | Faible |
| 3 | RM-27 (partiel) | Supprimer le forçage UI « type DOT ⇒ dot payée » (`add_union_dialog.dart:312-313`) | Trivial |
| 4 | RM-31 | Contrôles d'autorisation sur `updateDotStatus` et `endUnion` | Faible |
| 5 | RM-40 | Branche d'évaluation dédiée bigamie féminine/polyandrie dans `ComplianceService` + message propre | Faible |
| 6 | RM-38 | Corriger le message CONDITIONAL camerounais (présomption de polygamie, art. 49) | Trivial |
| 7 | RM-72 | Restreindre `mustHardReject` au pays de CÉLÉBRATION + forme CIVILE (première brique de RM-69) | Moyen |
| 8 | RM-77 (+ RM-57) | PrivacyFilter : masquer clan/totem/langue/`origin_*`/`residence_*` des vivants à tous niveaux ; levée du filtre sur décès VALIDÉ seulement | Moyen |
| 9 | RM-64 | Neutraliser le faux-doublon intra-familial + consigne IA anti-fusion d'homonymes (risque de fusions destructrices) | Faible |
| 10 | RM-26 | Mode `HISTORICAL` pour les unions dont les parties sont décédées/sans compte (débloque 80 % du corpus généalogique) | Moyen |

**Fondations à lancer en parallèle (P1)** : RM-07 (profils coutumiers `community_rules` — dérisque tout le configurable), RM-03 (lignages/ndap), RM-02 (`descent_system`), RM-70 (référentiel versionné), RM-04 (chefferies), RM-14/15 (exogamie/inceste), RM-11 (affiliation par la dot), RM-79 (champs sacrés), RM-24/25 (refonte unions).

---

# Sources principales

**Anthropologie/histoire** : J. Hurault, *La structure sociale des Bamiléké* (1962) ; C. Tardits, *Les Bamiléké de l'Ouest-Cameroun* (1960) et *Le Royaume Bamoum* (1980) ; C.-H. Pradelles de Latour, *Ethnopsychanalyse en pays bamiléké* (1991) ; R. Brain, *Bangwa Kinship and Marriage* (1972) ; P. Feldman-Savelsberg, *Plundered Kitchens, Empty Wombs* (1999) ; P. Laburthe-Tolra, *Les Seigneurs de la forêt* (1981) ; H. Ngoa, *Le mariage chez les Ewondo* (1968) ; Radcliffe-Brown & Forde (dir.), *African Systems of Kinship and Marriage* (1950) ; G. Balandier (1955) ; J.-C. Dongmo, *Le dynamisme bamiléké* (1981) ; J.-P. Warnier (1993) ; W. MacGaffey ; Austen & Derrick (1999) ; Lemb & de Gastines, *Dictionnaire basaá-français* (1973).

**Droit** : Ordonnance camerounaise n° 81-02 du 29/06/1981 (art. 41, 49, 52, 64, 70, 81) ; C. pén. camerounais 2016 (art. 347-1, 356, 359) ; décret n° 77-245 (chefferies) ; décret n° 69/DF/544 (juridictions traditionnelles) ; Cour suprême CM, arrêt Zamcho (n° 14/L, 04/02/1993) ; loi CM n° 2024/017 (données personnelles) ; C. civ. fr. (art. 147, 161-164, 202-1/202-2, 228, 311-312) ; jurisprudence fr. Rivière, Chemouni, Bendeddouche, Baaziz ; Code DIP belge 2004 ; UK Matrimonial Causes Act 1973 ; Sénégal CF 1972 (art. 133) ; Mali CPF 2011 ; Côte d'Ivoire lois du 07/10/1964 ; Gabon loi du 31/05/1963 ; Congo CF 1984 ; RDC CF 1987 (art. 361) ; Protocole de Maputo (art. 6, 7, 20, 21) ; CEDEF ; CDE ; RGPD (art. 5, 6, 8, 9, 14, 17, 21, considérant 27) ; Convention de Malabo ; CJUE Lindqvist C-101/01, Ryneš C-212/13.

*Toute règle configurable doit être validée avec des dépositaires de la coutume de chaque chefferie/communauté cible avant activation par défaut dans un profil.*
