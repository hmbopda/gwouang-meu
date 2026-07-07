import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/router/breadcrumb_provider.dart';
import 'package:gwangmeu/core/router/route_names.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/notifications/notifications_notifier.dart';
import 'package:gwangmeu/features/notifications/widgets/notification_panel.dart';

/// Topbar desktop 60 px (#2d) — fil d'Ariane mono « GWANG MEU — SECTION »,
/// recherche 44 px, cloche 44 px avec point ember.
class TopBar extends ConsumerWidget {
  const TopBar({super.key});

  static const double height = 60;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final location = GoRouterState.of(context).matchedLocation;
    final breadcrumbs = ref.watch(breadcrumbProvider);

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      child: Row(
        children: [
          // ── Fil d'Ariane mono ──
          Expanded(
            child: breadcrumbs.isNotEmpty
                ? _DynamicBreadcrumb(crumbs: breadcrumbs)
                : _StaticBreadcrumb(sectionName: _sectionName(location)),
          ),

          // ── Recherche 44 px ──
          const _SearchBar(),
          const SizedBox(width: 14),

          // ── Notifications 44 px ──
          const _NotificationButton(),
        ],
      ),
    );
  }

  String _sectionName(String location) {
    if (location.startsWith(Routes.feed)) return 'Fil';
    if (location.startsWith(Routes.genealogy)) return 'Lignées';
    if (location.startsWith(Routes.profile)) return 'Profil';
    if (location.startsWith(Routes.search)) return 'Recherche';
    if (location.startsWith(Routes.messages)) return 'Messages';
    if (location.startsWith('/my-villages')) return 'Mes villages';
    if (location.startsWith('/villages/create')) return 'Villages › Créer';
    if (location.contains('/edit')) return 'Villages › Édition';
    if (location.startsWith('/villages/')) return 'Villages › Détail';
    if (location.contains('villages')) return 'Villages';
    return 'Fil';
  }
}

// ─── Fil d'Ariane dynamique ──────────────────────────────────

class _DynamicBreadcrumb extends ConsumerWidget {
  const _DynamicBreadcrumb({required this.crumbs});
  final List<BreadcrumbEntry> crumbs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'GWANG MEU',
          style: GwType.mono(
              fontSize: 10, letterSpacing: 1.5, color: t.stoneFaint),
        ),
        for (int i = 0; i < crumbs.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text('—',
                style: GwType.mono(fontSize: 10, color: t.stoneFaint)),
          ),
          if (i < crumbs.length - 1)
            InkWell(
              onTap: () {
                ref.read(breadcrumbProvider.notifier).popTo(crumbs[i].route);
                context.go(crumbs[i].route);
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  crumbs[i].label.toUpperCase(),
                  style: GwType.mono(
                      fontSize: 10, letterSpacing: 1, color: t.stoneFaint),
                ),
              ),
            )
          else
            Text(
              crumbs[i].label.toUpperCase(),
              style: GwType.mono(
                fontSize: 10,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
                color: t.goldText,
              ),
            ),
        ],
      ],
    );
  }
}

// ─── Fil d'Ariane statique ───────────────────────────────────

class _StaticBreadcrumb extends StatelessWidget {
  const _StaticBreadcrumb({required this.sectionName});
  final String sectionName;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'GWANG MEU',
          style: GwType.mono(
              fontSize: 10, letterSpacing: 1.5, color: t.stoneFaint),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child:
              Text('—', style: GwType.mono(fontSize: 10, color: t.stoneFaint)),
        ),
        Text(
          sectionName.toUpperCase(),
          style: GwType.mono(
            fontSize: 10,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
            color: t.goldText,
          ),
        ),
      ],
    );
  }
}

// ─── Recherche 320×44 ────────────────────────────────────────

class _SearchBar extends ConsumerWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);

    return Material(
      color: t.inkCard,
      borderRadius: BorderRadius.circular(GwTokens.rPill),
      child: InkWell(
        onTap: () {
          ref.read(breadcrumbProvider.notifier).clear();
          context.go(Routes.search);
        },
        borderRadius: BorderRadius.circular(GwTokens.rPill),
        child: Container(
          width: 320,
          height: GwTokens.tapTarget,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GwTokens.rPill),
            border: Border.all(color: t.lineMid),
          ),
          child: Row(
            children: [
              Icon(Symbols.search, size: 18, color: t.stoneDim),
              const SizedBox(width: 10),
              Text(
                'Rechercher…',
                style: GwType.ui(fontSize: 13.5, color: t.stoneDim),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Cloche 44 px ────────────────────────────────────────────

class _NotificationButton extends ConsumerWidget {
  const _NotificationButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final unread = ref.watch(unreadCountProvider).valueOrNull ?? 0;

    return Material(
      color: t.inkCard,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () => _openPanel(context),
        customBorder: const CircleBorder(),
        child: Container(
          width: GwTokens.tapTarget,
          height: GwTokens.tapTarget,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: t.lineMid),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Symbols.notifications, size: 19, color: t.stoneMid),
              if (unread > 0)
                Positioned(
                  top: 8,
                  right: 9,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: GwTokens.ember,
                      shape: BoxShape.circle,
                      border: Border.all(color: t.ink, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPanel(BuildContext context) {
    final t = GwTokens.of(context);
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) => Stack(
        children: [
          Positioned(
            top: 64,
            right: 24,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 400,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(ctx).height - 100,
                ),
                decoration: BoxDecoration(
                  color: t.inkCard,
                  borderRadius: BorderRadius.circular(GwTokens.rCard),
                  border: Border.all(color: t.lineMid),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black38,
                        blurRadius: 24,
                        offset: Offset(0, 8)),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: const NotificationPanel(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
