import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/chat/direct_chat.dart';

/// Rangée « souvenirs » du Fil de famille : bulle « + Souvenir » (composer) puis
/// les personnes liées (famille, clan, village) — vraies données via
/// [chatContactsProvider]. État vide discret si aucun contact lié.
class FamilyStoriesRow extends ConsumerWidget {
  const FamilyStoriesRow({
    super.key,
    required this.onAdd,
    required this.onTapContact,
  });

  final VoidCallback onAdd;
  final void Function(ChatContact contact) onTapContact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final contactsAsync = ref.watch(chatContactsProvider(''));
    final contacts = contactsAsync.valueOrNull ?? const <ChatContact>[];

    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          _addBubble(t),
          for (final c in contacts) _contactBubble(t, c),
        ],
      ),
    );
  }

  Widget _addBubble(GwTokens t) {
    return _bubble(
      label: 'Souvenir',
      onTap: onAdd,
      circle: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: GwTokens.gold.withValues(alpha: 0.10),
          border: Border.all(
              color: GwTokens.gold.withValues(alpha: 0.5), width: 1.4),
        ),
        child: Center(
          child: Icon(Symbols.add, size: 24, color: t.goldText),
        ),
      ),
      labelColor: t.stoneMid,
    );
  }

  Widget _contactBubble(GwTokens t, ChatContact c) {
    final name = c.displayName.trim();
    final first = name.isEmpty ? '?' : name.split(' ').first;
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    final hasAvatar = c.avatarUrl != null && c.avatarUrl!.isNotEmpty;
    return _bubble(
      label: first,
      onTap: () => onTapContact(c),
      labelColor: t.stone,
      circle: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(colors: [
            GwTokens.gold,
            GwTokens.ember,
            GwTokens.sage,
            GwTokens.gold,
          ]),
        ),
        padding: const EdgeInsets.all(2.2),
        child: CircleAvatar(
          backgroundColor: t.inkLift,
          backgroundImage: hasAvatar ? NetworkImage(c.avatarUrl!) : null,
          child: hasAvatar
              ? null
              : Text(initial,
                  style: GwType.display(fontSize: 18, color: t.goldText)),
        ),
      ),
    );
  }

  Widget _bubble({
    required String label,
    required Widget circle,
    required VoidCallback onTap,
    required Color labelColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 74,
        child: Column(
          children: [
            SizedBox(width: 58, height: 58, child: circle),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GwType.ui(
                  fontSize: 11.5, color: labelColor, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
