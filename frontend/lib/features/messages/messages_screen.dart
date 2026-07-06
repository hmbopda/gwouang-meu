import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';

/// Messages — liste des conversations (#3a).
/// Destination de premier niveau (bottom nav).
class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const GwWeaveBand(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Messages',
                      style: GwType.display(fontSize: 22, color: t.stone),
                    ),
                  ),
                  Material(
                    color: t.inkLift,
                    borderRadius: BorderRadius.circular(GwTokens.rBtn),
                    child: InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(GwTokens.rBtn),
                      child: SizedBox(
                        width: GwTokens.tapTarget,
                        height: GwTokens.tapTarget,
                        child: Icon(Symbols.edit_square,
                            size: 22, color: t.goldText),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Symbols.forum, size: 48, color: t.stoneFaint),
                    const SizedBox(height: 12),
                    Text(
                      'Vos conversations arrivent ici',
                      style: GwType.ui(fontSize: 14, color: t.stoneMid),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
