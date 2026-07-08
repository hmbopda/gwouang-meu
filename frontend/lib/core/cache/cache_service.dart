import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:gwangmeu/core/cache/models/feed_post_cache.dart';
import 'package:gwangmeu/core/cache/models/user_profile_cache.dart';
import 'package:gwangmeu/core/cache/models/village_cache.dart';

part 'cache_service.g.dart';

const _kFeedBox = 'feed_posts';
const _kProfileBox = 'user_profiles';
const _kVillageBox = 'villages';
const _kFamilyTreeBox = 'family_tree_json';

// Ancienne box du modèle GenealogyNodeCache (typeId 3, supprimé).
// Ne pas réutiliser le typeId 3 pour un futur adapter Hive.
const _kLegacyGenealogyBox = 'genealogy_nodes';

// TTL : 30 minutes
const _kTtl = Duration(minutes: 30);

@riverpod
CacheService cacheService(Ref ref) => CacheService();

class CacheService {
  // ── Initialisation ──────────────────────────────────────────────────

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive
      ..registerAdapter(FeedPostCacheAdapter())
      ..registerAdapter(UserProfileCacheAdapter())
      ..registerAdapter(VillageCacheAdapter());

    await Future.wait([
      Hive.openBox<FeedPostCache>(_kFeedBox),
      Hive.openBox<UserProfileCache>(_kProfileBox),
      Hive.openBox<VillageCache>(_kVillageBox),
      Hive.openBox<String>(_kFamilyTreeBox),
    ]);

    // Purge silencieuse de l'ancienne box généalogie (modèle supprimé).
    unawaited(
      Hive.deleteBoxFromDisk(_kLegacyGenealogyBox).catchError((_) {}),
    );
  }

  // ── Feed ─────────────────────────────────────────────────────────────

  Box<FeedPostCache> get _feedBox => Hive.box<FeedPostCache>(_kFeedBox);

  void cacheFeedPosts(List<FeedPostCache> posts) {
    final box = _feedBox;
    box.clear();
    final map = {for (final p in posts) p.id: p};
    box.putAll(map);
  }

  List<FeedPostCache> getCachedFeed() {
    final now = DateTime.now();
    return _feedBox.values
        .where((p) => now.difference(p.cachedAt) < _kTtl)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // ── Profil utilisateur ───────────────────────────────────────────────

  Box<UserProfileCache> get _profileBox =>
      Hive.box<UserProfileCache>(_kProfileBox);

  void cacheUserProfile(UserProfileCache profile) {
    _profileBox.put(profile.id, profile);
  }

  UserProfileCache? getCachedProfile(String userId) {
    final p = _profileBox.get(userId);
    if (p == null) return null;
    if (DateTime.now().difference(p.cachedAt) >= _kTtl) {
      _profileBox.delete(userId);
      return null;
    }
    return p;
  }

  // ── Villages ─────────────────────────────────────────────────────────

  Box<VillageCache> get _villageBox => Hive.box<VillageCache>(_kVillageBox);

  void cacheVillages(List<VillageCache> villages) {
    final map = {for (final v in villages) v.id: v};
    _villageBox.putAll(map);
  }

  List<VillageCache> getCachedVillages() {
    final now = DateTime.now();
    return _villageBox.values
        .where((v) => now.difference(v.cachedAt) < _kTtl)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  // ── Arbre généalogique (stale-while-revalidate) ─────────────────────
  //
  // Clé = personId, valeur = JSON du FamilyTree enveloppé avec un
  // timestamp. Pas de TTL de lecture : le cache est toujours servi
  // (support hors-ligne), le réseau revalide en arrière-plan.

  Box<String> get _familyTreeBox => Hive.box<String>(_kFamilyTreeBox);

  void putFamilyTreeJson(String personId, Map<String, dynamic> treeJson) {
    _familyTreeBox.put(
      personId,
      jsonEncode({
        'cachedAt': DateTime.now().toIso8601String(),
        'tree': treeJson,
      }),
    );
  }

  /// Retourne le JSON du FamilyTree en cache pour [personId],
  /// ou null si absent ou illisible (entrée corrompue purgée).
  Map<String, dynamic>? getFamilyTreeJson(String personId) {
    final raw = _familyTreeBox.get(personId);
    if (raw == null) return null;
    try {
      final envelope = jsonDecode(raw) as Map<String, dynamic>;
      return envelope['tree'] as Map<String, dynamic>?;
    } catch (_) {
      _familyTreeBox.delete(personId);
      return null;
    }
  }

  // ── Nettoyage ────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    await Future.wait([
      _feedBox.clear(),
      _profileBox.clear(),
      _villageBox.clear(),
      _familyTreeBox.clear(),
    ]);
  }
}
