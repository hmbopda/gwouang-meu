import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gwangmeu/features/genealogy/services/genealogy_api_service.dart';

/// Parcours « Suggestion IA vers Arbre » — état de l'écran de vérification.
///
/// `step` suit le prototype (0 = fil, 1 = vérification, 2 = arbre) même si
/// la navigation réelle passe par GoRouter ; `checks` porte les 3
/// correspondances à valider ; `linkConfirmed` bascule la branche de
/// « AFFLUENT · 87% » à « BRANCHE CONFIRMÉE ».
class VerificationState {
  const VerificationState({
    this.step = 1,
    this.checks = const [false, false, false],
    this.linkConfirmed = false,
    this.submitting = false,
  });

  final int step;
  final List<bool> checks;
  final bool linkConfirmed;
  final bool submitting;

  bool get allChecked => checks.every((c) => c);
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
  VerificationNotifier(this._ref) : super(const VerificationState());

  final Ref _ref;

  void toggleCheck(int index) {
    if (index < 0 || index >= state.checks.length) return;
    final checks = List<bool>.from(state.checks);
    checks[index] = !checks[index];
    state = state.copyWith(checks: checks);
  }

  void setStep(int step) => state = state.copyWith(step: step);

  /// Confirme le lien : mutation optimiste (la branche rejoint la rivière
  /// immédiatement, compteur +1), puis POST /genealogy/suggestions/{id}/confirm.
  /// En cas d'échec API sur une vraie suggestion, l'état est annulé.
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

    // Suggestion de démonstration : pas d'appel réseau.
    if (suggestionId.startsWith('demo-')) {
      state = state.copyWith(submitting: false);
      return true;
    }

    try {
      await _ref
          .read(genealogyApiServiceProvider)
          .confirmSuggestion(suggestionId);
      // Re-synchronise l'arbre avec le backend.
      _ref.invalidate(familyTreeProvider(personId));
      state = state.copyWith(submitting: false);
      return true;
    } catch (e) {
      debugPrint('[VERIFY] confirmSuggestion failed: $e');
      // Rollback de la mutation optimiste
      _ref.read(confirmedSuggestionsProvider.notifier).update(
            (set) => {...set}..remove(suggestionId),
          );
      state = state.copyWith(
          linkConfirmed: false, step: 1, submitting: false);
      return false;
    }
  }

  void reset() => state = const VerificationState();
}

/// État du parcours de vérification (checks, confirmation).
final verificationProvider = StateNotifierProvider.autoDispose<
    VerificationNotifier, VerificationState>(
  (ref) => VerificationNotifier(ref),
);

/// Suggestions confirmées (mutation optimiste visible dans la rivière :
/// branche pleine « BRANCHE CONFIRMÉE », compteur de membres +1).
final confirmedSuggestionsProvider =
    StateProvider<Set<String>>((_) => <String>{});

/// Id de la suggestion de démonstration (Kwame Asante — prototype).
const kDemoSuggestionId = 'demo-kwame-asante';
