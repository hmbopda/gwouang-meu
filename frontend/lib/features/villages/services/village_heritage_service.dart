import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gwangmeu/core/network/api_client.dart';
import 'package:gwangmeu/shared/models/village_model.dart';

/// Patrimoine d'un village — dynastie des chefs (actuel + anciens) et temps forts.
///
/// Base : `/api/v1/villages/{villageId}`. Lectures publiques ; écritures réservées
/// à EDIT_VILLAGE (chef / délégué / super-admin) côté backend. Réponses enveloppées
/// `ApiResponse` → lecture via `response['data']`. JWT injecté par [ApiClient].

// ── Modèles ─────────────────────────────────────────────────

/// Chef d'un village dans la dynastie : chef actuel ([current]) ou ancien chef.
/// [reignStart]/[reignEnd] facultatifs (chefs historiques). Pas forcément un compte.
class DynastyChief {
  const DynastyChief({
    required this.id,
    required this.displayName,
    this.reignStart,
    this.reignEnd,
    this.current = false,
    this.ordinal = 0,
    this.note,
    this.avatarUrl,
    this.userId,
  });

  final String id;
  final String displayName;
  final int? reignStart;
  final int? reignEnd;
  final bool current;
  final int ordinal;
  final String? note;
  final String? avatarUrl;
  final String? userId;

  /// Libellé de règne affichable : « 1920 – 1975 », « depuis 2001 »,
  /// « à partir de 1850 », « jusqu'en 1912 » ou '' si aucune date.
  String get reignLabel {
    if (reignStart != null && reignEnd != null) return '$reignStart – $reignEnd';
    if (reignStart != null) {
      return current ? 'depuis $reignStart' : 'à partir de $reignStart';
    }
    if (reignEnd != null) return "jusqu'en $reignEnd";
    return '';
  }

  factory DynastyChief.fromJson(Map<String, dynamic> json) => DynastyChief(
        id: json['id']?.toString() ?? '',
        displayName: json['displayName'] as String? ?? '',
        reignStart: (json['reignStart'] as num?)?.toInt(),
        reignEnd: (json['reignEnd'] as num?)?.toInt(),
        current: json['current'] as bool? ?? false,
        ordinal: (json['ordinal'] as num?)?.toInt() ?? 0,
        note: json['note'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        userId: json['userId']?.toString(),
      );
}

/// Temps fort (jalon historique) d'un village.
/// La date est une [year] et/ou un [dateLabel] libre (« XVIIIe siècle »).
class VillageMilestone {
  const VillageMilestone({
    required this.id,
    this.year,
    this.dateLabel,
    required this.title,
    this.description,
    this.ordinal = 0,
  });

  final String id;
  final int? year;
  final String? dateLabel;
  final String title;
  final String? description;
  final int ordinal;

  /// Date affichable : libellé libre prioritaire, sinon année, sinon ''.
  String get dateText {
    final label = dateLabel?.trim();
    if (label != null && label.isNotEmpty) return label;
    if (year != null) return '$year';
    return '';
  }

  factory VillageMilestone.fromJson(Map<String, dynamic> json) => VillageMilestone(
        id: json['id']?.toString() ?? '',
        year: (json['year'] as num?)?.toInt(),
        dateLabel: json['dateLabel'] as String?,
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        ordinal: (json['ordinal'] as num?)?.toInt() ?? 0,
      );
}

// ── Service ─────────────────────────────────────────────────

class VillageHeritageService {
  VillageHeritageService(this._api);

  final ApiClient _api;

  static const _base = '/api/v1/villages';

  String _v(String villageId) => '$_base/$villageId';

  // ── Dynastie ──────────────────────────────────────────────

  Future<List<DynastyChief>> chiefs(String villageId) async {
    final r = await _api.get('${_v(villageId)}/chiefs');
    final list = r['data'] as List? ?? const [];
    return list
        .map((e) => DynastyChief.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Crée ([chiefId] null) ou met à jour un chef de la dynastie.
  Future<DynastyChief> saveChief(
    String villageId, {
    String? chiefId,
    required String displayName,
    int? reignStart,
    int? reignEnd,
    bool current = false,
    int? ordinal,
    String? note,
    String? avatarUrl,
    String? userId,
  }) async {
    final body = <String, dynamic>{
      'displayName': displayName,
      'reignStart': reignStart,
      'reignEnd': reignEnd,
      'current': current,
      'ordinal': ordinal,
      'note': note,
      'avatarUrl': avatarUrl,
      'userId': userId,
    };
    final r = chiefId == null
        ? await _api.post('${_v(villageId)}/chiefs', data: body)
        : await _api.put('${_v(villageId)}/chiefs/$chiefId', data: body);
    return DynastyChief.fromJson(r['data'] as Map<String, dynamic>);
  }

  Future<void> deleteChief(String villageId, String chiefId) =>
      _api.delete('${_v(villageId)}/chiefs/$chiefId');

  // ── Temps forts ───────────────────────────────────────────

  Future<List<VillageMilestone>> milestones(String villageId) async {
    final r = await _api.get('${_v(villageId)}/milestones');
    final list = r['data'] as List? ?? const [];
    return list
        .map((e) => VillageMilestone.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Crée ([milestoneId] null) ou met à jour un temps fort.
  Future<VillageMilestone> saveMilestone(
    String villageId, {
    String? milestoneId,
    int? year,
    String? dateLabel,
    required String title,
    String? description,
    int? ordinal,
  }) async {
    final body = <String, dynamic>{
      'year': year,
      'dateLabel': dateLabel,
      'title': title,
      'description': description,
      'ordinal': ordinal,
    };
    final r = milestoneId == null
        ? await _api.post('${_v(villageId)}/milestones', data: body)
        : await _api.put('${_v(villageId)}/milestones/$milestoneId', data: body);
    return VillageMilestone.fromJson(r['data'] as Map<String, dynamic>);
  }

  Future<void> deleteMilestone(String villageId, String milestoneId) =>
      _api.delete('${_v(villageId)}/milestones/$milestoneId');

  // ── Genèse (founded_year + historical_summary via PUT village) ─────

  Future<VillageModel> updateGenesis(
    String villageId, {
    int? foundedYear,
    String? historicalSummary,
  }) async {
    final r = await _api.put(_v(villageId), data: <String, dynamic>{
      if (foundedYear != null) 'foundedYear': foundedYear,
      if (historicalSummary != null) 'historicalSummary': historicalSummary,
    });
    return VillageModel.fromJson(r['data'] as Map<String, dynamic>);
  }
}

// ── Providers ───────────────────────────────────────────────

final villageHeritageServiceProvider =
    Provider<VillageHeritageService>((ref) {
  return VillageHeritageService(ref.read(apiClientProvider));
});

/// Dynastie d'un village (chef actuel + anciens). Invalidable après édition.
final villageDynastyProvider =
    FutureProvider.family<List<DynastyChief>, String>((ref, villageId) {
  return ref.read(villageHeritageServiceProvider).chiefs(villageId);
});

/// Temps forts d'un village. Invalidable après édition.
final villageMilestonesProvider =
    FutureProvider.family<List<VillageMilestone>, String>((ref, villageId) {
  return ref.read(villageHeritageServiceProvider).milestones(villageId);
});
