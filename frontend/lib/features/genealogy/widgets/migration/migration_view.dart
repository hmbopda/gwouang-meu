import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/genealogy/models/family_tree.dart';
import 'package:gwangmeu/features/genealogy/models/person_genealogy.dart';
import 'package:gwangmeu/features/genealogy/state/migration_journey.dart';
import 'package:gwangmeu/features/genealogy/state/tree_view_state.dart';
import 'package:gwangmeu/features/genealogy/widgets/tree_canvas/tree_toolbar.dart';
import 'package:gwangmeu/features/genealogy/widgets/tree_canvas/tree_zoom_controls.dart';

/// Brun « concession » de la maquette 5a (chip pilier, toggle actif).
const _brown = Color(0xFF3B2A16);
const _onBrown = Color(0xFFF0EBE1);

/// Carte de migration (maquette 5a) — remplace la zone arbre quand
/// `currentView == TreeView.migration`.
///
/// Pas de vraie géographie : les nœuds-villages sont posés à des positions
/// DÉTERMINISTES (fractions de la zone + hash du nom de lieu), jamais
/// superposés. Les trajets or relient les étapes chronologiques, les
/// alliances partent du village-pilier en pointillés rose / vert.
class MigrationView extends ConsumerStatefulWidget {
  const MigrationView({
    super.key,
    required this.tree,
    required this.personId,
  });

  final FamilyTree tree;
  final String personId;

  @override
  ConsumerState<MigrationView> createState() => _MigrationViewState();
}

class _MigrationViewState extends ConsumerState<MigrationView> {
  final TransformationController _transformCtrl = TransformationController();

  /// Toggle « Parcours » (false) / « Toute la famille » (true) — état local.
  bool _familyMode = false;

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  void _zoomIn() {
    final m = _transformCtrl.value.clone();
    m.scaleByDouble(1.2, 1.2, 1.2, 1.0);
    _transformCtrl.value = m;
  }

  void _zoomOut() {
    final m = _transformCtrl.value.clone();
    m.scaleByDouble(0.8, 0.8, 0.8, 1.0);
    _transformCtrl.value = m;
  }

  void _resetZoom() => _transformCtrl.value = Matrix4.identity();

  /// Personne dont on trace le parcours : la sélection courante si elle
  /// existe dans l'arbre, sinon le sujet.
  PersonGenealogy _resolvePerson(String? selectedId) {
    if (selectedId == null) return widget.tree.subject;
    for (final p in _allPersons(widget.tree)) {
      if (p.id == selectedId) return p;
    }
    return widget.tree.subject;
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final selectedId =
        ref.watch(treeViewProvider.select((s) => s.selectedPersonId));
    final currentView =
        ref.watch(treeViewProvider.select((s) => s.currentView));
    final notifier = ref.read(treeViewProvider.notifier);

    final person = _resolvePerson(selectedId);
    final journey = buildMigrationJourney(widget.tree, person);
    final firstName =
        person.firstName.trim().isEmpty ? '?' : person.firstName.trim();

    return Container(
      color: t.ink,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentSize = Size(
            math.max(constraints.maxWidth, 980),
            math.max(constraints.maxHeight, 620),
          );
          final geo = _buildGeometry(
            journey: journey,
            familyMode: _familyMode,
            size: contentSize,
            tokens: t,
          );

          return Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  transformationController: _transformCtrl,
                  constrained: false,
                  boundaryMargin: const EdgeInsets.all(200),
                  minScale: 0.4,
                  maxScale: 2.5,
                  child: RepaintBoundary(
                    child: SizedBox(
                      width: contentSize.width,
                      height: contentSize.height,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Fond pointillé discret + trajets/alliances.
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _MigrationMapPainter(
                                curves: geo.curves,
                                dotColor: t.line.withValues(alpha: 0.5),
                              ),
                            ),
                          ),

                          // Nœuds-villages.
                          for (final node in geo.nodes)
                            _VillageNodeWidget(
                              key: ValueKey('village-${node.key}'),
                              node: node,
                              pilierConcession: journey.pilierConcession,
                            ),

                          // Petits nœuds membres (mode famille).
                          for (final dot in geo.members)
                            _MemberDotWidget(
                              key: ValueKey('member-${dot.personId}'),
                              dot: dot,
                            ),

                          // Pilules-étiquettes des trajets.
                          for (final chip in geo.chips)
                            Positioned(
                              left: chip.pos.dx,
                              top: chip.pos.dy,
                              child: FractionalTranslation(
                                translation: const Offset(-0.5, -0.5),
                                child:
                                    _RouteChipWidget(label: chip.label),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Barre flottante (haut) : même rangée que tree_canvas —
              // TreeToolbar + pilule « N ÉTAPES · M ALLIANCES » + toggle
              // « Parcours / Toute la famille » à la place des boutons
              // d'action de l'arbre. ──
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 700;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TreeToolbar(
                                  currentView: currentView,
                                  onViewChanged: notifier.changeView,
                                  compact: compact,
                                ),
                                const SizedBox(width: 16),
                                _StatsPill(
                                  steps: journey.steps.length,
                                  alliances: journey.alliances.length,
                                ),
                                const SizedBox(width: 8),
                                _ModeToggle(
                                  familyMode: _familyMode,
                                  onChanged: (v) =>
                                      setState(() => _familyMode = v),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Micro-légende : origine = ancrage, résidence
                        // = évolution.
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 16, right: 16, top: 6),
                          child: Text(
                            'L\'arbre s\'ancre sur l\'origine — la '
                            'résidence trace l\'évolution.',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GwType.ui(
                                fontSize: 11.5, color: t.stoneDim),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // ── Légende (bas gauche) ──
              Positioned(
                bottom: 16,
                left: 20,
                child: _MigrationLegend(firstName: firstName),
              ),

              // ── Zoom (bas droite) ──
              Positioned(
                bottom: 16,
                right: 16,
                child: TreeZoomControls(
                  onZoomIn: _zoomIn,
                  onZoomOut: _zoomOut,
                  onReset: _resetZoom,
                ),
              ),

              // ── État vide ──
              if (geo.nodes.isEmpty)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: t.inkCard,
                      borderRadius: BorderRadius.circular(GwTokens.rCard),
                      border: Border.all(color: t.goldLine),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Symbols.travel_explore,
                            size: 44, color: t.stoneDim),
                        const SizedBox(height: 12),
                        Text(
                          'Aucun lieu connu',
                          style: GwType.display(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: t.stone),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Renseignez les lieux de naissance pour '
                          'tracer la migration',
                          style: GwType.ui(fontSize: 13, color: t.stoneDim),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
//  Pilule « N ÉTAPES · M ALLIANCES » (bordée or, fond blanc)
// ═════════════════════════════════════════════════════════════

/// Remplace les boutons d'action de l'arbre dans la barre flottante :
/// même hauteur (44 px) que les `_ActionPill` de tree_canvas.
class _StatsPill extends StatelessWidget {
  const _StatsPill({required this.steps, required this.alliances});

  final int steps;
  final int alliances;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.inkCard,
        borderRadius: BorderRadius.circular(GwTokens.rPill),
        border: Border.all(color: t.goldLine),
      ),
      child: Text(
        '$steps ÉTAPES · $alliances ALLIANCES',
        maxLines: 1,
        style: GwType.mono(
            fontSize: 9.5, letterSpacing: 1.5, color: t.goldText),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
//  Toggle « Parcours / Toute la famille »
// ═════════════════════════════════════════════════════════════

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.familyMode, required this.onChanged});

  final bool familyMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.inkCard,
        borderRadius: BorderRadius.circular(GwTokens.rPill),
        border: Border.all(color: t.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(t, 'Parcours', selected: !familyMode, value: false),
          _segment(t, 'Toute la famille', selected: familyMode, value: true),
        ],
      ),
    );
  }

  Widget _segment(GwTokens t, String label,
      {required bool selected, required bool value}) {
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? _brown : Colors.transparent,
          borderRadius: BorderRadius.circular(GwTokens.rPill),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GwType.ui(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? _onBrown : t.stoneFaint,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
//  Géométrie de la carte (positions déterministes, sans géo)
// ═════════════════════════════════════════════════════════════

class _SubLabel {
  const _SubLabel(this.text, this.color);
  final String text;
  final Color color;
}

class _PlaceNode {
  _PlaceNode({
    required this.key,
    required this.place,
    required this.diameter,
    required this.ringColor,
    required this.icon,
    this.isPilier = false,
  });

  final String key;
  final String place;
  final double diameter;
  final Color ringColor;
  final IconData icon;
  final bool isPilier;

  Offset pos = Offset.zero;
  final List<_SubLabel> subLabels = [];
}

class _RouteChip {
  const _RouteChip(this.pos, this.label);
  final Offset pos;
  final String label;
}

class _CurveSpec {
  const _CurveSpec({
    required this.p0,
    required this.control,
    required this.p1,
    required this.color,
    required this.dashed,
    required this.width,
  });

  final Offset p0;
  final Offset control;
  final Offset p1;
  final Color color;
  final bool dashed;
  final double width;
}

class _MemberDot {
  const _MemberDot({
    required this.personId,
    required this.pos,
    required this.initials,
    required this.name,
  });

  final String personId;
  final Offset pos;
  final String initials;
  final String name;
}

class _MapGeometry {
  const _MapGeometry({
    required this.nodes,
    required this.curves,
    required this.chips,
    required this.members,
  });

  final List<_PlaceNode> nodes;
  final List<_CurveSpec> curves;
  final List<_RouteChip> chips;
  final List<_MemberDot> members;
}

String _normPlace(String s) => s.trim().toLowerCase();

/// Hash déterministe d'un nom de lieu (jitter reproductible).
int _placeHash(String s) {
  var h = 17;
  for (final c in _normPlace(s).codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return h;
}

String _stepMonoLabel(MigrationStep step) {
  final base = switch (step.kind) {
    MigrationStepKind.naissance => 'NAISSANCE',
    MigrationStepKind.retour => 'RETOUR',
    MigrationStepKind.installation => 'INSTALLATION',
    MigrationStepKind.residence => 'AUJOURD\'HUI',
  };
  return step.year != null ? '$base · ${step.year}' : base;
}

_MapGeometry _buildGeometry({
  required MigrationJourney journey,
  required bool familyMode,
  required Size size,
  required GwTokens tokens,
}) {
  final byKey = <String, _PlaceNode>{};
  final order = <_PlaceNode>[];
  final fractions = <String, Offset>{};

  // Emplacements « alliances » (haut-droit, bas-centre…), puis de secours.
  const allianceSlots = <Offset>[
    Offset(0.62, 0.22),
    Offset(0.40, 0.85),
    Offset(0.84, 0.32),
    Offset(0.16, 0.34),
  ];
  const extraSlots = <Offset>[
    Offset(0.30, 0.18),
    Offset(0.86, 0.74),
    Offset(0.12, 0.54),
    Offset(0.48, 0.12),
    Offset(0.90, 0.50),
    Offset(0.26, 0.90),
    Offset(0.72, 0.88),
    Offset(0.08, 0.78),
  ];
  var allianceSlot = 0;
  var extraSlot = 0;

  Offset nextExtraSlot(String place) {
    if (extraSlot < extraSlots.length) return extraSlots[extraSlot++];
    // Au-delà des slots prévus : position dérivée du hash.
    final h = _placeHash(place);
    return Offset(0.15 + (h % 71) / 100.0, 0.15 + ((h ~/ 71) % 71) / 100.0);
  }

  _PlaceNode ensure(
    String place, {
    required double diameter,
    required Color ring,
    required IconData icon,
    bool pilier = false,
    Offset? wantedFraction,
  }) {
    final key = _normPlace(place);
    final existing = byKey[key];
    if (existing != null) return existing;
    final node = _PlaceNode(
      key: key,
      place: place,
      diameter: diameter,
      ringColor: ring,
      icon: icon,
      isPilier: pilier,
    );
    byKey[key] = node;
    order.add(node);
    fractions[key] = wantedFraction ?? nextExtraSlot(place);
    return node;
  }

  // ── 1. Nœuds ────────────────────────────────────────────────
  // Pilier (= ORIGINE) : le plus gros, anneau double or, centre-haut
  // décalé. Sous-libellé « {région} · {pays d'origine} » quand dispo.
  final pilierPlace = journey.pilierPlace;
  if (pilierPlace != null) {
    final pilierNode = ensure(
      pilierPlace,
      diameter: 90,
      ring: GwTokens.gold,
      icon: Symbols.home_work,
      pilier: true,
      wantedFraction: const Offset(0.55, 0.38),
    );
    final originDetail = journey.pilierOriginDetail;
    if (originDetail != null) {
      pilierNode.subLabels
          .add(_SubLabel(originDetail.toUpperCase(), tokens.stoneDim));
    }
  }

  // Étapes : naissance bas-gauche, résidence actuelle à droite.
  for (var i = 0; i < journey.steps.length; i++) {
    final step = journey.steps[i];
    Offset? wanted;
    if (step.kind == MigrationStepKind.naissance) {
      wanted = const Offset(0.22, 0.72);
    } else if (step.kind == MigrationStepKind.residence) {
      wanted = const Offset(0.68, 0.62);
    }
    final node = ensure(
      step.place,
      diameter: 64,
      ring: GwTokens.gold,
      icon: Symbols.location_city,
      wantedFraction: wanted,
    );
    if (!node.isPilier) {
      node.subLabels.add(_SubLabel(
        _stepMonoLabel(step),
        step.kind == MigrationStepKind.residence
            ? tokens.sageText
            : tokens.goldText,
      ));
    }
  }

  // Alliances : nœuds plus petits, anneau rose (maternelle) / vert (union).
  for (final alliance in journey.alliances) {
    final color = alliance.kind == AllianceKind.maternelle
        ? GwTokens.rose
        : GwTokens.sage;
    Offset? wanted;
    if (allianceSlot < allianceSlots.length &&
        !byKey.containsKey(_normPlace(alliance.place))) {
      wanted = allianceSlots[allianceSlot++];
    }
    final node = ensure(
      alliance.place,
      diameter: 56,
      ring: color,
      icon: Symbols.villa,
      wantedFraction: wanted,
    );
    node.subLabels.add(_SubLabel(
      alliance.kind == AllianceKind.maternelle
          ? 'ALLIANCE MATERNELLE'
          : 'ALLIANCE PAR UNION',
      color,
    ));
  }

  // Villages des membres (mode « Toute la famille ») : nœuds neutres.
  final familyGroups = <String, List<FamilyPlace>>{};
  if (familyMode) {
    for (final fp in journey.familyPlaces) {
      familyGroups.putIfAbsent(_normPlace(fp.place), () => []).add(fp);
    }
    for (final entry in familyGroups.entries) {
      ensure(
        entry.value.first.place,
        diameter: 44,
        ring: tokens.stoneFaint,
        icon: Symbols.location_city,
      );
    }
  }

  // ── 2. Positions en pixels (jitter par hash du lieu) ───────
  const marginX = 120.0;
  const marginTop = 100.0;
  const marginBottom = 160.0;
  for (final node in order) {
    final f = fractions[node.key]!;
    final h = _placeHash(node.place);
    final jx = ((h % 15) - 7) * 0.004; // ± 0.028
    final jy = (((h ~/ 15) % 15) - 7) * 0.003; // ± 0.021
    node.pos = Offset(
      ((f.dx + jx) * size.width)
          .clamp(marginX, size.width - marginX),
      ((f.dy + jy) * size.height)
          .clamp(marginTop, size.height - marginBottom),
    );
  }

  // ── 3. Anti-superposition : min 120 px, ajustement par pas ─
  const minDist = 130.0;
  for (var iter = 0; iter < 40; iter++) {
    var moved = false;
    for (var i = 0; i < order.length; i++) {
      for (var j = i + 1; j < order.length; j++) {
        final a = order[i];
        final b = order[j];
        var delta = b.pos - a.pos;
        var dist = delta.distance;
        if (dist >= minDist) continue;
        if (dist < 1) {
          // Superposition exacte : direction dérivée du hash.
          final angle = (_placeHash(b.place) % 360) * math.pi / 180;
          delta = Offset(math.cos(angle), math.sin(angle));
          dist = 1;
        }
        final push = delta / dist * (minDist - dist + 12);
        b.pos = Offset(
          (b.pos.dx + push.dx).clamp(marginX, size.width - marginX),
          (b.pos.dy + push.dy).clamp(marginTop, size.height - marginBottom),
        );
        moved = true;
      }
    }
    if (!moved) break;
  }

  // ── 4. Trajets or (étapes consécutives) + pilules-étiquettes ─
  final curves = <_CurveSpec>[];
  final chips = <_RouteChip>[];
  for (var i = 0; i + 1 < journey.steps.length; i++) {
    final from = byKey[_normPlace(journey.steps[i].place)];
    final to = byKey[_normPlace(journey.steps[i + 1].place)];
    if (from == null || to == null || identical(from, to)) continue;

    final p0 = from.pos;
    final p1 = to.pos;
    final dir = p1 - p0;
    final len = dir.distance;
    if (len < 1) continue;
    final normal = Offset(-dir.dy, dir.dx) / len;
    final sign = i.isEven ? -1.0 : 1.0;
    final control = Offset(
      (p0.dx + p1.dx) / 2 + normal.dx * sign * math.min(70, len * 0.25),
      (p0.dy + p1.dy) / 2 + normal.dy * sign * math.min(70, len * 0.25),
    );
    curves.add(_CurveSpec(
      p0: p0,
      control: control,
      p1: p1,
      color: GwTokens.gold,
      dashed: false,
      width: 2,
    ));

    // Milieu de la quadratique (t = 0.5) : 0.25·p0 + 0.5·c + 0.25·p1.
    final dest = journey.steps[i + 1];
    final title = dest.title.toUpperCase();
    chips.add(_RouteChip(
      Offset(
        0.25 * p0.dx + 0.5 * control.dx + 0.25 * p1.dx,
        0.25 * p0.dy + 0.5 * control.dy + 0.25 * p1.dy,
      ),
      dest.year != null ? '${dest.year} · $title' : title,
    ));
  }

  // ── 5. Alliances : pointillés depuis le pilier ──────────────
  final origin = pilierPlace != null
      ? byKey[_normPlace(pilierPlace)]
      : (order.isNotEmpty ? order.first : null);
  if (origin != null) {
    for (final alliance in journey.alliances) {
      final target = byKey[_normPlace(alliance.place)];
      if (target == null || identical(target, origin)) continue;
      final p0 = origin.pos;
      final p1 = target.pos;
      final dir = p1 - p0;
      final len = dir.distance;
      if (len < 1) continue;
      final normal = Offset(-dir.dy, dir.dx) / len;
      curves.add(_CurveSpec(
        p0: p0,
        control: Offset(
          (p0.dx + p1.dx) / 2 + normal.dx * 30,
          (p0.dy + p1.dy) / 2 + normal.dy * 30,
        ),
        p1: p1,
        color: alliance.kind == AllianceKind.maternelle
            ? GwTokens.rose
            : GwTokens.sage,
        dashed: true,
        width: 1.6,
      ));
    }
  }

  // ── 6. Membres (mode famille) : éventail autour du village ──
  final members = <_MemberDot>[];
  if (familyMode) {
    // Angles en degrés (écran : y vers le bas, 270° = au-dessus).
    const fanAngles = <double>[150, 30, 210, 330, 270, 180, 0, 240, 300, 120];
    for (final entry in familyGroups.entries) {
      final node = byKey[entry.key];
      if (node == null) continue;
      for (var i = 0; i < entry.value.length; i++) {
        final person = entry.value[i].person;
        final ring = 1 + i ~/ fanAngles.length;
        final angle =
            fanAngles[i % fanAngles.length] * math.pi / 180;
        final radius = node.diameter / 2 + 34.0 + (ring - 1) * 52.0;
        final first = person.firstName.trim();
        final last = person.lastName.trim();
        members.add(_MemberDot(
          personId: person.id,
          pos: node.pos +
              Offset(math.cos(angle) * radius, math.sin(angle) * radius),
          initials: [
            if (first.isNotEmpty) first[0].toUpperCase(),
            if (last.isNotEmpty) last[0].toUpperCase(),
          ].join(),
          name: first.isEmpty ? last : first,
        ));
      }
    }
  }

  return _MapGeometry(
    nodes: order,
    curves: curves,
    chips: chips,
    members: members,
  );
}

// ═════════════════════════════════════════════════════════════
//  Painter : fond pointillé + trajets or + alliances pointillées
// ═════════════════════════════════════════════════════════════

class _MigrationMapPainter extends CustomPainter {
  const _MigrationMapPainter({required this.curves, required this.dotColor});

  final List<_CurveSpec> curves;
  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Fond ivoire pointillé très discret.
    final dot = Paint()..color = dotColor;
    for (double y = 18; y < size.height; y += 28) {
      for (double x = 18; x < size.width; x += 28) {
        canvas.drawCircle(Offset(x, y), 1, dot);
      }
    }

    for (final c in curves) {
      final path = Path()
        ..moveTo(c.p0.dx, c.p0.dy)
        ..quadraticBezierTo(c.control.dx, c.control.dy, c.p1.dx, c.p1.dy);
      final paint = Paint()
        ..color = c.color
        ..strokeWidth = c.width
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(c.dashed ? _dashPath(path, 5, 6) : path, paint);
    }
  }

  /// Découpe un `Path` en tirets via sa longueur d'arc (PathMetric).
  static Path _dashPath(Path source, double dashLen, double gapLen) {
    final result = Path();
    for (final metric in source.computeMetrics()) {
      double d = 0;
      bool draw = true;
      while (d < metric.length) {
        final end = (d + (draw ? dashLen : gapLen)).clamp(0.0, metric.length);
        if (draw) result.addPath(metric.extractPath(d, end), Offset.zero);
        d = end;
        draw = !draw;
      }
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant _MigrationMapPainter oldDelegate) =>
      oldDelegate.curves != curves || oldDelegate.dotColor != dotColor;
}

// ═════════════════════════════════════════════════════════════
//  Nœud-village
// ═════════════════════════════════════════════════════════════

class _VillageNodeWidget extends StatelessWidget {
  const _VillageNodeWidget({
    super.key,
    required this.node,
    this.pilierConcession,
  });

  final _PlaceNode node;
  final String? pilierConcession;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final d = node.diameter;
    final iconColor = node.isPilier
        ? _brown
        : (node.ringColor == GwTokens.gold ? t.goldText : node.ringColor);

    return Positioned(
      left: node.pos.dx - 90,
      top: node.pos.dy - d / 2,
      child: SizedBox(
        width: 180,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cercle à anneau (double pour le pilier).
            Container(
              width: d,
              height: d,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: t.inkCard,
                border: Border.all(
                  color: node.ringColor,
                  width: node.isPilier ? 3 : 2.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: node.isPilier
                  ? Container(
                      margin: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: GwTokens.gold.withValues(alpha: 0.6),
                            width: 1.5),
                      ),
                      child: Icon(node.icon,
                          size: d * 0.4, color: iconColor),
                    )
                  : Icon(node.icon, size: d * 0.42, color: iconColor),
            ),
            const SizedBox(height: 6),

            // Étiquette : chip brune pour le pilier (+ sous-libellé
            // « région · pays d'origine »), sinon nom + méta.
            if (node.isPilier) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _brown,
                  borderRadius: BorderRadius.circular(GwTokens.rPill),
                ),
                child: Text(
                  pilierConcession != null
                      ? '${node.place.toUpperCase()} · PILIER · '
                          'CONCESSION ${pilierConcession!.toUpperCase()}'
                      : '${node.place.toUpperCase()} · PILIER',
                  textAlign: TextAlign.center,
                  style: GwType.mono(
                    fontSize: 9,
                    letterSpacing: 1.5,
                    color: GwTokens.goldLight,
                    height: 1.5,
                  ),
                ),
              ),
              for (final sub in node.subLabels)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    sub.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GwType.mono(
                        fontSize: 8.5,
                        letterSpacing: 1.5,
                        color: sub.color),
                  ),
                ),
            ] else ...[
              Text(
                node.place,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GwType.ui(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: t.stone),
              ),
              for (final sub in node.subLabels)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    sub.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GwType.mono(
                        fontSize: 8.5,
                        letterSpacing: 1.5,
                        color: sub.color),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
//  Petit nœud membre (mode « Toute la famille »)
// ═════════════════════════════════════════════════════════════

class _MemberDotWidget extends StatelessWidget {
  const _MemberDotWidget({super.key, required this.dot});

  final _MemberDot dot;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Positioned(
      left: dot.pos.dx - 40,
      top: dot.pos.dy - 18,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: t.inkCard,
                border: Border.all(color: t.lineMid, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                dot.initials.isEmpty ? '?' : dot.initials,
                style: GwType.display(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: t.stoneMid),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              dot.name.isEmpty ? '?' : dot.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GwType.ui(fontSize: 10, color: t.stoneDim),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
//  Pilule-étiquette de trajet (« 1969 · RETOUR À LA CONCESSION »)
// ═════════════════════════════════════════════════════════════

class _RouteChipWidget extends StatelessWidget {
  const _RouteChipWidget({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: t.inkCard,
        borderRadius: BorderRadius.circular(GwTokens.rPill),
        border: Border.all(color: GwTokens.gold.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: GwType.mono(
            fontSize: 9, letterSpacing: 1.5, color: t.goldText),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
//  Légende
// ═════════════════════════════════════════════════════════════

class _MigrationLegend extends StatelessWidget {
  const _MigrationLegend({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: t.ink.withValues(alpha: 0.88),
        border: Border.all(color: t.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // — Parcours (trait or plein).
          Container(
            width: 16,
            height: 2.5,
            decoration: BoxDecoration(
              color: GwTokens.gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text('Parcours de $firstName',
              style: GwType.ui(fontSize: 12, color: t.stoneMid)),
          const SizedBox(width: 14),

          // ⋯ Alliances (pointillés rose / vert).
          for (final c in const [GwTokens.rose, GwTokens.sage, GwTokens.rose])
            Container(
              width: 4,
              height: 2.5,
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          const SizedBox(width: 4),
          Text('Alliances', style: GwType.ui(fontSize: 12, color: t.stoneMid)),
          const SizedBox(width: 14),

          // 🏛 Village-pilier (anneau double or).
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: GwTokens.gold, width: 2),
            ),
            child: Container(
              margin: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: GwTokens.gold.withValues(alpha: 0.6), width: 1),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text('Village-pilier',
              style: GwType.ui(fontSize: 12, color: t.stoneMid)),
        ],
      ),
    );
  }
}

// ── Helpers ─────────────────────────────────────────────────

List<PersonGenealogy> _allPersons(FamilyTree tree) => [
      tree.subject,
      ...tree.father,
      ...tree.mother,
      ...tree.paternalGP,
      ...tree.maternalGP,
      ...tree.siblings.map((s) => s.person),
      ...tree.children,
      ...tree.cousins,
      ...tree.uncles,
      for (final u in tree.unions) ...[
        if (u.husband != null) u.husband!,
        if (u.wife != null) u.wife!,
      ],
    ];
