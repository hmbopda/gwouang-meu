import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gwangmeu/shared/models/post_model.dart';
import 'package:gwangmeu/shared/models/village_model.dart';
import 'package:gwangmeu/shared/widgets/compose_box.dart';
import 'package:gwangmeu/shared/widgets/loading_overlay.dart';
import 'package:gwangmeu/shared/widgets/post_card.dart';
import 'package:gwangmeu/shared/widgets/stories_row.dart';
import 'package:gwangmeu/shared/widgets/village_highlight_card.dart';
import 'package:gwangmeu/features/home/home_screen.dart';
import 'package:gwangmeu/features/feed/feed_notifier.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(feedNotifierProvider);
    final desktop = isDesktopLayout(context);
    final accent = Theme.of(context).colorScheme.primary;

    final body = feedState.when(
      loading: () => const ShimmerList(count: 5, cardHeight: 220),
      error: (e, _) => _buildFeed(context, ref, _demoPosts),
      data: (posts) => _buildFeed(context, ref, posts.isEmpty ? _demoPosts : posts),
    );

    if (desktop) return body;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 32,
              width: 32,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.language, color: accent, size: 28),
            ),
            const SizedBox(width: 10),
            Text(
              'GWANG MEU',
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: accent,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFeed(BuildContext context, WidgetRef ref, List<PostModel> posts) {
    final accent = Theme.of(context).colorScheme.primary;
    return RefreshIndicator(
      color: accent,
      onRefresh: () => ref.read(feedNotifierProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: posts.length + 3,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: StoriesRow(
                stories: _demoStories,
                onStoryTap: (_) {},
                onAddStory: () {},
              ),
            );
          }
          if (index == 1) {
            return Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: ComposeBox(onTap: () {}),
            );
          }
          if (index == 2) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: VillageHighlightCard(
                village: _demoVillage,
                onTap: () {},
                onJoin: () {},
              ),
            );
          }
          return PostCard(post: posts[index - 3]);
        },
      ),
    );
  }
}

// -- Demo data --

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

const _demoVillage = VillageModel(
  id: 'demo-1',
  name: 'Bassa-Likoko',
  country: 'Cameroun',
  primaryDialect: 'Bassa',
  memberCount: 1247,
);

final _demoPosts = [
  PostModel(
    id: 'demo-p1',
    authorId: 'u1',
    villageId: 'v1',
    content:
        'Les langues africaines sont les gardiens invisibles de notre ame collective. Chaque mot en Bassa porte des siecles de sagesse.',
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
        'La fete du Ngondo cette annee etait magnifique ! Des centaines de familles reunies sur les rives de la Wouri.',
    mediaUrl: 'https://picsum.photos/seed/ngondo/800/450',
    mediaType: 'IMAGE',
    tags: const ['Ngondo2025', 'Bassa'],
    reactionCount: 512,
    commentCount: 94,
    reactions: const ['fire', 'heart', 'love'],
    authorDisplayName: 'Fanta Kone',
    villageName: 'Foumbot Royal',
    createdAt: DateTime.now().subtract(const Duration(hours: 4)),
  ),
  PostModel(
    id: 'demo-p3',
    authorId: 'u3',
    villageId: 'v3',
    content: 'Cours de prononciation Bassa - Niveau 2. Rejoignez-nous !',
    isLive: true,
    liveViewerCount: 143,
    authorDisplayName: 'Prof. Jean-Baptiste Nkomo',
    authorRole: 'AMBASSADEUR',
    villageName: 'Yaounde - Centre',
    createdAt: DateTime.now(),
  ),
  PostModel(
    id: 'demo-p4',
    authorId: 'ai',
    villageId: 'v1',
    content:
        'Kwame Asante et vous partagez probablement un ancetre commun du clan Bakoko. Vos arbres genealogiques presentent 3 correspondances sur les noms de lignees.',
    isAiSuggestion: true,
    aiConfidence: '87%',
    aiDescription: 'Lien familial probable detecte',
    authorDisplayName: 'Claude AI',
    villageName: 'Bassa-Likoko',
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
  ),
];
