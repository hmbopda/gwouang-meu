import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/router/route_names.dart';
import 'package:gwangmeu/core/theme/app_theme.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/genealogy/genealogy_notifier.dart';
import 'package:gwangmeu/features/genealogy/verification/verification_provider.dart';

/// Écran de vérification du lien IA (prototype « Suggestion IA vers Arbre »).
///
/// 2 personnes face à face, 3 correspondances à cocher (toggle → fond/bordure
/// sage), indice « récit d'aîné » ; le CTA reste désactivé tant que tout
/// n'est pas validé, libellé dynamique « Validez les N correspondances
/// restantes ». Confirmer → mutation optimiste + navigation vers l'arbre,
/// toast sage 3,2 s.
class VerificationScreen extends ConsumerWidget {
  const VerificationScreen({super.key, this.suggestionId = kDemoSuggestionId});

  final String suggestionId;

  static const _matches = [
    (
      title: 'Lignée « Bakoko-Ndogbélé »',
      detail: 'Présente dans vos deux arbres, orthographes proches.',
      pct: '92%',
    ),
    (
      title: 'Ancêtre « Asante Mbog »',
      detail: 'Cité dans le récit audio de Grand-père Joseph (1994).',
      pct: '84%',
    ),
    (
      title: 'Village d\'origine : Edéa',
      detail: 'Les deux familles y sont établies avant 1930.',
      pct: '86%',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final state = ref.watch(verificationProvider);
    final notifier = ref.read(verificationProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Column(
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
                          '3 CORRESPONDANCES · CONFIANCE 87%',
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
                      initial: 'S',
                      name: 'Vous',
                      lineage: 'Lignée Mbopda',
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
                      initial: 'K',
                      name: 'Kwame Asante',
                      lineage: 'Lignée Asante',
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
                  for (int i = 0; i < _matches.length; i++) ...[
                    _matchCard(context, t, i, state.checks[i],
                        () => notifier.toggleCheck(i)),
                    const SizedBox(height: 10),
                  ],
                  // Indice récit d'aîné
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: t.inkCard,
                      borderRadius: BorderRadius.circular(GwTokens.rBtn),
                    ),
                    child: Row(
                      children: [
                        Icon(Symbols.mic, size: 18, color: t.goldText),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'En doute ? Demandez à un aîné — le récit de '
                            'Grand-père Joseph mentionne « les cousins d\'Asante ».',
                            style: GwType.ui(
                                fontSize: 12.5,
                                color: t.stoneMid,
                                height: 1.5),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('4:12',
                            style: GwType.mono(
                                fontSize: 10, color: t.goldText)),
                      ],
                    ),
                  ),
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
                        ? () => _confirm(context, ref)
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
                  ref.read(verificationProvider.notifier).reset();
                  context.pop();
                },
                child: Text(
                  'Rejeter cette suggestion',
                  style: GwType.ui(fontSize: 13, color: t.stoneFaint),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final person =
        ref.read(genealogyNotifierProvider).valueOrNull;
    final ok = await ref.read(verificationProvider.notifier).confirm(
          suggestionId: suggestionId,
          personId: person?.id ?? '',
        );
    if (!context.mounted) return;

    if (ok) {
      // La branche rejoint la rivière : navigation vers l'arbre + toast sage.
      context.go(Routes.genealogy);
      showGwToast(context, 'Kwame a rejoint la rivière — il en sera informé');
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
            style: GwType.ui(
                fontSize: 14, fontWeight: FontWeight.w600, color: t.stone),
          ),
          const SizedBox(height: 2),
          Text(
            lineage,
            style: GwType.ui(fontSize: 12, color: t.stoneFaint),
          ),
        ],
      ),
    );
  }

  Widget _matchCard(BuildContext context, GwTokens t, int index,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _matches[index].title,
                      style: GwType.ui(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: t.stone),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _matches[index].detail,
                      style: GwType.ui(
                          fontSize: 13, color: t.stoneDim, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _matches[index].pct,
                style: GwType.mono(fontSize: 10, color: t.sageText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
