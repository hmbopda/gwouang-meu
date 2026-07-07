import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';

/// Contrôles de zoom flottants (+, −, recentrer) — cibles 44 px.
class TreeZoomControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  const TreeZoomControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn(t, Symbols.add, 'Zoomer', onZoomIn),
        const SizedBox(height: 6),
        _btn(t, Symbols.remove, 'Dézoomer', onZoomOut),
        const SizedBox(height: 6),
        _btn(t, Symbols.center_focus_strong, 'Recentrer', onReset),
      ],
    );
  }

  Widget _btn(GwTokens t, IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: t.inkCard,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: GwTokens.tapTarget,
            height: GwTokens.tapTarget,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t.line),
            ),
            child: Icon(icon, size: 18, color: t.stoneMid),
          ),
        ),
      ),
    );
  }
}
