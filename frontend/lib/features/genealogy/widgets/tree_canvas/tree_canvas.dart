import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/family_tree.dart';
import '../../state/tree_layout_provider.dart';
import '../../state/tree_tokens.dart';
import '../../state/tree_view_state.dart';
import 'tree_link_painter.dart';
import '../dialogs/person_detail_popup.dart';
import 'tree_node_tooltip.dart';
import 'tree_node_widget.dart';
import 'tree_toolbar.dart';
import 'tree_zoom_controls.dart';

/// The main center canvas: interactive tree with pan/zoom, nodes and links.
class TreeCanvas extends ConsumerStatefulWidget {
  final FamilyTree tree;
  final String personId;
  final VoidCallback? onAddParent;
  final VoidCallback? onAddChild;
  final VoidCallback? onAddUnion;
  final VoidCallback? onExport;

  const TreeCanvas({
    super.key,
    required this.tree,
    required this.personId,
    this.onAddParent,
    this.onAddChild,
    this.onAddUnion,
    this.onExport,
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
    final viewState = ref.watch(treeViewProvider);
    final layout = ref.watch(treeLayoutProvider(widget.tree));
    final notifier = ref.read(treeViewProvider.notifier);

    return Container(
      color: T.ink,
      child: Stack(
        children: [
          // ── Grid pattern background ──
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),

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
                  // Links (Bézier curves)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: TreeLinkPainter(
                        links: layout.links,
                        selectedPersonId: viewState.selectedPersonId,
                      ),
                    ),
                  ),

                  // Nodes
                  ...layout.nodes.map((node) {
                    final isSelected = viewState.selectedPersonId == node.person.id;
                    final isHovered = viewState.hoveredPersonId == node.person.id;
                    return Positioned(
                      left: node.position.dx - 60,
                      top: node.position.dy - (node.isSubject ? T.subjectRadius : T.nodeRadius),
                      child: TreeNodeWidget(
                        node: node,
                        isSelected: isSelected,
                        isHovered: isHovered,
                        onTap: () {
                          notifier.selectPerson(node.person.id);
                          setState(() => _tooltipNodeId = null);
                        },
                        onHover: (hovering) {
                          if (hovering) {
                            notifier.hoverPerson(node.person.id);
                            setState(() => _tooltipNodeId = node.person.id);
                          } else {
                            // Deferred — onExit in TreeNodeWidget already defers
                            notifier.hoverPerson(null);
                            Future.delayed(const Duration(milliseconds: 300), () {
                              if (mounted && _tooltipNodeId == node.person.id) {
                                setState(() => _tooltipNodeId = null);
                              }
                            });
                          }
                        },
                      ),
                    );
                  }),

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
                          currentView: viewState.currentView,
                          onViewChanged: notifier.changeView,
                          compact: compact,
                        ),
                        const SizedBox(width: 16),
                        if (widget.onAddParent != null) ...[
                          _ActionChip(
                            icon: Icons.person_add_alt_1,
                            label: 'Ajouter un parent',
                            onTap: widget.onAddParent!,
                            compact: compact,
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (widget.onAddUnion != null) ...[
                          _ActionChip(
                            icon: Icons.favorite_border,
                            label: 'Ajouter une union',
                            onTap: widget.onAddUnion!,
                            compact: compact,
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (widget.onExport != null)
                          _ActionChip(
                            icon: Icons.download,
                            label: 'Exporter',
                            onTap: widget.onExport!,
                            compact: compact,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
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
                  color: T.ink3,
                  borderRadius: BorderRadius.circular(T.r),
                  border: Border.all(color: T.border2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_tree_outlined, size: 48, color: T.txt3),
                    const SizedBox(height: 12),
                    const Text(
                      'Votre arbre est encore vide',
                      style: TextStyle(color: T.txt1, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Utilisez les boutons pour ajouter des membres',
                      style: TextStyle(color: T.txt3, fontSize: 12),
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
      left: node.position.dx + 50,
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

/// Gold action chip for add parent / add child.
/// In compact mode, shows icon only with a tooltip.
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool compact;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final chip = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(T.rSm),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: T.gold,
            borderRadius: BorderRadius.circular(T.rSm),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: T.ink),
              if (!compact) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: T.ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (compact) {
      return Tooltip(message: label, child: chip);
    }
    return chip;
  }
}

/// Subtle dot grid background.
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = T.border
      ..style = PaintingStyle.fill;

    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 0.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
