import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/router/route_names.dart';
import 'package:gwangmeu/core/theme/app_theme.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/genealogy/genealogy_notifier.dart';
import 'package:gwangmeu/features/genealogy/models/ai_suggestion.dart';
import 'package:gwangmeu/features/genealogy/models/person_genealogy.dart';
import 'package:gwangmeu/features/genealogy/verification/verification_provider.dart';

/// Écran de vérification du lien IA — branché sur la suggestion réelle
/// (`tree.pendingSuggestions` / GET /ai/suggestions/{personId}).
///
/// 2 personnes face à face (sujet réel + personne suggérée), les
/// correspondances = `AiSuggestion.reasons` à cocher (toggle → fond/bordure
/// sage) ; le CTA reste désactivé tant que tout n'est pas validé, libellé
/// dynamique « Validez les N correspondances restantes ». Confirmer →
/// mutation optimiste + PUT /ai/suggestions/{id}/review + navigation vers
/// l'arbre, toast sage 3,2 s. Suggestion introuvable → écran d'erreur propre.
class VerificationScreen extends ConsumerWidget {
  const VerificationScreen({super.key, required this.suggestionId});

  final String suggestionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final suggestionAsync = ref.watch(suggestionByIdProvider(suggestionId));

    return Scaffold(
      body: SafeArea(
        child: suggestionAsync.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: t.goldText)),
          error: (e, _) => _NotFoundView(
            message: 'Impossible de charger la suggestion — '
                'vérifiez votre connexion.',
          ),
          data: (suggestion) => suggestion == null
              ? const _NotFoundView(
                  message: 'Cette suggestion n\'existe plus ou a déjà '
                      'été traitée.',
                )
              : _VerificationBody(suggestion: suggestion),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Corps de l'écran — suggestion réelle chargée
// ─────────────────────────────────────────────────────────────

class _VerificationBody extends ConsumerWidget {
  const _VerificationBody({required this.suggestion});

  final AiSuggestion suggestion;

  /// Correspondances réelles ; carte générique si `reasons` est vide.
  List<String> get _matches => suggestion.reasons.isNotEmpty
      ? suggestion.reasons
      : const [
          'Correspondance détectée par l\'analyse des lignées — '
              'vérifiez avec un aîné avant de confirmer.',
        ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final matches = _matches;
    final state = ref.watch(verificationProvider(matches.length));
    final notifier = ref.read(verificationProvider(matches.length).notifier);
    final subject = ref.watch(genealogyNotifierProvider).valueOrNull;
    final other = _suggestedPerson(subject);
    final pct = suggestionConfidencePct(suggestion);

    return Column(
      children: [
        const GwWeaveBand(),

        // ── Header ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: t.line)),
          ),
          child: Row(
            children: [
              Material(
                color: t.inkLift,
                borderRadius: BorderRadius.circular(GwTokens.rBtn),
                child: InkWell(
                  onTap: () => context.pop(),
                  borderRadius: BorderRadius.circular(GwTokens.rBtn),
                  child: SizedBox(
                    width: GwTokens.tapTarget,
                    height: GwTokens.tapTarget,
                    child: Icon(Symbols.arrow_back,
                        size: 20, color: t.stoneMid),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vérifier le lien',
                      style: GwType.display(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: t.stone),
                    ),
                    Text(
                      '${matches.length} CORRESPONDANCE'
                      '${matches.length > 1 ? 'S' : ''} · CONFIANCE $pct%',
                      style: GwType.mono(
                          fontSize: 11,
                          color: t.sageText,
                          letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Les deux personnes ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
          child: Row(
            children: [
              Expanded(
                child: _personCard(
                  t,
                  initial: _initialOf(subject?.firstName),
                  name: subject != null
                      ? '${subject.firstName} ${subject.lastName}'.trim()
                      : 'Vous',
                  lineage: subject != null && subject.lastName.isNotEmpty
                      ? 'Lignée ${subject.lastName}'
                      : 'Votre lignée',
                  confirmedStyle: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    Icon(Symbols.link, size: 22, color: t.sageText),
                    const SizedBox(height: 4),
                    Text(
                      'ANCÊTRE ?',
                      style: GwType.mono(
                          fontSize: 10,
                          color: t.sageText,
                          letterSpacing: 1),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _personCard(
                  t,
                  initial: _initialOf(other?.firstName),
                  name: other != null
                      ? '${other.firstName} ${other.lastName}'.trim()
                      : 'Personne suggérée',
                  lineage: other != null && other.lastName.isNotEmpty
                      ? 'Lignée ${other.lastName}'
                      : 'Lignée à vérifier',
                  confirmedStyle: false,
                ),
              ),
            ],
          ),
        ),

        // ── Correspondances ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'CORRESPONDANCES — TOUCHEZ POUR VALIDER',
              style: GwType.mono(
                  fontSize: 10, letterSpacing: 2, color: t.stoneFaint),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            children: [
              for (int i = 0; i < matches.length; i++) ...[
                _matchCard(context, t, matches[i],
                    i < state.checks.length && state.checks[i],
                    () => notifier.toggleCheck(i)),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),

        // ── CTA dynamique ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: Material(
              color: state.allChecked ? GwTokens.sage : t.inkLift,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: state.allChecked && !state.submitting
                    ? () => _confirm(context, ref, notifier)
                    : null,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: state.submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFF0EBE1)),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Symbols.family_history,
                              size: 19,
                              color: state.allChecked
                                  ? const Color(0xFFF0EBE1)
                                  : t.stoneFaint,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              state.allChecked
                                  ? 'Confirmer le lien familial'
                                  : 'Validez les ${state.remaining} correspondance${state.remaining > 1 ? 's' : ''} restantes',
                              style: GwType.ui(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: state.allChecked
                                    ? const Color(0xFFF0EBE1)
                                    : t.stoneFaint,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),

        // ── Rejeter ──
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextButton(
            onPressed: () {
              // Masque l'affluent localement, sans appel réseau.
              ref.read(dismissedSuggestionsProvider.notifier).update(
                    (s) => {...s, suggestion.id},
                  );
              notifier.reset();
              context.pop();
            },
            child: Text(
              'Rejeter cette suggestion',
              style: GwType.ui(fontSize: 13, color: t.stoneFaint),
            ),
          ),
        ),
      ],
    );
  }

  /// Personne proposée : personB, ou personA si personB est le sujet.
  PersonGenealogy? _suggestedPerson(PersonGenealogy? subject) {
    final subjectId = subject?.id;
    if (suggestion.personB != null && suggestion.personB!.id != subjectId) {
      return suggestion.personB;
    }
    if (suggestion.personA != null && suggestion.personA!.id != subjectId) {
      return suggestion.personA;
    }
    return suggestion.personB ?? suggestion.personA;
  }

  String _initialOf(String? firstName) =>
      (firstName != null && firstName.isNotEmpty)
          ? firstName[0].toUpperCase()
          : '?';

  Future<void> _confirm(BuildContext context, WidgetRef ref,
      VerificationNotifier notifier) async {
    final subject = ref.read(genealogyNotifierProvider).valueOrNull;
    final other = _suggestedPerson(subject);
    final ok = await notifier.confirm(
      suggestionId: suggestion.id,
      personId: subject?.id ?? '',
    );
    if (!context.mounted) return;

    if (ok) {
      // La branche rejoint la rivière : navigation vers l'arbre + toast sage.
      final name = (other?.firstName.isNotEmpty ?? false)
          ? other!.firstName
          : 'La branche';
      context.go(Routes.genealogy);
      showGwToast(context, '$name a rejoint la rivière — il en sera informé');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'La confirmation a échoué — réessayez.',
            style: GwType.ui(fontSize: 14, color: Colors.white),
          ),
          backgroundColor: GwTokens.ember,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _personCard(
    GwTokens t, {
    required String initial,
    required String name,
    required String lineage,
    required bool confirmedStyle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.inkCard,
        borderRadius: BorderRadius.circular(GwTokens.rCard),
        border: Border.all(
          color: confirmedStyle
              ? GwTokens.gold.withValues(alpha: 0.3)
              : GwTokens.sage.withValues(alpha: 0.5),
          width: confirmedStyle ? 1 : 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: confirmedStyle
                  ? GwTokens.gold
                  : const Color(0xFF0D1F16),
              shape: BoxShape.circle,
              border: confirmedStyle
                  ? null
                  : Border.all(color: GwTokens.sage, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: GwType.display(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: confirmedStyle
                    ? const Color(0xFF0C0B0F)
                    : t.sageText,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GwType.ui(
                fontSize: 14, fontWeight: FontWeight.w600, color: t.stone),
          ),
          const SizedBox(height: 2),
          Text(
            lineage,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GwType.ui(fontSize: 12, color: t.stoneFaint),
          ),
        ],
      ),
    );
  }

  Widget _matchCard(BuildContext context, GwTokens t, String reason,
      bool checked, VoidCallback onToggle) {
    return Material(
      color: checked ? GwTokens.sageBg : t.inkCard,
      borderRadius: BorderRadius.circular(GwTokens.rCard),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(GwTokens.rCard),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GwTokens.rCard),
            border: Border.all(
              color: checked ? GwTokens.sageLine : t.line,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color:
                      checked ? GwTokens.sage : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: checked ? GwTokens.sage : t.stoneFaint,
                    width: 1.5,
                  ),
                ),
                child: checked
                    ? const Icon(Symbols.check,
                        size: 17, color: Color(0xFFF0EBE1))
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  reason,
                  style: GwType.ui(
                      fontSize: 14, color: t.stone, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Suggestion introuvable / erreur de chargement
// ─────────────────────────────────────────────────────────────

class _NotFoundView extends StatelessWidget {
  const _NotFoundView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Column(
      children: [
        const GwWeaveBand(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Symbols.search_off, size: 48, color: t.stoneFaint),
                  const SizedBox(height: 14),
                  Text(
                    'Suggestion introuvable',
                    style: GwType.display(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: t.stone),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GwType.ui(
                        fontSize: 14, color: t.stoneMid, height: 1.6),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go(Routes.genealogy),
                      style: FilledButton.styleFrom(
                        backgroundColor: GwTokens.gold,
                        foregroundColor: const Color(0xFF0C0B0F),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(GwTokens.rBtn),
                        ),
                      ),
                      icon: const Icon(Symbols.arrow_back, size: 18),
                      label: Text(
                        'Revenir à l\'arbre',
                        style: GwType.ui(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
