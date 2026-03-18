import 'package:flutter/material.dart';

import '../../models/person_genealogy.dart';
import '../../state/tree_tokens.dart';
import '../../state/tree_view_state.dart';

/// A single tree node (circle with initials, name, clan badge).
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
      duration: const Duration(milliseconds: 1200),
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
    final p = n.person;
    final radius = n.isSubject ? T.subjectRadius : T.nodeRadius;
    final colors = _nodeColors(n.type);

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
        child: SizedBox(
          width: 120,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Circle avatar ──
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, child) {
                  final scale = widget.isHovered
                      ? 1.12
                      : n.isSubject
                          ? 1.0 + _pulseCtrl.value * 0.04
                          : 1.0;
                  return Transform.scale(scale: scale, child: child);
                },
                child: Container(
                  width: radius * 2,
                  height: radius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.bg,
                    border: Border.all(
                      color: widget.isSelected
                          ? T.gold
                          : widget.isHovered
                              ? colors.border.withValues(alpha: 0.9)
                              : colors.border,
                      width: widget.isSelected ? 3 : 2,
                    ),
                    boxShadow: [
                      if (widget.isSelected || widget.isHovered)
                        BoxShadow(
                          color: (widget.isSelected ? T.gold : colors.border)
                              .withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      if (n.isSubject)
                        BoxShadow(
                          color: T.goldGlow,
                          blurRadius: 16,
                          spreadRadius: 4,
                        ),
                    ],
                  ),
                  child: p.photoUrl != null
                      ? ClipOval(
                          child: Image.network(
                            p.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _Initials(person: p, radius: radius),
                          ),
                        )
                      : _Initials(person: p, radius: radius),
                ),
              ),
              const SizedBox(height: 5),
              // ── Name ──
              Text(
                p.firstName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: widget.isSelected ? T.gold : T.txt1,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                p.lastName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: T.txt2, fontSize: 10),
              ),
              // ── Badges ──
              if (p.clan != null && p.clan!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: T.goldBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    p.clan!,
                    style: const TextStyle(color: T.gold, fontSize: 8),
                  ),
                ),
              // ── Status badges ──
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!p.isAlive)
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.brightness_3, size: 10, color: T.txt3),
                    ),
                  if (n.hasDotPaid)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, left: 2),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: T.sacred,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Initials circle content ──

class _Initials extends StatelessWidget {
  final PersonGenealogy person;
  final double radius;

  const _Initials({required this.person, required this.radius});

  @override
  Widget build(BuildContext context) {
    final first = person.firstName.isNotEmpty ? person.firstName[0] : '';
    final last = person.lastName.isNotEmpty ? person.lastName[0] : '';
    return Center(
      child: Text(
        '$first$last'.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.55,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// ── Helper: node colors ──

class _NodeColors {
  final Color bg;
  final Color border;
  const _NodeColors(this.bg, this.border);
}

_NodeColors _nodeColors(NodeType type) {
  switch (type) {
    case NodeType.subject:
      return const _NodeColors(Color(0xFF2A1A00), T.gold);
    case NodeType.male:
      return const _NodeColors(T.maleNode, T.maleBorder);
    case NodeType.female:
      return const _NodeColors(T.femaleNode, T.femaleBorder);
    case NodeType.deceased:
      return const _NodeColors(T.deadNode, T.deadBorder);
    case NodeType.aiSuggestion:
      return const _NodeColors(T.aiNode, T.aiBorder);
    case NodeType.founder:
      return const _NodeColors(T.femaleNode, T.founderBorder);
    case NodeType.wife:
      return const _NodeColors(T.wifeNode, T.wifeBorder);
  }
}
