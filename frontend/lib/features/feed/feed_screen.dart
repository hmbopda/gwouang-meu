import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:share_plus/share_plus.dart';

import 'package:gwangmeu/core/router/breadcrumb_provider.dart';
import 'package:gwangmeu/core/router/route_names.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/core/theme/theme_notifier.dart';
import 'package:gwangmeu/features/chat/direct_chat.dart';
import 'package:gwangmeu/features/feed/feed_notifier.dart';
import 'package:gwangmeu/features/feed/widgets/comment_sheet.dart';
import 'package:gwangmeu/features/feed/widgets/compose_sheet.dart';
import 'package:gwangmeu/features/feed/widgets/family_rail.dart';
import 'package:gwangmeu/features/feed/widgets/family_stories_row.dart';
import 'package:gwangmeu/features/feed/widgets/feed_post_card.dart';
import 'package:gwangmeu/features/home/home_screen.dart';
import 'package:gwangmeu/features/notifications/notifications_notifier.dart';
import 'package:gwangmeu/features/notifications/widgets/notification_panel.dart';
import 'package:gwangmeu/features/profile/profile_notifier.dart';
import 'package:gwangmeu/shared/models/post_model.dart';
import 'package:gwangmeu/shared/widgets/loading_overlay.dart';

/// Fil de famille — le réseau social au centre, l'arbre en compagnon.
/// Souvenirs (stories), composer, publications & événements d'arbre (vraies
/// données), rail droit « Votre arbre / À relier / Cette semaine ».
class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isDesktopLayout(context)) {
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
          const Expanded(flex: 10, child: FamilyRail()),
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
//  Corps du fil (souvenirs + composer + publications)
// ─────────────────────────────────────────────────────────────────

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

  Future<void> _refresh() =>
      ref.read(feedNotifierProvider.notifier).refresh();

  Future<void> _openContact(ChatContact c) async {
    try {
      final group = await ref.read(directChatOpenerProvider).openWith(c.userId);
      if (!mounted) return;
      context.push(
        Routes.conversation(group.id),
        extra: <String, Object>{'group': group, 'villageName': c.displayName},
      );
    } catch (_) {/* ignore */}
  }

  void _openTree() {
    ref.read(breadcrumbProvider.notifier).clear();
    context.go(Routes.genealogy);
  }

  Future<void> _share(PostModel post) async {
    final author = post.authorDisplayName ?? 'Un membre';
    final text = '$author sur Gwouang Meu :\n\n${post.content}';
    try {
      await Share.share(text);
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copié — collez-le où vous voulez',
                style:
                    GwType.ui(fontSize: 14, color: GwTokens.of(context).stone)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final feedState = ref.watch(feedNotifierProvider);

    return feedState.when(
      loading: () => const ShimmerList(count: 4, cardHeight: 190),
      error: (e, _) => _FeedError(
        onRetry: () => ref.read(feedNotifierProvider.notifier).refresh(),
      ),
      data: (posts) {
        return RefreshIndicator(
          color: t.goldText,
          onRefresh: _refresh,
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
            itemCount: 2 + (posts.isEmpty ? 1 : posts.length),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FamilyStoriesRow(
                    onAdd: () => showComposeSheet(context),
                    onTapContact: _openContact,
                  ),
                );
              }
              if (index == 1) return const _ComposeTrigger();
              if (posts.isEmpty) return const _FeedEmpty();
              final post = posts[index - 2];
              return FeedPostCard(
                post: post,
                onLike: () =>
                    ref.read(feedNotifierProvider.notifier).toggleLike(post.id),
                onComment: () => showCommentSheet(
                  context,
                  postId: post.id,
                  onAdded: () => ref
                      .read(feedNotifierProvider.notifier)
                      .bumpCommentCount(post.id),
                ),
                onShare: () => _share(post),
                onOpenTree: _openTree,
              );
            },
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Composer — souvenir / photo / récit
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

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: t.inkCard,
        borderRadius: BorderRadius.circular(GwTokens.rCardLg),
        border: Border.all(color: t.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: t.goldBg,
                backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                child: hasAvatar
                    ? null
                    : Text(initial,
                        style:
                            GwType.display(fontSize: 15, color: t.goldText)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => showComposeSheet(context),
                  borderRadius: BorderRadius.circular(GwTokens.rPill),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                    decoration: BoxDecoration(
                      color: t.inkLift,
                      borderRadius: BorderRadius.circular(GwTokens.rPill),
                    ),
                    child: Text(
                      'Partagez un souvenir, une photo, une histoire…',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GwType.ui(fontSize: 13.5, color: t.stoneDim),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _composeAction(t,
                  icon: Symbols.photo_camera,
                  label: 'Photo',
                  color: t.sageText,
                  onTap: () =>
                      showComposeSheet(context, startWithPhoto: true)),
              const SizedBox(width: 8),
              _composeAction(t,
                  icon: Symbols.history_edu,
                  label: 'Récit',
                  color: t.goldText,
                  onTap: () => showComposeSheet(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _composeAction(GwTokens t,
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return Expanded(
      child: Material(
        color: t.inkLift,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 7),
                Text(label,
                    style: GwType.ui(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: t.stone)),
              ],
            ),
          ),
        ),
      ),
    );
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
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        children: [
          Icon(Symbols.family_history, size: 46, color: t.stoneFaint),
          const SizedBox(height: 14),
          Text('Votre fil de famille commence ici',
              textAlign: TextAlign.center,
              style: GwType.display(
                  fontSize: 17, fontWeight: FontWeight.w600, color: t.stone)),
          const SizedBox(height: 8),
          Text(
            'Les souvenirs partagés et les événements de l’arbre (naissances, '
            'unions, nouveaux liens) de vos villages, clans et familles '
            'apparaîtront ici. Partagez le premier souvenir.',
            textAlign: TextAlign.center,
            style: GwType.ui(fontSize: 13.5, color: t.stoneMid, height: 1.55),
          ),
        ],
      ),
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
                Text('Gwouang Meu',
                    style: GwType.display(
                        fontSize: 21, color: t.stone, letterSpacing: 0.5)),
                Text('FIL DE FAMILLE',
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
//  Erreur
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
