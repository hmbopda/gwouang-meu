import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/router/breadcrumb_provider.dart';
import 'package:gwangmeu/core/router/route_names.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/messages/messages_providers.dart';
import 'package:gwangmeu/features/profile/profile_notifier.dart';

/// Définition d'un item de la navigation globale.
class NavRailItem {
  const NavRailItem({
    required this.icon,
    required this.label,
    this.accent,
    this.route,
    this.hasBadge = false,
    this.isSeparator = false,
  });

  final IconData icon;

  /// Couleur propre de l'icône (rail maquette « Héritage clair » : maison
  /// terracotta, montagne brune, arbre vert…). Null → couleur du texte.
  final Color? accent;
  final String label;
  final String? route;

  /// Badge non-lus (Messages).
  final bool hasBadge;
  final bool isSeparator;

  static const separator =
      NavRailItem(icon: Symbols.remove, label: '', isSeparator: true);
}

/// Brun patrimonial de la charte (montagne Villages, valise Emploi).
const _brown = Color(0xFF3B2A16);

/// Gris pierre (bulle Messages, micro Live).
const _stoneGrey = Color(0xFF6B6255);

/// Navigation globale — les 5 mêmes destinations que la bottom nav mobile
/// (#2d, parité 1:1), puis les entrées futures sous « Plus (bientôt) ».
/// Icônes pleines COLORÉES, fidèles au rail de la maquette 1a.
const kNavItems = [
  NavRailItem(
      icon: Symbols.cottage,
      accent: GwTokens.ember,
      label: 'Fil',
      route: Routes.feed),
  NavRailItem(
      icon: Symbols.landscape,
      accent: _brown,
      label: 'Villages',
      route: Routes.villages),
  NavRailItem(
      icon: Symbols.park,
      accent: GwTokens.sage,
      label: 'Lignées',
      route: Routes.genealogy),
  NavRailItem(
      icon: Symbols.chat_bubble,
      accent: _stoneGrey,
      label: 'Messages',
      route: Routes.messages,
      hasBadge: true),
  NavRailItem(
      icon: Symbols.person,
      accent: GwTokens.azure,
      label: 'Profil',
      route: Routes.profile),
  NavRailItem.separator,
  NavRailItem(
      icon: Symbols.school, accent: GwTokens.gold, label: 'Formations'),
  NavRailItem(icon: Symbols.mic, accent: _stoneGrey, label: 'Live'),
  NavRailItem(
      icon: Symbols.travel_explore, accent: GwTokens.azure, label: 'Tourisme'),
  NavRailItem(icon: Symbols.work, accent: _brown, label: 'Emploi'),
];

/// Rail desktop 216 px (#2d) — icônes Material Symbols + labels
/// (remplace le rail emoji 64 px). Actif = fond or 14 % + icône FILL 1.
class IconRail extends ConsumerWidget {
  const IconRail({super.key});

  static const double width = 216;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final location = GoRouterState.of(context).matchedLocation;
    final unread = ref.watch(unreadMessagesCountProvider);

    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 16),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: t.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Logo ──
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: GwTokens.gold,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'G',
                    style: GwType.display(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        color: const Color(0xFF0C0B0F)),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Gwang Meu',
                  style: GwType.display(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      color: t.stone),
                ),
              ],
            ),
          ),

          // ── Destinations ──
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final item in kNavItems)
                    if (item.isSeparator)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: t.line)),
                        ),
                        child: Text(
                          'PLUS (BIENTÔT)',
                          style: GwType.mono(
                              fontSize: 10,
                              letterSpacing: 2,
                              color: t.stoneFaint),
                        ),
                      )
                    else
                      _RailItem(
                        item: item,
                        isActive: item.route != null &&
                            location.startsWith(item.route!),
                        badgeCount: item.hasBadge ? unread : 0,
                        onTap: item.route != null
                            ? () {
                                ref
                                    .read(breadcrumbProvider.notifier)
                                    .clear();
                                context.go(item.route!);
                              }
                            : () => _showComingSoon(context, item.label),
                      ),
                ],
              ),
            ),
          ),

          // ── Carte utilisateur ──
          const _UserCard(),
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

// ─── Item du rail ────────────────────────────────────────────

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.item,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
  });

  final NavRailItem item;
  final bool isActive;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final isFuture = item.route == null;
    final color = isActive
        ? t.goldText
        : isFuture
            ? t.stoneFaint
            : t.stoneMid;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: isActive ? t.goldBg : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: GwTokens.tapTarget,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Slot fixe 24 px : l'icône est centrée dedans, si bien que
                // tous les labels démarrent à la même abscisse. Icône PLEINE
                // colorée (maquette 1a), estompée pour les items « bientôt ».
                SizedBox(
                  width: 24,
                  child: Center(
                    child: Icon(
                      item.icon,
                      size: 20,
                      fill: 1,
                      color: (item.accent ?? color)
                          .withValues(alpha: isFuture ? 0.45 : 1),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: GwType.ui(
                      fontSize: 14,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w400,
                      color: color,
                    ),
                  ),
                ),
                if (badgeCount > 0)
                  Container(
                    constraints:
                        const BoxConstraints(minWidth: 20, minHeight: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: GwTokens.ember,
                      borderRadius: BorderRadius.circular(GwTokens.rPill),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$badgeCount',
                      style: GwType.ui(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
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

// ─── Carte utilisateur ───────────────────────────────────────

class _UserCard extends ConsumerWidget {
  const _UserCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final user = ref.watch(profileNotifierProvider).valueOrNull;
    final name = user?.displayName ?? 'Membre';

    return Material(
      color: t.inkCard,
      borderRadius: BorderRadius.circular(GwTokens.rBtn),
      child: InkWell(
        onTap: () {
          ref.read(breadcrumbProvider.notifier).clear();
          context.go(Routes.profile);
        },
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                    color: GwTokens.gold, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'M',
                  style: GwType.display(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0C0B0F)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GwType.ui(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: t.stone),
                    ),
                    if (user?.email != null)
                      Text(
                        user!.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            GwType.ui(fontSize: 11.5, color: t.stoneFaint),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
