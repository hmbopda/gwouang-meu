import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gwangmeu/core/router/breadcrumb_provider.dart';
import 'package:gwangmeu/core/router/route_names.dart';
import 'package:gwangmeu/features/home/widgets/accent_color_picker.dart';
import 'package:gwangmeu/features/home/widgets/icon_rail.dart';
import 'package:gwangmeu/features/home/widgets/top_bar.dart';

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
      body: Row(
        children: [
          // ── Icon Rail (64px, fixe à gauche) ──
          const IconRail(),

          // ── Zone principale (TopBar + Content) ──
          Expanded(
            child: Column(
              children: [
                // TopBar
                const TopBar(),

                // Contenu routé
                Expanded(child: child),
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

  static const _tabs = [
    _TabItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Accueil',
      route: Routes.feed,
    ),
    _TabItem(
      icon: Icons.location_city_outlined,
      activeIcon: Icons.location_city,
      label: 'Villages',
      route: Routes.villages,
    ),
    _TabItem(
      icon: Icons.account_tree_outlined,
      activeIcon: Icons.account_tree,
      label: 'Généalogie',
      route: Routes.genealogy,
    ),
    _TabItem(
      icon: Icons.search_outlined,
      activeIcon: Icons.search,
      label: 'Recherche',
      route: Routes.search,
    ),
    _TabItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profil',
      route: Routes.profile,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    var currentIndex = _tabs.indexWhere((t) => location.startsWith(t.route));
    // Routes internes villages/my-villages → surligner l'onglet Villages
    if (currentIndex < 0 && (location.startsWith('/villages') || location.startsWith('/my-villages'))) {
      currentIndex = _tabs.indexWhere((t) => t.route == Routes.villages);
    }

    return Scaffold(
      // ── Drawer mobile (équivalent de l'Icon Rail) ──
      drawer: _MobileDrawer(currentLocation: location),
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            BottomNavigationBar(
              currentIndex: currentIndex < 0 ? 0 : currentIndex,
              onTap: (i) {
                ref.read(breadcrumbProvider.notifier).clear();
                context.go(_tabs[i].route);
              },
              items: _tabs.map((t) {
                return BottomNavigationBarItem(
                  icon: Icon(t.icon),
                  activeIcon: Icon(t.activeIcon),
                  label: t.label,
                  tooltip: t.label,
                );
              }).toList(),
            ),
            // Accent color picker (en haut à droite de la bottom nav)
            const Positioned(
              right: 8,
              top: 4,
              child: AccentColorButton(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
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
                Text(item.icon, style: const TextStyle(fontSize: 18)),
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
                if (item.badge != null && item.badge! > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${item.badge}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
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
