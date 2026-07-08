import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/theme/app_theme.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/genealogy/models/ai_suggestion.dart';
import 'package:gwangmeu/features/genealogy/models/family_tree.dart';
import 'package:gwangmeu/features/genealogy/models/person_genealogy.dart';
import 'package:gwangmeu/features/genealogy/verification/verification_provider.dart'
    show suggestionConfidencePct;

/// Panneau droit « Récit » (#2c) — la lignée se raconte au lieu de se lister :
/// extrait Fraunces italique, récits audio (état honnête tant qu'aucun
/// enregistrement n'existe), affluent IA réel s'il y en a un,
/// progression « X / N récits ».
class GenealogyStoryPanel extends StatelessWidget {
  const GenealogyStoryPanel({
    super.key,
    required this.tree,
    this.suggestion,
    this.onVerifySuggestion,
    this.onDismissSuggestion,
    this.suggestionConfirmed = false,
  });

  final FamilyTree tree;

  /// Suggestion IA réelle (la plus forte confidence de
  /// `tree.pendingSuggestions`). `null` → la section affluent est absente.
  final AiSuggestion? suggestion;

  /// CTA « Vérifier ensemble » de l'affluent IA.
  final VoidCallback? onVerifySuggestion;

  /// « Plus tard » — masque la carte (état local côté écran parent).
  final VoidCallback? onDismissSuggestion;

  /// L'affluent a rejoint la rivière (mutation optimiste confirmée).
  final bool suggestionConfirmed;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final subject = tree.subject;
    final memberCount = _memberCount();

    return Container(
      width: 380,
      color: t.inkDeep,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header sujet ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: t.line)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                      color: GwTokens.gold, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    subject.firstName.isNotEmpty
                        ? subject.firstName[0].toUpperCase()
                        : '?',
                    style: GwType.display(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0C0B0F)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${subject.firstName} ${subject.lastName}',
                        style: GwType.display(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: t.stone),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subject.clan != null && subject.clan!.isNotEmpty
                            ? 'Sujet de l\'arbre · Clan ${subject.clan}'
                            : 'Sujet de l\'arbre',
                        style: GwType.ui(fontSize: 12.5, color: t.stoneDim),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Le récit de la lignée ──
                _sectionLabel(t, 'LE RÉCIT DE LA LIGNÉE'),
                const SizedBox(height: 10),
                Text(
                  '« Chaque nom de cette rivière porte une histoire. '
                  'Enregistrez les récits de vos aînés pour que la mémoire '
                  'coule vers les générations suivantes… »',
                  style: GwType.quote(
                      fontSize: 15,
                      color: t.stone.withValues(alpha: 0.92),
                      height: 1.7),
                ),
                const SizedBox(height: 12),
                _noRecordingState(context, t),

                // ── Affluent proposé / branche confirmée (données réelles) ──
                if (suggestion != null) ...[
                  const SizedBox(height: 22),
                  if (suggestionConfirmed)
                    ..._confirmedSection(t, suggestion!)
                  else
                    ..._proposalSection(context, t, suggestion!),
                ],
                const SizedBox(height: 22),

                // ── Mémoire vivante ──
                _sectionLabel(t, 'MÉMOIRE VIVANTE'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text('Récits audio collectés',
                          style:
                              GwType.ui(fontSize: 13, color: t.stoneMid)),
                    ),
                    Text(
                      '0 / $memberCount membres',
                      style: GwType.mono(
                          fontSize: 12,
                          color: t.goldText,
                          letterSpacing: 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: SizedBox(
                    height: 6,
                    child: LinearProgressIndicator(
                      value: 0,
                      backgroundColor: t.inkCard,
                      valueColor:
                          const AlwaysStoppedAnimation(GwTokens.gold),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Proposez à un membre de la famille d\'enregistrer son récit.',
                  style: GwType.ui(fontSize: 12, color: t.stoneFaint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Personne proposée par la suggestion : personB, ou personA si personB
  /// est le sujet de l'arbre.
  PersonGenealogy? _suggestedPerson(AiSuggestion s) {
    if (s.personB != null && s.personB!.id != tree.subject.id) {
      return s.personB;
    }
    if (s.personA != null && s.personA!.id != tree.subject.id) {
      return s.personA;
    }
    return s.personB ?? s.personA;
  }

  String _suggestedName(AiSuggestion s) {
    final p = _suggestedPerson(s);
    if (p == null) return 'Un membre';
    return '${p.firstName} ${p.lastName}'.trim();
  }

  List<Widget> _confirmedSection(GwTokens t, AiSuggestion s) {
    return [
      _sectionLabel(t, 'BRANCHE CONFIRMÉE', color: t.sageText),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: GwTokens.sage.withValues(alpha: 0.1),
          border: Border.all(color: GwTokens.sageLine),
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
        ),
        child: Row(
          children: [
            Icon(Symbols.check_circle, size: 20, color: t.sageText, fill: 1),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${_suggestedName(s)} a rejoint la rivière — '
                'il en sera informé.',
                style: GwType.ui(
                    fontSize: 13, color: t.stoneMid, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _proposalSection(
      BuildContext context, GwTokens t, AiSuggestion s) {
    final reason = s.reasons.isNotEmpty
        ? s.reasons.first
        : 'Un lien familial possible a été détecté.';
    return [
      _sectionLabel(t, 'AFFLUENT PROPOSÉ · ${suggestionConfidencePct(s)}%',
          color: t.sageText),
      const SizedBox(height: 10),
      Text(
        '${_suggestedName(s)} — $reason '
        'Vérifiez ensemble, puis la branche rejoindra la rivière.',
        style: GwType.ui(fontSize: 13.5, color: t.stoneMid, height: 1.65),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 46,
              child: FilledButton(
                onPressed: onVerifySuggestion,
                style: FilledButton.styleFrom(
                  backgroundColor: GwTokens.sage,
                  foregroundColor: const Color(0xFFF0EBE1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(GwTokens.rBtn),
                  ),
                ),
                child: Text(
                  'Vérifier ensemble',
                  style: GwType.ui(
                      fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 46,
            child: TextButton(
              onPressed: onDismissSuggestion,
              style: TextButton.styleFrom(
                backgroundColor: t.inkCard,
                foregroundColor: t.stoneFaint,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(GwTokens.rBtn),
                ),
              ),
              child: Text('Plus tard', style: GwType.ui(fontSize: 13.5)),
            ),
          ),
        ],
      ),
    ];
  }

  int _memberCount() {
    return 1 +
        tree.father.length +
        tree.mother.length +
        tree.paternalGP.length +
        tree.maternalGP.length +
        tree.siblings.length +
        tree.children.length +
        tree.uncles.length;
  }

  Widget _sectionLabel(GwTokens t, String text, {Color? color}) {
    return Text(
      text,
      style: GwType.mono(
          fontSize: 10, letterSpacing: 2, color: color ?? t.stoneFaint),
    );
  }

  /// État honnête : aucun récit n'a encore été enregistré — pas de faux
  /// lecteur audio.
  Widget _noRecordingState(BuildContext context, GwTokens t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: t.inkCard,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
      ),
      child: Row(
        children: [
          Icon(Symbols.mic_off, size: 20, color: t.stoneFaint),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Aucun récit enregistré pour l\'instant',
              style: GwType.ui(fontSize: 13, color: t.stoneMid, height: 1.4),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 44,
            child: TextButton.icon(
              onPressed: () => showGwToast(
                  context, 'Enregistrement des récits — bientôt disponible'),
              style: TextButton.styleFrom(
                foregroundColor: t.goldText,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(GwTokens.rBtn),
                ),
              ),
              icon: Icon(Symbols.mic, size: 18, color: t.goldText),
              label: Text(
                'Enregistrer un récit',
                style: GwType.ui(
                    fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
