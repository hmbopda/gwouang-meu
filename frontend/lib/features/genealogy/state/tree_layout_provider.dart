import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/genealogy/models/family_tree.dart';
import 'package:gwangmeu/features/genealogy/models/person_genealogy.dart';
import 'package:gwangmeu/features/genealogy/models/sibling_genealogy.dart';
import 'package:gwangmeu/features/genealogy/state/tree_view_state.dart';

/// Result of layout computation.
class TreeLayout {
  final List<LayoutNode> nodes;
  final List<LayoutLink> links;
  final double contentWidth;
  final double contentHeight;
  final Map<String, LayoutNode> nodeMap; // personId → node

  const TreeLayout({
    required this.nodes,
    required this.links,
    required this.contentWidth,
    required this.contentHeight,
    required this.nodeMap,
  });

  static const empty = TreeLayout(
    nodes: [],
    links: [],
    contentWidth: 600,
    contentHeight: 400,
    nodeMap: {},
  );
}

// ── Provider ────────────────────────────────────────────────

// select() : n'écoute QUE currentView et hiddenGenerations
// selectedPersonId / hoveredPersonId → PAS de recalcul (géré au niveau Painter)
final treeLayoutProvider = Provider.autoDispose.family<TreeLayout, FamilyTree>(
  (ref, tree) {
    final currentView = ref.watch(treeViewProvider.select((s) => s.currentView));
    final hiddenGenerations = ref.watch(treeViewProvider.select((s) => s.hiddenGenerations));
    return _computeLayout(tree, currentView, hiddenGenerations);
  },
);

// ── Layout algorithm ────────────────────────────────────────

// Nœuds-cartes « Tissage » (~180 px de large) → espacements élargis.
const double _hSpacing = 210.0;
const double _vSpacing = 190.0;
const double _padding = 100.0;
const double _topPadding = 170.0; // extra top space for floating toolbar

TreeLayout _computeLayout(FamilyTree tree, TreeView currentView, Set<int> hiddenGenerations) {
  final nodes = <LayoutNode>[];
  final links = <LayoutLink>[];
  final nodeMap = <String, LayoutNode>{};

  // ── Build generation rows based on view ──
  final rows = <int, List<_NodeInfo>>{};

  // Extraire les conjoints depuis les unions
  final spouses = _extractSpouses(tree);

  switch (currentView) {
    case TreeView.full:
      _addRow(rows, 0, tree.paternalGP, tree.maternalGP);
      _addRow3(rows, 1, tree.father, tree.mother, tree.uncles);
      _addSubjectRowWithSpouses(rows, 2, tree.subject, tree.siblings, spouses);
      _addRow(rows, 3, tree.children, const []);
      break;
    case TreeView.ancestors:
      _addRow(rows, 0, tree.paternalGP, tree.maternalGP);
      _addRow3(rows, 1, tree.father, tree.mother, tree.uncles);
      _addSubjectRowWithSpouses(rows, 2, tree.subject, const [], spouses);
      break;
    case TreeView.descendants:
      _addSubjectRowWithSpouses(rows, 0, tree.subject, const [], spouses);
      _addRow(rows, 1, tree.children, const [], lineage1: NodeType.primaryLineage);
      break;
    case TreeView.migration:
      _addSubjectRow(rows, 0, tree.subject, const []);
      break;
  }

  // Remove empty rows and compact
  rows.removeWhere((_, v) => v.isEmpty);

  // Filter hidden generations
  if (hiddenGenerations.isNotEmpty) {
    rows.removeWhere((gen, _) => hiddenGenerations.contains(gen));
  }

  if (rows.isEmpty) return TreeLayout.empty;

  // ── Calculate positions ──
  final sortedGens = rows.keys.toList()..sort();
  int maxNodesInRow = 1;
  for (final row in rows.values) {
    if (row.length > maxNodesInRow) maxNodesInRow = row.length;
  }

  final contentW = (maxNodesInRow * _hSpacing) + _padding * 2;
  final contentH = (sortedGens.length * _vSpacing) + _topPadding + _padding;
  final centerX = contentW / 2;

  for (int i = 0; i < sortedGens.length; i++) {
    final gen = sortedGens[i];
    final row = rows[gen]!;
    final y = _topPadding + i * _vSpacing;
    final totalW = row.length * _hSpacing;
    final startX = centerX - totalW / 2 + _hSpacing / 2;

    for (int j = 0; j < row.length; j++) {
      final info = row[j];
      final x = startX + j * _hSpacing;
      final pos = Offset(x, y);

      final node = LayoutNode(
        person: info.person,
        position: pos,
        generation: gen,
        type: _nodeType(info.person, tree.subject.id, info.lineage),
        hasDotPaid: info.hasDotPaid,
        isSubject: info.person.id == tree.subject.id,
      );
      nodes.add(node);
      nodeMap[info.person.id] = node;
    }
  }

  // ── Build links — courbes colorées par lignée ──
  // Lignée du sujet = or, lignée alliée/maternelle = rose cuivré.
  const goldLine = GwTokens.gold;
  const roseLine = GwTokens.rose;

  // Parent → child (filiation)
  void linkParentSide(List<PersonGenealogy> parents, Color color) {
    for (final parent in parents) {
      final pNode = nodeMap[parent.id];
      if (pNode == null) continue;

      // Subject
      final sNode = nodeMap[tree.subject.id];
      if (sNode != null) {
        links.add(LayoutLink(
          from: pNode.position,
          to: sNode.position,
          type: LinkType.filiation,
          color: color,
        ));
      }

      // Siblings — link only to the shared parent(s)
      for (final sib in tree.siblings) {
        final sibNode = nodeMap[sib.person.id];
        if (sibNode == null) continue;
        if (sib.type == 'FULL' || sib.sharedParentId == parent.id) {
          links.add(LayoutLink(
            from: pNode.position,
            to: sibNode.position,
            type: LinkType.filiation,
            color: color,
          ));
        }
      }
    }
  }

  linkParentSide(tree.father, goldLine);
  linkParentSide(tree.mother, roseLine);

  // Grandparents → parents
  for (final gp in tree.paternalGP) {
    final gpNode = nodeMap[gp.id];
    if (gpNode == null) continue;
    for (final f in tree.father) {
      final fNode = nodeMap[f.id];
      if (fNode != null) {
        links.add(LayoutLink(
            from: gpNode.position,
            to: fNode.position,
            type: LinkType.filiation,
            color: goldLine));
      }
    }
  }
  for (final gp in tree.maternalGP) {
    final gpNode = nodeMap[gp.id];
    if (gpNode == null) continue;
    for (final m in tree.mother) {
      final mNode = nodeMap[m.id];
      if (mNode != null) {
        links.add(LayoutLink(
            from: gpNode.position,
            to: mNode.position,
            type: LinkType.filiation,
            color: roseLine));
      }
    }
  }

  // Grandparents → uncles/aunts
  for (final uncle in tree.uncles) {
    final uNode = nodeMap[uncle.id];
    if (uNode == null) continue;
    // Link to all grandparents (uncle is a child of one of them)
    for (final gp in [...tree.paternalGP, ...tree.maternalGP]) {
      final gpNode = nodeMap[gp.id];
      if (gpNode != null) {
        links.add(LayoutLink(
            from: gpNode.position,
            to: uNode.position,
            type: LinkType.filiation,
            color: goldLine));
      }
    }
  }

  // Subject → children
  final subNode = nodeMap[tree.subject.id];
  if (subNode != null) {
    for (final child in tree.children) {
      final cNode = nodeMap[child.id];
      if (cNode != null) {
        links.add(LayoutLink(
          from: subNode.position,
          to: cNode.position,
          type: LinkType.filiation,
          color: goldLine,
        ));
      }
    }
  }

  // Spouse → children (le conjoint est aussi parent des enfants communs)
  for (final spouse in spouses) {
    final spNode = nodeMap[spouse.person.id];
    if (spNode == null) continue;
    for (final child in tree.children) {
      final cNode = nodeMap[child.id];
      if (cNode != null) {
        links.add(LayoutLink(
          from: spNode.position,
          to: cNode.position,
          type: LinkType.filiation,
          color: roseLine,
        ));
      }
    }
  }

  // Unions (horizontal links between spouses)
  for (final union in tree.unions) {
    final hNode = nodeMap[union.husbandId];
    final wNode = nodeMap[union.wifeId];
    if (hNode != null && wNode != null) {
      links.add(LayoutLink(
        from: hNode.position,
        to: wNode.position,
        type: LinkType.union,
      ));
    }
  }

  return TreeLayout(
    nodes: nodes,
    links: links,
    contentWidth: contentW,
    contentHeight: contentH,
    nodeMap: nodeMap,
  );
}

// ── Helpers ─────────────────────────────────────────────────

class _NodeInfo {
  final PersonGenealogy person;
  final bool hasDotPaid;

  /// Lignée structurelle (or = lignée du sujet, rose = lignée alliée).
  final NodeType lineage;

  const _NodeInfo(
    this.person, {
    this.hasDotPaid = false,
    this.lineage = NodeType.primaryLineage,
  });
}

/// group1 = lignée du sujet (or), group2 = lignée alliée/maternelle (rose).
void _addRow(Map<int, List<_NodeInfo>> rows, int gen,
    List<PersonGenealogy> group1, List<PersonGenealogy> group2,
    {NodeType lineage1 = NodeType.primaryLineage,
    NodeType lineage2 = NodeType.secondaryLineage}) {
  final list = <_NodeInfo>[
    ...group1.map((p) => _NodeInfo(p, lineage: lineage1)),
    ...group2.map((p) => _NodeInfo(p, lineage: lineage2)),
  ];
  if (list.isNotEmpty) rows[gen] = list;
}

/// group1 = paternel (or), group2 = maternel (rose), group3 = oncles (or).
void _addRow3(Map<int, List<_NodeInfo>> rows, int gen,
    List<PersonGenealogy> group1, List<PersonGenealogy> group2, List<PersonGenealogy> group3) {
  final list = <_NodeInfo>[
    ...group1.map((p) => _NodeInfo(p, lineage: NodeType.primaryLineage)),
    ...group2.map((p) => _NodeInfo(p, lineage: NodeType.secondaryLineage)),
    ...group3.map((p) => _NodeInfo(p, lineage: NodeType.primaryLineage)),
  ];
  if (list.isNotEmpty) rows[gen] = list;
}

void _addSubjectRow(Map<int, List<_NodeInfo>> rows, int gen,
    PersonGenealogy subject, List<PersonGenealogy> siblings) {
  rows[gen] = [
    _NodeInfo(subject),
    ...siblings.map((p) => _NodeInfo(p)),
  ];
}

/// Extrait les conjoints depuis les unions (husband ou wife selon le sujet)
List<_NodeInfo> _extractSpouses(FamilyTree tree) {
  final spouses = <_NodeInfo>[];
  final addedIds = <String>{};
  for (final union in tree.unions) {
    // Déterminer le conjoint (l'autre personne de l'union)
    PersonGenealogy? spouse;
    if (union.husbandId == tree.subject.id && union.wife != null) {
      spouse = union.wife;
    } else if (union.wifeId == tree.subject.id && union.husband != null) {
      spouse = union.husband;
    }
    if (spouse != null && !addedIds.contains(spouse.id)) {
      addedIds.add(spouse.id);
      spouses.add(_NodeInfo(
        spouse,
        hasDotPaid: union.isDotPaid,
        lineage: NodeType.spouse,
      ));
    }
  }
  return spouses;
}

/// Ajoute le sujet + conjoints + frères/sœurs sur la même ligne
void _addSubjectRowWithSpouses(Map<int, List<_NodeInfo>> rows, int gen,
    PersonGenealogy subject, List<SiblingGenealogy> siblings, List<_NodeInfo> spouses) {
  if (subject.gender == 'FEMALE') {
    // Femme : conjoint(s) à gauche, elle à droite
    rows[gen] = [
      ...spouses,
      _NodeInfo(subject),
      ...siblings.map((s) => _NodeInfo(s.person)),
    ];
  } else {
    // Homme : lui à gauche, conjointe(s) à droite
    rows[gen] = [
      _NodeInfo(subject),
      ...spouses,
      ...siblings.map((s) => _NodeInfo(s.person)),
    ];
  }
}

/// Couleur par lignée, plus par genre. Les disparus deviennent des
/// « ancêtres » (bordure discrète + ✦), jamais de noir « décédé ».
NodeType _nodeType(PersonGenealogy p, String subjectId, NodeType lineage) {
  if (p.id == subjectId) return NodeType.subject;
  if (!p.isAlive) return NodeType.ancestor;
  return lineage;
}
