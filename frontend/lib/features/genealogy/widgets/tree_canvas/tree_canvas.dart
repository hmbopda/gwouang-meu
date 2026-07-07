import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/genealogy/models/family_tree.dart';
import 'package:gwangmeu/features/genealogy/state/tree_layout_provider.dart';
import 'package:gwangmeu/features/genealogy/state/tree_view_state.dart';
import 'package:gwangmeu/features/genealogy/widgets/tree_canvas/tree_link_painter.dart';
import 'package:gwangmeu/features/genealogy/widgets/dialogs/person_detail_popup.dart';
import 'package:gwangmeu/features/genealogy/widgets/tree_canvas/tree_node_tooltip.dart';
import 'package:gwangmeu/features/genealogy/widgets/tree_canvas/tree_node_widget.dart';
import 'package:gwangmeu/features/genealogy/widgets/tree_canvas/tree_toolbar.dart';
import 'package:gwangmeu/features/genealogy/widgets/tree_canvas/tree_zoom_controls.dart';

/// Canvas central « Rivière » (#2c) : strates de générations en bandes douces,
/// nœuds-cartes colorés par lignée, liens bézier calmes, légende des lignées.
class TreeCanvas extends ConsumerStatefulWidget {
  final FamilyTree tree;
  final String personId;
  final VoidCallback? onAddParent;
  final VoidCallback? onAddChild;
  final VoidCallback? onAddUnion;
  final VoidCallback? onExport;

  /// Affiche la légende des lignées (desktop).
  final bool showLegend;

  const TreeCanvas({
    super.key,
    required this.tree,
    required this.personId,
    this.onAddParent,
    this.onAddChild,
    this.onAddUnion,
    this.onExport,
    this.showLegend = false,
  });

  @override
  ConsumerState<TreeCanvas> createState() => _TreeCanvasState();
}

class _TreeCanvasState extends ConsumerState<TreeCanvas> {
  final TransformationController _transformCtrl = TransformationController();
  String? _tooltipNodeId;

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

  void _resetZoom() {
    _transformCtrl.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    // select() : rebuild uniquement si le layout géométrique ou la vue changent
    final layout = ref.watch(treeLayoutProvider(widget.tree));
    final selectedPersonId =
        ref.watch(treeViewProvider.select((s) => s.selectedPersonId));
    final currentView =
        ref.watch(treeViewProvider.select((s) => s.currentView));
    final notifier = ref.read(treeViewProvider.notifier);

    return Container(
      color: t.ink,
      child: Stack(
        children: [
          // ── Interactive pan/zoom area ──
          InteractiveViewer(
            transformationController: _transformCtrl,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(200),
            minScale: 0.3,
            maxScale: 3.0,
            child: SizedBox(
              width: layout.contentWidth,
              height: layout.contentHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Strates de générations — bandes douces + labels mono
                  Positioned.fill(
                    child: CustomPaint(painter: _StrataPainter(layout)),
                  ),

                  // Links (Bézier curves)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: TreeLinkPainter(
                        links: layout.links,
                        selectedPersonId: selectedPersonId,
                      ),
                    ),
                  ),

                  // Nodes — chaque _NodeSlot observe son propre isSelected/isHovered
                  ...layout.nodes.map((node) => _NodeSlot(
                        key: ValueKey(node.person.id),
                        node: node,
                        notifier: notifier,
                        tooltipNodeId: _tooltipNodeId,
                        onTooltipChanged: (id) =>
                            setState(() => _tooltipNodeId = id),
                      )),

                  // Tooltip overlay
                  if (_tooltipNodeId != null &&
                      layout.nodeMap.containsKey(_tooltipNodeId))
                    _buildTooltip(layout.nodeMap[_tooltipNodeId]!, notifier),
                ],
              ),
            ),
          ),

          // ── Floating toolbar + action buttons (top) ──
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 700;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
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
                        if (widget.onAddParent != null) ...[
                          _ActionPill(
                            icon: Symbols.person_add,
                            label: 'Ajouter un parent',
                            onTap: widget.onAddParent!,
                            compact: compact,
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (widget.onAddUnion != null) ...[
                          _ActionPill(
                            icon: Symbols.favorite,
                            label: 'Ajouter une union',
                            onTap: widget.onAddUnion!,
                            compact: compact,
                            outlined: true,
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (widget.onExport != null)
                          _ActionPill(
                            icon: Symbols.download,
                            label: 'Exporter',
                            onTap: widget.onExport!,
                            compact: compact,
                            outlined: true,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Légende des lignées (desktop, bas gauche) ──
          if (widget.showLegend)
            Positioned(
              bottom: 16,
              left: 20,
              child: _LineageLegend(),
            ),

          // ── Zoom controls (bottom right) ──
          Positioned(
            bottom: 16,
            right: 16,
            child: TreeZoomControls(
              onZoomIn: _zoomIn,
              onZoomOut: _zoomOut,
              onReset: _resetZoom,
            ),
          ),

          // ── Empty state ──
          if (layout.nodes.length <= 1)
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
                    Icon(Symbols.family_history,
                        size: 48, color: t.stoneDim),
                    const SizedBox(height: 12),
                    Text(
                      'Votre rivière commence ici',
                      style: GwType.display(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: t.stone),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ajoutez vos parents pour faire couler la lignée',
                      style: GwType.ui(fontSize: 13, color: t.stoneDim),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTooltip(LayoutNode node, TreeViewNotifier notifier) {
    return Positioned(
      left: node.position.dx + 70,
      top: node.position.dy - 60,
      child: MouseRegion(
        onEnter: (_) {},
        onExit: (_) {
          // Defer to next frame to avoid mouse_tracker assertion on Flutter Web
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _tooltipNodeId = null);
          });
        },
        child: TreeNodeTooltip(
          node: node,
          onViewDetails: () {
            notifier.selectPerson(node.person.id);
            setState(() => _tooltipNodeId = null);
            showDialog(
              context: context,
              builder: (_) => PersonDetailPopup(person: node.person),
            );
          },
          onAddParent: () {
            notifier.selectPerson(node.person.id);
            setState(() => _tooltipNodeId = null);
            widget.onAddParent?.call();
          },
          onAddChild: () {
            notifier.selectPerson(node.person.id);
            setState(() => _tooltipNodeId = null);
            widget.onAddChild?.call();
          },
        ),
      ),
    );
  }
}

/// Pilule d'action or (pleine ou contour), cible ≥ 40 px.
class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool compact;
  final bool outlined;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.compact = false,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = outlined ? GwTokens.gold : const Color(0xFF0C0B0F);

    final pill = Material(
      color: outlined ? GwTokens.dark.inkCard : GwTokens.gold,
      borderRadius: BorderRadius.circular(GwTokens.rPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GwTokens.rPill),
        child: Container(
          height: 44,
          padding: EdgeInsets.symmetric(horizontal: compact ? 13 : 18),
          decoration: outlined
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(GwTokens.rPill),
                  border: Border.all(
                      color: GwTokens.gold.withValues(alpha: 0.35)),
                )
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: fg),
              if (!compact) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GwType.ui(
                      fontSize: 13.5,
                      fontWeight: outlined ? FontWeight.w600 : FontWeight.w700,
                      color: fg),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (compact) {
      return Tooltip(message: label, child: pill);
    }
    return pill;
  }
}

/// Légende : lignées, affluent IA, ancêtres ✦.
class _LineageLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: t.ink.withValues(alpha: 0.85),
        border: Border.all(color: t.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _item(t, GwTokens.gold, 'Lignée du sujet'),
          const SizedBox(width: 14),
          _item(t, GwTokens.rose, 'Lignée alliée'),
          const SizedBox(width: 14),
          _item(t, GwTokens.sage, 'Affluent IA', dashed: true),
          const SizedBox(width: 14),
          _item(t, t.stoneFaint, 'Ancêtres ✦'),
        ],
      ),
    );
  }

  Widget _item(GwTokens t, Color color, String label, {bool dashed = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: GwType.ui(fontSize: 12, color: t.stoneMid)),
      ],
    );
  }
}

/// Widget isolé pour un node : observe UNIQUEMENT isSelected et isHovered
/// pour ce node. Évite le rebuild de tous les nodes à chaque clic.
class _NodeSlot extends ConsumerWidget {
  final LayoutNode node;
  final TreeViewNotifier notifier;
  final String? tooltipNodeId;
  final ValueChanged<String?> onTooltipChanged;

  const _NodeSlot({
    super.key,
    required this.node,
    required this.notifier,
    required this.tooltipNodeId,
    required this.onTooltipChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(
      treeViewProvider.select((s) => s.selectedPersonId == node.person.id),
    );
    final isHovered = ref.watch(
      treeViewProvider.select((s) => s.hoveredPersonId == node.person.id),
    );

    final width = node.isSubject ? kTreeSubjectWidth : kTreeNodeWidth;

    return Positioned(
      left: node.position.dx - width / 2,
      top: node.position.dy - 40,
      child: TreeNodeWidget(
        node: node,
        isSelected: isSelected,
        isHovered: isHovered,
        onTap: () {
          notifier.selectPerson(node.person.id);
          onTooltipChanged(null);
        },
        onHover: (hovering) {
          if (hovering) {
            notifier.hoverPerson(node.person.id);
            onTooltipChanged(node.person.id);
          } else {
            notifier.hoverPerson(null);
            Future.delayed(const Duration(milliseconds: 300), () {
              if (tooltipNodeId == node.person.id) {
                onTooltipChanged(null);
              }
            });
          }
        },
      ),
    );
  }
}

/// Strates de générations : bandes douces, séparateurs pointillés,
/// labels mono « GÉNÉRATION N » (or pour la génération du sujet).
class _StrataPainter extends CustomPainter {
  final TreeLayout layout;

  _StrataPainter(this.layout);

  @override
  void paint(Canvas canvas, Size size) {
    if (layout.nodes.isEmpty) return;

    // Générations → bornes Y
    final gens = <int, double>{};
    int? subjectGen;
    for (final n in layout.nodes) {
      gens[n.generation] = n.position.dy;
      if (n.isSubject) subjectGen = n.generation;
    }
    final sorted = gens.keys.toList()..sort();

    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    for (int i = 0; i < sorted.length; i++) {
      final gen = sorted[i];
      final y = gens[gen]!;
      final top = y - 90;
      final isSubjectGen = gen == subjectGen;

      // Bande douce pour la génération du sujet + la première
      if (isSubjectGen || i == 0) {
        final rect = Rect.fromLTWH(0, top, size.width, 180);
        final gradient = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isSubjectGen
              ? [
                  GwTokens.gold.withValues(alpha: 0.05),
                  GwTokens.gold.withValues(alpha: 0.015),
                ]
              : [
                  GwTokens.dark.stoneFaint.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
        );
        canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
      }

      // Séparateur pointillé bas de strate
      final sepY = top + 180;
      double x = 0;
      while (x < size.width) {
        canvas.drawLine(Offset(x, sepY), Offset(x + 4, sepY), dashPaint);
        x += 12;
      }

      // Label mono
      final label = isSubjectGen
          ? 'GÉNÉRATION ${gen + 1} · VOUS'
          : i == 0
              ? 'GÉNÉRATION ${gen + 1} · LES FONDATEURS'
              : 'GÉNÉRATION ${gen + 1}';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: GwType.mono(
            fontSize: 10,
            letterSpacing: 2,
            color: isSubjectGen ? GwTokens.gold : GwTokens.dark.stoneFaint,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(24, top + 14));
    }
  }

  @override
  bool shouldRepaint(covariant _StrataPainter oldDelegate) =>
      oldDelegate.layout != layout;
}
