import 'package:flutter/material.dart';

import '../../models/person_genealogy.dart';
import '../../state/tree_tokens.dart';
import '../../state/tree_view_state.dart';

/// Hover tooltip overlay for a tree node — shows person details + action buttons.
class TreeNodeTooltip extends StatelessWidget {
  final LayoutNode node;
  final VoidCallback onViewDetails;
  final VoidCallback onAddParent;
  final VoidCallback onAddChild;

  const TreeNodeTooltip({
    super.key,
    required this.node,
    required this.onViewDetails,
    required this.onAddParent,
    required this.onAddChild,
  });

  @override
  Widget build(BuildContext context) {
    final p = node.person;
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: T.ink3,
        borderRadius: BorderRadius.circular(T.rSm),
        border: Border.all(color: T.border2),
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
              _avatar(p),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${p.firstName} ${p.lastName}',
                      style: const TextStyle(
                        color: T.txt1,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (p.clan != null && p.clan!.isNotEmpty)
                      Text(
                        'Clan ${p.clan}',
                        style: const TextStyle(color: T.gold, fontSize: 10),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Info rows
          _infoRow(Icons.wc, p.gender == 'MALE' ? 'Homme' : 'Femme'),
          if (!p.isAlive) _infoRow(Icons.brightness_3, 'Décédé(e)'),
          if (p.birthPlace != null) _infoRow(Icons.place_outlined, p.birthPlace!),
          if (p.totem != null) _infoRow(Icons.pets, 'Totem: ${p.totem}'),
          const SizedBox(height: 8),
          const Divider(color: T.border, height: 1),
          const SizedBox(height: 8),
          // Actions
          Row(
            children: [
              _actionBtn(Icons.visibility, 'Détails', onViewDetails),
              const SizedBox(width: 6),
              _actionBtn(Icons.person_add, 'Parent', onAddParent),
              const SizedBox(width: 6),
              _actionBtn(Icons.child_care, 'Enfant', onAddChild),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatar(PersonGenealogy p) {
    final initials =
        '${p.firstName.isNotEmpty ? p.firstName[0] : ''}${p.lastName.isNotEmpty ? p.lastName[0] : ''}';
    return CircleAvatar(
      radius: 16,
      backgroundColor: p.gender == 'MALE' ? T.maleNode : T.femaleNode,
      child: Text(
        initials.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 12, color: T.txt3),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: T.txt2, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: T.ink5,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: T.border),
          ),
          child: Column(
            children: [
              Icon(icon, size: 14, color: T.txt2),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(color: T.txt2, fontSize: 9)),
            ],
          ),
        ),
      ),
    );
  }
}
