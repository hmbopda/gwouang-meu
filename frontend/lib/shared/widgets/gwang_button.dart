import 'package:flutter/material.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';

enum GwangButtonVariant { primary, outline, ghost }

/// Bouton custom GWANG MEU — couleur or, 3 variantes.
class GwangButton extends StatelessWidget {
  const GwangButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = GwangButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final GwangButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: GwTokens.inkOnGold,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              // Flexible + ellipsis : un libellé long ne déborde plus du bouton
              // (ni troncature brutale au milieu du texte).
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );

    switch (variant) {
      case GwangButtonVariant.primary:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          child: ElevatedButton(
            onPressed: loading ? null : onPressed,
            child: child,
          ),
        );

      case GwangButtonVariant.outline:
        final accent = Theme.of(context).colorScheme.primary;
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          child: OutlinedButton(
            onPressed: loading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              side: BorderSide(color: accent),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              minimumSize: const Size(0, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(GwTokens.rBtn)),
            ),
            child: child,
          ),
        );

      case GwangButtonVariant.ghost:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          child: TextButton(
            onPressed: loading ? null : onPressed,
            style: TextButton.styleFrom(
              foregroundColor: GwTokens.of(context).stoneMid,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              minimumSize: const Size(0, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(GwTokens.rBtn)),
            ),
            child: child,
          ),
        );
    }
  }
}
