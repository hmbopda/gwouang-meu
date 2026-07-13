import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:gwangmeu/core/network/api_client.dart';
import 'package:gwangmeu/shared/models/post_model.dart';

part 'feed_notifier.g.dart';

@riverpod
class FeedNotifier extends _$FeedNotifier {
  static const _pageSize = 20;
  int _page = 0;
  bool _hasMore = true;
  bool _loadingMore = false;

  @override
  Future<List<PostModel>> build() async {
    _page = 0;
    _hasMore = true;
    return _fetchPage(0);
  }

  Future<List<PostModel>> _fetchPage(int page) async {
    final client = ref.read(apiClientProvider);
    // /feed/home : fil agrégé par appartenance (mes villages, clans, familles,
    // groupes) + enrichi (auteur, village, aimé par moi).
    final json = await client.get(
      '/api/v1/feed/home',
      queryParameters: {'page': page, 'size': _pageSize},
    );
    final rawData = json['data'];

    // Le backend peut retourner soit une liste directe, soit un objet pagine {content, last, ...}
    List<dynamic> items;
    if (rawData is List) {
      items = rawData;
      _hasMore = rawData.length >= _pageSize;
    } else if (rawData is Map<String, dynamic>) {
      items = rawData['content'] as List<dynamic>? ?? [];
      _hasMore = !(rawData['last'] as bool? ?? true);
    } else {
      items = [];
      _hasMore = false;
    }

    return items
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Pull-to-refresh
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Pagination infinie (protégée contre les appels concurrents du scroll).
  Future<void> loadMore() async {
    if (!_hasMore || _loadingMore) return;
    _loadingMore = true;
    try {
      final current = state.valueOrNull ?? [];
      _page++;
      final more = await _fetchPage(_page);
      state = AsyncData([...current, ...more]);
    } finally {
      _loadingMore = false;
    }
  }

  /// J'aime / je n'aime plus — mise à jour optimiste puis appel réseau.
  Future<void> toggleLike(String postId) async {
    final list = state.valueOrNull;
    if (list == null) return;
    final idx = list.indexWhere((p) => p.id == postId);
    if (idx < 0) return;
    final original = list[idx];
    final liked = original.likedByMe;

    // Optimiste
    final optimistic = original.copyWith(
      likedByMe: !liked,
      reactionCount:
          (original.reactionCount + (liked ? -1 : 1)).clamp(0, 1 << 31),
    );
    state = AsyncData([...list]..[idx] = optimistic);

    final client = ref.read(apiClientProvider);
    try {
      if (liked) {
        await client.delete('/api/v1/feed/$postId/react');
      } else {
        await client.post('/api/v1/feed/$postId/react');
      }
    } catch (_) {
      // Revert en cas d'échec
      final now = state.valueOrNull;
      if (now == null) return;
      final j = now.indexWhere((p) => p.id == postId);
      if (j >= 0) state = AsyncData([...now]..[j] = original);
    }
  }

  /// Publier un post (personnel si [villageId] est null, sinon dans un village).
  /// Recharge le fil pour faire apparaître la publication auto-approuvée.
  Future<void> createPost({required String content, String? villageId}) async {
    final client = ref.read(apiClientProvider);
    await client.post('/api/v1/feed', data: {
      'content': content,
      if (villageId != null) 'villageId': villageId,
    });
    await refresh();
  }

  /// Incrémente localement le compteur de commentaires d'un post (après ajout).
  void bumpCommentCount(String postId) {
    final list = state.valueOrNull;
    if (list == null) return;
    final idx = list.indexWhere((p) => p.id == postId);
    if (idx < 0) return;
    final p = list[idx];
    state = AsyncData(
        [...list]..[idx] = p.copyWith(commentCount: p.commentCount + 1));
  }
}
