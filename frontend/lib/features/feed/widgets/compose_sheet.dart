import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/feed/feed_notifier.dart';
import 'package:gwangmeu/features/villages/villages_notifier.dart';
import 'package:gwangmeu/shared/widgets/gw_dialog.dart';

/// Ouvre la feuille de composition d'une publication.
Future<void> showComposeSheet(BuildContext context) {
  return showGwDialog(context, builder: (_) => const _ComposeSheet());
}

class _ComposeSheet extends ConsumerStatefulWidget {
  const _ComposeSheet();

  @override
  ConsumerState<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends ConsumerState<_ComposeSheet> {
  final _ctrl = TextEditingController();
  String? _villageId; // null = publication personnelle
  bool _publishing = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _publishing) return;
    setState(() => _publishing = true);
    try {
      await ref
          .read(feedNotifierProvider.notifier)
          .createPost(content: text, villageId: _villageId);
      if (mounted) Navigator.of(context).maybePop();
    } catch (_) {
      if (mounted) {
        setState(() => _publishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: GwTokens.ember,
            content: Text("La publication n'a pas pu être envoyée",
                style: GwType.ui(fontSize: 14, color: GwTokens.inkOnGold)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final villages = ref.watch(myVillagesNotifierProvider).valueOrNull ?? const [];

    return GwDialog(
      title: 'Nouvelle publication',
      subtitle: 'Partagez avec votre communauté',
      icon: Symbols.edit_square,
      actions: [
        GwDialogAction(
          label: 'Publier',
          primary: true,
          loading: _publishing,
          onPressed: _publish,
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _ctrl,
            autofocus: true,
            minLines: 3,
            maxLines: 8,
            style: GwType.ui(fontSize: 15, color: t.stone, height: 1.5),
            decoration: InputDecoration(
              hintText: 'Quoi de neuf dans votre communauté ?',
              hintStyle: GwType.ui(fontSize: 14.5, color: t.stoneDim),
              filled: true,
              fillColor: t.inkLift,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(GwTokens.rBtn),
                borderSide: BorderSide(color: t.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(GwTokens.rBtn),
                borderSide: BorderSide(color: t.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(GwTokens.rBtn),
                borderSide: const BorderSide(color: GwTokens.gold, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('PUBLIER DANS',
              style: GwType.mono(
                  fontSize: 10, letterSpacing: 1.5, color: t.stoneFaint)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _scopePill(
                t,
                label: 'Personnel',
                icon: Symbols.person,
                selected: _villageId == null,
                onTap: () => setState(() => _villageId = null),
              ),
              for (final v in villages)
                _scopePill(
                  t,
                  label: v.name,
                  icon: Symbols.holiday_village,
                  selected: _villageId == v.id,
                  onTap: () => setState(() => _villageId = v.id),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scopePill(
    GwTokens t, {
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final accent = selected ? GwTokens.gold : t.stoneMid;
    return Material(
      color: selected ? GwTokens.gold.withValues(alpha: 0.14) : t.inkLift,
      borderRadius: BorderRadius.circular(GwTokens.rPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GwTokens.rPill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GwTokens.rPill),
            border: Border.all(
                color: selected ? GwTokens.gold : t.line, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: accent),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GwType.ui(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? t.goldText : t.stone),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
