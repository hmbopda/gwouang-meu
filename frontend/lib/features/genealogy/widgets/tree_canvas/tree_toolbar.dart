import 'package:flutter/material.dart';

import '../../state/tree_tokens.dart';
import '../../state/tree_view_state.dart';

/// Floating toolbar for switching tree views (Full, Ancestors, Descendants, Migration).
/// Adapts to screen width: shows labels on desktop, icons-only + tooltip on mobile.
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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: T.ink3,
        borderRadius: BorderRadius.circular(T.r),
        border: Border.all(color: T.border2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _chip(TreeView.full, Icons.account_tree, 'Arbre complet'),
          _chip(TreeView.ancestors, Icons.arrow_upward, 'Ascendants'),
          _chip(TreeView.descendants, Icons.arrow_downward, 'Descendants'),
          _chip(TreeView.migration, Icons.flight, 'Migration'),
        ],
      ),
    );
  }

  Widget _chip(TreeView view, IconData icon, String label) {
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
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: selected ? T.gold : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: selected ? T.ink : T.txt2,
                ),
                if (!compact) ...[
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? T.ink : T.txt2,
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
