import 'package:flutter/material.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/shared/widgets/gwang_button.dart';

/// Widget d'erreur avec bouton de réessai.
class GwangErrorWidget extends StatelessWidget {
  const GwangErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: GwTokens.dark.stoneDim),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: GwTokens.dark.stoneMid,
                  ),
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
    this.icon = Icons.inbox_outlined,
    this.action,
    this.actionLabel,
  });

  final String message;
  final IconData icon;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: GwTokens.dark.stoneDim),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: GwTokens.dark.stoneMid,
                  ),
            ),
            if (action != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              GwangButton(label: actionLabel!, onPressed: action, fullWidth: false),
            ],
          ],
        ),
      ),
    );
  }
}
