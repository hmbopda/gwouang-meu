import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/genealogy/models/family_tree.dart';

/// Panneau droit « Récit » (#2c) — la lignée se raconte au lieu de se lister :
/// extrait Fraunces italique, lecteur audio, affluent IA proposé,
/// progression « X / N récits ».
class GenealogyStoryPanel extends StatelessWidget {
  const GenealogyStoryPanel({
    super.key,
    required this.tree,
    this.onVerifySuggestion,
    this.onDismissSuggestion,
  });

  final FamilyTree tree;

  /// CTA « Vérifier ensemble » de l'affluent IA.
  final VoidCallback? onVerifySuggestion;
  final VoidCallback? onDismissSuggestion;

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
                _audioPlayer(t),
                const SizedBox(height: 22),

                // ── Affluent proposé ──
                _sectionLabel(t, 'AFFLUENT PROPOSÉ · 87%',
                    color: t.sageText),
                const SizedBox(height: 10),
                Text(
                  'Kwame Asante partage 3 lignées Bakoko avec vous. '
                  'Vérifiez ensemble, puis la branche rejoindra la rivière.',
                  style: GwType.ui(
                      fontSize: 13.5, color: t.stoneMid, height: 1.65),
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
                              borderRadius:
                                  BorderRadius.circular(GwTokens.rBtn),
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
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(GwTokens.rBtn),
                          ),
                        ),
                        child: Text('Plus tard',
                            style: GwType.ui(fontSize: 13.5)),
                      ),
                    ),
                  ],
                ),
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

  Widget _audioPlayer(GwTokens t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: t.inkCard,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: t.goldBg,
              shape: BoxShape.circle,
            ),
            child: Icon(Symbols.play_arrow, size: 20, color: t.goldText),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Récit de la lignée',
                  style: GwType.ui(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: t.stone),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: SizedBox(
                    height: 4,
                    child: LinearProgressIndicator(
                      value: 0,
                      backgroundColor: t.inkLift,
                      valueColor:
                          const AlwaysStoppedAnimation(GwTokens.gold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('—:—',
              style: GwType.mono(fontSize: 11, color: t.stoneFaint)),
        ],
      ),
    );
  }
}
