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

enum LinkType { filiation, union, siblings, aiSuggestion }

// ── Layout models ───────────────────────────────────────────

class LayoutNode {
  final PersonGenealogy person;
  final Offset position;
  final int generation;
  final NodeType type;
  final bool hasDotPaid;
  final bool isSubject;

  const LayoutNode({
    required this.person,
    required this.position,
    required this.generation,
    required this.type,
    this.hasDotPaid = false,
    this.isSubject = false,
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

  const LayoutLink({
    required this.from,
    required this.to,
    required this.type,
    this.highlight = false,
    this.color,
  });
}

// ── View state ──────────────────────────────────────────────

class TreeViewState {
  final String? selectedPersonId;
  final TreeView currentView;
  final Set<int> hiddenGenerations;
  final RightTab rightTab;
  final String? hoveredPersonId;

  const TreeViewState({
    this.selectedPersonId,
    this.currentView = TreeView.full,
    this.hiddenGenerations = const {},
    this.rightTab = RightTab.personne,
    this.hoveredPersonId,
  });

  TreeViewState copyWith({
    String? selectedPersonId,
    TreeView? currentView,
    Set<int>? hiddenGenerations,
    RightTab? rightTab,
    String? hoveredPersonId,
    bool clearSelected = false,
    bool clearHovered = false,
  }) {
    return TreeViewState(
      selectedPersonId: clearSelected ? null : (selectedPersonId ?? this.selectedPersonId),
      currentView: currentView ?? this.currentView,
      hiddenGenerations: hiddenGenerations ?? this.hiddenGenerations,
      rightTab: rightTab ?? this.rightTab,
      hoveredPersonId: clearHovered ? null : (hoveredPersonId ?? this.hoveredPersonId),
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
    state = state.copyWith(currentView: view);
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
}

// ── Providers ───────────────────────────────────────────────

final treeViewProvider =
    StateNotifierProvider.autoDispose<TreeViewNotifier, TreeViewState>(
  (ref) => TreeViewNotifier(),
);

/// Mode d'affichage mobile de la lignée (#1d) — Rivière par défaut.
final riverModeProvider =
    StateProvider.autoDispose<RiverMode>((_) => RiverMode.river);
