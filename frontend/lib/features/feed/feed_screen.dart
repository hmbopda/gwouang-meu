import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/router/route_names.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/feed/feed_notifier.dart';
import 'package:gwangmeu/features/home/home_screen.dart';
import 'package:gwangmeu/features/notifications/widgets/notification_panel.dart';
import 'package:gwangmeu/features/profile/profile_notifier.dart';
import 'package:gwangmeu/shared/models/post_model.dart';
import 'package:gwangmeu/shared/widgets/compose_box.dart';
import 'package:gwangmeu/shared/widgets/loading_overlay.dart';
import 'package:gwangmeu/shared/widgets/post_card.dart';
import 'package:gwangmeu/shared/widgets/stories_row.dart';

/// Feed « Tissage » (#1a) — header Fraunces + MBƐ́Ɛ mono, stories 72 px,
/// compose une ligne, gabarits de posts différenciés, bande tissée signature.
class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(feedNotifierProvider);
    final desktop = isDesktopLayout(context);

    final feed = feedState.when(
      loading: () => const ShimmerList(count: 5, cardHeight: 220),
      error: (e, _) => _FeedList(posts: _demoPosts),
      data: (posts) => _FeedList(posts: posts.isEmpty ? _demoPosts : posts),
    );

    if (desktop) return feed;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const GwWeaveBand(),
            const _FeedHeader(),
            Expanded(child: feed),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Header — Fraunces + « MBƐ́Ɛ — BIENVENUE » mono, cibles 44 px
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
                Text(
                  'Gwang Meu',
                  style: GwType.display(
                      fontSize: 21, color: t.stone, letterSpacing: 0.5),
                ),
                Text(
                  'MBƐ́Ɛ — BIENVENUE',
                  style: GwType.mono(
                      fontSize: 10, color: t.stoneFaint, letterSpacing: 2),
                ),
              ],
            ),
          ),
          _HeaderAction(
            icon: Symbols.notifications,
            showDot: true,
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
//  Liste du fil
// ─────────────────────────────────────────────────────────────────

class _FeedList extends ConsumerWidget {
  const _FeedList({required this.posts});

  final List<PostModel> posts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(profileNotifierProvider).valueOrNull;

    return RefreshIndicator(
      color: GwTokens.of(context).goldText,
      onRefresh: () => ref.read(feedNotifierProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 16),
        itemCount: posts.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 4),
              child: StoriesRow(
                stories: _demoStories,
                onStoryTap: (_) {},
                onAddStory: () {},
              ),
            );
          }
          if (index == 1) {
            return Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 10),
              child: ComposeBox(
                displayName: user?.displayName,
                avatarUrl: user?.avatarUrl,
                onTap: () {},
              ),
            );
          }
          final post = posts[index - 2];
          return PostCard(
            post: post,
            onAiExplore: () => context.go(Routes.genealogy),
            onAiDismiss: () {},
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Données démo
// ─────────────────────────────────────────────────────────────────

final _demoStories = [
  const StoryData(
    id: '1',
    name: 'Amara K.',
    villageName: 'Bassa-Likoko',
    backgroundGradientStart: Color(0xFF1A3300),
    backgroundGradientEnd: Color(0xFF4A8800),
  ),
  const StoryData(
    id: '2',
    name: 'Fanta K.',
    villageName: 'Foumbot',
    backgroundGradientStart: Color(0xFF3A1A00),
    backgroundGradientEnd: Color(0xFF8A5200),
  ),
  const StoryData(
    id: '3',
    name: 'Cours Bassa',
    villageName: 'Live replay',
    backgroundGradientStart: Color(0xFF1A0A3A),
    backgroundGradientEnd: Color(0xFF4A2080),
    isLiveReplay: true,
  ),
  const StoryData(
    id: '4',
    name: 'Kofi A.',
    villageName: 'Diaspora Paris',
    backgroundGradientStart: Color(0xFF0A1A3A),
    backgroundGradientEnd: Color(0xFF1A5080),
  ),
  const StoryData(
    id: '5',
    name: 'Nadia M.',
    villageName: 'Ngaoundere',
    backgroundGradientStart: Color(0xFF1A1A0A),
    backgroundGradientEnd: Color(0xFF4A3A00),
  ),
];

final _demoPosts = [
  PostModel(
    id: 'demo-p1',
    authorId: 'u1',
    villageId: 'v1',
    content:
        'Les langues africaines sont les gardiens invisibles de notre âme collective. Chaque mot en Bassa porte des siècles de sagesse.',
    isLargeText: true,
    tags: const ['Bassa', 'LanguesAfricaines', 'Heritage'],
    reactionCount: 247,
    commentCount: 38,
    shareCount: 12,
    reactions: const ['heart', 'fire', 'clap'],
    authorDisplayName: 'Amara Kouassi',
    villageName: 'Bassa-Likoko',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  PostModel(
    id: 'demo-p2',
    authorId: 'u2',
    villageId: 'v2',
    content:
        'La fête du Ngondo cette année était magnifique ! Des centaines de familles réunies sur les rives du Wouri.',
    mediaUrl: 'https://picsum.photos/seed/ngondo/800/450',
    mediaType: 'IMAGE',
    tags: const ['Ngondo2026', 'Bassa'],
    reactionCount: 512,
    commentCount: 94,
    reactions: const ['fire', 'heart', 'love'],
    authorDisplayName: 'Fanta Koné',
    villageName: 'Foumbot Royal',
    createdAt: DateTime.now().subtract(const Duration(hours: 4)),
  ),
  PostModel(
    id: 'demo-p4',
    authorId: 'ai',
    villageId: 'v1',
    content:
        'Kwame Asante et vous partagez probablement un ancêtre du clan Bakoko — 3 lignées correspondent.',
    isAiSuggestion: true,
    aiConfidence: '87%',
    aiDescription: 'Lien familial probable détecté',
    authorDisplayName: 'Mémoire familiale',
    villageName: 'Bassa-Likoko',
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  PostModel(
    id: 'demo-p3',
    authorId: 'u3',
    villageId: 'v3',
    content: 'Cours de prononciation Bassa — Niveau 2. Rejoignez-nous !',
    isLive: true,
    liveViewerCount: 143,
    authorDisplayName: 'Prof. Jean-Baptiste Nkomo',
    authorRole: 'AMBASSADEUR',
    villageName: 'Yaoundé - Centre',
    createdAt: DateTime.now(),
  ),
];
