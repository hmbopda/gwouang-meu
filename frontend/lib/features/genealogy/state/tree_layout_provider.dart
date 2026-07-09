import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/genealogy/models/family_tree.dart';
import 'package:gwangmeu/features/genealogy/models/genealogy_union.dart';
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

  // Unions du sujet, ordonnées par unionOrder (1re, 2e…) → co-épouses contiguës.
  final subjectUnions = _subjectUnions(tree);

  // Extraire les conjoints depuis les unions (ordre = unionOrder)
  final spouses = _extractSpouses(tree, subjectUnions);

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

  // ── Conjoints des ANCÊTRES (co-épouses d'un fondateur polygame…) ──
  // Le backend renvoie désormais les unions du sujet ET des ascendants.
  // Pour chaque union, si un seul des deux conjoints est déjà placé (ex : le
  // père en génération 1), on ajoute l'AUTRE (la co-épouse) dans la MÊME ligne,
  // juste après lui, sinon la polygamie des ancêtres reste invisible.
  _ensureUnionSpousesPlaced(rows, tree);

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
        unionInfo: info.unionInfo,
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

  // ── Filiation vers les enfants, REGROUPÉE PAR UNION ──────────
  // En polygamie, chaque co-épouse a SES enfants : on ne relie jamais
  // le sujet (ni un conjoint) à TOUS les enfants. On rattache chaque enfant
  // au bon couple via unionId / motherId / fatherId, avec une barre de
  // fratrie descendante DISTINCTE par union.
  final subNode = nodeMap[tree.subject.id];

  // Enfants restants : ceux qu'aucune union n'a réclamés (données legacy).
  final unclaimed = <PersonGenealogy>{...tree.children};

  for (final union in subjectUnions) {
    // Le conjoint (autre que le sujet) de cette union.
    final spouseId =
        union.husbandId == tree.subject.id ? union.wifeId : union.husbandId;
    final spNode = nodeMap[spouseId];

    // Enfants de CETTE union.
    final unionChildren = <PersonGenealogy>[];
    for (final child in tree.children) {
      if (_belongsToUnion(child, union, tree.subject.id, spouseId)) {
        unionChildren.add(child);
        unclaimed.remove(child);
      }
    }
    if (unionChildren.isEmpty) continue;

    // Point de rattachement de la fratrie : milieu du couple si le conjoint
    // est présent, sinon le sujet seul.
    final anchor = (subNode != null && spNode != null)
        ? Offset(
            (subNode.position.dx + spNode.position.dx) / 2,
            (subNode.position.dy + spNode.position.dy) / 2,
          )
        : subNode?.position;
    if (anchor == null) continue;

    final ended = !union.isActive;

    // Barre de fratrie : segment horizontal reliant les enfants de l'union.
    final childNodes = unionChildren
        .map((c) => nodeMap[c.id])
        .whereType<LayoutNode>()
        .toList();
    if (childNodes.length > 1) {
      childNodes.sort((a, b) => a.position.dx.compareTo(b.position.dx));
      final barY = childNodes.first.position.dy - _vSpacing * 0.28;
      links.add(LayoutLink(
        from: Offset(childNodes.first.position.dx, barY),
        to: Offset(childNodes.last.position.dx, barY),
        type: LinkType.siblings,
        ended: ended,
      ));
      // Descente du couple vers la barre.
      links.add(LayoutLink(
        from: anchor,
        to: Offset(
          (childNodes.first.position.dx + childNodes.last.position.dx) / 2,
          barY,
        ),
        type: LinkType.filiation,
        color: goldLine,
        ended: ended,
      ));
    }

    // Filiation couple → chaque enfant de l'union.
    for (final cNode in childNodes) {
      links.add(LayoutLink(
        from: anchor,
        to: cNode.position,
        type: LinkType.filiation,
        color: goldLine,
        ended: ended,
      ));
    }
  }

  // Enfants non réclamés par une union (monogame sans unionId, ou legacy) :
  // rattachés au sujet seul — on ne casse pas le cas simple.
  if (subNode != null) {
    for (final child in unclaimed) {
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

  // ── Unions (liens horizontaux sujet↔conjoint + co-épouses contiguës) ──
  for (final union in tree.unions) {
    final hNode = nodeMap[union.husbandId];
    final wNode = nodeMap[union.wifeId];
    if (hNode != null && wNode != null) {
      links.add(LayoutLink(
        from: hNode.position,
        to: wNode.position,
        type: LinkType.union,
        ended: !union.isActive,
      ));
    }
  }

  // Co-épouses contiguës d'un même sujet reliées entre elles (rang → rang+1).
  for (int i = 0; i + 1 < spouses.length; i++) {
    final a = nodeMap[spouses[i].person.id];
    final b = nodeMap[spouses[i + 1].person.id];
    if (a != null && b != null) {
      links.add(LayoutLink(
        from: a.position,
        to: b.position,
        type: LinkType.union,
        ended: true, // trait atténué : lien de co-épouses, pas une union active
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

  /// Métadonnées d'union (rang, régime, conformité) pour un conjoint.
  final NodeUnionInfo? unionInfo;

  const _NodeInfo(
    this.person, {
    this.hasDotPaid = false,
    this.lineage = NodeType.primaryLineage,
    this.unionInfo,
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

/// Unions du sujet, ordonnées par unionOrder (1re, 2e…).
/// L'ordre pilote la contiguïté des co-épouses et le badge de rang.
List<GenealogyUnion> _subjectUnions(FamilyTree tree) {
  final list = tree.unions
      .where((u) =>
          u.husbandId == tree.subject.id || u.wifeId == tree.subject.id)
      .toList()
    ..sort((a, b) => a.unionOrder.compareTo(b.unionOrder));
  return list;
}

/// Un conjoint est polygame si le sujet a ≥ 2 unions actives, OU si l'union
/// elle-même est marquée polygame par le backend.
bool _isPolygamousContext(GenealogyUnion union, List<GenealogyUnion> all) {
  if (union.isPolygamous) return true;
  final activeCount = all.where((u) => u.isActive).length;
  return activeCount >= 2;
}

/// Extrait les conjoints depuis les unions du sujet, dans l'ordre unionOrder,
/// chacun porteur de ses métadonnées d'union (rang, régime, conformité, dot).
List<_NodeInfo> _extractSpouses(
    FamilyTree tree, List<GenealogyUnion> subjectUnions) {
  final spouses = <_NodeInfo>[];
  final addedIds = <String>{};
  for (int i = 0; i < subjectUnions.length; i++) {
    final union = subjectUnions[i];
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
        unionInfo: NodeUnionInfo(
          unionId: union.id,
          rank: union.unionOrder,
          isPolygamous: _isPolygamousContext(union, subjectUnions),
          isActive: union.isActive,
          legalRegime: union.legalRegime,
          compliance: unionComplianceFromStatus(union.complianceStatus),
        ),
      ));
    }
  }
  return spouses;
}

/// Un enfant appartient-il à cette union ? Priorité à unionId (le plus sûr),
/// sinon on rattache par le couple (mother/father = les deux conjoints).
bool _belongsToUnion(
    PersonGenealogy child, GenealogyUnion union, String subjectId,
    String spouseId) {
  if (child.unionId != null) return child.unionId == union.id;
  // Sans unionId : l'enfant appartient au couple si ses deux parents sont
  // exactement {sujet, conjoint} (ordre indifférent selon le genre).
  final parents = {child.motherId, child.fatherId};
  if (parents.contains(subjectId) && parents.contains(spouseId)) return true;
  return false;
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

/// Garantit que les DEUX conjoints de chaque union possèdent un nœud.
///
/// Le backend fournit les unions du sujet mais aussi celles des ascendants
/// (père, mère, grands-parents). Les conjoint·es des ancêtres (autres épouses
/// d'un fondateur polygame…) ne sont créés par aucune passe. Ici, pour chaque
/// union dont UN SEUL conjoint est déjà placé, on ajoute l'AUTRE dans la même
/// ligne, immédiatement après le partenaire déjà présent. On réutilise la
/// personne embarquée (union.husband / union.wife) et on marque le nœud comme
/// [NodeType.spouse] avec un [NodeUnionInfo] cohérent (rang = unionOrder).
void _ensureUnionSpousesPlaced(Map<int, List<_NodeInfo>> rows, FamilyTree tree) {
  // Ensemble des personnes déjà placées (tous rangs confondus), anti-doublon.
  final placed = <String>{};
  for (final row in rows.values) {
    for (final info in row) {
      placed.add(info.person.id);
    }
  }

  for (final union in tree.unions) {
    final husbandPlaced = placed.contains(union.husbandId);
    final wifePlaced = placed.contains(union.wifeId);

    // Rien à faire si les deux sont déjà placés ou si aucun ne l'est
    // (aucun point d'ancrage : on ne peut choisir de ligne).
    if (husbandPlaced == wifePlaced) continue;

    // Le conjoint déjà placé et celui à ajouter (personne embarquée).
    final String anchorId;
    final PersonGenealogy? missing;
    if (husbandPlaced) {
      anchorId = union.husbandId;
      missing = union.wife;
    } else {
      anchorId = union.wifeId;
      missing = union.husband;
    }

    // Personne conjoint indisponible → on ne crée rien.
    if (missing == null) continue;
    // Anti-doublon : déjà placée (autre union, même personne).
    if (placed.contains(missing.id)) continue;

    // Localiser la ligne + l'index du partenaire déjà placé.
    for (final entry in rows.entries) {
      final row = entry.value;
      final anchorIndex = row.indexWhere((info) => info.person.id == anchorId);
      if (anchorIndex < 0) continue;

      row.insert(
        anchorIndex + 1,
        _NodeInfo(
          missing,
          hasDotPaid: union.isDotPaid,
          lineage: NodeType.spouse,
          unionInfo: NodeUnionInfo(
            unionId: union.id,
            rank: union.unionOrder,
            isPolygamous: _isPolygamousContext(union, tree.unions),
            isActive: union.isActive,
            legalRegime: union.legalRegime,
            compliance: unionComplianceFromStatus(union.complianceStatus),
          ),
        ),
      );
      placed.add(missing.id);
      break;
    }
  }
}

/// Couleur par lignée, plus par genre. Les disparus deviennent des
/// « ancêtres » (bordure discrète + ✦), jamais de noir « décédé ».
NodeType _nodeType(PersonGenealogy p, String subjectId, NodeType lineage) {
  if (p.id == subjectId) return NodeType.subject;
  if (!p.isAlive) return NodeType.ancestor;
  return lineage;
}
