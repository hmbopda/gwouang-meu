import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gwangmeu/features/genealogy/models/family_tree.dart';
import 'package:gwangmeu/features/genealogy/models/person_genealogy.dart';
import 'package:gwangmeu/features/genealogy/state/tree_tokens.dart';
import 'package:gwangmeu/features/genealogy/state/tree_view_state.dart';

/// Left sidebar: Stats grid, Legend, Generation filters, Clan members list.
class GenealogyLeftPanel extends ConsumerWidget {
  final FamilyTree tree;

  const GenealogyLeftPanel({super.key, required this.tree});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewState = ref.watch(treeViewProvider);
    final notifier = ref.read(treeViewProvider.notifier);
    final allMembers = _allMembers(tree);

    return Container(
      width: T.leftPanelW,
      color: T.ink2,
      child: Column(
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: T.border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: T.goldBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.account_tree, size: 16, color: T.gold),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Arbre Généalogique',
                    style: TextStyle(
                      color: T.txt1,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // ── Stats grid ──
                const _SectionTitle(title: 'Statistiques'),
                const SizedBox(height: 8),
                _StatsGrid(tree: tree),
                const SizedBox(height: 16),

                // ── Legend ──
                const _SectionTitle(title: 'Légende'),
                const SizedBox(height: 8),
                _LegendSection(),
                const SizedBox(height: 16),

                // ── Generation filters ──
                const _SectionTitle(title: 'Générations'),
                const SizedBox(height: 8),
                _GenerationFilters(
                  hiddenGenerations: viewState.hiddenGenerations,
                  onToggle: notifier.toggleGeneration,
                ),
                const SizedBox(height: 16),

                // ── Members list ──
                _SectionTitle(title: 'Membres (${allMembers.length})'),
                const SizedBox(height: 8),
                ...allMembers.map((p) => _MemberTile(
                      person: p,
                      isSelected: viewState.selectedPersonId == p.id,
                      isSubject: p.id == tree.subject.id,
                      onTap: () => notifier.selectPerson(p.id),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PersonGenealogy> _allMembers(FamilyTree tree) {
    final seen = <String>{};
    final list = <PersonGenealogy>[];
    void add(PersonGenealogy p) {
      if (seen.add(p.id)) list.add(p);
    }

    add(tree.subject);
    for (final p in tree.father) {
      add(p);
    }
    for (final p in tree.mother) {
      add(p);
    }
    for (final p in tree.paternalGP) {
      add(p);
    }
    for (final p in tree.maternalGP) {
      add(p);
    }
    for (final s in tree.siblings) {
      add(s.person);
    }
    for (final p in tree.children) {
      add(p);
    }
    return list;
  }
}

// ── Section title ──

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: T.txt3,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ── Stats grid ──

class _StatsGrid extends StatelessWidget {
  final FamilyTree tree;
  const _StatsGrid({required this.tree});

  @override
  Widget build(BuildContext context) {
    final total = _countUnique(tree);
    final living = _countLiving(tree);
    final generations = _countGenerations(tree);
    final unions = tree.unions.length;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _StatCard(value: '$total', label: 'Membres', icon: Icons.people, color: T.blue),
        _StatCard(value: '$living', label: 'Vivants', icon: Icons.favorite, color: T.green),
        _StatCard(value: '$generations', label: 'Générations', icon: Icons.layers, color: T.gold),
        _StatCard(value: '$unions', label: 'Unions', icon: Icons.favorite_border, color: T.orange),
      ],
    );
  }

  int _countUnique(FamilyTree tree) {
    final ids = <String>{};
    ids.add(tree.subject.id);
    for (final p in [...tree.father, ...tree.mother, ...tree.paternalGP, ...tree.maternalGP, ...tree.siblings.map((s) => s.person), ...tree.children]) {
      ids.add(p.id);
    }
    return ids.length;
  }

  int _countLiving(FamilyTree tree) {
    final all = [tree.subject, ...tree.father, ...tree.mother, ...tree.paternalGP, ...tree.maternalGP, ...tree.siblings.map((s) => s.person), ...tree.children];
    return all.where((p) => p.isAlive).length;
  }

  int _countGenerations(FamilyTree tree) {
    int g = 1;
    if (tree.father.isNotEmpty || tree.mother.isNotEmpty) g++;
    if (tree.paternalGP.isNotEmpty || tree.maternalGP.isNotEmpty) g++;
    if (tree.children.isNotEmpty) g++;
    return g;
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(T.rSm),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(color: T.txt3, fontSize: 9),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Legend ──

class _LegendSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _legendRow(T.gold, 'Sujet principal'),
        _legendRow(T.maleBorder, 'Homme'),
        _legendRow(T.femaleBorder, 'Femme'),
        _legendRow(T.deadBorder, 'Décédé(e)'),
        _legendRow(T.aiBorder, 'Suggestion IA'),
        _legendRow(T.wifeBorder, 'Épouse'),
        const SizedBox(height: 6),
        _linkLegend(T.txt3, 'Filiation', false),
        _linkLegend(T.orange, 'Union', true),
        _linkLegend(T.green, 'Suggestion IA', true),
      ],
    );
  }

  Widget _legendRow(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: T.txt2, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _linkLegend(Color color, String label, bool dashed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 10,
            child: CustomPaint(painter: _LinePainter(color, dashed)),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: T.txt2, fontSize: 11)),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final Color color;
  final bool dashed;
  _LinePainter(this.color, this.dashed);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    if (dashed) {
      double x = 0;
      while (x < size.width) {
        canvas.drawLine(
          Offset(x, size.height / 2),
          Offset((x + 4).clamp(0, size.width), size.height / 2),
          paint,
        );
        x += 7;
      }
    } else {
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Generation filters ──

class _GenerationFilters extends StatelessWidget {
  final Set<int> hiddenGenerations;
  final ValueChanged<int> onToggle;

  const _GenerationFilters({
    required this.hiddenGenerations,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final gens = [
      (0, 'Grands-parents', T.genColors[1]),
      (1, 'Parents', T.genColors[2]),
      (2, 'Sujet / Fratrie', T.genColors[3]),
      (3, 'Enfants', T.genColors[5]),
    ];

    return Column(
      children: gens.map((g) {
        final hidden = hiddenGenerations.contains(g.$1);
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: InkWell(
            onTap: () => onToggle(g.$1),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: hidden ? Colors.transparent : g.$3.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: hidden ? T.border : g.$3.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hidden ? T.txt3 : g.$3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      g.$2,
                      style: TextStyle(
                        color: hidden ? T.txt3 : T.txt1,
                        fontSize: 11,
                        decoration: hidden ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  Icon(
                    hidden ? Icons.visibility_off : Icons.visibility,
                    size: 14,
                    color: hidden ? T.txt3 : g.$3,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Member tile ──

class _MemberTile extends StatelessWidget {
  final PersonGenealogy person;
  final bool isSelected;
  final bool isSubject;
  final VoidCallback onTap;

  const _MemberTile({
    required this.person,
    required this.isSelected,
    required this.isSubject,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials =
        '${person.firstName.isNotEmpty ? person.firstName[0] : ''}${person.lastName.isNotEmpty ? person.lastName[0] : ''}'
            .toUpperCase();
    final avatarColor = person.gender == 'MALE' ? T.maleNode : T.femaleNode;
    final borderColor = person.gender == 'MALE' ? T.maleBorder : T.femaleBorder;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(T.rSm),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? T.goldBg : Colors.transparent,
              borderRadius: BorderRadius.circular(T.rSm),
              border: isSelected ? Border.all(color: T.gold.withValues(alpha: 0.3)) : null,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: avatarColor,
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: borderColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${person.firstName} ${person.lastName}',
                        style: TextStyle(
                          color: isSelected ? T.gold : T.txt1,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isSubject)
                        const Text(
                          'Sujet',
                          style: TextStyle(color: T.gold, fontSize: 9),
                        ),
                    ],
                  ),
                ),
                if (!person.isAlive)
                  const Icon(Icons.brightness_3, size: 12, color: T.txt3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
