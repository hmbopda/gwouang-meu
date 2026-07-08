import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gwangmeu/features/genealogy/genealogy_notifier.dart';
import 'package:gwangmeu/features/genealogy/models/ai_suggestion.dart';
import 'package:gwangmeu/features/genealogy/services/genealogy_api_service.dart';

/// Parcours « Suggestion IA vers Arbre » — état de l'écran de vérification.
///
/// `step` suit le prototype (0 = fil, 1 = vérification, 2 = arbre) même si
/// la navigation réelle passe par GoRouter ; `checks` porte les
/// correspondances à valider ; `linkConfirmed` bascule la branche
/// d'« AFFLUENT · n% » à « BRANCHE CONFIRMÉE ».
class VerificationState {
  const VerificationState({
    this.step = 1,
    this.checks = const [],
    this.linkConfirmed = false,
    this.submitting = false,
  });

  final int step;
  final List<bool> checks;
  final bool linkConfirmed;
  final bool submitting;

  bool get allChecked => checks.isNotEmpty && checks.every((c) => c);
  int get remaining => checks.where((c) => !c).length;

  VerificationState copyWith({
    int? step,
    List<bool>? checks,
    bool? linkConfirmed,
    bool? submitting,
  }) {
    return VerificationState(
      step: step ?? this.step,
      checks: checks ?? this.checks,
      linkConfirmed: linkConfirmed ?? this.linkConfirmed,
      submitting: submitting ?? this.submitting,
    );
  }
}

class VerificationNotifier extends StateNotifier<VerificationState> {
  VerificationNotifier(this._ref, int matchCount)
      : super(VerificationState(checks: List.filled(matchCount, false)));

  final Ref _ref;

  void toggleCheck(int index) {
    if (index < 0 || index >= state.checks.length) return;
    final checks = List<bool>.from(state.checks);
    checks[index] = !checks[index];
    state = state.copyWith(checks: checks);
  }

  void setStep(int step) => state = state.copyWith(step: step);

  /// Confirme le lien : mutation optimiste (la branche rejoint la rivière
  /// immédiatement, compteur +1), puis PUT /ai/suggestions/{id}/review
  /// avec accepted=true. En cas d'échec API, l'état est annulé (rollback).
  Future<bool> confirm({
    required String suggestionId,
    required String personId,
  }) async {
    if (!state.allChecked || state.submitting) return false;
    state = state.copyWith(submitting: true);

    // Mutation optimiste
    state = state.copyWith(linkConfirmed: true, step: 2);
    _ref.read(confirmedSuggestionsProvider.notifier).update(
          (set) => {...set, suggestionId},
        );

    try {
      await _ref
          .read(genealogyApiServiceProvider)
          .reviewSuggestion(suggestionId, true);
      // Re-synchronise l'arbre avec le backend.
      if (personId.isNotEmpty) {
        _ref.invalidate(familyTreeProvider(personId));
      }
      state = state.copyWith(submitting: false);
      return true;
    } catch (e) {
      debugPrint('[VERIFY] reviewSuggestion failed: $e');
      // Rollback de la mutation optimiste
      _ref.read(confirmedSuggestionsProvider.notifier).update(
            (set) => {...set}..remove(suggestionId),
          );
      state = state.copyWith(
          linkConfirmed: false, step: 1, submitting: false);
      return false;
    }
  }

  void reset() =>
      state = VerificationState(
          checks: List.filled(state.checks.length, false));
}

/// État du parcours de vérification (checks, confirmation),
/// dimensionné sur le nombre de correspondances à valider.
final verificationProvider = StateNotifierProvider.autoDispose
    .family<VerificationNotifier, VerificationState, int>(
  (ref, matchCount) => VerificationNotifier(ref, matchCount),
);

/// Suggestions confirmées (mutation optimiste visible dans la rivière :
/// branche pleine « BRANCHE CONFIRMÉE », compteur de membres +1).
final confirmedSuggestionsProvider =
    StateProvider<Set<String>>((_) => <String>{});

/// Suggestions écartées localement (« Plus tard » / « Rejeter ») :
/// la carte affluent est masquée sans appel réseau.
final dismissedSuggestionsProvider =
    StateProvider<Set<String>>((_) => <String>{});

/// Résout une suggestion IA réelle depuis son id : d'abord dans
/// `tree.pendingSuggestions` du sujet courant, sinon via
/// GET /ai/suggestions/{personId}. Retourne `null` si introuvable.
final suggestionByIdProvider = FutureProvider.autoDispose
    .family<AiSuggestion?, String>((ref, suggestionId) async {
  final person = await ref.watch(genealogyNotifierProvider.future);
  final tree = await ref.watch(familyTreeProvider(person.id).future);
  for (final s in tree.pendingSuggestions) {
    if (s.id == suggestionId) return s;
  }
  try {
    final pending = await ref
        .read(genealogyApiServiceProvider)
        .getPendingSuggestions(person.id);
    for (final s in pending) {
      if (s.id == suggestionId) return s;
    }
  } catch (e) {
    debugPrint('[VERIFY] getPendingSuggestions failed: $e');
  }
  return null;
});

/// Pourcentage de confiance affichable (le backend renvoie 0.0–1.0).
int suggestionConfidencePct(AiSuggestion s) {
  final raw = s.confidence <= 1 ? s.confidence * 100 : s.confidence;
  return raw.round().clamp(0, 100);
}
