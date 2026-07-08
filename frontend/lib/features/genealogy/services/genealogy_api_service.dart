import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gwangmeu/core/cache/cache_service.dart';
import 'package:gwangmeu/core/network/api_client.dart';
import 'package:gwangmeu/features/genealogy/models/ai_suggestion.dart';
import 'package:gwangmeu/features/genealogy/models/clan_model.dart';
import 'package:gwangmeu/features/genealogy/models/family_tree.dart';
import 'package:gwangmeu/features/genealogy/models/genealogy_union.dart';
import 'package:gwangmeu/features/genealogy/models/person_comment_model.dart';
import 'package:gwangmeu/features/genealogy/models/person_genealogy.dart';

class GenealogyApiService {
  final ApiClient _api;

  GenealogyApiService(this._api);

  // ── Ma fiche personne ───────────────────────────────────

  Future<PersonGenealogy> getMyPerson() async {
    final t = DateTime.now();
    final response = await _api.get('/api/v1/persons/me');
    if (kDebugMode) {
      debugPrint('[PERF] GET /persons/me : ${DateTime.now().difference(t).inMilliseconds}ms');
    }
    return PersonGenealogy.fromJson(response['data'] as Map<String, dynamic>);
  }

  // ── Arbre complet ────────────────────────────────────────

  Future<FamilyTree> getFullTree(String personId) async {
    final t = DateTime.now();
    final response = await _api.get('/api/v1/genealogy/tree/$personId');
    if (kDebugMode) {
      debugPrint('[PERF] GET /genealogy/tree : ${DateTime.now().difference(t).inMilliseconds}ms');
    }
    return FamilyTree.fromJson(response['data'] as Map<String, dynamic>);
  }

  // ── Persons ──────────────────────────────────────────────

  Future<PersonGenealogy> createPerson(Map<String, dynamic> data) async {
    final response = await _api.post('/api/v1/persons', data: data);
    return PersonGenealogy.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<PersonGenealogy> getPersonById(String id) async {
    final response = await _api.get('/api/v1/persons/$id');
    return PersonGenealogy.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<PersonGenealogy> updatePerson(String id, Map<String, dynamic> data) async {
    final response = await _api.put('/api/v1/persons/$id', data: data);
    return PersonGenealogy.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deletePerson(String id) async {
    await _api.delete('/api/v1/persons/$id');
  }

  Future<List<PersonGenealogy>> searchPersonsByClan(String clan, {String query = ''}) async {
    final response = await _api.get(
      '/api/v1/persons/search',
      queryParameters: {'clan': clan, 'q': query},
    );
    final list = response['data'] as List;
    return list.map((e) => PersonGenealogy.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Clans (grandes familles) ─────────────────────────────

  Future<List<ClanModel>> getClansByVillage(String villageId) async {
    final response = await _api.get('/api/v1/persons/village/$villageId/clans');
    final list = response['data'] as List;
    return list.map((e) => ClanModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<PersonGenealogy>> getPersonsByClan(String clanId, {String? gender}) async {
    final params = <String, String>{};
    if (gender != null) params['gender'] = gender;
    final response = await _api.get('/api/v1/persons/clan/$clanId/members', queryParameters: params);
    final list = response['data'] as List;
    return list.map((e) => PersonGenealogy.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<PersonGenealogy>> getPersonsByVillageAndGender(String villageId, String gender) async {
    final response = await _api.get(
      '/api/v1/persons/village/$villageId/by-gender',
      queryParameters: {'gender': gender},
    );
    final list = response['data'] as List;
    return list.map((e) => PersonGenealogy.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Enfant (atomique: creation + lien parent) ───────────

  Future<PersonGenealogy> createChild({
    required String parentId,
    required String firstName,
    required String lastName,
    required String gender,
    String? birthDate,
    String? clan,
    String? email,
    String parentType = 'BIOLOGICAL',
    String? coParentPersonId,
    String? existingPersonId,
  }) async {
    final response = await _api.post('/api/v1/persons/$parentId/children', data: {
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      if (birthDate != null) 'birthDate': birthDate,
      if (clan != null) 'clan': clan,
      if (email != null) 'email': email,
      'parentType': parentType,
      if (coParentPersonId != null) 'coParentPersonId': coParentPersonId,
      if (existingPersonId != null) 'existingPersonId': existingPersonId,
    });
    return PersonGenealogy.fromJson(response['data'] as Map<String, dynamic>);
  }

  // ── Deduplication ─────────────────────────────────────────

  Future<List<PersonGenealogy>> checkDuplicate({
    required String firstName,
    required String lastName,
    required String gender,
    String? birthDate,
    String? email,
  }) async {
    final response = await _api.post('/api/v1/persons/check-duplicate', data: {
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      if (birthDate != null) 'birthDate': birthDate,
      if (email != null) 'email': email,
    });
    final list = response['data'] as List;
    return list.map((e) => PersonGenealogy.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Child Association (accept / reject) ───────────────────

  Future<void> acceptChildAssociation(String requestId) async {
    await _api.post('/api/v1/genealogy/child-associations/$requestId/accept');
  }

  Future<void> rejectChildAssociation(String requestId) async {
    await _api.post('/api/v1/genealogy/child-associations/$requestId/reject');
  }

  // ── Filiation ────────────────────────────────────────────

  Future<void> linkParentChild({
    required String parentId,
    required String childId,
    required String role,
    String type = 'BIOLOGICAL',
  }) async {
    await _api.post('/api/v1/genealogy/link/parent-child', data: {
      'parentId': parentId,
      'childId': childId,
      'role': role,
      'type': type,
    });
  }

  Future<void> unlinkParentChild(String parentId, String childId) async {
    await _api.delete(
      '/api/v1/genealogy/link/parent-child?parentId=$parentId&childId=$childId',
    );
  }

  // ── Unions ───────────────────────────────────────────────

  Future<GenealogyUnion> createUnion(Map<String, dynamic> data) async {
    final response = await _api.post('/api/v1/unions', data: data);
    return GenealogyUnion.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Règle matrimoniale d'un pays (polygamie autorisée / conditionnelle /
  /// interdite + base légale). Renvoie null si le pays est inconnu.
  Future<Map<String, dynamic>?> getMarriageRule(String iso2) async {
    if (iso2.trim().isEmpty) return null;
    final response =
        await _api.get('/api/v1/genealogy/marriage-rules/${iso2.trim()}');
    return response['data'] as Map<String, dynamic>?;
  }

  Future<GenealogyUnion> updateDotStatus(String unionId, Map<String, dynamic> data) async {
    final response = await _api.put('/api/v1/unions/$unionId/dot', data: data);
    return GenealogyUnion.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> endUnion(String unionId, Map<String, dynamic> data) async {
    await _api.put('/api/v1/unions/$unionId/end', data: data);
  }

  Future<List<GenealogyUnion>> getUnionsByPerson(String personId) async {
    final response = await _api.get('/api/v1/unions/person/$personId');
    final list = response['data'] as List;
    return list.map((e) => GenealogyUnion.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Relations (Neo4j) ────────────────────────────────────

  Future<List<PersonGenealogy>> getParents(String personId) async {
    final response = await _api.get('/api/v1/genealogy/$personId/parents');
    final list = response['data'] as List;
    return list.map((e) => PersonGenealogy.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<PersonGenealogy>> getChildren(String personId) async {
    final response = await _api.get('/api/v1/genealogy/$personId/children');
    final list = response['data'] as List;
    return list.map((e) => PersonGenealogy.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<PersonGenealogy>> getSiblings(String personId) async {
    final response = await _api.get('/api/v1/genealogy/$personId/siblings');
    final list = response['data'] as List;
    return list.map((e) => PersonGenealogy.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Modification fiche enfant (< 4 ans) ────────────────

  Future<void> requestChildModification(
      String personId, Map<String, dynamic> changes) async {
    await _api.post(
      '/api/v1/genealogy/persons/$personId/modification-request',
      data: changes,
    );
  }

  Future<void> acceptModificationRequest(String requestId) async {
    await _api.post(
        '/api/v1/genealogy/modification-requests/$requestId/accept');
  }

  Future<void> rejectModificationRequest(String requestId) async {
    await _api.post(
        '/api/v1/genealogy/modification-requests/$requestId/reject');
  }

  // ── Invitations ─────────────────────────────────────────

  Future<Map<String, dynamic>> invitePerson({
    required String personId,
    String? email,
    String? phone,
    String invitationType = 'PARENT',
  }) async {
    final response = await _api.post('/api/v1/invitations', data: {
      'personId': personId,
      'invitationType': invitationType,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
    });
    return response['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getInvitationByToken(String token) async {
    final response = await _api.get('/api/v1/invitations/token/$token');
    return response['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> acceptInvitation(
      String token, Map<String, dynamic> data) async {
    final response =
        await _api.post('/api/v1/invitations/token/$token/accept', data: data);
    return response['data'] as Map<String, dynamic>;
  }

  // ── Commentaires sur fiche personne ─────────────────────

  Future<List<PersonCommentModel>> getPersonComments(String personId) async {
    final response = await _api.get('/api/v1/persons/$personId/comments');
    final list = response['data'] as List;
    return list.map((e) => PersonCommentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PersonCommentModel> addPersonComment(String personId, String content, {String? parentCommentId}) async {
    final response = await _api.post('/api/v1/persons/$personId/comments', data: {
      'content': content,
      if (parentCommentId != null) 'parentCommentId': parentCommentId,
    });
    return PersonCommentModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deletePersonComment(String personId, String commentId) async {
    await _api.delete('/api/v1/persons/$personId/comments/$commentId');
  }

  // ── Claude AI ────────────────────────────────────────────

  Future<List<AiSuggestion>> generateAiSuggestions(String personId) async {
    final response = await _api.post('/api/v1/genealogy/ai/suggest/$personId');
    final list = response['data'] as List;
    return list.map((e) => AiSuggestion.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<AiSuggestion>> getPendingSuggestions(String personId) async {
    final response = await _api.get('/api/v1/genealogy/ai/suggestions/$personId');
    final list = response['data'] as List;
    return list.map((e) => AiSuggestion.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Accepte (`accepted=true`) ou rejette une suggestion IA via l'endpoint
  /// existant PUT /ai/suggestions/{id}/review. C'est l'unique voie de
  /// confirmation — l'ancien POST /suggestions/{id}/confirm n'existe pas
  /// côté backend.
  Future<AiSuggestion> reviewSuggestion(String suggestionId, bool accepted) async {
    final response = await _api.put(
      '/api/v1/genealogy/ai/suggestions/$suggestionId/review',
      data: {'accepted': accepted},
    );
    return AiSuggestion.fromJson(response['data'] as Map<String, dynamic>);
  }
}

// ── Providers ──────────────────────────────────────────────

final genealogyApiServiceProvider = Provider<GenealogyApiService>((ref) {
  return GenealogyApiService(ref.read(apiClientProvider));
});

/// Arbre familial avec lecture stale-while-revalidate :
/// 1. si un cache local existe, il est émis immédiatement (affichage instantané
///    et support hors-ligne) ;
/// 2. le réseau est ensuite interrogé en arrière-plan — succès → l'état est mis
///    à jour et le cache réécrit ; échec → silencieux si un cache a été servi,
///    sinon l'erreur remonte à l'UI.
/// API publique inchangée : `ref.watch(familyTreeProvider(personId))` expose un
/// `AsyncValue<FamilyTree>` et `ref.invalidate(...)` relance le cycle.
final familyTreeProvider =
    StreamProvider.autoDispose.family<FamilyTree, String>((ref, personId) async* {
  if (kDebugMode) {
    debugPrint('[TREE] familyTreeProvider called for personId=$personId');
  }
  final cache = ref.watch(cacheServiceProvider);

  // ── 1. Cache d'abord ──
  FamilyTree? cachedTree;
  final cachedJson = cache.getFamilyTreeJson(personId);
  if (cachedJson != null) {
    try {
      cachedTree = FamilyTree.fromJson(cachedJson);
      if (kDebugMode) {
        debugPrint('[TREE] cache hit — émission immédiate pour $personId');
      }
      yield cachedTree;
    } catch (e) {
      cachedTree = null;
      if (kDebugMode) {
        debugPrint('[TREE] cache illisible pour $personId — $e');
      }
    }
  }

  // ── 2. Réseau (revalidation en arrière-plan) ──
  try {
    final tree = await ref.read(genealogyApiServiceProvider).getFullTree(personId);
    if (kDebugMode) {
      debugPrint('[TREE] SUCCESS — subject=${tree.subject.firstName} ${tree.subject.lastName}, '
          'father=${tree.father.length}, mother=${tree.mother.length}, '
          'children=${tree.children.length}, siblings=${tree.siblings.length}, '
          'unions=${tree.unions.length}');
    }
    cache.putFamilyTreeJson(personId, tree.toJson());
    yield tree;
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('[TREE] ERROR — $e');
      debugPrint('[TREE] STACKTRACE — $st');
    }
    // Hors ligne avec cache servi : erreur silencieuse, l'arbre reste affiché.
    if (cachedTree == null) rethrow;
  }
});
