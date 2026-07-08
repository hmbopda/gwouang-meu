import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/genealogy/models/person_genealogy.dart';
import 'package:gwangmeu/features/genealogy/state/tree_view_state.dart';

/// Largeur d'un nœud-carte standard (le sujet est plus large).
const double kTreeNodeWidth = 180;
const double kTreeSubjectWidth = 210;

/// Nœud-carte « Tissage » (#2c) : avatar cerclé par la couleur de LIGNÉE
/// (or Mbopda / rose Ngo Bassa), ancêtres marqués ✦, sujet en carte glow or,
/// suggestion IA en pointillé sage « AFFLUENT ».
///
/// Performance : seul le nœud SUJET instancie un AnimationController
/// (pulse d'opacité du halo). Tous les autres nœuds sont Stateless.
class TreeNodeWidget extends StatelessWidget {
  final LayoutNode node;
  final bool isSelected;
  final bool isHovered;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  const TreeNodeWidget({
    super.key,
    required this.node,
    required this.isSelected,
    required this.isHovered,
    required this.onTap,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    if (node.isSubject) {
      return _SubjectNode(
        node: node,
        isSelected: isSelected,
        isHovered: isHovered,
        onTap: onTap,
        onHover: onHover,
      );
    }
    return _StandardNode(
      node: node,
      isSelected: isSelected,
      isHovered: isHovered,
      onTap: onTap,
      onHover: onHover,
    );
  }
}

/// Enveloppe commune hover/tap : léger scale au survol, curseur main.
class _NodeShell extends StatelessWidget {
  final bool isHovered;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;
  final Widget child;

  const _NodeShell({
    required this.isHovered,
    required this.onTap,
    required this.onHover,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) {
        // Defer to next frame to avoid mouse_tracker assertion on Flutter Web
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) onHover(false);
        });
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: isHovered ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: child,
        ),
      ),
    );
  }
}

// ── Nœud sujet : carte glow or, halo fixe à opacité pulsée ────

class _SubjectNode extends StatefulWidget {
  final LayoutNode node;
  final bool isSelected;
  final bool isHovered;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  const _SubjectNode({
    required this.node,
    required this.isSelected,
    required this.isHovered,
    required this.onTap,
    required this.onHover,
  });

  @override
  State<_SubjectNode> createState() => _SubjectNodeState();
}

class _SubjectNodeState extends State<_SubjectNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _haloOpacity;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _haloOpacity = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final p = widget.node.person;

    return _NodeShell(
      isHovered: widget.isHovered,
      onTap: widget.onTap,
      onHover: widget.onHover,
      child: Stack(
        children: [
          // Halo FIXE : seule l'opacité pulse (FadeTransition), jamais
          // de Transform.scale — le repaint reste local au RepaintBoundary.
          Positioned.fill(
            child: FadeTransition(
              opacity: _haloOpacity,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.all(Radius.circular(GwTokens.rCardLg)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x24C9A84C), // gold 14 %
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: kTreeSubjectWidth,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  GwTokens.gold.withValues(alpha: 0.16),
                  GwTokens.gold.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(GwTokens.rCardLg),
              border: Border.all(
                color: GwTokens.gold
                    .withValues(alpha: widget.isSelected ? 0.9 : 0.6),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                _avatar(t, p,
                    size: 54,
                    solid: true,
                    borderColor: GwTokens.gold,
                    textColor: const Color(0xFF0C0B0F)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${p.firstName} ${p.lastName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GwType.ui(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: t.stone),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _lifeline(p),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GwType.ui(fontSize: 12, color: t.stoneMid),
                      ),
                      if (p.clan != null && p.clan!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _monoBadge(p.clan!.toUpperCase(), GwTokens.gold),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nœud standard (Stateless) : bordure = couleur de lignée ──

class _StandardNode extends StatelessWidget {
  final LayoutNode node;
  final bool isSelected;
  final bool isHovered;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  const _StandardNode({
    required this.node,
    required this.isSelected,
    required this.isHovered,
    required this.onTap,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final style = _nodeStyle(node.type, t);
    final p = node.person;
    final isAncestor = node.type == NodeType.ancestor;
    final borderColor = isSelected
        ? GwTokens.gold
        : style.border.withValues(alpha: isHovered ? 0.7 : 0.35);

    return _NodeShell(
      isHovered: isHovered,
      onTap: onTap,
      onHover: onHover,
      child: Container(
        width: kTreeNodeWidth,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: t.inkCard.withValues(alpha: 0.9), // léger verre
          borderRadius: BorderRadius.circular(16),
          border: node.type == NodeType.aiSuggestion
              ? null
              : Border.all(color: borderColor),
          boxShadow: [
            if (isSelected || isHovered)
              BoxShadow(
                color: style.border.withValues(alpha: 0.25),
                blurRadius: 14,
                spreadRadius: 1,
              ),
          ],
        ),
        foregroundDecoration: node.type == NodeType.aiSuggestion
            ? ShapeDecoration(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: GwTokens.sage.withValues(alpha: 0.55),
                    width: 1.5,
                    style: BorderStyle.solid,
                  ),
                ),
              )
            : null,
        child: Row(
          children: [
            if (node.type == NodeType.aiSuggestion)
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: GwTokens.sageBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: GwTokens.sage, width: 2),
                ),
                child: Icon(Symbols.auto_awesome,
                    size: 18, color: t.sageText),
              )
            else
              _avatar(t, p,
                  size: 44,
                  borderColor: style.border,
                  textColor: isAncestor ? t.stoneMid : t.stone),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${p.firstName} ${p.lastName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GwType.ui(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: t.stone),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    // Ancêtres : « ✦ » remplace tout marquage sombre de décès.
                    isAncestor ? '${_lifeline(p)} ✦' : _lifeline(p),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GwType.ui(fontSize: 11.5, color: t.stoneFaint),
                  ),
                  if (_badgeText(node) != null) ...[
                    const SizedBox(height: 3),
                    _monoBadge(_badgeText(node)!, style.badge),
                  ],
                  // Badges d'union (conjoint) : rang, régime, conformité — mono
                  // et discrets. Aucun jugement de « légitimité ».
                  if (node.unionInfo != null) ...[
                    const SizedBox(height: 4),
                    _UnionBadges(info: node.unionInfo!, t: t),
                  ],
                ],
              ),
            ),
            // Dot payée : badge DOT or discret (remplace l'ancien point rose).
            if (node.hasDotPaid)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: GwTokens.gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                      color: GwTokens.gold.withValues(alpha: 0.35)),
                ),
                child: Text(
                  'DOT',
                  style: GwType.mono(
                      fontSize: 9,
                      color: GwTokens.gold,
                      letterSpacing: 1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Éléments partagés ────────────────────────────────────────

Widget _avatar(
  GwTokens t,
  PersonGenealogy p, {
  required double size,
  required Color borderColor,
  required Color textColor,
  bool solid = false,
}) {
  final first = p.firstName.isNotEmpty ? p.firstName[0] : '';
  final initials = first.toUpperCase();

  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: solid ? GwTokens.gold : t.inkLift,
      border: solid ? null : Border.all(color: borderColor, width: 2),
    ),
    clipBehavior: Clip.antiAlias,
    alignment: Alignment.center,
    child: p.photoUrl != null
        ? CachedNetworkImage(
            imageUrl: p.photoUrl!,
            fit: BoxFit.cover,
            width: size,
            height: size,
            errorWidget: (_, __, ___) => Text(
              initials,
              style: GwType.display(
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.w600,
                  color: textColor),
            ),
          )
        : Text(
            initials,
            style: GwType.display(
                fontSize: size * 0.38,
                fontWeight: FontWeight.w600,
                color: textColor),
          ),
  );
}

Widget _monoBadge(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GwType.mono(fontSize: 10, color: color, letterSpacing: 1),
    ),
  );
}

String? _badgeText(LayoutNode n) {
  final p = n.person;
  if (n.type == NodeType.aiSuggestion) return 'AFFLUENT PROBABLE';
  if (n.type == NodeType.secondaryLineage || n.type == NodeType.spouse) {
    return 'LIGNÉE ${p.lastName.toUpperCase()}';
  }
  if (p.clan != null && p.clan!.isNotEmpty) {
    return 'CLAN ${p.clan!.toUpperCase()}';
  }
  return null;
}

String _lifeline(PersonGenealogy p) {
  final birth = p.birthDate?.year;
  final place = p.birthPlace;
  final parts = <String>[];
  if (birth != null) {
    parts.add(p.gender == 'FEMALE' ? 'née en $birth' : 'né en $birth');
  }
  if (place != null && place.isNotEmpty) parts.add(place);
  return parts.isEmpty ? '—' : parts.join(' · ');
}

// ── Badges d'union (conjoint) : rang · régime · conformité ───

/// Chips mono discrètes portées par un nœud conjoint.
/// - Rang : « 1RE UNION », « 2E UNION »… (seulement si polygamie / rang > 1)
/// - Régime : « CIVIL », « COUTUMIER »… (méta)
/// - Conformité : ton sage (conforme), ember doux (non conforme / à vérifier).
///   JAMAIS de « légitimité », aucune croix rouge.
class _UnionBadges extends StatelessWidget {
  final NodeUnionInfo info;
  final GwTokens t;

  const _UnionBadges({required this.info, required this.t});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    // Rang d'union : utile seulement en contexte polygame ou rang ≥ 2.
    if (info.isPolygamous || info.rank >= 2) {
      chips.add(_chip(_rankLabel(info.rank), GwTokens.gold));
    }

    // Régime légal (méta).
    final regime = _regimeLabel(info.legalRegime);
    if (regime != null) chips.add(_chip(regime, t.stoneMid));

    // Union terminée.
    if (!info.isActive) chips.add(_chip('TERMINÉE', t.stoneFaint));

    // Conformité au droit civil — ton doux, jamais de rouge dur.
    final comp = _complianceChip(context);
    if (comp != null) chips.add(comp);

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      runSpacing: 3,
      children: chips,
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GwType.mono(fontSize: 9, color: color, letterSpacing: 1),
      ),
    );
  }

  /// Chip de conformité : sage (conforme) ou ember doux (à vérifier / non
  /// conforme au droit civil). WARNING et NON_COMPLIANT partagent le ton sage
  /// ember — aucune sanction visuelle brutale.
  Widget? _complianceChip(BuildContext context) {
    switch (info.compliance) {
      case UnionCompliance.compliant:
        return _chip('CONFORME', GwTokens.sage);
      case UnionCompliance.warning:
        return _chip('À VÉRIFIER', GwTokens.ember);
      case UnionCompliance.nonCompliant:
        return _chip('DROIT CIVIL', GwTokens.ember);
      case UnionCompliance.unknown:
        return null;
    }
  }

  static String _rankLabel(int rank) {
    switch (rank) {
      case 1:
        return '1RE UNION';
      case 2:
        return '2E UNION';
      case 3:
        return '3E UNION';
      default:
        return '${rank}E UNION';
    }
  }

  static String? _regimeLabel(String? regime) {
    if (regime == null || regime.isEmpty) return null;
    switch (regime.toUpperCase()) {
      case 'CIVIL':
        return 'CIVIL';
      case 'CUSTOMARY':
      case 'COUTUMIER':
        return 'COUTUMIER';
      case 'RELIGIOUS':
        return 'RELIGIEUX';
      case 'DE_FACTO':
        return 'DE FAIT';
      default:
        return regime.toUpperCase();
    }
  }
}

// ── Style par type de nœud ───────────────────────────────────

class _NodeStyle {
  final Color border;
  final Color badge;
  const _NodeStyle(this.border, this.badge);
}

_NodeStyle _nodeStyle(NodeType type, GwTokens t) {
  switch (type) {
    case NodeType.subject:
    case NodeType.primaryLineage:
    case NodeType.founder:
      return const _NodeStyle(GwTokens.gold, GwTokens.gold);
    case NodeType.secondaryLineage:
    case NodeType.spouse:
      return const _NodeStyle(GwTokens.rose, GwTokens.rose);
    case NodeType.ancestor:
      // Bordure stoneFaint — jamais de noir « décédé ».
      return _NodeStyle(t.stoneFaint, GwTokens.gold);
    case NodeType.aiSuggestion:
      return const _NodeStyle(GwTokens.sage, GwTokens.sage);
  }
}
