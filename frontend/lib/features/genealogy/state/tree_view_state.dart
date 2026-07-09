import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gwangmeu/features/genealogy/models/person_genealogy.dart';

// ── Enum types ──────────────────────────────────────────────

enum TreeView { full, ancestors, descendants, migration }

/// Mode d'affichage mobile de la lignée (#1d) : rivière, arbre ou liste.
enum RiverMode { river, tree, list }

enum RightTab { personne, migration, ia }

/// Couleur par lignée, plus par genre (« Tissage » #1d/#2c) :
/// - [primaryLineage] : lignée du sujet (or)
/// - [secondaryLineage] : lignée alliée, ex. maternelle (rose cuivré)
/// - [ancestor] : ancêtre disparu — bordure discrète + « ✦ », jamais de noir
/// - [spouse] : conjoint·e (lignée alliée, rose)
enum NodeType {
  subject,
  primaryLineage,
  secondaryLineage,
  ancestor,
  aiSuggestion,
  founder,
  spouse,
}

/// - [foyerDrop] : descente POINTILLÉE épouse → boîte foyer (maquette 2a),
///   rendue dans la couleur du foyer (or / rose / vert).
enum LinkType { filiation, union, siblings, aiSuggestion, foyerDrop }

/// Conformité d'une union au droit civil du pays de résidence.
/// Jamais de « légitimité » : rendu en ton sage/ember doux, aucune croix rouge.
enum UnionCompliance { compliant, warning, nonCompliant, unknown }

UnionCompliance unionComplianceFromStatus(String? status) {
  switch (status) {
    case 'COMPLIANT':
      return UnionCompliance.compliant;
    case 'WARNING':
      return UnionCompliance.warning;
    case 'NON_COMPLIANT':
      return UnionCompliance.nonCompliant;
    default:
      return UnionCompliance.unknown;
  }
}

// ── Layout models ───────────────────────────────────────────

/// Métadonnées d'union portées par un nœud conjoint (badges rang / dot / régime).
class NodeUnionInfo {
  final String unionId;

  /// Rang de l'union (1 = 1re, 2 = 2e…), dérivé de unionOrder.
  final int rank;

  /// Union polygame déclarée (≥ 2 conjoints actifs).
  final bool isPolygamous;

  /// Union active (non terminée).
  final bool isActive;

  /// Régime légal déclaré (CIVIL, CUSTOMARY…), affiché en méta discret.
  final String? legalRegime;

  final UnionCompliance compliance;

  const NodeUnionInfo({
    required this.unionId,
    required this.rank,
    required this.isPolygamous,
    required this.isActive,
    this.legalRegime,
    this.compliance = UnionCompliance.unknown,
  });
}

class LayoutNode {
  final PersonGenealogy person;
  final Offset position;
  final int generation;
  final NodeType type;
  final bool hasDotPaid;
  final bool isSubject;

  /// Renseigné pour un conjoint : rang de l'union, régime, conformité, dot.
  /// Alimente les badges discrets (mono) du nœud.
  final NodeUnionInfo? unionInfo;

  /// Mari d'un groupe « foyers » (maquette 2a) : carte or pâle, bordure or,
  /// pilule brune « ♛ CHEF DE FAMILLE » sous le nom.
  final bool isChief;

  /// Enfant EMPILÉ à l'intérieur d'une boîte foyer : rendu mini-carte
  /// (badge initiales 28 px + nom 13 px), pas de carte standard.
  final bool inFoyerBox;

  /// Couleur du foyer (or / rose / vert / azure, cycle) : bordure de la carte
  /// conjoint, teinte des enfants du foyer. Null si union unique.
  final Color? foyerColor;

  /// Épouse d'un GROUPE FOYERS (maquette 2a) : pilule « ÉPOUSE N ».
  /// Un conjoint coloré HORS mode foyers (maquette 6a) porte « {N}E UNION ».
  final bool isFoyerWife;

  const LayoutNode({
    required this.person,
    required this.position,
    required this.generation,
    required this.type,
    this.hasDotPaid = false,
    this.isSubject = false,
    this.unionInfo,
    this.isChief = false,
    this.inFoyerBox = false,
    this.foyerColor,
    this.isFoyerWife = false,
  });
}

class LayoutLink {
  final Offset from;
  final Offset to;
  final LinkType type;
  final bool highlight;

  /// Couleur de lignée du lien (or Mbopda, rose Ngo Bassa…).
  /// Null → couleur neutre du painter.
  final Color? color;

  /// Union terminée (isActive=false) : le lien se rend en trait atténué.
  final bool ended;

  const LayoutLink({
    required this.from,
    required this.to,
    required this.type,
    this.highlight = false,
    this.color,
    this.ended = false,
  });
}

/// Pilule-étiquette mono posée au MILIEU du connecteur mari↔épouse
/// (maquette 2a — foyers polygames) : « 1RE UNION · 1968 », bordée de la
/// couleur du foyer.
class UnionBadge {
  /// Milieu du connecteur mari↔épouse (coordonnées contenu, comme les nœuds).
  final Offset position;

  /// Ex. « 1RE UNION · 1968 » (année de startDate si connue, sinon sans année).
  final String label;

  /// Couleur du foyer : rang 1 → or, 2 → rose, 3 → vert (cycle modulo).
  final Color color;

  /// Union terminée : rendu atténué (jamais barré).
  final bool ended;

  const UnionBadge({
    required this.position,
    required this.label,
    required this.color,
    this.ended = false,
  });
}

/// Boîte EN POINTILLÉS ARRONDIS de la couleur du foyer, englobant les
/// mini-cartes des enfants d'une épouse (maquette 2a). En-tête mono
/// « FOYER MAAH · 3 ENFANTS » + point de couleur à droite.
class FoyerBox {
  /// Rect englobant les mini-cartes enfants (padding 12 px, en-tête 26 px).
  final Rect rect;

  /// Couleur du foyer (or / rose / vert, cycle).
  final Color color;

  /// Ex. « FOYER MAAH · 3 ENFANTS » (prénom de l'épouse en MAJUSCULES).
  final String label;

  final int childCount;

  const FoyerBox({
    required this.rect,
    required this.color,
    required this.label,
    required this.childCount,
  });
}

// ── View state ──────────────────────────────────────────────

/// Une étape du fil d'Ariane : personne devenue racine de l'arbre.
class FocusCrumb {
  final String personId;
  final String label; // « Prénom Nom » au moment du focus

  const FocusCrumb({required this.personId, required this.label});
}

class TreeViewState {
  final String? selectedPersonId;
  final TreeView currentView;
  final Set<int> hiddenGenerations;
  final RightTab rightTab;
  final String? hoveredPersonId;

  /// Personne actuellement racine de l'arbre (geste « centrer ici »).
  /// `null` = sujet par défaut (⌂ retour à moi).
  final String? focusPersonId;

  /// Pile des focus successifs pour le fil d'Ariane (nom cliquable).
  /// La dernière entrée correspond à [focusPersonId].
  final List<FocusCrumb> focusStack;

  /// Filtre « vue par foyer » (maquette 2c) : id de l'épouse dont le foyer
  /// reste seul visible en MODE FOYERS. `null` = tous les foyers.
  final String? foyerFilterWifeId;

  const TreeViewState({
    this.selectedPersonId,
    this.currentView = TreeView.full,
    this.hiddenGenerations = const {},
    this.rightTab = RightTab.personne,
    this.hoveredPersonId,
    this.focusPersonId,
    this.focusStack = const [],
    this.foyerFilterWifeId,
  });

  TreeViewState copyWith({
    String? selectedPersonId,
    TreeView? currentView,
    Set<int>? hiddenGenerations,
    RightTab? rightTab,
    String? hoveredPersonId,
    String? focusPersonId,
    List<FocusCrumb>? focusStack,
    String? foyerFilterWifeId,
    bool clearSelected = false,
    bool clearHovered = false,
    bool clearFocus = false,
    bool clearFoyerFilter = false,
  }) {
    return TreeViewState(
      selectedPersonId: clearSelected ? null : (selectedPersonId ?? this.selectedPersonId),
      currentView: currentView ?? this.currentView,
      hiddenGenerations: hiddenGenerations ?? this.hiddenGenerations,
      rightTab: rightTab ?? this.rightTab,
      hoveredPersonId: clearHovered ? null : (hoveredPersonId ?? this.hoveredPersonId),
      focusPersonId: clearFocus ? null : (focusPersonId ?? this.focusPersonId),
      focusStack: clearFocus ? const [] : (focusStack ?? this.focusStack),
      foyerFilterWifeId:
          clearFoyerFilter ? null : (foyerFilterWifeId ?? this.foyerFilterWifeId),
    );
  }
}

// ── Notifier ────────────────────────────────────────────────

class TreeViewNotifier extends StateNotifier<TreeViewState> {
  TreeViewNotifier() : super(const TreeViewState());

  void selectPerson(String id) {
    state = state.copyWith(selectedPersonId: id, rightTab: RightTab.personne);
  }

  void clearSelection() {
    state = state.copyWith(clearSelected: true);
  }

  void changeView(TreeView view) {
    // Changer de vue réinitialise le filtre par foyer (2c).
    state = state.copyWith(currentView: view, clearFoyerFilter: true);
  }

  /// Filtre « vue par foyer » (maquette 2c) : ne garder que le foyer de
  /// [wifeId] en mode foyers. `null` = « Tous les foyers ».
  void setFoyerFilter(String? wifeId) {
    state = wifeId == null
        ? state.copyWith(clearFoyerFilter: true)
        : state.copyWith(foyerFilterWifeId: wifeId);
  }

  void toggleGeneration(int gen) {
    final hidden = Set<int>.from(state.hiddenGenerations);
    if (hidden.contains(gen)) {
      hidden.remove(gen);
    } else {
      hidden.add(gen);
    }
    state = state.copyWith(hiddenGenerations: hidden);
  }

  void setRightTab(RightTab tab) {
    state = state.copyWith(rightTab: tab);
  }

  void hoverPerson(String? id) {
    state = id == null
        ? state.copyWith(clearHovered: true)
        : state.copyWith(hoveredPersonId: id);
  }

  /// Fait de [personId] la nouvelle racine de l'arbre (« centrer ici »).
  /// Empile un fil d'Ariane ; ne fait rien si déjà au sommet.
  void focusPerson(String personId, String label) {
    if (state.focusPersonId == personId) return;
    final stack = [...state.focusStack, FocusCrumb(personId: personId, label: label)];
    state = state.copyWith(
      focusPersonId: personId,
      focusStack: stack,
      selectedPersonId: personId,
      rightTab: RightTab.personne,
    );
  }

  /// Revient à une étape précise du fil d'Ariane (nom cliquable).
  /// [index] pointe dans [focusStack] ; on tronque au-delà.
  void focusToCrumb(int index) {
    if (index < 0 || index >= state.focusStack.length) return;
    final stack = state.focusStack.sublist(0, index + 1);
    state = state.copyWith(
      focusPersonId: stack.last.personId,
      focusStack: stack,
      selectedPersonId: stack.last.personId,
    );
  }

  /// « ⌂ Retour à moi » : réinitialise le focus sur le sujet
  /// (et le filtre par foyer 2c).
  void clearFocus() {
    state = state.copyWith(clearFocus: true, clearFoyerFilter: true);
  }
}

// ── Providers ───────────────────────────────────────────────

final treeViewProvider =
    StateNotifierProvider.autoDispose<TreeViewNotifier, TreeViewState>(
  (ref) => TreeViewNotifier(),
);

/// Mode d'affichage mobile de la lignée (#1d) — Rivière par défaut.
final riverModeProvider =
    StateProvider.autoDispose<RiverMode>((_) => RiverMode.river);
