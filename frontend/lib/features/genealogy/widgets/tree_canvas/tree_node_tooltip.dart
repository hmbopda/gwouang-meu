import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/genealogy/models/person_genealogy.dart';
import 'package:gwangmeu/features/genealogy/state/tree_view_state.dart';

/// Hover tooltip overlay for a tree node — shows person details + action buttons.
class TreeNodeTooltip extends StatelessWidget {
  final LayoutNode node;
  final VoidCallback onViewDetails;
  final VoidCallback onAddParent;
  final VoidCallback onAddChild;
  // Re-centrage : « faire de cette personne la racine ».
  // Null quand le nœud est déjà le sujet (pas de recentrage possible).
  final VoidCallback? onCenterHere;

  const TreeNodeTooltip({
    super.key,
    required this.node,
    required this.onViewDetails,
    required this.onAddParent,
    required this.onAddChild,
    this.onCenterHere,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final p = node.person;
    return Container(
      width: 230,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.inkCard,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        border: Border.all(color: t.goldLine),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              _avatar(t, p),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${p.firstName} ${p.lastName}',
                      style: GwType.ui(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: t.stone,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (p.clan != null && p.clan!.isNotEmpty)
                      Text(
                        'Clan ${p.clan}',
                        style: GwType.ui(fontSize: 12, color: t.goldText),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Info rows
          _infoRow(t, Symbols.wc, p.gender == 'MALE' ? 'Homme' : 'Femme'),
          if (!p.isAlive) _infoRow(t, Symbols.dark_mode, 'Décédé(e)'),
          if (p.birthPlace != null)
            _infoRow(t, Symbols.location_on, p.birthPlace!),
          if (p.totem != null) _infoRow(t, Symbols.pets, 'Totem: ${p.totem}'),
          const SizedBox(height: 8),
          Divider(color: t.line, height: 1),
          const SizedBox(height: 8),
          // Actions
          Row(
            children: [
              _actionBtn(t, Symbols.visibility, 'Détails', onViewDetails),
              const SizedBox(width: 6),
              _actionBtn(t, Symbols.person_add, 'Parent', onAddParent),
              const SizedBox(width: 6),
              _actionBtn(t, Symbols.child_care, 'Enfant', onAddChild),
            ],
          ),
          if (onCenterHere != null) ...[
            const SizedBox(height: 6),
            _actionBtn(t, Symbols.center_focus_strong, 'Recentrer', onCenterHere!),
          ],
        ],
      ),
    );
  }

  Widget _avatar(GwTokens t, PersonGenealogy p) {
    final initials =
        '${p.firstName.isNotEmpty ? p.firstName[0] : ''}${p.lastName.isNotEmpty ? p.lastName[0] : ''}';
    return CircleAvatar(
      radius: 16,
      backgroundColor: t.inkLift,
      child: Text(
        initials.toUpperCase(),
        style: GwType.display(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: t.stone,
        ),
      ),
    );
  }

  Widget _infoRow(GwTokens t, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: t.stoneDim),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: GwType.ui(fontSize: 12, color: t.stoneMid),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(GwTokens t, IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: t.inkHigh,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: t.line),
          ),
          child: Column(
            children: [
              Icon(icon, size: 14, color: t.stoneMid),
              const SizedBox(height: 2),
              Text(label, style: GwType.ui(fontSize: 12, color: t.stoneMid)),
            ],
          ),
        ),
      ),
    );
  }
}
