import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gwangmeu/core/network/api_client.dart';

/// Langues d'un village (référentiel `languages` + jonction N:N). Un village
/// parle une ou plusieurs langues ; l'une est « principale » (native par défaut
/// pour la traduction). Lectures publiques ; édition réservée EDIT_VILLAGE.

class Language {
  const Language({
    required this.id,
    required this.name,
    this.code,
    this.frenchName,
    this.iso6393,
    this.region,
  });

  final String id;
  final String name; // endonyme
  final String? code;
  final String? frenchName;
  final String? iso6393;
  final String? region;

  /// Libellé d'affichage : nom français si présent, sinon endonyme.
  String get label =>
      (frenchName != null && frenchName!.isNotEmpty) ? frenchName! : name;

  factory Language.fromJson(Map<String, dynamic> j) => Language(
        id: j['id']?.toString() ?? '',
        name: j['name'] as String? ?? '',
        code: j['code'] as String?,
        frenchName: j['frenchName'] as String?,
        iso6393: j['iso6393'] as String?,
        region: j['region'] as String?,
      );
}

class VillageLanguage {
  const VillageLanguage({
    required this.language,
    this.isPrimary = false,
    this.ordinal = 0,
  });

  final Language language;
  final bool isPrimary;
  final int ordinal;

  factory VillageLanguage.fromJson(Map<String, dynamic> j) => VillageLanguage(
        language: Language.fromJson(j['language'] as Map<String, dynamic>),
        isPrimary: j['isPrimary'] as bool? ?? false,
        ordinal: (j['ordinal'] as num?)?.toInt() ?? 0,
      );
}

class VillageLanguageService {
  VillageLanguageService(this._api);
  final ApiClient _api;

  Future<List<Language>> allLanguages() async {
    final r = await _api.get('/api/v1/languages');
    final list = r['data'] as List? ?? const [];
    return list.map((e) => Language.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<VillageLanguage>> villageLanguages(String villageId) async {
    final r = await _api.get('/api/v1/villages/$villageId/languages');
    final list = r['data'] as List? ?? const [];
    return list
        .map((e) => VillageLanguage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Remplace l'ensemble des langues du village. [primaryId] = langue principale.
  Future<void> setVillageLanguages(
    String villageId, {
    required List<String> languageIds,
    String? primaryId,
  }) async {
    final body = {
      'languages': [
        for (var i = 0; i < languageIds.length; i++)
          {
            'languageId': languageIds[i],
            'isPrimary': languageIds[i] == primaryId,
            'ordinal': i,
          }
      ],
    };
    await _api.put('/api/v1/villages/$villageId/languages', data: body);
  }
}

final villageLanguageServiceProvider = Provider<VillageLanguageService>(
    (ref) => VillageLanguageService(ref.read(apiClientProvider)));

/// Référentiel de toutes les langues actives.
final languagesProvider = FutureProvider<List<Language>>(
    (ref) => ref.read(villageLanguageServiceProvider).allLanguages());

/// Langues d'un village (avec la principale).
final villageLanguagesProvider =
    FutureProvider.family<List<VillageLanguage>, String>(
        (ref, villageId) =>
            ref.read(villageLanguageServiceProvider).villageLanguages(villageId));

/// Langue principale d'un village (native par défaut) — null si non renseignée.
final villagePrimaryLanguageProvider =
    FutureProvider.family<Language?, String>((ref, villageId) async {
  final langs = await ref.watch(villageLanguagesProvider(villageId).future);
  if (langs.isEmpty) return null;
  final primary = langs.where((l) => l.isPrimary);
  return (primary.isNotEmpty ? primary.first : langs.first).language;
});
