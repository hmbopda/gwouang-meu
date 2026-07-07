import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/genealogy/models/family_tree.dart';
import 'package:gwangmeu/features/genealogy/models/person_genealogy.dart';

/// « Rivière des générations » mobile (#1d) — l'arbre navigable
/// verticalement, génération par génération, le long d'un axe or.
/// Couleur par lignée (or = lignée du sujet, rose = lignée alliée),
/// ancêtres marqués ✦, sujet en carte glow, IA en « affluent » pointillé.
class GenealogyRiverView extends StatelessWidget {
  const GenealogyRiverView({
    super.key,
    required this.tree,
    this.onPersonTap,
    this.onVerifySuggestion,
    this.showAiAffluent = true,
    this.aiConfirmed = false,
  });

  final FamilyTree tree;
  final void Function(PersonGenealogy person)? onPersonTap;
  final VoidCallback? onVerifySuggestion;
  final bool showAiAffluent;

  /// La suggestion a été confirmée : la branche passe de pointillée
  /// « AFFLUENT · 87% » à pleine « BRANCHE CONFIRMÉE » (fade-up 0,5 s).
  final bool aiConfirmed;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final generations = _buildGenerations();

    return Stack(
      children: [
        // ── Axe de la rivière ──
        Positioned.fill(
          child: Center(
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    t.stoneFaint.withValues(alpha: 0.5),
                    GwTokens.gold,
                    GwTokens.gold.withValues(alpha: 0.25),
                  ],
                  stops: const [0, 0.45, 1],
                ),
              ),
            ),
          ),
        ),

        ListView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          children: [
            for (final gen in generations) ...[
              _generationLabel(context, gen),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    for (final m in gen.members)
                      m.person.id == tree.subject.id
                          ? _subjectCard(context, m)
                          : _personCard(context, m),
                    if (gen.isSubjectGen && showAiAffluent)
                      aiConfirmed
                          ? _confirmedBranchCard(context)
                          : _affluentCard(context),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ── Générations structurées ────────────────────────────────

  List<_Generation> _buildGenerations() {
    final gens = <_Generation>[];

    final g1 = [
      ...tree.paternalGP.map((p) => _Member(p, GwTokens.gold)),
      ...tree.maternalGP.map((p) => _Member(p, GwTokens.rose)),
    ];
    final g2 = [
      ...tree.father.map((p) => _Member(p, GwTokens.gold)),
      ...tree.mother.map((p) => _Member(p, GwTokens.rose)),
      ...tree.uncles.map((p) => _Member(p, GwTokens.gold)),
    ];
    final spouses = <PersonGenealogy>[];
    for (final u in tree.unions) {
      if (u.husbandId == tree.subject.id && u.wife != null) {
        spouses.add(u.wife!);
      } else if (u.wifeId == tree.subject.id && u.husband != null) {
        spouses.add(u.husband!);
      }
    }
    final g3 = [
      _Member(tree.subject, GwTokens.gold),
      ...spouses.map((p) => _Member(p, GwTokens.rose)),
      ...tree.siblings.map((s) => _Member(s.person, GwTokens.gold)),
    ];
    final g4 = tree.children.map((p) => _Member(p, GwTokens.gold)).toList();

    if (g1.isNotEmpty) gens.add(_Generation(members: g1, founders: true));
    if (g2.isNotEmpty) gens.add(_Generation(members: g2));
    gens.add(_Generation(members: g3, isSubjectGen: true));
    if (g4.isNotEmpty) gens.add(_Generation(members: g4));

    // Numérotation continue
    for (int i = 0; i < gens.length; i++) {
      gens[i].index = i + 1;
    }
    return gens;
  }

  // ── Éléments ───────────────────────────────────────────────

  Widget _generationLabel(BuildContext context, _Generation gen) {
    final t = GwTokens.of(context);
    final label = gen.isSubjectGen
        ? 'GÉNÉRATION ${gen.index} · VOUS'
        : gen.founders
            ? 'GÉNÉRATION ${gen.index} · LES FONDATEURS'
            : 'GÉNÉRATION ${gen.index}';
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        color: t.ink,
        child: Text(
          label,
          style: GwType.mono(
            fontSize: 10,
            letterSpacing: 2,
            color: gen.isSubjectGen ? t.goldText : t.stoneFaint,
          ),
        ),
      ),
    );
  }

  Widget _personCard(BuildContext context, _Member m) {
    final t = GwTokens.of(context);
    final p = m.person;
    final isAncestor = !p.isAlive;
    final lineColor = isAncestor ? t.stoneFaint : m.lineage;

    return GestureDetector(
      onTap: () => onPersonTap?.call(p),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.inkCard,
          border: Border.all(color: lineColor.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(GwTokens.rCard),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: t.inkLift,
                shape: BoxShape.circle,
                border: Border.all(color: lineColor, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                p.firstName.isNotEmpty ? p.firstName[0].toUpperCase() : '?',
                style: GwType.display(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: isAncestor ? t.stoneMid : t.stone,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${p.firstName} ${p.lastName}',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GwType.ui(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: t.stone),
            ),
            const SizedBox(height: 2),
            Text(
              isAncestor ? '${_lifeline(p)} ✦' : _lifeline(p),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GwType.ui(fontSize: 12, color: t.stoneFaint),
            ),
            if (p.clan != null && p.clan!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _monoBadge(context, 'CLAN ${p.clan!.toUpperCase()}',
                  color: t.goldText, bg: t.goldBg),
            ],
          ],
        ),
      ),
    );
  }

  Widget _subjectCard(BuildContext context, _Member m) {
    final t = GwTokens.of(context);
    final p = m.person;
    return GestureDetector(
      onTap: () => onPersonTap?.call(p),
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              GwTokens.gold.withValues(alpha: 0.14),
              GwTokens.gold.withValues(alpha: 0.03),
            ],
          ),
          border: Border.all(
              color: GwTokens.gold.withValues(alpha: 0.55), width: 1.5),
          borderRadius: BorderRadius.circular(GwTokens.rCardLg),
          boxShadow: [
            BoxShadow(
              color: GwTokens.gold.withValues(alpha: 0.12),
              blurRadius: 28,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                  color: GwTokens.gold, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                p.firstName.isNotEmpty ? p.firstName[0].toUpperCase() : '?',
                style: GwType.display(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0C0B0F)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${p.firstName} ${p.lastName}',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GwType.ui(
                  fontSize: 16, fontWeight: FontWeight.w700, color: t.stone),
            ),
            const SizedBox(height: 2),
            Text(
              _lifeline(p),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GwType.ui(fontSize: 12.5, color: t.stoneMid),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                if (p.clan != null && p.clan!.isNotEmpty)
                  _monoBadge(context, p.clan!.toUpperCase(),
                      color: t.goldText, bg: t.goldBg),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Affluent IA — carte pointillée sage « AFFLUENT · 87% ».
  Widget _affluentCard(BuildContext context) {
    final t = GwTokens.of(context);
    return GestureDetector(
      onTap: onVerifySuggestion,
      child: CustomPaint(
        foregroundPainter: _DashedBorderPainter(
          color: GwTokens.sage.withValues(alpha: 0.5),
          radius: GwTokens.rCard,
          strokeWidth: 1.5,
        ),
        child: Container(
          width: 122,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: GwTokens.sage.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(GwTokens.rCard),
          ),
          child: Column(
            children: [
              Icon(Symbols.auto_awesome, size: 20, color: t.sageText),
              const SizedBox(height: 6),
              Text(
                'Kwame A.',
                style: GwType.ui(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: t.stone),
              ),
              const SizedBox(height: 2),
              Text(
                'AFFLUENT · 87%',
                style: GwType.mono(
                    fontSize: 10, color: t.sageText, letterSpacing: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Branche confirmée — carte pleine sage, fade-up 0,5 s.
  Widget _confirmedBranchCard(BuildContext context) {
    final t = GwTokens.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - v)),
          child: child,
        ),
      ),
      child: Container(
        width: 132,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: GwTokens.sage.withValues(alpha: 0.1),
          border: Border.all(color: GwTokens.sage, width: 1.5),
          borderRadius: BorderRadius.circular(GwTokens.rCard),
        ),
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF0D1F16),
                shape: BoxShape.circle,
                border: Border.all(color: GwTokens.sage, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                'K',
                style: GwType.display(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: t.sageText),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Kwame Asante',
              style: GwType.ui(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: t.stone),
            ),
            const SizedBox(height: 2),
            Text(
              'BRANCHE CONFIRMÉE',
              textAlign: TextAlign.center,
              style: GwType.mono(
                  fontSize: 10, color: t.sageText, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _monoBadge(BuildContext context, String text,
      {required Color color, required Color bg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GwType.mono(fontSize: 10, color: color, letterSpacing: 1),
      ),
    );
  }

  String _lifeline(PersonGenealogy p) {
    final birth = p.birthDate?.year;
    final place = p.birthPlace;
    final parts = <String>[];
    if (birth != null) {
      parts.add(p.gender == 'FEMALE' ? 'née en $birth' : 'né en $birth');
    }
    if (place != null && place.isNotEmpty) parts.add(place);
    return parts.isEmpty ? '—' : parts.join(' · ');
  }
}

class _Generation {
  _Generation({
    required this.members,
    this.isSubjectGen = false,
    this.founders = false,
  });

  final List<_Member> members;
  final bool isSubjectGen;
  final bool founders;
  int index = 1;
}

class _Member {
  const _Member(this.person, this.lineage);

  final PersonGenealogy person;
  final Color lineage;
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    this.strokeWidth = 1.5,
    this.dash = 5,
    this.gap = 4,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, Radius.circular(radius)));

    for (final ui.PathMetric metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color;
}
