import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/network/api_client.dart';
import '../../shared/models/post_model.dart';
import '../../shared/models/village_member_model.dart';
import '../../shared/models/village_model.dart';

part 'villages_notifier.g.dart';

@riverpod
class VillagesNotifier extends _$VillagesNotifier {
  @override
  Future<List<VillageModel>> build() async {
    return _fetch();
  }

  Future<List<VillageModel>> _fetch({String? countryCode, String? query}) async {
    final client = ref.read(apiClientProvider);

    if (query != null && query.isNotEmpty) {
      final json = await client.get(
        '/api/v1/villages/search',
        queryParameters: {'q': query},
      );
      return _parseList(json);
    }

    final params = <String, dynamic>{};
    if (countryCode != null) params['countryCode'] = countryCode;

    final json = await client.get('/api/v1/villages', queryParameters: params);
    return _parseList(json);
  }

  List<VillageModel> _parseList(Map<String, dynamic> json) {
    final data = json['data'];
    final list = data is List ? data : (data as Map?)?['content'] as List? ?? [];
    return list
        .map((e) => VillageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> search(String query) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(query: query));
  }

  Future<void> filterByCountry(String countryCode) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(countryCode: countryCode));
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Mettre à jour un village via PUT /api/v1/villages/{id}
  Future<VillageModel> updateVillage({
    required String villageId,
    String? description,
    String? coverImageUrl,
    int? foundedYear,
    int? populationEstimate,
    String? historicalSummary,
  }) async {
    final client = ref.read(apiClientProvider);
    final json = await client.put('/api/v1/villages/$villageId', data: {
      if (description != null) 'description': description,
      if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
      if (foundedYear != null) 'foundedYear': foundedYear,
      if (populationEstimate != null) 'populationEstimate': populationEstimate,
      if (historicalSummary != null) 'historicalSummary': historicalSummary,
    });
    final village = VillageModel.fromJson(json['data'] as Map<String, dynamic>);
    ref.invalidateSelf();
    // Invalider aussi le détail pour refresh immédiat
    ref.invalidate(villageDetailProvider(villageId));
    return village;
  }

  /// Créer un village via POST /api/v1/villages
  Future<VillageModel> createVillage({
    required String name,
    required String country,
    String? description,
    String? region,
    String? continentCode,
    double? latitude,
    double? longitude,
    String? primaryDialect,
  }) async {
    final client = ref.read(apiClientProvider);
    final json = await client.post('/api/v1/villages', data: {
      'name': name,
      'country': country,
      if (description != null) 'description': description,
      if (region != null) 'region': region,
      if (continentCode != null) 'continentCode': continentCode,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (primaryDialect != null) 'primaryDialect': primaryDialect,
    });
    final village = VillageModel.fromJson(json['data'] as Map<String, dynamic>);
    ref.invalidateSelf();
    return village;
  }
}

@riverpod
Future<VillageModel> villageDetail(VillageDetailRef ref, String villageId) async {
  final client = ref.read(apiClientProvider);
  final json = await client.get('/api/v1/villages/$villageId');
  return VillageModel.fromJson(json['data'] as Map<String, dynamic>);
}

/// Membres d'un village
@riverpod
Future<List<VillageMemberModel>> villageMembers(VillageMembersRef ref, String villageId) async {
  final client = ref.read(apiClientProvider);
  final json = await client.get('/api/v1/villages/$villageId/members');
  final data = json['data'];
  final list = data is List ? data : <dynamic>[];
  return list
      .map((e) => VillageMemberModel.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// Feed d'un village (posts approuvés)
@riverpod
class VillageFeedNotifier extends _$VillageFeedNotifier {
  static const _pageSize = 20;
  late String _villageId;
  int _page = 0;
  bool _hasMore = true;

  @override
  Future<List<PostModel>> build(String villageId) async {
    _villageId = villageId;
    _page = 0;
    _hasMore = true;
    return _fetchPage(0);
  }

  Future<List<PostModel>> _fetchPage(int page) async {
    final client = ref.read(apiClientProvider);
    final json = await client.get(
      '/api/v1/feed/village/$_villageId',
      queryParameters: {'page': page, 'size': _pageSize},
    );
    final rawData = json['data'];
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

  Future<PostModel> createPost(String content) async {
    final client = ref.read(apiClientProvider);
    final json = await client.post('/api/v1/feed', data: {
      'villageId': _villageId,
      'content': content,
    });
    final post = PostModel.fromJson(json['data'] as Map<String, dynamic>);
    ref.invalidateSelf();
    return post;
  }

  Future<void> react(String postId, String type) async {
    final client = ref.read(apiClientProvider);
    await client.post('/api/v1/feed/$postId/react', data: {'type': type});
    ref.invalidateSelf();
  }

  Future<void> removeReaction(String postId) async {
    final client = ref.read(apiClientProvider);
    await client.delete('/api/v1/feed/$postId/react');
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    final current = state.valueOrNull ?? [];
    _page++;
    final more = await _fetchPage(_page);
    state = AsyncData([...current, ...more]);
  }
}

/// Villages auxquels l'utilisateur connecte est abonne
@riverpod
class MyVillagesNotifier extends _$MyVillagesNotifier {
  @override
  Future<List<VillageModel>> build() async {
    final client = ref.read(apiClientProvider);
    final json = await client.get('/api/v1/villages/my-villages');
    final data = json['data'];
    final list = data is List ? data : <dynamic>[];
    return list
        .map((e) => VillageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> joinVillage(String villageId) async {
    final client = ref.read(apiClientProvider);
    await client.post('/api/v1/villages/$villageId/join');
    ref.invalidateSelf();
    await future;
  }

  Future<void> leaveVillage(String villageId) async {
    final client = ref.read(apiClientProvider);
    await client.delete('/api/v1/villages/$villageId/leave');
    ref.invalidateSelf();
    await future;
  }

  bool isSubscribed(String villageId) {
    final villages = state.valueOrNull ?? [];
    return villages.any((v) => v.id == villageId);
  }
}
