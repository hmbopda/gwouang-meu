import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_notifier.dart';

/// Bouton qui ouvre un popup de personnalisation (mode + couleur).
class AccentColorButton extends ConsumerWidget {
  const AccentColorButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);

    return Tooltip(
      message: 'Apparence',
      child: InkWell(
        onTap: () => _showPicker(context),
        borderRadius: BorderRadius.circular(99),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.color.withAlpha(30),
            border: Border.all(color: accent.color.withAlpha(80)),
          ),
          child: Center(
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.color,
                boxShadow: [
                  BoxShadow(color: accent.color.withAlpha(80), blurRadius: 6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset position = button.localToGlobal(Offset.zero);
    final Size size = button.size;

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(ctx).pop(),
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            top: position.dy + size.height + 8,
            right: MediaQuery.of(context).size.width - position.dx - size.width,
            child: const _AppearancePopup(),
          ),
        ],
      ),
    );
  }
}

// ── Popup complet : mode + couleur ──────────────────────────

class _AppearancePopup extends ConsumerWidget {
  const _AppearancePopup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(displayModeProvider);
    final currentAccent = ref.watch(accentColorProvider);
    final popupBg = Theme.of(context).colorScheme.surfaceContainerHighest;
    final subtitleColor = Theme.of(context).textTheme.bodySmall?.color ?? const Color(0xFF666666);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: popupBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withAlpha(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(120),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Mode d'affichage ──
            Text(
              'MODE D\'AFFICHAGE',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: subtitleColor,
              ),
            ),
            const SizedBox(height: 10),

            // Grille 2x2 des modes
            Row(
              children: [
                Expanded(
                  child: _ModeCard(
                    mode: DisplayMode.dark,
                    isSelected: currentMode == DisplayMode.dark,
                    onTap: () => ref.read(displayModeProvider.notifier).setMode(DisplayMode.dark),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ModeCard(
                    mode: DisplayMode.light,
                    isSelected: currentMode == DisplayMode.light,
                    onTap: () => ref.read(displayModeProvider.notifier).setMode(DisplayMode.light),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ModeCard(
                    mode: DisplayMode.amoled,
                    isSelected: currentMode == DisplayMode.amoled,
                    onTap: () => ref.read(displayModeProvider.notifier).setMode(DisplayMode.amoled),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ModeCard(
                    mode: DisplayMode.highContrast,
                    isSelected: currentMode == DisplayMode.highContrast,
                    onTap: () => ref.read(displayModeProvider.notifier).setMode(DisplayMode.highContrast),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ── Couleur d'accent ──
            Text(
              'COULEUR D\'ACCENT',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: subtitleColor,
              ),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kAccentColors.map((accent) {
                final isSelected = accent.name == currentAccent.name;
                return _ColorDot(
                  accent: accent,
                  isSelected: isSelected,
                  onTap: () {
                    ref.read(accentColorProvider.notifier).setAccent(accent);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 10),

            // Nom couleur active
            Center(
              child: Text(
                currentAccent.name,
                style: TextStyle(
                  fontSize: 11,
                  color: currentAccent.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Carte de mode ───────────────────────────────────────────

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  final DisplayMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? accent.withAlpha(20) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? accent : Theme.of(context).colorScheme.outline.withAlpha(40),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              mode.icon,
              size: 20,
              color: isSelected ? accent : Theme.of(context).textTheme.bodyMedium?.color,
            ),
            const SizedBox(height: 4),
            Text(
              mode.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? accent : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dot de couleur ──────────────────────────────────────────

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.accent,
    required this.isSelected,
    required this.onTap,
  });

  final AccentColor accent;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: accent.name,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.color.withAlpha(isSelected ? 40 : 15),
            border: Border.all(
              color: isSelected ? accent.color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 18 : 16,
              height: isSelected ? 18 : 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.color,
                boxShadow: isSelected
                    ? [BoxShadow(color: accent.color.withAlpha(100), blurRadius: 8, spreadRadius: 1)]
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
