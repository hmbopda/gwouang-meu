import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gwangmeu/core/router/breadcrumb_provider.dart';
import 'package:gwangmeu/core/router/route_names.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/notifications/widgets/notification_bell.dart';
import 'package:gwangmeu/features/home/widgets/accent_color_picker.dart';

/// Barre supérieure du layout desktop — breadcrumb dynamique, recherche, notifications, users.
class TopBar extends ConsumerWidget {
  const TopBar({super.key});

  static const double height = 52;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final cs = Theme.of(context).colorScheme;
    final breadcrumbs = ref.watch(breadcrumbProvider);

    final bgColor = Theme.of(context).scaffoldBackgroundColor.withAlpha(235);
    final borderColor = cs.outline.withAlpha(30);

    final fallbackSection = _sectionName(location);

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          // ── Breadcrumb (dynamique si disponible, sinon fallback) ──
          breadcrumbs.isNotEmpty
              ? _DynamicBreadcrumb(crumbs: breadcrumbs)
              : _StaticBreadcrumb(sectionName: fallbackSection),

          const Spacer(),

          // ── Search ──
          const _SearchBar(),

          const SizedBox(width: 16),

          // ── Actions ──
          const _ActionButton(
            icon: Icons.notifications_outlined,
            hasDot: true,
            child: NotificationBell(),
          ),
          const SizedBox(width: 8),
          _IconCircle(
            icon: Icons.people_outline,
            hasDot: false,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Communauté — bientôt disponible'),
                duration: Duration(seconds: 2),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _IconCircle(
            icon: Icons.chat_bubble_outline,
            hasDot: true,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Messages — bientôt disponible'),
                duration: Duration(seconds: 2),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ── Accent color picker ──
          const AccentColorButton(),
        ],
      ),
    );
  }

  String _sectionName(String location) {
    if (location.startsWith(Routes.feed)) return 'Fil d\'actualité';
    if (location == Routes.villages || location.startsWith('${Routes.villages}/')) return 'Villages';
    if (location.startsWith(Routes.genealogy)) return 'Généalogie';
    if (location.startsWith(Routes.profile)) return 'Profil';
    if (location.startsWith(Routes.search)) return 'Recherche';
    if (location.startsWith('/my-villages')) return 'Mes villages';
    if (location.startsWith('/villages/create')) return 'Villages › Créer';
    if (location.contains('/edit')) return 'Villages › Édition';
    if (location.startsWith('/villages/')) return 'Villages › Détail';
    return 'Accueil';
  }
}

// ─── Dynamic Breadcrumb (from provider) ──────────────────────────────────────

class _DynamicBreadcrumb extends ConsumerWidget {
  const _DynamicBreadcrumb({required this.crumbs});
  final List<BreadcrumbEntry> crumbs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // GWANG MEU prefix
        Text(
          'GWANG MEU',
          style: TextStyle(fontFamily: 'monospace', fontSize: 9, letterSpacing: 1.2, color: GwTokens.dark.stoneDim),
        ),

        // Breadcrumb segments
        for (int i = 0; i < crumbs.length; i++) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text('—', style: TextStyle(color: GwTokens.dark.stoneDim, fontSize: 9)),
          ),
          if (i < crumbs.length - 1)
            // Clickable intermediate segment
            InkWell(
              onTap: () {
                ref.read(breadcrumbProvider.notifier).popTo(crumbs[i].route);
                context.go(crumbs[i].route);
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  crumbs[i].label.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    letterSpacing: 1,
                    color: GwTokens.dark.stoneDim,
                  ),
                ),
              ),
            )
          else
            // Last segment (active, not clickable)
            Text(
              crumbs[i].label.toUpperCase(),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                letterSpacing: 1,
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ],
    );
  }
}

// ─── Static Breadcrumb (fallback) ────────────────────────────────────────────

class _StaticBreadcrumb extends StatelessWidget {
  const _StaticBreadcrumb({required this.sectionName});
  final String sectionName;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'GWANG MEU',
          style: TextStyle(fontFamily: 'monospace', fontSize: 9, letterSpacing: 1.2, color: GwTokens.dark.stoneDim),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('—', style: TextStyle(color: GwTokens.dark.stoneDim, fontSize: 9)),
        ),
        Text(
          sectionName.toUpperCase(),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 9,
            letterSpacing: 1,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

// ─── Search Bar ──────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final borderColor = Theme.of(context).colorScheme.outline.withAlpha(30);

    return Container(
      width: 320,
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 14, color: GwTokens.dark.stoneDim),
          SizedBox(width: 8),
          Expanded(
            child: Text('Rechercher…', style: TextStyle(fontSize: 12, color: GwTokens.dark.stoneDim)),
          ),
        ],
      ),
    );
  }
}

// ─── Action Buttons ──────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    this.hasDot = false,
    required this.child,
  });

  final IconData icon;
  final bool hasDot;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class _IconCircle extends StatelessWidget {
  const _IconCircle({
    required this.icon,
    this.hasDot = false,
    required this.onTap,
  });

  final IconData icon;
  final bool hasDot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final borderColor = Theme.of(context).colorScheme.outline.withAlpha(30);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor),
            ),
            child: Icon(icon, size: 14, color: GwTokens.dark.stoneMid),
          ),
          if (hasDot)
            Positioned(
              top: 5,
              right: 5,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
