import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/router/breadcrumb_provider.dart';
import 'package:gwangmeu/core/router/route_names.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/genealogy/genealogy_notifier.dart';
import 'package:gwangmeu/features/genealogy/models/ai_suggestion.dart';
import 'package:gwangmeu/features/genealogy/models/family_tree.dart';
import 'package:gwangmeu/features/genealogy/models/person_genealogy.dart';
import 'package:gwangmeu/features/genealogy/services/genealogy_api_service.dart';

/// Rail droit du Fil (desktop) : « Votre arbre » (stats réelles dérivées de
/// l'arbre), « À relier » (suggestions IA réelles) et « Cette semaine »
/// (anniversaires dérivés des dates de naissance). Aucune donnée inventée :
/// états vides soignés quand il n'y a rien.
class FamilyRail extends ConsumerWidget {
  const FamilyRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final me = ref.watch(genealogyNotifierProvider).valueOrNull;
    final FamilyTree? tree =
        me == null ? null : ref.watch(familyTreeProvider(me.id)).valueOrNull;

    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 20, 24, 20),
      children: [
        _arbreCard(context, ref, t, tree),
        const SizedBox(height: 14),
        _relierCard(context, t, me, tree),
        const SizedBox(height: 14),
        _semaineCard(t, tree),
      ],
    );
  }

  // ── Votre arbre ──────────────────────────────────────────────
  Widget _arbreCard(
      BuildContext context, WidgetRef ref, GwTokens t, FamilyTree? tree) {
    final persons = tree == null ? const <PersonGenealogy>[] : _allPersons(tree);
    final members = persons.length;
    final clans =
        persons.map((p) => p.clan).whereType<String>().where((c) => c.isNotEmpty).toSet().length;
    final generations = tree == null ? 0 : _generations(tree);

    return _card(
      t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('VOTRE ARBRE',
                    style: GwType.mono(
                        fontSize: 10, letterSpacing: 1.5, color: t.stoneFaint)),
              ),
              InkWell(
                onTap: () {
                  ref.read(breadcrumbProvider.notifier).clear();
                  context.go(Routes.genealogy);
                },
                child: Text('Ouvrir →',
                    style: GwType.ui(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: t.goldText)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 74,
            decoration: BoxDecoration(
              color: GwTokens.gold.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(GwTokens.rBtn),
            ),
            alignment: Alignment.center,
            child: Icon(Symbols.account_tree,
                size: 34, color: GwTokens.gold.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _stat(t, '$members', members > 1 ? 'membres' : 'membre'),
              _stat(t, '$generations',
                  generations > 1 ? 'générations' : 'génération'),
              _stat(t, '$clans', clans > 1 ? 'clans' : 'clan'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(GwTokens t, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: GwType.display(
                  fontSize: 22, fontWeight: FontWeight.w700, color: t.stone)),
          const SizedBox(height: 2),
          Text(label,
              style: GwType.mono(fontSize: 10, color: t.stoneFaint)),
        ],
      ),
    );
  }

  // ── À relier (IA) ────────────────────────────────────────────
  Widget _relierCard(
      BuildContext context, GwTokens t, PersonGenealogy? me, FamilyTree? tree) {
    final suggestions = tree?.pendingSuggestions ?? const <AiSuggestion>[];
    return _card(
      t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('À RELIER',
              style: GwType.mono(
                  fontSize: 10, letterSpacing: 1.5, color: t.sageText)),
          const SizedBox(height: 8),
          Text(
            suggestions.isEmpty
                ? "L'IA n'a pas encore repéré de lien probable avec votre lignée."
                : 'L\'IA a repéré des liens probables avec votre lignée.',
            style: GwType.ui(fontSize: 12.5, color: t.stoneMid, height: 1.5),
          ),
          if (suggestions.isNotEmpty) const SizedBox(height: 12),
          for (final s in suggestions.take(3))
            _suggestionRow(context, t, me, s),
        ],
      ),
    );
  }

  Widget _suggestionRow(
      BuildContext context, GwTokens t, PersonGenealogy? me, AiSuggestion s) {
    final other = _otherPerson(me, s);
    final name = other == null
        ? 'Personne'
        : '${other.firstName} ${other.lastName}'.trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final pct = (s.confidence * 100).round();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: GwTokens.sage.withValues(alpha: 0.16),
            child: Text(initial,
                style: GwType.display(fontSize: 13, color: t.sageText)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GwType.ui(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: t.stone)),
                Text('${_relationFr(s.suggestedRelation)} · $pct %',
                    style: GwType.mono(fontSize: 10.5, color: t.stoneFaint)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _pill(t, 'Voir', () => context.push(Routes.verify(s.id))),
        ],
      ),
    );
  }

  // ── Cette semaine (anniversaires) ────────────────────────────
  Widget _semaineCard(GwTokens t, FamilyTree? tree) {
    final events = tree == null ? <_Birthday>[] : _birthdaysThisWeek(tree);
    return _card(
      t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CETTE SEMAINE',
              style: GwType.mono(
                  fontSize: 10, letterSpacing: 1.5, color: t.emberText)),
          const SizedBox(height: 10),
          if (events.isEmpty)
            Text('Aucun anniversaire cette semaine.',
                style: GwType.ui(fontSize: 12.5, color: t.stoneMid))
          else
            for (final e in events) _birthdayRow(t, e),
        ],
      ),
    );
  }

  Widget _birthdayRow(GwTokens t, _Birthday e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: GwTokens.ember.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Symbols.cake, size: 16, color: t.emberText),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Anniversaire de ${e.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GwType.ui(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: t.stone)),
                Text(
                    '${e.whenLabel}${e.age != null ? ' · ${e.age} ans' : ''}',
                    style: GwType.mono(fontSize: 10.5, color: t.stoneFaint)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────
  Widget _card(GwTokens t, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: t.inkCard,
        borderRadius: BorderRadius.circular(GwTokens.rCard),
        border: Border.all(color: t.line),
      ),
      child: child,
    );
  }

  Widget _pill(GwTokens t, String label, VoidCallback onTap) {
    return Material(
      color: GwTokens.sage.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(GwTokens.rPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GwTokens.rPill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(label,
              style: GwType.ui(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: t.sageText)),
        ),
      ),
    );
  }

  List<PersonGenealogy> _allPersons(FamilyTree tree) {
    final list = <PersonGenealogy>[
      tree.subject,
      ...tree.father,
      ...tree.mother,
      ...tree.paternalGP,
      ...tree.maternalGP,
      ...tree.children,
      ...tree.uncles,
      ...tree.cousins,
      ...tree.siblings.map((s) => s.person),
    ];
    final seen = <String>{};
    return list.where((p) => seen.add(p.id)).toList();
  }

  int _generations(FamilyTree tree) {
    var g = 1; // le sujet
    if (tree.paternalGP.isNotEmpty || tree.maternalGP.isNotEmpty) g++;
    if (tree.father.isNotEmpty || tree.mother.isNotEmpty || tree.uncles.isNotEmpty) g++;
    if (tree.children.isNotEmpty) g++;
    return g;
  }

  PersonGenealogy? _otherPerson(PersonGenealogy? me, AiSuggestion s) {
    if (me == null) return s.personB ?? s.personA;
    if (s.personA?.id == me.id) return s.personB;
    if (s.personB?.id == me.id) return s.personA;
    return s.personB ?? s.personA;
  }

  String _relationFr(String rel) {
    switch (rel.toUpperCase()) {
      case 'COUSIN':
        return 'Cousin·e probable';
      case 'UNCLE':
      case 'AUNT':
        return 'Oncle / tante probable';
      case 'SIBLING':
        return 'Frère / sœur probable';
      case 'PARENT':
        return 'Parent probable';
      case 'CHILD':
        return 'Enfant probable';
      case 'GRANDPARENT':
        return 'Grand-parent probable';
      default:
        return 'Lien probable';
    }
  }

  List<_Birthday> _birthdaysThisWeek(FamilyTree tree) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final out = <_Birthday>[];
    for (final p in _allPersons(tree)) {
      final b = p.birthDate;
      if (b == null || !p.isAlive) continue;
      var next = DateTime(now.year, b.month, b.day);
      if (next.isBefore(today)) next = DateTime(now.year + 1, b.month, b.day);
      final diff = next.difference(today).inDays;
      if (diff < 0 || diff > 7) continue;
      final name = '${p.firstName} ${p.lastName}'.trim();
      out.add(_Birthday(
        name: name.isEmpty ? 'Un proche' : name,
        whenLabel: diff == 0 ? "Aujourd'hui" : (diff == 1 ? 'Demain' : _dayFr(next)),
        age: next.year - b.year,
        inDays: diff,
      ));
    }
    out.sort((a, b) => a.inDays.compareTo(b.inDays));
    return out;
  }

  String _dayFr(DateTime d) {
    const days = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];
    return days[(d.weekday - 1) % 7];
  }
}

class _Birthday {
  const _Birthday({
    required this.name,
    required this.whenLabel,
    required this.inDays,
    this.age,
  });
  final String name;
  final String whenLabel;
  final int inDays;
  final int? age;
}
