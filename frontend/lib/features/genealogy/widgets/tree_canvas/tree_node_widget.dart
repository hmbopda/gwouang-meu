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
class TreeNodeWidget extends StatefulWidget {
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
  State<TreeNodeWidget> createState() => _TreeNodeWidgetState();
}

class _TreeNodeWidgetState extends State<TreeNodeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.node.isSubject) _pulseCtrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.node;
    final style = _nodeStyle(n.type);

    return MouseRegion(
      onEnter: (_) => widget.onHover(true),
      onExit: (_) {
        // Defer to next frame to avoid mouse_tracker assertion on Flutter Web
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onHover(false);
        });
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, child) {
            final scale = widget.isHovered
                ? 1.04
                : n.isSubject
                    ? 1.0 + _pulseCtrl.value * 0.015
                    : 1.0;
            return Transform.scale(scale: scale, child: child);
          },
          child: n.isSubject ? _subjectCard(n) : _card(n, style),
        ),
      ),
    );
  }

  // ── Carte sujet : glow or ──────────────────────────────────
  Widget _subjectCard(LayoutNode n) {
    final p = n.person;
    return Container(
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
        boxShadow: [
          BoxShadow(
            color: GwTokens.gold.withValues(alpha: 0.14),
            blurRadius: 36,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          _avatar(p,
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
                      color: GwTokens.dark.stone),
                ),
                const SizedBox(height: 2),
                Text(
                  _lifeline(p),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GwType.ui(
                      fontSize: 12, color: GwTokens.dark.stoneMid),
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
    );
  }

  // ── Carte standard : bordure = couleur de lignée ───────────
  Widget _card(LayoutNode n, _NodeStyle style) {
    final p = n.person;
    final isAncestor = n.type == NodeType.ancestor;
    final borderColor = widget.isSelected
        ? GwTokens.gold
        : style.border.withValues(alpha: widget.isHovered ? 0.7 : 0.35);

    return Container(
      width: kTreeNodeWidth,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xE616141B), // inkCard 90 % (léger verre)
        borderRadius: BorderRadius.circular(16),
        border: n.type == NodeType.aiSuggestion
            ? null
            : Border.all(color: borderColor),
        boxShadow: [
          if (widget.isSelected || widget.isHovered)
            BoxShadow(
              color: style.border.withValues(alpha: 0.25),
              blurRadius: 14,
              spreadRadius: 1,
            ),
        ],
      ),
      foregroundDecoration: n.type == NodeType.aiSuggestion
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
          if (n.type == NodeType.aiSuggestion)
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF0D1F16),
                shape: BoxShape.circle,
                border: Border.all(color: GwTokens.sage, width: 2),
              ),
              child: Icon(Symbols.auto_awesome,
                  size: 18, color: GwTokens.dark.sageText),
            )
          else
            _avatar(p,
                size: 44,
                borderColor: style.border,
                textColor: isAncestor
                    ? GwTokens.dark.stoneMid
                    : GwTokens.dark.stone),
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
                      color: GwTokens.dark.stone),
                ),
                const SizedBox(height: 1),
                Text(
                  // Ancêtres : « ✦ » remplace tout marquage sombre de décès.
                  isAncestor ? '${_lifeline(p)} ✦' : _lifeline(p),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GwType.ui(
                      fontSize: 11.5, color: GwTokens.dark.stoneFaint),
                ),
                if (_badgeText(n) != null) ...[
                  const SizedBox(height: 3),
                  _monoBadge(_badgeText(n)!, style.badge),
                ],
              ],
            ),
          ),
          if (n.hasDotPaid)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(left: 4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: GwTokens.rose,
              ),
            ),
        ],
      ),
    );
  }

  // ── Éléments ───────────────────────────────────────────────

  Widget _avatar(
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
        color: solid ? GwTokens.gold : GwTokens.dark.inkLift,
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
        style: GwType.mono(
            fontSize: 10, color: color, letterSpacing: 1),
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
}

// ── Style par type de nœud ───────────────────────────────────

class _NodeStyle {
  final Color border;
  final Color badge;
  const _NodeStyle(this.border, this.badge);
}

_NodeStyle _nodeStyle(NodeType type) {
  switch (type) {
    case NodeType.subject:
      return const _NodeStyle(GwTokens.gold, GwTokens.gold);
    case NodeType.primaryLineage:
      return const _NodeStyle(GwTokens.gold, GwTokens.gold);
    case NodeType.secondaryLineage:
    case NodeType.spouse:
      return const _NodeStyle(GwTokens.rose, GwTokens.rose);
    case NodeType.ancestor:
      // Bordure #7A7268 — jamais de noir « décédé ».
      return _NodeStyle(GwTokens.dark.stoneFaint, GwTokens.gold);
    case NodeType.aiSuggestion:
      return const _NodeStyle(GwTokens.sage, GwTokens.sage);
    case NodeType.founder:
      return const _NodeStyle(GwTokens.gold, GwTokens.gold);
  }
}
