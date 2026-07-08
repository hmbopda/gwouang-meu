import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/connectivity/connectivity_service.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';

/// Bande « hors ligne » Tissage — fond ember, texte blanc ≥ 12 px.
class OfflineBanner extends ConsumerWidget {
  final Widget child;

  const OfflineBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider);

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: online ? 0 : 32,
          color: GwTokens.ember,
          child: online
              ? const SizedBox.shrink()
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Symbols.wifi_off,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Hors ligne — données en cache',
                      style: GwType.ui(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
