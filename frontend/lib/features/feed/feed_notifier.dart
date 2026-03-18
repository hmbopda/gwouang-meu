import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/network/api_client.dart';
import '../../shared/models/post_model.dart';

part 'feed_notifier.g.dart';

@riverpod
class FeedNotifier extends _$FeedNotifier {
  static const _pageSize = 20;
  int _page = 0;
  bool _hasMore = true;

  @override
  Future<List<PostModel>> build() async {
    _page = 0;
    _hasMore = true;
    return _fetchPage(0);
  }

  Future<List<PostModel>> _fetchPage(int page) async {
    final client = ref.read(apiClientProvider);
    final json = await client.get(
      '/api/v1/feed',
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

  /// Pagination infinie
  Future<void> loadMore() async {
    if (!_hasMore) return;
    final current = state.valueOrNull ?? [];
    _page++;
    final more = await _fetchPage(_page);
    state = AsyncData([...current, ...more]);
  }
}
