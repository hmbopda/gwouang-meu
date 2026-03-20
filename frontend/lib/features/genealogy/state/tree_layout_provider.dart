import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final treeLayoutProvider = Provider.autoDispose.family<TreeLayout, FamilyTree>(
  (ref, tree) {
    final viewState = ref.watch(treeViewProvider);
    return _computeLayout(tree, viewState);
  },
);

// ── Layout algorithm ────────────────────────────────────────

const double _hSpacing = 140.0;
const double _vSpacing = 180.0;
const double _padding = 80.0;
const double _topPadding = 160.0; // extra top space for floating toolbar

TreeLayout _computeLayout(FamilyTree tree, TreeViewState state) {
  final nodes = <LayoutNode>[];
  final links = <LayoutLink>[];
  final nodeMap = <String, LayoutNode>{};

  // ── Build generation rows based on view ──
  final rows = <int, List<_NodeInfo>>{};

  // Extraire les conjoints depuis les unions
  final spouses = _extractSpouses(tree);

  switch (state.currentView) {
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
      _addRow(rows, 1, tree.children, const []);
      break;
    case TreeView.migration:
      _addSubjectRow(rows, 0, tree.subject, const []);
      break;
  }

  // Remove empty rows and compact
  rows.removeWhere((_, v) => v.isEmpty);

  // Filter hidden generations
  if (state.hiddenGenerations.isNotEmpty) {
    rows.removeWhere((gen, _) => state.hiddenGenerations.contains(gen));
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
        type: _nodeType(info.person, tree.subject.id),
        hasDotPaid: info.hasDotPaid,
        isSubject: info.person.id == tree.subject.id,
      );
      nodes.add(node);
      nodeMap[info.person.id] = node;
    }
  }

  // ── Build links ──
  // Parent → child (filiation)
  for (final parent in [...tree.father, ...tree.mother]) {
    final pNode = nodeMap[parent.id];
    if (pNode == null) continue;

    // Subject
    final sNode = nodeMap[tree.subject.id];
    if (sNode != null) {
      links.add(LayoutLink(
        from: pNode.position,
        to: sNode.position,
        type: LinkType.filiation,
        highlight: state.selectedPersonId == parent.id ||
            state.selectedPersonId == tree.subject.id,
      ));
    }

    // Siblings — link only to the shared parent(s)
    for (final sib in tree.siblings) {
      final sibNode = nodeMap[sib.person.id];
      if (sibNode == null) continue;
      // For FULL siblings, link to all parents
      // For HALF siblings, link only if this parent is the shared one
      if (sib.type == 'FULL' || sib.sharedParentId == parent.id) {
        links.add(LayoutLink(
          from: pNode.position,
          to: sibNode.position,
          type: LinkType.filiation,
        ));
      }
    }
  }

  // Grandparents → parents
  for (final gp in tree.paternalGP) {
    final gpNode = nodeMap[gp.id];
    if (gpNode == null) continue;
    for (final f in tree.father) {
      final fNode = nodeMap[f.id];
      if (fNode != null) {
        links.add(LayoutLink(from: gpNode.position, to: fNode.position, type: LinkType.filiation));
      }
    }
  }
  for (final gp in tree.maternalGP) {
    final gpNode = nodeMap[gp.id];
    if (gpNode == null) continue;
    for (final m in tree.mother) {
      final mNode = nodeMap[m.id];
      if (mNode != null) {
        links.add(LayoutLink(from: gpNode.position, to: mNode.position, type: LinkType.filiation));
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
        links.add(LayoutLink(from: gpNode.position, to: uNode.position, type: LinkType.filiation));
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
          highlight: state.selectedPersonId == child.id,
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
  const _NodeInfo(this.person, {this.hasDotPaid = false});
}

void _addRow(Map<int, List<_NodeInfo>> rows, int gen,
    List<PersonGenealogy> group1, List<PersonGenealogy> group2) {
  final list = <_NodeInfo>[
    ...group1.map((p) => _NodeInfo(p)),
    ...group2.map((p) => _NodeInfo(p)),
  ];
  if (list.isNotEmpty) rows[gen] = list;
}

void _addRow3(Map<int, List<_NodeInfo>> rows, int gen,
    List<PersonGenealogy> group1, List<PersonGenealogy> group2, List<PersonGenealogy> group3) {
  final list = <_NodeInfo>[
    ...group1.map((p) => _NodeInfo(p)),
    ...group2.map((p) => _NodeInfo(p)),
    ...group3.map((p) => _NodeInfo(p)),
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
      spouses.add(_NodeInfo(spouse, hasDotPaid: union.isDotPaid));
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

NodeType _nodeType(PersonGenealogy p, String subjectId) {
  if (p.id == subjectId) return NodeType.subject;
  if (!p.isAlive) return NodeType.deceased;
  if (p.gender == 'MALE') return NodeType.male;
  if (p.gender == 'FEMALE') return NodeType.female;
  return NodeType.male;
}
