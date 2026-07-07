import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/router/breadcrumb_provider.dart';
import 'package:gwangmeu/core/router/route_names.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/home/widgets/icon_rail.dart';
import 'package:gwangmeu/features/home/widgets/top_bar.dart';
import 'package:gwangmeu/features/messages/messages_providers.dart';

/// Shell de navigation responsive :
/// - Desktop (>= 1024px) : Icon Rail + TopBar + Content
/// - Mobile  (< 1024px)  : Bottom Nav + Drawer
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1024) {
      return _DesktopShell(child: child);
    }
    return _MobileShell(child: child);
  }
}

// =============================================================================
//  DESKTOP LAYOUT (>= 1024px) — Icon Rail + TopBar + Content
// =============================================================================

class _DesktopShell extends ConsumerWidget {
  const _DesktopShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Bande tissée signature ──
          const GwWeaveBand(),
          Expanded(
            child: Row(
              children: [
                // ── Rail 216px avec labels (#2d) ──
                const IconRail(),

                // ── Zone principale (TopBar 60px + Content) ──
                Expanded(
                  child: Column(
                    children: [
                      const TopBar(),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
//  MOBILE LAYOUT (< 1024px) — Bottom Nav + Drawer accessible
// =============================================================================

class _MobileShell extends ConsumerWidget {
  const _MobileShell({required this.child});
  final Widget child;

  /// Les 5 vraies destinations « Tissage » (#1a) :
  /// Fil · Villages · Lignées · Messages (badge) · Profil.
  static const _tabs = [
    _TabItem(icon: Symbols.home, label: 'Fil', route: Routes.feed),
    _TabItem(
        icon: Symbols.holiday_village,
        label: 'Villages',
        route: Routes.villages),
    _TabItem(
        icon: Symbols.family_history,
        label: 'Lignées',
        route: Routes.genealogy),
    _TabItem(
        icon: Symbols.forum,
        label: 'Messages',
        route: Routes.messages,
        hasBadge: true),
    _TabItem(icon: Symbols.person, label: 'Profil', route: Routes.profile),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    var currentIndex = _tabs.indexWhere((t) => location.startsWith(t.route));
    // Routes internes villages/my-villages → surligner l'onglet Villages
    if (currentIndex < 0 &&
        (location.startsWith('/villages') ||
            location.startsWith('/my-villages'))) {
      currentIndex = _tabs.indexWhere((t) => t.route == Routes.villages);
    }

    final t = GwTokens.of(context);
    final unread = ref.watch(unreadMessagesCountProvider);

    return Scaffold(
      // ── Drawer mobile (destinations secondaires : recherche, réglages…) ──
      drawer: _MobileDrawer(currentLocation: location),
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: t.inkCard,
          border: Border(top: BorderSide(color: t.line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
            child: Row(
              children: [
                for (int i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _NavDestination(
                      item: _tabs[i],
                      isActive: i == currentIndex,
                      badgeCount: _tabs[i].hasBadge ? unread : 0,
                      onTap: () {
                        ref.read(breadcrumbProvider.notifier).clear();
                        context.go(_tabs[i].route);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.route,
    this.hasBadge = false,
  });

  final IconData icon;
  final String label;
  final String route;
  final bool hasBadge;
}

/// Destination bottom nav — actif : pilule 52×32 or 16 % + icône remplie
/// + label 12 px w600 ; inactif : icône + label stoneMid.
class _NavDestination extends StatelessWidget {
  const _NavDestination({
    required this.item,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
  });

  final _TabItem item;
  final bool isActive;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final color = isActive ? t.goldText : t.stoneMid;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GwTokens.rBtn),
      child: Semantics(
        selected: isActive,
        button: true,
        label: item.label,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isActive ? t.goldBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(GwTokens.rPill),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    item.icon,
                    size: 22,
                    color: color,
                    fill: isActive ? 1 : 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: GwType.ui(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: color,
                  ),
                ),
              ],
            ),
            if (badgeCount > 0)
              Positioned(
                top: -2,
                right: 12,
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: GwTokens.ember,
                    borderRadius: BorderRadius.circular(GwTokens.rPill),
                    border: Border.all(color: t.inkCard, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$badgeCount',
                    style: GwType.ui(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

// =============================================================================
//  MOBILE DRAWER — Navigation complète (équivalent de l'Icon Rail)
// =============================================================================

class _MobileDrawer extends StatelessWidget {
  const _MobileDrawer({required this.currentLocation});
  final String currentLocation;

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Drawer(
      backgroundColor: bgColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Builder(builder: (ctx) {
                    final accent = Theme.of(ctx).colorScheme.primary;
                    final accentLight = Theme.of(ctx).colorScheme.secondary;
                    final accentDark = HSLColor.fromColor(accent).withLightness(
                      (HSLColor.fromColor(accent).lightness - 0.15).clamp(0.0, 1.0),
                    ).toColor();
                    return Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [accentDark, accent, accentLight],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'G',
                      style: TextStyle(
                        color: Theme.of(ctx).colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  );
                  }),
                  const SizedBox(width: 12),
                  Text(
                    'Gwang Meu',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),

            Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outline.withAlpha(30),
            ),

            // Nav items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final item in kNavItems)
                    if (item.isSeparator)
                      Divider(
                        height: 20,
                        indent: 20,
                        endIndent: 20,
                        color: Theme.of(context).colorScheme.outline.withAlpha(30),
                      )
                    else
                      _DrawerItem(
                        item: item,
                        isActive: item.route != null &&
                            currentLocation.startsWith(item.route!),
                        onTap: () {
                          Navigator.of(context).pop(); // close drawer
                          if (item.route != null) {
                            context.go(item.route!);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '${item.label} — bientôt disponible'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                ],
              ),
            ),

            // Footer avatar
            Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outline.withAlpha(30),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(40),
                    child: Text(
                      'SM',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Stéphane Mbopda',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isActive
                  ? accent.withAlpha(20)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isActive
                  ? Border(
                      left: BorderSide(
                        color: accent,
                        width: 2,
                      ),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(item.icon, size: 20,
                    color: isActive
                        ? accent
                        : Theme.of(context).textTheme.bodyMedium?.color),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: isActive
                          ? accent
                          : Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper for child screens to check desktop mode.
bool isDesktopLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= 1024;
