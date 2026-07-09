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

class _TreeCanvasState extends ConsumerState<TreeCanvas>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformCtrl = TransformationController();

  /// Tooltip courant : ValueNotifier + ValueListenableBuilder autour du seul
  /// overlay — le hover ne rebuild ni le Stack ni les _NodeSlot.
  final ValueNotifier<String?> _tooltipNodeId = ValueNotifier<String?>(null);

  late final AnimationController _centerAnimCtrl;
  Animation<Matrix4>? _centerAnim;

  Size _viewportSize = Size.zero;

  // Cache des strates (TextPainter par génération) : recalculé uniquement
  // quand le layout ou le thème change — jamais dans paint().
  TreeLayout? _strataLayout;
  Brightness? _strataBrightness;
  List<_StrataInfo> _strata = const [];

  @override
  void initState() {
    super.initState();
    _centerAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        final anim = _centerAnim;
        if (anim != null) _transformCtrl.value = anim.value;
      });

    // Centrage initial sur le nœud sujet au premier build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _centerOnSubject(animate: false);
    });
  }

  @override
  void dispose() {
    _centerAnimCtrl.dispose();
    _transformCtrl.dispose();
    _tooltipNodeId.dispose();
    super.dispose();
  }

  void _zoomIn() {
    _centerAnimCtrl.stop();
    final m = _transformCtrl.value.clone();
    m.scaleByDouble(1.2, 1.2, 1.2, 1.0);
    _transformCtrl.value = m;
  }

  void _zoomOut() {
    _centerAnimCtrl.stop();
    final m = _transformCtrl.value.clone();
    m.scaleByDouble(0.8, 0.8, 0.8, 1.0);
    _transformCtrl.value = m;
  }

  void _resetZoom() => _centerOnSubject(animate: true);

  /// Recentre la vue sur le nœud sujet (échelle 1), animé si demandé.
  void _centerOnSubject({required bool animate}) {
    final layout = ref.read(treeLayoutProvider(widget.tree));
    if (_viewportSize == Size.zero || layout.nodes.isEmpty) return;

    LayoutNode? subject;
    for (final node in layout.nodes) {
      if (node.isSubject) {
        subject = node;
        break;
      }
    }
    final target = subject?.position ??
        Offset(layout.contentWidth / 2, layout.contentHeight / 2);

    final matrix = Matrix4.identity()
      ..setTranslationRaw(
        _viewportSize.width / 2 - target.dx,
        _viewportSize.height / 2 - target.dy,
        0,
      );

    if (animate) {
      _centerAnim =
          Matrix4Tween(begin: _transformCtrl.value.clone(), end: matrix)
              .animate(CurvedAnimation(
        parent: _centerAnimCtrl,
        curve: Curves.easeInOutCubic,
      ));
      _centerAnimCtrl.forward(from: 0);
    } else {
      _transformCtrl.value = matrix;
    }
  }

  // ── Tooltip (ValueNotifier — aucun setState) ──────────────

  void _showTooltip(String id) => _tooltipNodeId.value = id;

  void _hideTooltipNow() => _tooltipNodeId.value = null;

  void _scheduleHideTooltip(String id) {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _tooltipNodeId.value == id) {
        _tooltipNodeId.value = null;
      }
    });
  }

  // ── Strates : précalcul des TextPainter hors paint() ──────

  List<_StrataInfo> _strataFor(TreeLayout layout, GwTokens t) {
    if (identical(layout, _strataLayout) && t.brightness == _strataBrightness) {
      return _strata;
    }
    _strataLayout = layout;
    _strataBrightness = t.brightness;
    _strata = _buildStrata(layout, t);
    return _strata;
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
    // Mode foyers (maquette 2a) : pas de bandes de générations.
    final strata =
        layout.isFoyerMode ? const <_StrataInfo>[] : _strataFor(layout, t);

    return Container(
      color: t.ink,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _viewportSize = constraints.biggest;

          return Stack(
            children: [
              // ── Interactive pan/zoom area ──
              InteractiveViewer(
                transformationController: _transformCtrl,
                constrained: false,
                boundaryMargin: const EdgeInsets.all(200),
                minScale: 0.3,
                maxScale: 3.0,
                child: RepaintBoundary(
                  child: SizedBox(
                    width: layout.contentWidth,
                    height: layout.contentHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Strates de générations — bandes douces + labels mono
                        // (rendu 1a uniquement — masquées en mode foyers 2a)
                        if (!layout.isFoyerMode)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _StrataPainter(
                                strata: strata,
                                dashColor: t.line.withValues(alpha: 0.05),
                                faintColor: t.stoneFaint,
                              ),
                            ),
                          ),

                        // Boîtes foyer (maquette 2a) : rectangle arrondi en
                        // pointillés 1.5 px de la couleur du foyer, fond 4 %.
                        if (layout.isFoyerMode)
                          Positioned.fill(
                            child: CustomPaint(
                              painter:
                                  _FoyerBoxPainter(boxes: layout.foyerBoxes),
                            ),
                          ),

                        // Links (Bézier curves)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: TreeLinkPainter(
                              links: layout.links,
                              selectedPersonId: selectedPersonId,
                              neutralColor: t.stoneFaint,
                              unionColor: t.stone.withValues(alpha: 0.12),
                            ),
                          ),
                        ),

                        // En-têtes des boîtes foyer (maquette 2a) : label mono
                        // « FOYER X · N ENFANTS » + point de couleur à droite.
                        ...layout.foyerBoxes.map(
                          (box) => _FoyerBoxHeader(
                            key: ValueKey('foyer-${box.rect.left}'),
                            box: box,
                          ),
                        ),

                        // Nodes — chaque _NodeSlot observe son propre
                        // isSelected/isHovered (le tooltip ne les rebuild pas)
                        ...layout.nodes.map((node) => _NodeSlot(
                              key: ValueKey(node.person.id),
                              node: node,
                              notifier: notifier,
                              onTooltipShow: _showTooltip,
                              onTooltipScheduleHide: _scheduleHideTooltip,
                              onTooltipHideNow: _hideTooltipNow,
                            )),

                        // Ligne « {n} autres foyers masqués · Tout afficher »
                        // (maquette 2c) — sous les boîtes, quand un filtre
                        // par foyer est actif.
                        if (layout.isFoyerMode && layout.hiddenFoyerCount > 0)
                          _HiddenFoyersLine(
                            layout: layout,
                            notifier: notifier,
                          ),

                        // Pilules-étiquettes d'union (maquette 2a) : centrées
                        // sur le connecteur mari↔épouse, « 1RE UNION · 1968 ».
                        ...layout.unionBadges.map(
                          (badge) => Positioned(
                            left: badge.position.dx,
                            top: badge.position.dy,
                            child: FractionalTranslation(
                              translation: const Offset(-0.5, -0.5),
                              child: _UnionBadgeChip(badge: badge),
                            ),
                          ),
                        ),

                        // Tooltip overlay — seul ce builder écoute le hover
                        ValueListenableBuilder<String?>(
                          valueListenable: _tooltipNodeId,
                          builder: (context, tooltipId, _) {
                            final node = tooltipId == null
                                ? null
                                : layout.nodeMap[tooltipId];
                            if (node == null) return const SizedBox.shrink();
                            return _buildTooltip(node, notifier);
                          },
                        ),
                      ],
                    ),
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

              // ── Chips-filtres par foyer (maquette 2c, mode foyers) ──
              if (layout.isFoyerMode && layout.foyerChips.isNotEmpty)
                Positioned(
                  top: 60,
                  left: 12,
                  right: 12,
                  child: _FoyerFilterChips(
                    chips: layout.foyerChips,
                    notifier: notifier,
                  ),
                ),

              // ── Fil d'Ariane des re-centrages (haut, sous la toolbar ;
              // décalé sous les chips-filtres 2c quand elles coexistent) ──
              Positioned(
                top: layout.isFoyerMode && layout.foyerChips.isNotEmpty
                    ? 100
                    : 60,
                left: 12,
                right: 12,
                child: _FocusBreadcrumb(notifier: notifier),
              ),

              // ── Légende (desktop, bas gauche) : lignées en mode 1a,
              // foyers colorés + chef de famille en mode 2a ──
              if (widget.showLegend)
                Positioned(
                  bottom: 16,
                  left: 20,
                  child: layout.isFoyerMode
                      ? const _FoyerLegend()
                      : _LineageLegend(),
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
          );
        },
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
            if (mounted) _tooltipNodeId.value = null;
          });
        },
        child: TreeNodeTooltip(
          node: node,
          onViewDetails: () {
            notifier.selectPerson(node.person.id);
            _hideTooltipNow();
            showDialog(
              context: context,
              builder: (_) => PersonDetailPopup(person: node.person),
            );
          },
          onCenterHere: node.isSubject ? null : () {
            _hideTooltipNow();
            _focusOnNode(node, notifier);
          },
          onAddParent: () {
            notifier.selectPerson(node.person.id);
            _hideTooltipNow();
            widget.onAddParent?.call();
          },
          onAddChild: () {
            notifier.selectPerson(node.person.id);
            _hideTooltipNow();
            widget.onAddChild?.call();
          },
        ),
      ),
    );
  }

  /// Geste #1 : « faire de cette personne la racine ».
  void _focusOnNode(LayoutNode node, TreeViewNotifier notifier) {
    final p = node.person;
    notifier.focusPerson(p.id, '${p.firstName} ${p.lastName}'.trim());
  }

}

/// Pilule d'action or (pleine ou contour), cible ≥ 44 px.
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
    final t = GwTokens.of(context);
    final fg = outlined ? GwTokens.gold : const Color(0xFF0C0B0F);

    final pill = Material(
      color: outlined ? t.inkCard : GwTokens.gold,
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

/// Légende du mode foyers (maquette 2a) : points de couleur par foyer
/// (or / rose / vert) + « ♛ Chef de famille / successeur ».
class _FoyerLegend extends StatelessWidget {
  const _FoyerLegend();

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
          _dot(t, GwTokens.gold, 'Foyer 1'),
          const SizedBox(width: 14),
          _dot(t, GwTokens.rose, 'Foyer 2'),
          const SizedBox(width: 14),
          _dot(t, GwTokens.sage, 'Foyer 3'),
          const SizedBox(width: 14),
          Text('♛ Chef de famille / successeur',
              style: GwType.ui(fontSize: 12, color: t.stoneMid)),
        ],
      ),
    );
  }

  Widget _dot(GwTokens t, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(label, style: GwType.ui(fontSize: 12, color: t.stoneMid)),
      ],
    );
  }
}

// ── Vue filtrée par foyer (maquette 2c) ──────────────────────

/// Crème des textes sur pilule pleine (chips 2c actifs).
const Color _kFoyerChipCream = Color(0xFFF0EBE1);

/// Brun du chip « Tous les foyers » actif (pilule pleine).
const Color _kFoyerChipBrown = Color(0xFF3B2A16);

/// Rangée de chips-filtres du mode foyers (maquette 2c) :
/// « Tous les foyers » puis un chip par épouse (● couleur du foyer + prénom).
/// Chip actif = pilule PLEINE de la couleur du foyer, texte crème ;
/// inactifs = fond carte, liseré fin, texte stone.
class _FoyerFilterChips extends ConsumerWidget {
  final List<FoyerChipInfo> chips;
  final TreeViewNotifier notifier;

  const _FoyerFilterChips({required this.chips, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final filter =
        ref.watch(treeViewProvider.select((s) => s.foyerFilterWifeId));
    // Filtre inconnu du layout → considéré « Tous les foyers ».
    final active =
        chips.any((c) => c.wifeId == filter) ? filter : null;

    Widget chip({
      required String label,
      required bool isActive,
      required Color activeColor,
      required VoidCallback onTap,
      Color? dotColor,
    }) {
      return Material(
        color: isActive ? activeColor : t.inkCard,
        borderRadius: BorderRadius.circular(GwTokens.rPill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GwTokens.rPill),
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(GwTokens.rPill),
              border: isActive ? null : Border.all(color: t.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dotColor != null) ...[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? _kFoyerChipCream : dotColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: GwType.ui(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? _kFoyerChipCream : t.stone,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            chip(
              label: 'Tous les foyers',
              isActive: active == null,
              activeColor: _kFoyerChipBrown,
              onTap: () => notifier.setFoyerFilter(null),
            ),
            for (final info in chips) ...[
              const SizedBox(width: 6),
              chip(
                label: info.label.isEmpty ? '?' : info.label,
                isActive: active == info.wifeId,
                activeColor: info.color,
                dotColor: info.color,
                onTap: () => notifier.setFoyerFilter(info.wifeId),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ligne « {n} autres foyers masqués · Tout afficher » (maquette 2c), posée
/// dans le contenu du canvas SOUS la boîte foyer visible. « Tout afficher »
/// est or et cliquable → réinitialise le filtre.
class _HiddenFoyersLine extends StatelessWidget {
  final TreeLayout layout;
  final TreeViewNotifier notifier;

  const _HiddenFoyersLine({required this.layout, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final n = layout.hiddenFoyerCount;
    if (n <= 0 || layout.foyerBoxes.isEmpty) return const SizedBox.shrink();

    double left = layout.foyerBoxes.first.rect.left;
    double bottom = layout.foyerBoxes.first.rect.bottom;
    for (final box in layout.foyerBoxes) {
      if (box.rect.left < left) left = box.rect.left;
      if (box.rect.bottom > bottom) bottom = box.rect.bottom;
    }

    final label = n == 1 ? '1 autre foyer masqué' : '$n autres foyers masqués';

    return Positioned(
      left: left,
      top: bottom + 14,
      child: Material(
        color: Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label · ',
              style: GwType.ui(fontSize: 12, color: t.stoneDim),
            ),
            InkWell(
              onTap: () => notifier.setFoyerFilter(null),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Text(
                  'Tout afficher',
                  style: GwType.ui(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: GwTokens.gold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// En-tête d'une boîte foyer (maquette 2a), posé dans le Stack du canvas
/// au-dessus du coin haut-gauche du rect : label mono « FOYER MAAH ·
/// 3 ENFANTS » + point de couleur à droite.
class _FoyerBoxHeader extends StatelessWidget {
  final FoyerBox box;

  const _FoyerBoxHeader({super.key, required this.box});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: box.rect.left + 12,
      top: box.rect.top + 12,
      width: box.rect.width - 24,
      height: 26,
      child: Row(
        children: [
          Expanded(
            child: Text(
              box.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GwType.mono(
                fontSize: 9.5,
                letterSpacing: 1.5,
                color: box.color,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: box.color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pilule-étiquette d'union (maquette 2a) : blanche, bordée 1 px de la
/// couleur du foyer, texte mono « 1RE UNION · 1968 » ; atténuée si terminée.
class _UnionBadgeChip extends StatelessWidget {
  final UnionBadge badge;

  const _UnionBadgeChip({required this.badge});

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Opacity(
      opacity: badge.ended ? 0.6 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: t.inkCard,
          borderRadius: BorderRadius.circular(GwTokens.rPill),
          border: Border.all(color: badge.color),
        ),
        child: Text(
          badge.label,
          maxLines: 1,
          style: GwType.mono(
            fontSize: 9,
            letterSpacing: 1.5,
            color: badge.color,
          ),
        ),
      ),
    );
  }
}

// ── Boîtes foyer (maquette 2a) ───────────────────────────────

/// Rectangles arrondis EN POINTILLÉS (1.5 px, couleur du foyer) avec fond de
/// la même couleur à 4 % d'opacité — sous les nœuds, au-dessus du fond.
class _FoyerBoxPainter extends CustomPainter {
  final List<FoyerBox> boxes;

  const _FoyerBoxPainter({required this.boxes});

  @override
  void paint(Canvas canvas, Size size) {
    for (final box in boxes) {
      final rrect =
          RRect.fromRectAndRadius(box.rect, const Radius.circular(12));

      // Fond très léger de la couleur du foyer.
      canvas.drawRRect(rrect, Paint()..color = box.color.withValues(alpha: 0.04));

      // Bordure pointillée arrondie.
      final border = Paint()
        ..color = box.color.withValues(alpha: 0.6)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final outline = Path()..addRRect(rrect);
      canvas.drawPath(_dashOutline(outline, 5, 5), border);
    }
  }

  /// Découpe un `Path` fermé en tirets via sa longueur d'arc (PathMetric).
  static Path _dashOutline(Path source, double dashLen, double gapLen) {
    final result = Path();
    for (final metric in source.computeMetrics()) {
      double d = 0;
      bool draw = true;
      while (d < metric.length) {
        final end =
            (d + (draw ? dashLen : gapLen)).clamp(0.0, metric.length);
        if (draw) result.addPath(metric.extractPath(d, end), Offset.zero);
        d = end;
        draw = !draw;
      }
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant _FoyerBoxPainter oldDelegate) =>
      oldDelegate.boxes != boxes;
}

/// Widget isolé pour un node : observe UNIQUEMENT isSelected et isHovered
/// pour ce node. Évite le rebuild de tous les nodes à chaque clic.
class _NodeSlot extends ConsumerWidget {
  final LayoutNode node;
  final TreeViewNotifier notifier;
  final ValueChanged<String> onTooltipShow;
  final ValueChanged<String> onTooltipScheduleHide;
  final VoidCallback onTooltipHideNow;

  const _NodeSlot({
    super.key,
    required this.node,
    required this.notifier,
    required this.onTooltipShow,
    required this.onTooltipScheduleHide,
    required this.onTooltipHideNow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(
      treeViewProvider.select((s) => s.selectedPersonId == node.person.id),
    );
    final isHovered = ref.watch(
      treeViewProvider.select((s) => s.hoveredPersonId == node.person.id),
    );

    // Mini-carte empilée dans une boîte foyer (2a) : 200×48 centrée dans sa
    // rangée de 56 px. Sinon carte standard 230×84 centrée sur node.position
    // (le layout raisonne en CENTRES : _cardHalfH = kTreeNodeHeight / 2).
    final width = node.inFoyerBox
        ? kTreeMiniNodeWidth
        : node.isSubject
            ? kTreeSubjectWidth
            : kTreeNodeWidth;
    final topOffset =
        node.inFoyerBox ? kTreeMiniNodeHeight / 2 : kTreeNodeHeight / 2;

    return Positioned(
      left: node.position.dx - width / 2,
      top: node.position.dy - topOffset,
      child: RepaintBoundary(
        child: TreeNodeWidget(
          node: node,
          isSelected: isSelected,
          isHovered: isHovered,
          onTap: () {
            notifier.selectPerson(node.person.id);
            onTooltipHideNow();
          },
          onHover: (hovering) {
            if (hovering) {
              notifier.hoverPerson(node.person.id);
              onTooltipShow(node.person.id);
            } else {
              notifier.hoverPerson(null);
              onTooltipScheduleHide(node.person.id);
            }
          },
        ),
      ),
    );
  }
}

// ── Strates de générations ───────────────────────────────────

/// Données précalculées d'une strate : label déjà layouté (jamais de
/// GwType.*()/TextPainter.layout() dans paint()).
class _StrataInfo {
  final double top;
  final bool isSubjectGen;
  final bool isFirst;
  final TextPainter label;

  const _StrataInfo({
    required this.top,
    required this.isSubjectGen,
    required this.isFirst,
    required this.label,
  });
}

List<_StrataInfo> _buildStrata(TreeLayout layout, GwTokens t) {
  if (layout.nodes.isEmpty) return const [];

  // Générations → bornes Y
  final gens = <int, double>{};
  int? subjectGen;
  for (final n in layout.nodes) {
    gens[n.generation] = n.position.dy;
    if (n.isSubject) subjectGen = n.generation;
  }
  final sorted = gens.keys.toList()..sort();

  final result = <_StrataInfo>[];
  for (int i = 0; i < sorted.length; i++) {
    final gen = sorted[i];
    final isSubjectGen = gen == subjectGen;
    final isFirst = i == 0;

    final label = isSubjectGen
        ? 'GÉNÉRATION ${gen + 1} · VOUS'
        : isFirst
            ? 'GÉNÉRATION ${gen + 1} · LES FONDATEURS'
            : 'GÉNÉRATION ${gen + 1}';

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: GwType.mono(
          fontSize: 10,
          letterSpacing: 2,
          color: isSubjectGen ? t.goldText : t.stoneFaint,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    result.add(_StrataInfo(
      top: gens[gen]! - 90,
      isSubjectGen: isSubjectGen,
      isFirst: isFirst,
      label: tp,
    ));
  }
  return result;
}

/// Strates de générations : bandes douces, séparateurs pointillés,
/// labels mono « GÉNÉRATION N » (or pour la génération du sujet).
/// Reçoit toutes les couleurs en paramètre (aucun GwTokens.dark ici).
class _StrataPainter extends CustomPainter {
  final List<_StrataInfo> strata;
  final Color dashColor;
  final Color faintColor;

  const _StrataPainter({
    required this.strata,
    required this.dashColor,
    required this.faintColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (strata.isEmpty) return;

    final dashPaint = Paint()
      ..color = dashColor
      ..strokeWidth = 1;

    for (final s in strata) {
      // Bande douce pour la génération du sujet + la première
      if (s.isSubjectGen || s.isFirst) {
        final rect = Rect.fromLTWH(0, s.top, size.width, 180);
        final gradient = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: s.isSubjectGen
              ? [
                  GwTokens.gold.withValues(alpha: 0.05),
                  GwTokens.gold.withValues(alpha: 0.015),
                ]
              : [
                  faintColor.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
        );
        canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
      }

      // Séparateur pointillé bas de strate
      final sepY = s.top + 180;
      double x = 0;
      while (x < size.width) {
        canvas.drawLine(Offset(x, sepY), Offset(x + 4, sepY), dashPaint);
        x += 12;
      }

      // Label mono précalculé
      s.label.paint(canvas, Offset(24, s.top + 14));
    }
  }

  @override
  bool shouldRepaint(covariant _StrataPainter oldDelegate) =>
      oldDelegate.strata != strata ||
      oldDelegate.dashColor != dashColor ||
      oldDelegate.faintColor != faintColor;
}

// ─────────────────────────────────────────────────────────────
//  Fil d'Ariane des re-centrages (« ⌂ Moi › Papa › Grand-père »)
// ─────────────────────────────────────────────────────────────

class _FocusBreadcrumb extends ConsumerWidget {
  const _FocusBreadcrumb({required this.notifier});

  final TreeViewNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final stack = ref.watch(treeViewProvider.select((s) => s.focusStack));
    if (stack.isEmpty) return const SizedBox.shrink();

    Widget chip(String label, bool active, VoidCallback onTap, {IconData? icon}) {
      return Material(
        color: active ? GwTokens.gold : t.inkCard,
        borderRadius: BorderRadius.circular(GwTokens.rPill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GwTokens.rPill),
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(GwTokens.rPill),
              border: active ? null : Border.all(color: t.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon,
                      size: 15,
                      color: active ? GwTokens.inkOnGold : t.stoneMid),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: GwType.ui(
                    fontSize: 12.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? GwTokens.inkOnGold : t.stoneMid,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            chip('Moi', false, notifier.clearFocus, icon: Symbols.home),
            for (int i = 0; i < stack.length; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Symbols.chevron_right,
                    size: 16, color: t.stoneFaint),
              ),
              chip(
                stack[i].label.isEmpty ? '?' : stack[i].label,
                i == stack.length - 1,
                () => notifier.focusToCrumb(i),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
