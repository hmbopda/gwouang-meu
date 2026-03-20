import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gwangmeu/core/router/breadcrumb_provider.dart';
import 'package:gwangmeu/core/router/route_names.dart';

/// Définition d'un item de la barre latérale icônes.
class NavRailItem {
  const NavRailItem({
    required this.icon,
    required this.label,
    this.route,
    this.badge,
    this.isSeparator = false,
  });

  final String icon; // emoji
  final String label;
  final String? route;
  final int? badge;
  final bool isSeparator;

  static const separator = NavRailItem(icon: '', label: '', isSeparator: true);
}

/// Items de navigation globale — reproduit la maquette HTML.
const kNavItems = [
  NavRailItem(icon: '📰', label: 'Fil', route: Routes.feed),
  NavRailItem(icon: '👤', label: 'Profil', route: Routes.profile),
  NavRailItem(icon: '🏘', label: 'Villages', route: Routes.villages),
  NavRailItem(icon: '🌳', label: 'Généalogie', route: Routes.genealogy),
  NavRailItem.separator,
  NavRailItem(icon: '🎓', label: 'Formations', badge: 4),
  NavRailItem(icon: '🔴', label: 'Live', badge: 2),
  NavRailItem.separator,
  NavRailItem(icon: '🗺', label: 'Tourisme'),
  NavRailItem(icon: '💼', label: 'Emploi'),
  NavRailItem(icon: '💬', label: 'Messages', badge: 3),
];

/// Barre latérale verticale d'icônes (desktop, 64px) — fidèle à la maquette.
class IconRail extends ConsumerWidget {
  const IconRail({super.key});

  static const double width = 64;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final borderColor = Theme.of(context).colorScheme.outline.withAlpha(30);

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: scaffoldBg,
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: Column(
        children: [
          _Logo(borderColor: borderColor),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: kNavItems.map((item) {
                  if (item.isSeparator) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Container(width: 28, height: 1, color: borderColor),
                    );
                  }
                  final isActive =
                      item.route != null && location.startsWith(item.route!);
                  return _RailItem(
                    item: item,
                    isActive: isActive,
                    onTap: item.route != null
                        ? () {
                            ref.read(breadcrumbProvider.notifier).clear();
                            context.go(item.route!);
                          }
                        : () => _showComingSoon(context, item.label),
                  );
                }).toList(),
              ),
            ),
          ),
          const _UserAvatar(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label — bientôt disponible'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ─── Logo ─────────────────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  const _Logo({required this.borderColor});
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final accentLight = Theme.of(context).colorScheme.secondary;
    final accentDark = HSLColor.fromColor(accent).withLightness(
      (HSLColor.fromColor(accent).lightness - 0.15).clamp(0.0, 1.0),
    ).toColor();

    return Container(
      height: 52,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Center(
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accentDark, accent, accentLight],
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withAlpha(65),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            'G',
            style: TextStyle(
              color: Theme.of(context).scaffoldBackgroundColor,
              fontWeight: FontWeight.w600,
              fontSize: 16,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Rail Item ────────────────────────────────────────────────────────────────

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final NavRailItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Tooltip(
        message: item.label,
        preferBelow: false,
        waitDuration: const Duration(milliseconds: 400),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Indicateur actif (trait coloré à gauche)
            if (isActive)
              Positioned(
                left: -1,
                top: 8,
                bottom: 8,
                child: Container(
                  width: 2,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

            // Bouton icône
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isActive ? accent.withAlpha(18) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(item.icon, style: const TextStyle(fontSize: 17)),
              ),
            ),

            // Badge
            if (item.badge != null && item.badge! > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${item.badge}',
                    style: TextStyle(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      fontSize: 7.5,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── User Avatar ──────────────────────────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  const _UserAvatar();

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final accentDark = HSLColor.fromColor(accent).withLightness(
      (HSLColor.fromColor(accent).lightness - 0.15).clamp(0.0, 1.0),
    ).toColor();

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accentDark, accent],
        ),
        border: Border.all(color: accent.withAlpha(46), width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        'SM',
        style: TextStyle(
          color: Theme.of(context).scaffoldBackgroundColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
