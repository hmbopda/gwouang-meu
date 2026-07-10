import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/genealogy/models/family_tree.dart';
import 'package:gwangmeu/features/genealogy/models/genealogy_union.dart';
import 'package:gwangmeu/features/genealogy/models/person_genealogy.dart';
import 'package:gwangmeu/features/genealogy/models/sibling_genealogy.dart';
import 'package:gwangmeu/features/genealogy/state/tree_view_state.dart';

/// Entrée d'un chip-filtre « vue par foyer » (maquette 2c) : une épouse du
/// mode foyers, avec la couleur de SON foyer (or / rose / vert).
class FoyerChipInfo {
  final String wifeId;
  final String label; // prénom de l'épouse
  final Color color;

  const FoyerChipInfo({
    required this.wifeId,
    required this.label,
    required this.color,
  });
}

/// Result of layout computation.
class TreeLayout {
  final List<LayoutNode> nodes;
  final List<LayoutLink> links;
  final double contentWidth;
  final double contentHeight;
  final Map<String, LayoutNode> nodeMap; // personId → node

  /// Pilules-étiquettes des connecteurs d'union (maquette 2a — foyers).
  /// Vide en mode monogame (rendu 1a).
  final List<UnionBadge> unionBadges;

  /// Boîtes pointillées par foyer (maquette 2a). Vide en mode monogame.
  final List<FoyerBox> foyerBoxes;

  /// Chips-filtres du mode foyers (maquette 2c) : TOUTES les épouses,
  /// même celles masquées par le filtre. Vide en mode monogame.
  final List<FoyerChipInfo> foyerChips;

  /// Nombre d'épouses (foyers) masquées par le filtre 2c. 0 sans filtre.
  final int hiddenFoyerCount;

  /// ENCLOS DES UNIONS (maquette 8a, vue Ascendants) : cadre pointillé qui
  /// regroupe les conjoints du sujet en grille. Null hors de ce mode.
  final Rect? unionEnclos;

  /// Libellé mono de l'enclos, ex « VOS UNIONS · 4 · 8 ENFANTS ».
  final String? unionEnclosLabel;

  /// Mode « foyers » PLEIN ÉCRAN (maquette 2a, vue Rivière) : bandes de
  /// générations masquées, chips 2c affichées. Les vues Ascendants /
  /// Descendants réutilisent enclos et boîtes SANS ce mode.
  final bool foyerMode;

  const TreeLayout({
    required this.nodes,
    required this.links,
    required this.contentWidth,
    required this.contentHeight,
    required this.nodeMap,
    this.unionBadges = const [],
    this.foyerBoxes = const [],
    this.foyerChips = const [],
    this.hiddenFoyerCount = 0,
    this.unionEnclos,
    this.unionEnclosLabel,
    this.foyerMode = false,
  });

  /// Mode « foyers polygames » actif (maquette 2a) : le canvas ne peint ni
  /// bandes de générations ni barres de fratrie, mais chef + épouses + boîtes.
  bool get isFoyerMode => foyerMode;

  static const empty = TreeLayout(
    nodes: [],
    links: [],
    contentWidth: 600,
    contentHeight: 400,
    nodeMap: {},
  );
}

// ── Provider ────────────────────────────────────────────────

// select() : n'écoute QUE currentView, hiddenGenerations et foyerFilterWifeId
// selectedPersonId / hoveredPersonId → PAS de recalcul (géré au niveau Painter)
final treeLayoutProvider = Provider.autoDispose.family<TreeLayout, FamilyTree>(
  (ref, tree) {
    final currentView = ref.watch(treeViewProvider.select((s) => s.currentView));
    final hiddenGenerations = ref.watch(treeViewProvider.select((s) => s.hiddenGenerations));
    final foyerFilterWifeId =
        ref.watch(treeViewProvider.select((s) => s.foyerFilterWifeId));
    return _computeLayout(tree, currentView, hiddenGenerations, foyerFilterWifeId);
  },
);

// ── Layout algorithm ────────────────────────────────────────

// Nœuds-cartes maquette (230 px de large) → 264 = carte + gouttière 34 px,
// AUCUN chevauchement possible entre cartes voisines.
const double _hSpacing = 264.0;
const double _vSpacing = 190.0;
const double _padding = 100.0;
const double _topPadding = 170.0; // extra top space for floating toolbar

TreeLayout _computeLayout(FamilyTree tree, TreeView currentView,
    Set<int> hiddenGenerations, String? foyerFilterWifeId) {
  // ── Mode FOYERS (maquette 2a) : un homme de l'arbre a ≥ 2 unions ──
  // Mari (chef) centré en haut, épouses en rangée dessous (couleur de foyer
  // or / rose / vert cyclique), enfants EMPILÉS dans une boîte pointillée
  // sous chaque mère. En mode monogame (0 ou 1 union), rendu 1a inchangé.
  // UNIQUEMENT sur la vue Rivière : Ascendants / Descendants gardent leur
  // rendu par générations (sinon ces boutons semblaient inactifs).
  if (currentView == TreeView.full) {
    final foyerGroups = _detectFoyerGroups(tree);
    if (foyerGroups.isNotEmpty) {
      return _computeFoyerLayout(tree, foyerGroups, foyerFilterWifeId);
    }
  }

  final nodes = <LayoutNode>[];
  final links = <LayoutLink>[];
  final nodeMap = <String, LayoutNode>{};

  // ── Build generation rows based on view ──
  final rows = <int, List<_NodeInfo>>{};

  // Unions du sujet, ordonnées par unionOrder (1re, 2e…) → co-épouses contiguës.
  final subjectUnions = _subjectUnions(tree);

  // Extraire les conjoints depuis les unions (ordre = unionOrder)
  final spouses = _extractSpouses(tree, subjectUnions);

  // ENCLOS DES UNIONS (maquette 8a) : en vue Ascendants avec ≥ 2 unions,
  // les conjoints sont regroupés dans un CADRE POINTILLÉ en grille 2 colonnes
  // à droite du sujet (un seul lien or), au lieu d'être étalés sur la rangée.
  final enclosMode =
      currentView == TreeView.ancestors && spouses.length >= 2;

  // Vue DESCENDANTS avec ≥ 2 unions (maquette 9a) : sujet en haut, enclos des
  // épouses en rangée dessous, puis les ENFANTS DISSOCIÉS PAR FOYER dans des
  // boîtes pointillées colorées reliées à leur mère.
  final descEnclosMode =
      currentView == TreeView.descendants && spouses.length >= 2;

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
      _addSubjectRowWithSpouses(
          rows, 2, tree.subject, const [], enclosMode ? const [] : spouses);
      break;
    case TreeView.descendants:
      _addSubjectRowWithSpouses(
          rows, 0, tree.subject, const [], descEnclosMode ? const [] : spouses);
      if (!descEnclosMode) {
        _addRow(rows, 1, tree.children, const [],
            lineage1: NodeType.primaryLineage);
      }
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
  // En mode enclos, les unions du SUJET sont exclues (posées dans l'enclos).
  _ensureUnionSpousesPlaced(
    rows,
    tree,
    excludeUnionIds: (enclosMode || descEnclosMode)
        ? subjectUnions.map((u) => u.id).toSet()
        : const {},
  );

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

  // Génération du sujet (pour l'ancrage à gauche en mode enclos).
  final subjectGen = rows.entries
      .where((e) => e.value.any((n) => n.person.id == tree.subject.id))
      .map((e) => e.key)
      .firstOrNull;

  for (int i = 0; i < sortedGens.length; i++) {
    final gen = sortedGens[i];
    final row = rows[gen]!;
    final y = _topPadding + i * _vSpacing;
    final totalW = row.length * _hSpacing;
    // Mode enclos : le sujet est ANCRÉ À GAUCHE de sa bande, l'enclos des
    // unions occupe la droite (maquette 8a).
    final startX = (enclosMode && gen == subjectGen)
        ? _padding + 140
        : centerX - totalW / 2 + _hSpacing / 2;

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
        foyerColor: info.foyerColor,
      );
      nodes.add(node);
      nodeMap[info.person.id] = node;
    }
  }

  // ── ENCLOS DES UNIONS (maquette 8a, vue Ascendants) ─────────
  // Cadre pointillé à droite du sujet : conjoints en grille 2 colonnes,
  // couleur par union, UN SEUL lien or sujet → enclos.
  Rect? unionEnclos;
  String? unionEnclosLabel;
  var outW = contentW;
  var outH = contentH;
  if (enclosMode) {
    final subjNode = nodeMap[tree.subject.id];
    if (subjNode != null) {
      const cardW = 230.0, cardH = 84.0, pad = 16.0;
      const headerH = 26.0, colGap = 18.0, rowGap = 14.0, footerH = 44.0;
      final n = spouses.length;
      final rowsN = (n + 1) ~/ 2;
      const enclosW = pad * 2 + 2 * cardW + colGap;
      final enclosH =
          headerH + pad * 2 + rowsN * cardH + (rowsN - 1) * rowGap + footerH;
      final left = subjNode.position.dx + cardW / 2 + 56;
      final top = subjNode.position.dy - cardH / 2 - 6;
      unionEnclos = Rect.fromLTWH(left, top, enclosW, enclosH);

      for (int i = 0; i < n; i++) {
        final info = spouses[i];
        final col = i % 2;
        final r = i ~/ 2;
        final pos = Offset(
          left + pad + cardW / 2 + col * (cardW + colGap),
          top + headerH + pad + cardH / 2 + r * (cardH + rowGap),
        );
        final node = LayoutNode(
          person: info.person,
          position: pos,
          generation: subjectGen ?? 2,
          type: _nodeType(info.person, tree.subject.id, NodeType.spouse),
          hasDotPaid: info.hasDotPaid,
          unionInfo: info.unionInfo,
          foyerColor: info.foyerColor,
        );
        nodes.add(node);
        nodeMap[info.person.id] = node;
      }

      // Lien unique sujet → bord gauche de l'enclos (trait or plein).
      links.add(LayoutLink(
        from: subjNode.position,
        to: Offset(left, subjNode.position.dy),
        type: LinkType.filiation,
        color: GwTokens.gold,
      ));

      final kids = tree.children.length;
      unionEnclosLabel = 'VOS UNIONS · $n'
          '${kids > 0 ? ' · $kids ENFANT${kids > 1 ? 'S' : ''}' : ''}';
      outW = math.max(outW, left + enclosW + _padding);
      outH = math.max(outH, top + enclosH + _padding);
    }
  }

  // ── DESCENDANTS PAR FOYER (maquette 9a) ─────────────────────
  // Sujet en haut → enclos des épouses en RANGÉE → une boîte pointillée
  // colorée par foyer avec les enfants empilés, reliée à sa mère.
  final descBoxes = <FoyerBox>[];
  if (descEnclosMode) {
    var subjNode = nodeMap[tree.subject.id];
    if (subjNode != null) {
      const cardW = 230.0, cardH = 84.0, pad = 16.0;
      const headerH = 26.0, colGap = 40.0;
      final n = spouses.length;
      final enclosW = pad * 2 + n * cardW + (n - 1) * colGap;
      const enclosH = headerH + pad * 2 + cardH;

      // L'enclos est souvent plus large que la rangée générique : on recentre
      // le SUJET sur la largeur réelle pour éviter tout débord à gauche.
      final fullW = math.max(contentW, enclosW + 2 * _padding);
      final cx = fullW / 2;
      if ((subjNode.position.dx - cx).abs() > 1) {
        final moved = LayoutNode(
          person: subjNode.person,
          position: Offset(cx, subjNode.position.dy),
          generation: subjNode.generation,
          type: subjNode.type,
          hasDotPaid: subjNode.hasDotPaid,
          isSubject: true,
          unionInfo: subjNode.unionInfo,
        );
        nodes[nodes.indexOf(subjNode)] = moved;
        nodeMap[tree.subject.id] = moved;
        subjNode = moved;
      }
      outW = math.max(outW, fullW);

      final left = subjNode.position.dx - enclosW / 2;
      final top = subjNode.position.dy + cardH / 2 + 46;
      unionEnclos = Rect.fromLTWH(left, top, enclosW, enclosH);
      unionEnclosLabel = 'VOS UNIONS · $n FOYER${n > 1 ? 'S' : ''}';

      // Lien unique sujet → haut de l'enclos (trait or vertical).
      links.add(LayoutLink(
        from: subjNode.position,
        to: Offset(subjNode.position.dx, top),
        type: LinkType.filiation,
        color: GwTokens.gold,
      ));

      final boxTop = top + enclosH + 44;
      var maxBoxBottom = boxTop;
      for (int i = 0; i < n; i++) {
        final info = spouses[i];
        final union = subjectUnions[i];
        final color = _foyerColors[i % _foyerColors.length];
        final wifeX = left + pad + cardW / 2 + i * (cardW + colGap);
        final wifeY = top + headerH + pad + cardH / 2;

        // Carte de l'épouse dans l'enclos.
        final wifeNode = LayoutNode(
          person: info.person,
          position: Offset(wifeX, wifeY),
          generation: 0,
          type: _nodeType(info.person, tree.subject.id, NodeType.spouse),
          hasDotPaid: info.hasDotPaid,
          unionInfo: info.unionInfo,
          foyerColor: color,
        );
        nodes.add(wifeNode);
        nodeMap[info.person.id] = wifeNode;

        // Enfants de CE foyer (unionId prioritaire, sinon couple exact).
        final kids = tree.children
            .where((c) =>
                _belongsToUnion(c, union, tree.subject.id, info.person.id))
            .toList()
          ..sort((a, b) {
            final da = a.birthDate, db = b.birthDate;
            if (da != null && db != null) return da.compareTo(db);
            if (da != null) return -1;
            if (db != null) return 1;
            return a.firstName.compareTo(b.firstName);
          });

        // Boîte pointillée du foyer, centrée sous l'épouse.
        const boxW = 250.0;
        final k = kids.length;
        final boxH = _boxHeaderH +
            _boxPad * 2 +
            (k == 0 ? 34.0 : k * _miniCardH);
        final rect =
            Rect.fromLTWH(wifeX - boxW / 2, boxTop, boxW, boxH);
        final firstName = info.person.firstName.trim();
        descBoxes.add(FoyerBox(
          rect: rect,
          color: color,
          label:
              'FOYER ${(firstName.isEmpty ? '?' : firstName).toUpperCase()}'
              ' · ${k == 0 ? 'SANS ENFANT' : '$k ENFANT${k > 1 ? 'S' : ''}'}',
          childCount: k,
        ));

        // Descente pointillée épouse → boîte, couleur du foyer.
        links.add(LayoutLink(
          from: Offset(wifeX, wifeY + cardH / 2),
          to: Offset(wifeX, boxTop),
          type: LinkType.foyerDrop,
          color: color,
          ended: !union.isActive,
        ));

        // Mini-cartes des enfants empilées.
        for (int j = 0; j < k; j++) {
          final childY =
              boxTop + _boxPad + _boxHeaderH + j * _miniCardH + _miniCardH / 2;
          final childNode = LayoutNode(
            person: kids[j],
            position: Offset(wifeX, childY),
            generation: 1,
            type:
                _nodeType(kids[j], tree.subject.id, NodeType.primaryLineage),
            isSubject: kids[j].id == tree.subject.id,
            inFoyerBox: true,
            foyerColor: color,
          );
          nodes.add(childNode);
          nodeMap[kids[j].id] = childNode;
        }

        if (rect.bottom > maxBoxBottom) maxBoxBottom = rect.bottom;
      }

      outW = math.max(outW, left + enclosW + _padding);
      outH = math.max(outH, maxBoxBottom + _padding);
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
  // ≥ 2 unions du sujet : chaque union porte SA couleur (or/rose/vert/azure)
  // et le peintre les TRESSE sous la rangée (maquette 6a) au lieu du
  // pointillé latéral.
  final subjectUnionColor = <String, Color>{};
  if (subjectUnions.length >= 2) {
    for (int i = 0; i < subjectUnions.length; i++) {
      subjectUnionColor[subjectUnions[i].id] =
          _foyerColors[i % _foyerColors.length];
    }
  }

  for (final union in tree.unions) {
    // Modes enclos (8a/9a) : les unions du sujet sont matérialisées par
    // l'enclos lui-même (un seul lien or) — pas de trait par union.
    if ((enclosMode || descEnclosMode) &&
        subjectUnionColor.containsKey(union.id)) {
      continue;
    }
    final hNode = nodeMap[union.husbandId];
    final wNode = nodeMap[union.wifeId];
    if (hNode != null && wNode != null) {
      // Le tressage part toujours du SUJET vers le conjoint.
      final fromSubject = hNode.isSubject || !wNode.isSubject;
      links.add(LayoutLink(
        from: fromSubject ? hNode.position : wNode.position,
        to: fromSubject ? wNode.position : hNode.position,
        type: LinkType.union,
        ended: !union.isActive,
        color: subjectUnionColor[union.id],
      ));
    }
  }

  // Co-épouses contiguës reliées entre elles — uniquement quand les unions ne
  // sont PAS tressées en couleur (le tressage rend ce lien redondant).
  if (subjectUnionColor.isEmpty) {
    for (int i = 0; i + 1 < spouses.length; i++) {
      final a = nodeMap[spouses[i].person.id];
      final b = nodeMap[spouses[i + 1].person.id];
      if (a != null && b != null) {
        links.add(LayoutLink(
          from: a.position,
          to: b.position,
          type: LinkType.union,
          ended: true, // trait atténué : lien de co-épouses
        ));
      }
    }
  }

  return TreeLayout(
    nodes: nodes,
    links: links,
    contentWidth: outW,
    contentHeight: outH,
    nodeMap: nodeMap,
    unionEnclos: unionEnclos,
    unionEnclosLabel: unionEnclosLabel,
    foyerBoxes: descBoxes,
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

  /// Couleur d'union (maquette 6a) : bordure de carte + tressage, quand le
  /// sujet a ≥ 2 unions (or / rose / vert / azure par rang).
  final Color? foyerColor;

  const _NodeInfo(
    this.person, {
    this.hasDotPaid = false,
    this.lineage = NodeType.primaryLineage,
    this.unionInfo,
    this.foyerColor,
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
        // ≥ 2 unions : chaque conjoint porte la couleur de SON union
        // (bordure de carte + tressage sous la rangée, maquette 6a).
        foyerColor: subjectUnions.length >= 2
            ? _foyerColors[i % _foyerColors.length]
            : null,
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
void _ensureUnionSpousesPlaced(Map<int, List<_NodeInfo>> rows, FamilyTree tree,
    {Set<String> excludeUnionIds = const {}}) {
  // Ensemble des personnes déjà placées (tous rangs confondus), anti-doublon.
  final placed = <String>{};
  for (final row in rows.values) {
    for (final info in row) {
      placed.add(info.person.id);
    }
  }

  for (final union in tree.unions) {
    // Unions posées ailleurs (ex : enclos des unions du sujet, maquette 8a).
    if (excludeUnionIds.contains(union.id)) continue;
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

// ═══════════════════════════════════════════════════════════
// Mode FOYERS POLYGAMES (maquette 2a)
// ═══════════════════════════════════════════════════════════

// Géométrie — base d'espacement 8 px. Cartes standard ~230×84 (centres).
const double _foyerBoxW = 250.0; // largeur d'une boîte foyer
const double _foyerSlotW = 274.0; // boîte 250 + gouttière 24 → ~250 px utiles
const double _foyerGroupGap = 80.0; // écart horizontal entre deux groupes
const double _cardHalfH = 42.0; // demi-hauteur de carte standard (84 px)
const double _chiefToWifeV = 170.0; // centre chef → centre rangée épouses
const double _wifeToBoxV = 28.0; // bas de carte épouse → haut de boîte
const double _miniCardH = 56.0; // hauteur d'une mini-carte enfant empilée
const double _boxPad = 12.0; // padding interne de la boîte
const double _boxHeaderH = 26.0; // en-tête « FOYER MAAH · 3 ENFANTS »

/// Couleurs de foyer/union, cycle modulo (maquette 6a) :
/// rang 1 → or, 2 → rose, 3 → vert, 4 → azure.
const List<Color> _foyerColors = [
  GwTokens.gold,
  GwTokens.rose,
  GwTokens.sage,
  GwTokens.azure,
];

/// Une épouse d'un groupe foyers, avec son union et SES enfants (rattachés
/// via union.id / motherId — jamais mélangés entre co-épouses).
class _FoyerWife {
  final GenealogyUnion union;
  final PersonGenealogy wife;
  final List<PersonGenealogy> children;

  const _FoyerWife(this.union, this.wife, this.children);
}

/// Un groupe « foyers » : un mari (chef) et ses épouses ordonnées par
/// unionOrder, chacune avec ses enfants.
class _FoyerGroup {
  final PersonGenealogy chief;
  final List<_FoyerWife> wives;

  const _FoyerGroup(this.chief, this.wives);
}

/// Toutes les personnes connues de l'arbre, indexées par id (sujet, parents,
/// grands-parents, oncles, fratrie, enfants + conjoints embarqués des unions).
Map<String, PersonGenealogy> _allPersons(FamilyTree tree) {
  final map = <String, PersonGenealogy>{};
  void add(PersonGenealogy? p) {
    if (p != null) map.putIfAbsent(p.id, () => p);
  }

  add(tree.subject);
  for (final p in [
    ...tree.father,
    ...tree.mother,
    ...tree.paternalGP,
    ...tree.maternalGP,
    ...tree.uncles,
    ...tree.children,
  ]) {
    add(p);
  }
  for (final s in tree.siblings) {
    add(s.person);
  }
  for (final u in tree.unions) {
    add(u.husband);
    add(u.wife);
  }
  return map;
}

/// Détecte les groupes « foyers » : chaque personne masculine (mari des
/// unions) ayant ≥ 2 unions dans tree.unions, triées par unionOrder.
///
/// Ne s'active que si le SUJET est concerné (chef, épouse ou enfant d'un
/// foyer) : sinon on retombe sur le rendu 1a, où les co-épouses des ancêtres
/// restent visibles via [_ensureUnionSpousesPlaced] — le sujet ne disparaît
/// jamais de son propre arbre.
List<_FoyerGroup> _detectFoyerGroups(FamilyTree tree) {
  final persons = _allPersons(tree);

  // Parents du SUJET : son propre DTO ne porte pas motherId/fatherId (le
  // backend ne les attribue qu'aux enfants) — on passe par tree.father/mother.
  final subjectId = tree.subject.id;
  final subjectFatherIds = {for (final p in tree.father) p.id};
  final subjectMotherIds = {for (final p in tree.mother) p.id};

  // Unions groupées par mari.
  final byHusband = <String, List<GenealogyUnion>>{};
  for (final u in tree.unions) {
    byHusband.putIfAbsent(u.husbandId, () => []).add(u);
  }

  final groups = <_FoyerGroup>[];
  final claimed = <String>{}; // enfants déjà rattachés à un foyer

  for (final entry in byHusband.entries) {
    if (entry.value.length < 2) continue;
    final chief = persons[entry.key];
    if (chief == null) continue; // mari non résolvable → pas de carte possible

    final unions = [...entry.value]
      ..sort((a, b) => a.unionOrder.compareTo(b.unionOrder));
    final wifeIds = unions.map((u) => u.wifeId).toSet();

    final wives = <_FoyerWife>[];
    for (final union in unions) {
      final wife = persons[union.wifeId] ?? union.wife;
      if (wife == null) continue;

      // Enfants de CETTE union (réutilise _belongsToUnion : unionId d'abord,
      // sinon couple exact {mari, épouse} via motherId/fatherId).
      final children = <PersonGenealogy>[];
      for (final p in persons.values) {
        if (p.id == chief.id || wifeIds.contains(p.id)) continue;
        if (claimed.contains(p.id)) continue;
        if (_belongsToUnion(p, union, chief.id, wife.id)) {
          children.add(p);
          claimed.add(p.id);
        }
      }
      // Le SUJET est enfant de cette union si le chef et cette épouse sont
      // ses parents (via tree.father/tree.mother, cf. plus haut).
      if (!claimed.contains(subjectId) &&
          subjectFatherIds.contains(chief.id) &&
          subjectMotherIds.contains(wife.id)) {
        children.add(tree.subject);
        claimed.add(subjectId);
      }

      // Aîné·e d'abord (dates croissantes, inconnues à la fin), puis prénom.
      children.sort((a, b) {
        final da = a.birthDate;
        final db = b.birthDate;
        if (da != null && db != null) return da.compareTo(db);
        if (da != null) return -1;
        if (db != null) return 1;
        return a.firstName.compareTo(b.firstName);
      });
      wives.add(_FoyerWife(union, wife, children));
    }
    if (wives.length < 2) continue; // < 2 épouses plaçables → rendu 1a

    groups.add(_FoyerGroup(chief, wives));
  }

  // Le sujet doit être RÉELLEMENT placé dans un groupe (chef, épouse ou
  // enfant réclamé), sinon rendu 1a — il ne disparaît jamais de son arbre.
  final involvesSubject = claimed.contains(subjectId) ||
      groups.any((g) =>
          g.chief.id == subjectId ||
          g.wives.any((w) => w.wife.id == subjectId));
  if (!involvesSubject) return const [];

  // Groupe du sujet en premier (lecture gauche → droite).
  groups.sort((a, b) {
    bool inGroup(_FoyerGroup g) =>
        g.chief.id == subjectId ||
        g.wives.any((w) =>
            w.wife.id == subjectId ||
            w.children.any((c) => c.id == subjectId));
    final ia = inGroup(a) ? 0 : 1;
    final ib = inGroup(b) ? 0 : 1;
    return ia.compareTo(ib);
  });
  return groups;
}

/// Libellé de pilule d'union : « 1RE UNION · 1968 » (année si connue).
String _unionBadgeLabel(int rank, DateTime? startDate) {
  final ordinal = rank == 1 ? '1RE' : '${rank}E';
  return startDate != null
      ? '$ordinal UNION · ${startDate.year}'
      : '$ordinal UNION';
}

/// Libellé d'en-tête de boîte : « FOYER MAAH · 3 ENFANTS » (prénom en MAJ).
String _foyerBoxLabel(PersonGenealogy wife, int childCount) {
  final name = wife.firstName.trim().toUpperCase();
  final String suffix;
  if (childCount == 0) {
    suffix = 'SANS ENFANT';
  } else if (childCount == 1) {
    suffix = '1 ENFANT';
  } else {
    suffix = '$childCount ENFANTS';
  }
  return 'FOYER $name · $suffix';
}

/// Layout « foyers » (maquette 2a) : chef centré en haut, épouses en rangée
/// (~250 px utiles par foyer), enfants empilés en mini-cartes (56 px) dans une
/// boîte pointillée sous chaque mère. Pas de liens de filiation individuels :
/// la boîte matérialise la fratrie. contentHeight suit la boîte la plus
/// profonde — jamais de chevauchement possible avec un contenu suivant.
///
/// [foyerFilterWifeId] (maquette 2c) : si non-null et connu, seuls le chef et
/// l'épouse filtrée (avec sa boîte) sont posés ; les autres épouses comptent
/// dans [TreeLayout.hiddenFoyerCount]. Filtre inconnu → ignoré (rendu complet).
TreeLayout _computeFoyerLayout(
    FamilyTree tree, List<_FoyerGroup> groups, String? foyerFilterWifeId) {
  final nodes = <LayoutNode>[];
  final links = <LayoutLink>[];
  final nodeMap = <String, LayoutNode>{};
  final unionBadges = <UnionBadge>[];
  final foyerBoxes = <FoyerBox>[];

  // ── Chips-filtres (2c) : TOUTES les épouses, couleur de foyer d'ORIGINE ──
  final foyerChips = <FoyerChipInfo>[];
  for (final group in groups) {
    for (int i = 0; i < group.wives.length; i++) {
      foyerChips.add(FoyerChipInfo(
        wifeId: group.wives[i].wife.id,
        label: group.wives[i].wife.firstName,
        color: _foyerColors[i % _foyerColors.length],
      ));
    }
  }

  // Filtre inconnu (aucune épouse ne matche) → ignoré : rendu complet.
  final bool filterKnown = foyerFilterWifeId != null &&
      foyerChips.any((c) => c.wifeId == foyerFilterWifeId);
  final String? filter = filterKnown ? foyerFilterWifeId : null;
  int hiddenFoyerCount = 0;

  void addNode(LayoutNode node) {
    if (nodeMap.containsKey(node.person.id)) return; // anti-doublon
    nodes.add(node);
    nodeMap[node.person.id] = node;
  }

  double groupLeft = _padding;
  double maxBottom = _topPadding;

  for (final group in groups) {
    // Indices d'ORIGINE des épouses à poser : le filtre 2c ne garde que
    // l'épouse ciblée, mais couleur et rang restent ceux du rendu complet.
    final visibleIdx = <int>[];
    for (int i = 0; i < group.wives.length; i++) {
      if (filter == null || group.wives[i].wife.id == filter) visibleIdx.add(i);
    }
    hiddenFoyerCount += group.wives.length - visibleIdx.length;
    if (visibleIdx.isEmpty) continue; // groupe entièrement masqué par le filtre

    final groupW = visibleIdx.length * _foyerSlotW;
    final chiefX = groupLeft + groupW / 2;
    const chiefY = _topPadding;
    const wifeY = chiefY + _chiefToWifeV;
    final chiefPos = Offset(chiefX, chiefY);

    // ── Chef de famille : carte or pâle + pilule « ♛ CHEF DE FAMILLE » ──
    addNode(LayoutNode(
      person: group.chief,
      position: chiefPos,
      generation: 0,
      type: _nodeType(group.chief, tree.subject.id, NodeType.primaryLineage),
      isSubject: group.chief.id == tree.subject.id,
      isChief: true,
    ));

    for (int slot = 0; slot < visibleIdx.length; slot++) {
      final i = visibleIdx[slot];
      final foyer = group.wives[i];
      final union = foyer.union;
      final color = _foyerColors[i % _foyerColors.length];
      final wifeX = groupLeft + _foyerSlotW / 2 + slot * _foyerSlotW;
      final wifePos = Offset(wifeX, wifeY);
      final ended = !union.isActive;

      // ── Épouse : carte blanche, BORDURE de la couleur du foyer ──
      addNode(LayoutNode(
        person: foyer.wife,
        position: wifePos,
        generation: 1,
        type: _nodeType(foyer.wife, tree.subject.id, NodeType.spouse),
        hasDotPaid: union.isDotPaid,
        isSubject: foyer.wife.id == tree.subject.id,
        isFoyerWife: true,
        foyerColor: color,
        unionInfo: NodeUnionInfo(
          unionId: union.id,
          rank: i + 1, // rang d'affichage « ÉPOUSE 1 / 2 / 3 » (unionOrder trié)
          isPolygamous: true,
          isActive: union.isActive,
          legalRegime: union.legalRegime,
          compliance: unionComplianceFromStatus(union.complianceStatus),
        ),
      ));

      // ── Connecteur d'union chef ↔ épouse, couleur du foyer ──
      links.add(LayoutLink(
        from: chiefPos,
        to: wifePos,
        type: LinkType.union,
        color: color,
        ended: ended,
      ));

      // Pilule-étiquette au MILIEU du connecteur : « 1RE UNION · 1968 ».
      unionBadges.add(UnionBadge(
        position: Offset(wifeX, (chiefY + wifeY) / 2),
        label: _unionBadgeLabel(i + 1, union.startDate),
        color: color,
        ended: ended,
      ));

      // ── Boîte foyer pointillée (padding 12, en-tête 26, 56/enfant) ──
      const boxTop = wifeY + _cardHalfH + _wifeToBoxV;
      final childCount = foyer.children.length;
      final boxH = _boxPad + _boxHeaderH + childCount * _miniCardH + _boxPad;
      final rect =
          Rect.fromLTWH(wifeX - _foyerBoxW / 2, boxTop, _foyerBoxW, boxH);
      foyerBoxes.add(FoyerBox(
        rect: rect,
        color: color,
        label: _foyerBoxLabel(foyer.wife, childCount),
        childCount: childCount,
      ));

      // Petit trait pointillé vertical épouse → boîte (couleur du foyer).
      links.add(LayoutLink(
        from: wifePos,
        to: Offset(wifeX, boxTop),
        type: LinkType.foyerDrop,
        color: color,
        ended: ended,
      ));

      // ── Enfants EMPILÉS en mini-cartes (56 px), PAS de liens filiation ──
      for (int j = 0; j < childCount; j++) {
        final child = foyer.children[j];
        final childY =
            boxTop + _boxPad + _boxHeaderH + j * _miniCardH + _miniCardH / 2;
        addNode(LayoutNode(
          person: child,
          position: Offset(wifeX, childY),
          generation: 2,
          type: _nodeType(child, tree.subject.id, NodeType.primaryLineage),
          isSubject: child.id == tree.subject.id,
          inFoyerBox: true,
          foyerColor: color,
        ));
      }

      if (rect.bottom > maxBottom) maxBottom = rect.bottom;
    }

    groupLeft += groupW + _foyerGroupGap;
  }

  // contentHeight recalculée depuis la boîte la plus profonde : les piles
  // d'enfants ne chevauchent jamais le contenu suivant. contentWidth suit
  // les seuls foyers posés (filtre 2c → largeur réduite).
  final contentW = groupLeft - _foyerGroupGap + _padding;
  final contentH = maxBottom + _padding;

  return TreeLayout(
    nodes: nodes,
    links: links,
    contentWidth: contentW < 600 ? 600 : contentW,
    contentHeight: contentH < 400 ? 400 : contentH,
    nodeMap: nodeMap,
    unionBadges: unionBadges,
    foyerBoxes: foyerBoxes,
    foyerChips: foyerChips,
    hiddenFoyerCount: hiddenFoyerCount,
    foyerMode: true,
  );
}
