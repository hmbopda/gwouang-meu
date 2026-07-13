import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/router/breadcrumb_provider.dart';
import 'package:gwangmeu/core/router/route_names.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/core/theme/theme_notifier.dart';
import 'package:gwangmeu/features/feed/feed_notifier.dart';
import 'package:gwangmeu/features/feed/widgets/comment_sheet.dart';
import 'package:gwangmeu/features/feed/widgets/compose_sheet.dart';
import 'package:gwangmeu/features/feed/widgets/feed_post_card.dart';
import 'package:gwangmeu/features/home/home_screen.dart';
import 'package:gwangmeu/features/notifications/models/notification_model.dart';
import 'package:gwangmeu/features/notifications/notifications_notifier.dart';
import 'package:gwangmeu/features/notifications/widgets/notification_panel.dart';
import 'package:gwangmeu/features/profile/profile_notifier.dart';
import 'package:gwangmeu/features/villages/villages_notifier.dart';
import 'package:gwangmeu/shared/models/post_model.dart';
import 'package:gwangmeu/shared/widgets/loading_overlay.dart';

/// Fil « Tissage » dynamique — agrège en temps réel les publications ET les
/// notifications de tous les villages, clans, familles et groupes auxquels
/// l'utilisateur appartient, avec J'aime, commentaires et partage (façon
/// Facebook/Instagram, habillage maison).
class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desktop = isDesktopLayout(context);

    if (desktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 16,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: const _FeedBody(),
            ),
          ),
          const Expanded(flex: 10, child: _DesktopContextRail()),
        ],
      );
    }

    return const Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            GwWeaveBand(),
            _FeedHeader(),
            Expanded(child: _FeedBody()),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Corps du fil — liste fusionnée (publications + notifications)
// ─────────────────────────────────────────────────────────────────

/// Élément du fil : soit une publication, soit une notification.
class _FeedItem {
  _FeedItem.post(PostModel this.post)
      : notif = null,
        when = post.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  _FeedItem.notif(NotificationModel this.notif)
      : post = null,
        when = notif.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  final PostModel? post;
  final NotificationModel? notif;
  final DateTime when;
}

class _FeedBody extends ConsumerStatefulWidget {
  const _FeedBody();

  @override
  ConsumerState<_FeedBody> createState() => _FeedBodyState();
}

class _FeedBodyState extends ConsumerState<_FeedBody> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 400) {
      ref.read(feedNotifierProvider.notifier).loadMore();
    }
  }

  Future<void> _refresh() async {
    await ref.read(feedNotifierProvider.notifier).refresh();
    await ref.read(notificationsNotifierProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final feedState = ref.watch(feedNotifierProvider);

    return feedState.when(
      loading: () => const ShimmerList(count: 5, cardHeight: 200),
      error: (e, _) => _FeedError(
        onRetry: () => ref.read(feedNotifierProvider.notifier).refresh(),
      ),
      data: (posts) {
        // Notifications au mieux : si en erreur/chargement, le fil n'est pas bloqué.
        final notifs =
            ref.watch(notificationsNotifierProvider).valueOrNull ?? const [];

        final items = <_FeedItem>[
          ...posts.map(_FeedItem.post),
          ...notifs.map(_FeedItem.notif),
        ]..sort((a, b) => b.when.compareTo(a.when));

        return RefreshIndicator(
          color: t.goldText,
          onRefresh: _refresh,
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.only(top: 8, bottom: 20),
            itemCount: items.length + 2, // compose + items + éventuel vide
            itemBuilder: (context, index) {
              if (index == 0) return const _ComposeTrigger();
              if (index == 1 && items.isEmpty) return const _FeedEmpty();
              final itemIndex = index - 1;
              if (itemIndex >= items.length) return const SizedBox.shrink();
              final item = items[itemIndex];
              if (item.post != null) {
                return _buildPost(item.post!);
              }
              return _NotificationCard(notif: item.notif!);
            },
          ),
        );
      },
    );
  }

  Widget _buildPost(PostModel post) {
    return FeedPostCard(
      post: post,
      onLike: () => ref.read(feedNotifierProvider.notifier).toggleLike(post.id),
      onComment: () => showCommentSheet(
        context,
        postId: post.id,
        onAdded: () =>
            ref.read(feedNotifierProvider.notifier).bumpCommentCount(post.id),
      ),
      onShare: () => _share(post),
    );
  }

  void _share(PostModel post) {
    Clipboard.setData(ClipboardData(text: post.content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Publication copiée — collez-la où vous voulez',
            style: GwType.ui(fontSize: 14, color: GwTokens.of(context).stone)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Déclencheur de composition
// ─────────────────────────────────────────────────────────────────

class _ComposeTrigger extends ConsumerWidget {
  const _ComposeTrigger();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final user = ref.watch(profileNotifierProvider).valueOrNull;
    final name = (user?.displayName ?? '').trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final avatarUrl = user?.avatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Material(
        color: t.inkCard,
        borderRadius: BorderRadius.circular(GwTokens.rCardLg),
        child: InkWell(
          onTap: () => showComposeSheet(context),
          borderRadius: BorderRadius.circular(GwTokens.rCardLg),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(GwTokens.rCardLg),
              border: Border.all(color: t.line),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: t.goldBg,
                  backgroundImage:
                      hasAvatar ? NetworkImage(avatarUrl) : null,
                  child: hasAvatar
                      ? null
                      : Text(initial,
                          style: GwType.display(
                              fontSize: 15, color: t.goldText)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Partagez quelque chose avec votre communauté…',
                    style: GwType.ui(fontSize: 14, color: t.stoneDim),
                  ),
                ),
                Icon(Symbols.edit_square, size: 20, color: t.goldText),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Carte notification (compacte, secondaire)
// ─────────────────────────────────────────────────────────────────

class _NotificationCard extends ConsumerWidget {
  const _NotificationCard({required this.notif});

  final NotificationModel notif;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final unread = !notif.read;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Material(
        color: unread
            ? GwTokens.azure.withValues(alpha: 0.07)
            : t.inkCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(GwTokens.rCard),
        child: InkWell(
          onTap: () => ref
              .read(notificationsNotifierProvider.notifier)
              .markAsRead(notif.id),
          borderRadius: BorderRadius.circular(GwTokens.rCard),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(GwTokens.rCard),
              border: Border.all(
                color: unread
                    ? GwTokens.azure.withValues(alpha: 0.28)
                    : t.line,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: GwTokens.azure.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(_icon(notif.type),
                      size: 17, color: t.azureText),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notif.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GwType.ui(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: t.stone),
                      ),
                      if (notif.body.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          notif.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GwType.ui(
                              fontSize: 12.5,
                              color: t.stoneMid,
                              height: 1.4),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _timeAgo(notif.createdAt),
                  style: GwType.mono(fontSize: 10, color: t.stoneFaint),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _icon(String type) {
    switch (type) {
      case 'UNION_REQUEST':
        return Symbols.favorite;
      case 'PARENT_LINK':
      case 'CHILD_LINK':
        return Symbols.family_history;
      case 'INVITATION_ACCEPTED':
        return Symbols.celebration;
      default:
        return Symbols.notifications;
    }
  }

  static String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    if (d.inHours < 24) return '${d.inHours} h';
    if (d.inDays < 7) return '${d.inDays} j';
    return '${(d.inDays / 7).floor()} sem';
  }
}

// ─────────────────────────────────────────────────────────────────
//  État vide — honnête
// ─────────────────────────────────────────────────────────────────

class _FeedEmpty extends StatelessWidget {
  const _FeedEmpty();

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 48, 28, 28),
      child: Column(
        children: [
          Icon(Symbols.forum, size: 46, color: t.stoneFaint),
          const SizedBox(height: 14),
          Text(
            'Votre fil est encore calme',
            textAlign: TextAlign.center,
            style: GwType.display(
                fontSize: 17, fontWeight: FontWeight.w600, color: t.stone),
          ),
          const SizedBox(height: 8),
          Text(
            'Les publications de vos villages, clans, familles et groupes '
            'apparaîtront ici. Rejoignez une communauté ou publiez le premier '
            'message.',
            textAlign: TextAlign.center,
            style: GwType.ui(fontSize: 13.5, color: t.stoneMid, height: 1.55),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Rail contextuel desktop — Mémoire familiale + Mon village
// ─────────────────────────────────────────────────────────────────

class _DesktopContextRail extends ConsumerWidget {
  const _DesktopContextRail();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final myVillages = ref.watch(myVillagesNotifierProvider).valueOrNull;
    final village = (myVillages?.isNotEmpty ?? false) ? myVillages!.first : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 20, 24, 20),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            color: GwTokens.sage.withValues(alpha: 0.08),
            border: Border.all(color: GwTokens.sage.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(GwTokens.rCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MÉMOIRE FAMILIALE',
                  style: GwType.mono(
                      fontSize: 10, letterSpacing: 1.5, color: t.sageText)),
              const SizedBox(height: 10),
              Text(
                'Explorez votre lignée et enregistrez les récits de vos aînés.',
                style: GwType.ui(fontSize: 13.5, color: t.stone, height: 1.6),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 42,
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    ref.read(breadcrumbProvider.notifier).clear();
                    context.go(Routes.genealogy);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: GwTokens.sage,
                    foregroundColor: const Color(0xFFF0EBE1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Ouvrir ma rivière',
                      style: GwType.ui(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (village != null)
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            decoration: BoxDecoration(
              color: t.inkCard,
              borderRadius: BorderRadius.circular(GwTokens.rCard),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MON VILLAGE',
                    style: GwType.mono(
                        fontSize: 10,
                        letterSpacing: 1.5,
                        color: t.stoneFaint)),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () {
                    ref.read(breadcrumbProvider.notifier).clear();
                    context.push(Routes.villageDetail(village.id));
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: GwTokens.gold,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          village.name.isNotEmpty
                              ? village.name[0].toUpperCase()
                              : '?',
                          style: GwType.display(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0C0B0F)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(village.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GwType.ui(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: t.stone)),
                            Text('${village.memberCount} MEMBRES',
                                style: GwType.mono(
                                    fontSize: 11.5,
                                    color: t.emberText,
                                    letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Header mobile
// ─────────────────────────────────────────────────────────────────

class _FeedHeader extends ConsumerWidget {
  const _FeedHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gwang Meu',
                    style: GwType.display(
                        fontSize: 21, color: t.stone, letterSpacing: 0.5)),
                Text('MBƐ́Ɛ — BIENVENUE',
                    style: GwType.mono(
                        fontSize: 10, color: t.stoneFaint, letterSpacing: 2)),
              ],
            ),
          ),
          _HeaderAction(
            icon: t.brightness == Brightness.dark
                ? Symbols.light_mode
                : Symbols.dark_mode,
            onTap: () =>
                ref.read(displayModeProvider.notifier).toggleLightDark(),
          ),
          const SizedBox(width: 10),
          _HeaderAction(
            icon: Symbols.notifications,
            showDot: (ref.watch(unreadCountProvider).valueOrNull ?? 0) > 0,
            onTap: () => _openNotifications(context),
          ),
          const SizedBox(width: 10),
          _HeaderAction(
            icon: Symbols.forum,
            onTap: () => context.go(Routes.messages),
          ),
        ],
      ),
    );
  }

  void _openNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
        decoration: BoxDecoration(
          color: GwTokens.of(context).inkCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        clipBehavior: Clip.antiAlias,
        child: const NotificationPanel(),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.icon, this.onTap, this.showDot = false});

  final IconData icon;
  final VoidCallback? onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Material(
      color: t.inkLift,
      borderRadius: BorderRadius.circular(GwTokens.rBtn),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        child: SizedBox(
          width: GwTokens.tapTarget,
          height: GwTokens.tapTarget,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 22, color: t.stone),
              if (showDot)
                Positioned(
                  top: 9,
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
}

// ─────────────────────────────────────────────────────────────────
//  État d'erreur
// ─────────────────────────────────────────────────────────────────

class _FeedError extends StatelessWidget {
  const _FeedError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.cloud_off, size: 48, color: t.stoneFaint),
            const SizedBox(height: 14),
            Text('Le fil n\'a pas pu se charger',
                style: GwType.display(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: t.stone)),
            const SizedBox(height: 6),
            Text('Vérifiez votre connexion, puis réessayez.',
                textAlign: TextAlign.center,
                style: GwType.ui(fontSize: 14, color: t.stoneMid)),
            const SizedBox(height: 18),
            SizedBox(
              height: GwTokens.tapTarget,
              child: FilledButton.icon(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: GwTokens.gold,
                  foregroundColor: GwTokens.inkOnGold,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(GwTokens.rBtn),
                  ),
                ),
                icon: const Icon(Symbols.refresh, size: 18),
                label: Text('Réessayer',
                    style: GwType.ui(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
