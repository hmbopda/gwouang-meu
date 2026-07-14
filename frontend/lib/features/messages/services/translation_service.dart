import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gwangmeu/core/network/api_client.dart';

/// Traduction FR ↔ langue native via le moteur backend
/// `POST /api/v1/translate` (IA + dictionnaire). Appel AUTHENTIFIÉ : le JWT
/// Supabase est injecté par [ApiClient] comme pour tous les `/api/v1/**`.
/// Réponse enveloppée `ApiResponse` → charge utile dans `data`.

/// Sens de traduction attendus par le backend (valeurs du corps `direction`).
///
/// Exposés en constantes plutôt qu'en énum pour coller exactement au contrat
/// (`String direction`) tout en évitant les chaînes magiques côté UI.
abstract final class TranslationDirection {
  /// Français → langue native (sens par défaut du pill « Activer »).
  static const frToNative = 'FR_TO_NATIVE';

  /// Langue native → français.
  static const nativeToFr = 'NATIVE_TO_FR';
}

/// Le moteur de traduction est momentanément indisponible (HTTP 503 — clé IA
/// pas encore configurée). À présenter par un message doux, jamais un crash.
class TranslationUnavailableException implements Exception {
  const TranslationUnavailableException();
}

/// Résultat d'une traduction (désenveloppé depuis `data`).
class TranslationResult {
  const TranslationResult({
    required this.translation,
    this.pronunciation,
    this.confidence = 0,
    this.notes,
  });

  /// Texte traduit.
  final String translation;

  /// Prononciation phonétique — `null` si le moteur n'en fournit pas.
  final String? pronunciation;

  /// Confiance du moteur, bornée 0..1.
  final double confidence;

  /// Notes contextuelles (registre, variante…) — `null` si absentes.
  final String? notes;

  factory TranslationResult.fromJson(Map<String, dynamic> j) =>
      TranslationResult(
        translation: (j['translation'] as String? ?? '').trim(),
        pronunciation: _blankToNull(j['pronunciation']),
        confidence: ((j['confidence'] as num?)?.toDouble() ?? 0).clamp(0, 1),
        notes: _blankToNull(j['notes']),
      );

  /// Ramène les chaînes vides/espaces à `null` (le backend peut renvoyer `""`).
  static String? _blankToNull(dynamic v) {
    if (v is! String) return null;
    final s = v.trim();
    return s.isEmpty ? null : s;
  }
}

class TranslationService {
  TranslationService(this._api);
  final ApiClient _api;

  /// Traduit [text] dans le sens [direction] pour le dictionnaire [languageCode].
  ///
  /// [direction] : [TranslationDirection.frToNative] ou
  /// [TranslationDirection.nativeToFr].
  ///
  /// Lève [TranslationUnavailableException] si le moteur répond 503 (clé IA non
  /// configurée) — à traiter par un message doux, pas une erreur brutale.
  Future<TranslationResult> translate({
    required String text,
    required String direction,
    // TODO(langues): mapper `village.language.code` → code de dictionnaire
    // quand d'autres dictionnaires existeront. MVP : « moye-bandenkop » seul.
    String languageCode = 'moye-bandenkop',
  }) async {
    try {
      final r = await _api.post('/api/v1/translate', data: {
        'languageCode': languageCode,
        'direction': direction,
        'text': text,
      });
      final data = r['data'] as Map<String, dynamic>?;
      if (data == null) throw const TranslationUnavailableException();
      return TranslationResult.fromJson(data);
    } on DioException catch (e) {
      // 503 = moteur momentanément indisponible → message doux côté UI.
      if (e.response?.statusCode == 503) {
        throw const TranslationUnavailableException();
      }
      rethrow;
    }
  }
}

final translationServiceProvider = Provider<TranslationService>(
    (ref) => TranslationService(ref.read(apiClientProvider)));
