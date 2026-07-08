import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/shared/widgets/gwang_button.dart';

/// Widget d'erreur avec bouton de réessai.
class GwangErrorWidget extends StatelessWidget {
  const GwangErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Symbols.error,
  });

  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: t.stoneDim),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GwType.ui(fontSize: 14, color: t.stoneMid, height: 1.5),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              GwangButton(
                label: 'Réessayer',
                onPressed: onRetry,
                fullWidth: false,
                variant: GwangButtonVariant.outline,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget état vide.
class GwangEmptyWidget extends StatelessWidget {
  const GwangEmptyWidget({
    super.key,
    required this.message,
    this.icon = Symbols.inbox,
    this.action,
    this.actionLabel,
  });

  final String message;
  final IconData icon;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: t.stoneDim),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GwType.ui(fontSize: 14, color: t.stoneMid, height: 1.5),
            ),
            if (action != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              GwangButton(
                  label: actionLabel!, onPressed: action, fullWidth: false),
            ],
          ],
        ),
      ),
    );
  }
}
