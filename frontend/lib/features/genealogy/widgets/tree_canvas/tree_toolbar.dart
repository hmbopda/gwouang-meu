import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/genealogy/state/tree_view_state.dart';

/// Toolbar flottante — portée de l'arbre (complet, ascendants, descendants,
/// migration). Segmenté « Tissage » : actif = pilule or, cibles ≥ 40 px.
class TreeToolbar extends StatelessWidget {
  final TreeView currentView;
  final ValueChanged<TreeView> onViewChanged;
  final bool compact;

  const TreeToolbar({
    super.key,
    required this.currentView,
    required this.onViewChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.inkCard,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        border: Border.all(color: t.line),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _chip(t, TreeView.full, Symbols.family_history, 'Rivière'),
          _chip(t, TreeView.ancestors, Symbols.arrow_upward, 'Ascendants'),
          _chip(t, TreeView.descendants, Symbols.arrow_downward, 'Descendants'),
          _chip(t, TreeView.migration, Symbols.travel_explore, 'Migration'),
        ],
      ),
    );
  }

  Widget _chip(GwTokens t, TreeView view, IconData icon, String label) {
    final selected = currentView == view;
    final chip = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onViewChanged(view),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 40,
            padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
            decoration: BoxDecoration(
              color: selected ? GwTokens.gold : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  fill: selected ? 1 : 0,
                  color: selected ? const Color(0xFF0C0B0F) : t.stoneMid,
                ),
                if (!compact) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: GwType.ui(
                      fontSize: 13,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w600,
                      color: selected ? const Color(0xFF0C0B0F) : t.stoneMid,
                    ),
                  ),
                ],
              ],
            ),
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
