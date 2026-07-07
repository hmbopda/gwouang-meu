import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gwangmeu/features/genealogy/models/ai_suggestion.dart';
import 'package:gwangmeu/features/genealogy/models/family_tree.dart';
import 'package:gwangmeu/features/genealogy/models/person_genealogy.dart';
import 'package:gwangmeu/features/genealogy/models/sibling_genealogy.dart';
import 'package:gwangmeu/features/genealogy/services/genealogy_api_service.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/genealogy/state/tree_view_state.dart';
import 'package:gwangmeu/features/genealogy/widgets/dialogs/add_person_dialog.dart';

/// Right panel with 3 tabs: Personne, Migration, IA.
class GenealogyRightPanel extends ConsumerWidget {
  final FamilyTree tree;
  final String personId;

  const GenealogyRightPanel({
    super.key,
    required this.tree,
    required this.personId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewState = ref.watch(treeViewProvider);
    final notifier = ref.read(treeViewProvider.notifier);

    return Container(
      width: 380.0,
      color: GwTokens.dark.inkCard,
      child: Column(
        children: [
          // ── Tabs ──
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: GwTokens.dark.line)),
            ),
            child: Row(
              children: [
                _Tab(
                  label: 'Personne',
                  icon: Icons.person,
                  selected: viewState.rightTab == RightTab.personne,
                  onTap: () => notifier.setRightTab(RightTab.personne),
                ),
                _Tab(
                  label: 'Migration',
                  icon: Icons.flight,
                  selected: viewState.rightTab == RightTab.migration,
                  onTap: () => notifier.setRightTab(RightTab.migration),
                ),
                _Tab(
                  label: 'IA',
                  icon: Icons.auto_awesome,
                  selected: viewState.rightTab == RightTab.ia,
                  onTap: () => notifier.setRightTab(RightTab.ia),
                  badge: tree.pendingSuggestions.isNotEmpty
                      ? '${tree.pendingSuggestions.length}'
                      : null,
                ),
              ],
            ),
          ),

          // ── Tab content ──
          Expanded(
            child: switch (viewState.rightTab) {
              RightTab.personne => _PersonTab(
                  tree: tree,
                  selectedId: viewState.selectedPersonId,
                  treeOwnerId: personId,
                ),
              RightTab.migration => const _MigrationTab(),
              RightTab.ia => _IaTab(
                  suggestions: tree.pendingSuggestions,
                  personId: personId,
                ),
            },
          ),
        ],
      ),
    );
  }
}

// ── Tab widget ──

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  const _Tab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? GwTokens.gold : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: selected ? GwTokens.gold : GwTokens.dark.stoneDim),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? GwTokens.gold : GwTokens.dark.stoneDim,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: GwTokens.sage,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Person detail tab ──

class _PersonTab extends StatelessWidget {
  final FamilyTree tree;
  final String? selectedId;
  final String treeOwnerId;

  const _PersonTab({
    required this.tree,
    required this.selectedId,
    required this.treeOwnerId,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedId == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app, size: 40, color: GwTokens.dark.stoneDim),
              SizedBox(height: 8),
              Text(
                'Sélectionnez un membre\npour voir ses détails',
                textAlign: TextAlign.center,
                style: TextStyle(color: GwTokens.dark.stoneDim, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    final person = _findPerson(selectedId!);
    if (person == null) {
      return Center(
        child: Text('Personne introuvable', style: TextStyle(color: GwTokens.dark.stoneDim)),
      );
    }

    return Column(
      children: [
        // ── Scrollable content ──
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _PersonHeader(
                  person: person, isSubject: person.id == tree.subject.id),
              const SizedBox(height: 16),
              _InfoCard(person: person),
              const SizedBox(height: 12),
              _RelationsCard(tree: tree, person: person),
            ],
          ),
        ),

        // ── Fixed bottom actions ──
        _FixedActions(
          person: person,
          treeOwnerId: treeOwnerId,
        ),
      ],
    );
  }

  PersonGenealogy? _findPerson(String id) {
    final all = [
      tree.subject,
      ...tree.father,
      ...tree.mother,
      ...tree.paternalGP,
      ...tree.maternalGP,
      ...tree.siblings.map((s) => s.person),
      ...tree.children,
      ...tree.uncles,
    ];
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

class _PersonHeader extends StatelessWidget {
  final PersonGenealogy person;
  final bool isSubject;

  const _PersonHeader({required this.person, required this.isSubject});

  @override
  Widget build(BuildContext context) {
    final initials =
        '${person.firstName.isNotEmpty ? person.firstName[0] : ''}${person.lastName.isNotEmpty ? person.lastName[0] : ''}'
            .toUpperCase();
    final avatarColor = person.gender == 'MALE' ? GwTokens.dark.inkLift : GwTokens.dark.inkLift;
    final borderColor = isSubject
        ? GwTokens.gold
        : (person.gender == 'MALE' ? GwTokens.gold : GwTokens.rose);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar with alive indicator
        Stack(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: avatarColor,
                border: Border.all(color: borderColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: person.photoUrl != null
                  ? ClipOval(
                      child:
                          Image.network(person.photoUrl!, fit: BoxFit.cover))
                  : Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
            // Status dot (alive indicator)
            if (person.isAlive)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: GwTokens.sage,
                    border: Border.all(color: GwTokens.dark.inkCard, width: 2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Name
        Text(
          '${person.firstName} ${person.lastName}',
          style: TextStyle(
            color: GwTokens.dark.stone,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (person.maidenName != null)
          Text(
            'née ${person.maidenName}',
            style: TextStyle(
              color: GwTokens.dark.stoneDim,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final PersonGenealogy person;
  const _InfoCard({required this.person});

  @override
  Widget build(BuildContext context) {
    final birthInfo = [
      if (person.birthDate != null)
        'né(e) ${person.birthDate!.year}',
      if (person.birthPlace != null) person.birthPlace!,
    ].join('  ·  ');

    // Tags row
    final tags = <Widget>[];
    if (person.clan != null) {
      tags.add(_tag(person.clan!, GwTokens.dark.stoneMid, GwTokens.dark.inkHigh));
    }
    tags.add(_tag(
      person.isAlive ? 'Vivant(e)' : 'Décédé(e)',
      person.isAlive ? GwTokens.sage : GwTokens.dark.stoneDim,
      person.isAlive
          ? GwTokens.sage.withValues(alpha: 0.12)
          : GwTokens.dark.stoneDim.withValues(alpha: 0.12),
      dotColor: person.isAlive ? GwTokens.sage : GwTokens.dark.stoneDim,
    ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Birth info subtitle
        if (birthInfo.isNotEmpty)
          Text(
            birthInfo,
            style: TextStyle(color: GwTokens.dark.stoneDim, fontSize: 12),
          ),
        const SizedBox(height: 8),

        // Tags
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: tags,
        ),
        const SizedBox(height: 16),

        // Detail rows with icons
        _iconRow(Icons.language, 'Langue', person.nativeLanguage),
        _iconRow(Icons.work_outline, 'Profession', person.profession),
        _iconRow(Icons.location_on, 'Résidence', person.birthPlace),
        _iconRow(Icons.phone_outlined, 'Téléphone', person.phone),
        _iconRow(Icons.favorite_border, 'Union(s)', null),
      ],
    );
  }

  Widget _tag(String label, Color textColor, Color bgColor, {Color? dotColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: GwTokens.dark.stoneDim),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(color: GwTokens.dark.stoneDim, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '—',
              style: TextStyle(
                color: value != null ? GwTokens.dark.stone : GwTokens.dark.stoneDim,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GrandParentEntry {
  final PersonGenealogy person;
  final String side; // 'paternel' or 'maternel'
  const _GrandParentEntry(this.person, this.side);
}

class _RelationsCard extends StatelessWidget {
  final FamilyTree tree;
  final PersonGenealogy person;

  const _RelationsCard({required this.tree, required this.person});

  @override
  Widget build(BuildContext context) {
    final parents = <PersonGenealogy>[];
    final grandParents = <_GrandParentEntry>[];
    final children = <PersonGenealogy>[];
    final siblings = <SiblingGenealogy>[];

    final uncles = <PersonGenealogy>[];

    if (person.id == tree.subject.id) {
      parents.addAll(tree.father);
      parents.addAll(tree.mother);
      for (final gp in tree.paternalGP) {
        grandParents.add(_GrandParentEntry(gp, 'paternel'));
      }
      for (final gp in tree.maternalGP) {
        grandParents.add(_GrandParentEntry(gp, 'maternel'));
      }
      children.addAll(tree.children);
      siblings.addAll(tree.siblings);
      uncles.addAll(tree.uncles);
    }

    if (parents.isEmpty && grandParents.isEmpty && children.isEmpty && siblings.isEmpty && uncles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Grands-Parents ──
        if (grandParents.isNotEmpty) ...[
          _grandParentBlock(grandParents),
          const SizedBox(height: 12),
        ],

        // ── Parents ──
        if (parents.isNotEmpty) ...[
          _sectionBlock(
            icon: Icons.people,
            label: 'PARENTS',
            persons: parents,
            roleBuilder: (p) => p.gender == 'MALE' ? 'Père' : 'Mère',
          ),
          const SizedBox(height: 12),
        ],

        // ── Enfants ──
        if (children.isNotEmpty) ...[
          _sectionBlock(
            icon: Icons.child_friendly,
            label: 'ENFANTS',
            persons: children,
            roleBuilder: (_) => 'Enfant',
          ),
          const SizedBox(height: 12),
        ],

        // ── Oncles/Tantes ──
        if (uncles.isNotEmpty) ...[
          _sectionBlock(
            icon: Icons.people_alt,
            label: 'ONCLES / TANTES',
            persons: uncles,
            roleBuilder: (p) => p.gender == 'MALE' ? 'Oncle' : 'Tante',
          ),
          const SizedBox(height: 12),
        ],

        // ── Frères/Sœurs ──
        if (siblings.isNotEmpty)
          _siblingBlock(siblings),
      ],
    );
  }

  Widget _grandParentBlock(List<_GrandParentEntry> entries) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GwTokens.dark.inkCard,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: GwTokens.dark.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.elderly, size: 12, color: GwTokens.dark.stoneDim),
              SizedBox(width: 6),
              Text('GRANDS-PARENTS', style: TextStyle(color: GwTokens.dark.stoneDim, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 8),
          ...entries.map((e) {
            final p = e.person;
            final side = e.side;
            final role = p.gender == 'MALE' ? 'Grand-père' : 'Grand-mère';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    p.gender == 'MALE' ? Icons.man : Icons.woman,
                    size: 14,
                    color: p.gender == 'MALE' ? GwTokens.gold : GwTokens.rose,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${p.firstName} ${p.lastName}',
                      style: TextStyle(color: GwTokens.dark.stone, fontSize: 11),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: GwTokens.dark.inkHigh,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('$role $side', style: TextStyle(color: GwTokens.dark.stoneMid, fontSize: 9)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _siblingBlock(List<SiblingGenealogy> siblings) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GwTokens.dark.inkCard,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: GwTokens.dark.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group, size: 12, color: GwTokens.dark.stoneDim),
              SizedBox(width: 6),
              Text('FRÈRES / SŒURS', style: TextStyle(color: GwTokens.dark.stoneDim, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 8),
          ...siblings.map((s) {
            final p = s.person;
            final role = _siblingLabel(p.gender, s.type);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    p.gender == 'MALE' ? Icons.man : Icons.woman,
                    size: 14,
                    color: p.gender == 'MALE' ? GwTokens.gold : GwTokens.rose,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${p.firstName} ${p.lastName}',
                      style: TextStyle(color: GwTokens.dark.stone, fontSize: 11),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: s.type == 'FULL' ? GwTokens.dark.inkHigh : GwTokens.dark.inkHigh,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(role, style: TextStyle(
                      color: s.type == 'FULL' ? GwTokens.dark.stoneMid : GwTokens.ember,
                      fontSize: 9,
                    )),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _siblingLabel(String gender, String type) {
    final base = gender == 'MALE' ? 'Frère' : 'Sœur';
    switch (type) {
      case 'HALF_PATERNAL':
        return 'Demi-$base (pat.)';
      case 'HALF_MATERNAL':
        return 'Demi-$base (mat.)';
      case 'STEP':
        return gender == 'MALE' ? 'Beau-frère' : 'Belle-sœur';
      default:
        return base;
    }
  }

  Widget _sectionBlock({
    required IconData icon,
    required String label,
    required List<PersonGenealogy> persons,
    required String Function(PersonGenealogy) roleBuilder,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GwTokens.dark.inkCard,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: GwTokens.dark.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: GwTokens.dark.stoneDim),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: GwTokens.dark.stoneDim, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 8),
          ...persons.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      p.gender == 'MALE' ? Icons.man : Icons.woman,
                      size: 14,
                      color: p.gender == 'MALE' ? GwTokens.gold : GwTokens.rose,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${p.firstName} ${p.lastName}',
                        style: TextStyle(color: GwTokens.dark.stone, fontSize: 11),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: GwTokens.dark.inkHigh,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(roleBuilder(p), style: TextStyle(color: GwTokens.dark.stoneMid, fontSize: 9)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

/// Opens a dialog. The mouse_tracker assertion is suppressed globally in main.dart.
void _safeDialog(BuildContext context, Widget dialog) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => dialog,
  );
}

void _showEditDialog(BuildContext context, PersonGenealogy person, String treeOwnerId) {
  _safeDialog(context, _InlineEditDialog(person: person, treeOwnerId: treeOwnerId));
}

/// Fixed action buttons at the bottom of the person tab.
class _FixedActions extends StatelessWidget {
  final PersonGenealogy person;
  final String treeOwnerId;

  const _FixedActions({
    required this.person,
    required this.treeOwnerId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: GwTokens.dark.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Modifier la fiche ──
          _FixedActionBtn(
            icon: Icons.edit_note,
            label: 'Modifier la fiche',
            backgroundColor: GwTokens.gold,
            foregroundColor: GwTokens.dark.ink,
            onTap: () => _showEditDialog(context, person, treeOwnerId),
          ),
          const SizedBox(height: 8),

          // ── Voir carte de migration ──
          _FixedActionBtn(
            icon: Icons.flight_takeoff,
            label: 'Voir carte de migration',
            backgroundColor: const Color(0xFF3D1C1C),
            foregroundColor: const Color(0xFFE57373),
            borderColor: const Color(0xFF6D2B2B),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Carte de migration bientôt disponible'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // ── Ajouter un enfant ──
          _FixedActionBtn(
            icon: Icons.add,
            label: 'Ajouter un enfant',
            backgroundColor: GwTokens.dark.inkCard,
            foregroundColor: GwTokens.dark.stoneMid,
            borderColor: GwTokens.dark.goldLine,
            onTap: () => _safeDialog(
              context,
              AddPersonDialog(personId: person.id, isParent: false),
            ),
          ),
        ],
      ),
    );
  }
}

class _FixedActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final VoidCallback onTap;

  const _FixedActionBtn({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: borderColor != null
                ? BorderSide(color: borderColor!)
                : BorderSide.none,
          ),
          alignment: Alignment.centerLeft,
          elevation: 0,
        ),
      ),
    );
  }
}

// ── Migration tab ──

class _MigrationTab extends StatelessWidget {
  const _MigrationTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flight_takeoff, size: 40, color: GwTokens.dark.stoneDim),
            SizedBox(height: 8),
            Text(
              'Parcours migratoire',
              style: TextStyle(color: GwTokens.dark.stone, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4),
            Text(
              'Fonctionnalité en cours de développement.\nVous pourrez bientôt visualiser les parcours migratoires de chaque membre.',
              textAlign: TextAlign.center,
              style: TextStyle(color: GwTokens.dark.stoneDim, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ── IA tab ──

class _IaTab extends ConsumerWidget {
  final List<AiSuggestion> suggestions;
  final String personId;

  const _IaTab({required this.suggestions, required this.personId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (suggestions.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 40, color: GwTokens.dark.stoneDim),
              SizedBox(height: 8),
              Text(
                'Aucune suggestion',
                style: TextStyle(color: GwTokens.dark.stone, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4),
              Text(
                'L\'IA analysera votre arbre et proposera des liens potentiels.',
                textAlign: TextAlign.center,
                style: TextStyle(color: GwTokens.dark.stoneDim, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: suggestions.length,
      itemBuilder: (_, i) => _AiSuggestionCard(
        suggestion: suggestions[i],
        onAccept: () => _review(ref, suggestions[i].id, true),
        onReject: () => _review(ref, suggestions[i].id, false),
      ),
    );
  }

  void _review(WidgetRef ref, String id, bool accepted) async {
    try {
      await ref.read(genealogyApiServiceProvider).reviewSuggestion(id, accepted);
      ref.invalidate(familyTreeProvider(personId));
    } catch (_) {}
  }
}

class _AiSuggestionCard extends StatelessWidget {
  final AiSuggestion suggestion;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _AiSuggestionCard({
    required this.suggestion,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (suggestion.confidence * 100).toStringAsFixed(0);
    final color = suggestion.confidence >= 0.75
        ? GwTokens.sage
        : suggestion.confidence >= 0.5
            ? GwTokens.ember
            : GwTokens.ember;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GwTokens.dark.inkCard,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: GwTokens.sage.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Relation
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 14, color: GwTokens.sage),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${suggestion.personA?.firstName ?? "?"} ↔ ${suggestion.personB?.firstName ?? "?"}',
                  style: TextStyle(color: GwTokens.dark.stone, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '$pct%',
                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            suggestion.suggestedRelation,
            style: TextStyle(color: GwTokens.dark.stoneMid, fontSize: 11),
          ),

          // Confidence bar
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: suggestion.confidence,
              backgroundColor: GwTokens.dark.inkHigh,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 4,
            ),
          ),

          // Reasons
          if (suggestion.reasons.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...suggestion.reasons.map((r) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(color: GwTokens.dark.stoneDim, fontSize: 10)),
                      Expanded(
                        child: Text(r, style: TextStyle(color: GwTokens.dark.stoneMid, fontSize: 10)),
                      ),
                    ],
                  ),
                )),
          ],

          // Actions
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onReject,
                icon: const Icon(Icons.close, size: 14),
                label: const Text('Rejeter'),
                style: TextButton.styleFrom(
                  foregroundColor: GwTokens.ember,
                  textStyle: const TextStyle(fontSize: 11),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                onPressed: onAccept,
                icon: const Icon(Icons.check, size: 14),
                label: const Text('Confirmer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GwTokens.sage,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 11),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Inline Edit Dialog (bypasses separate file) ──

class _InlineEditDialog extends ConsumerStatefulWidget {
  final PersonGenealogy person;
  final String treeOwnerId;

  const _InlineEditDialog({required this.person, required this.treeOwnerId});

  @override
  ConsumerState<_InlineEditDialog> createState() => _InlineEditDialogState();
}

class _InlineEditDialogState extends ConsumerState<_InlineEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _birthPlaceCtrl;
  late final TextEditingController _dateCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _professionCtrl;
  late String _status;
  late String _privacy;
  DateTime? _birthDate;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.person;
    _firstNameCtrl = TextEditingController(text: p.firstName);
    _lastNameCtrl = TextEditingController(text: p.lastName);
    _birthPlaceCtrl = TextEditingController(text: p.birthPlace ?? '');
    _phoneCtrl = TextEditingController(text: p.phone ?? '');
    _professionCtrl = TextEditingController(text: p.profession ?? '');
    _birthDate = p.birthDate;
    _dateCtrl = TextEditingController(
      text: p.birthDate != null ? '${p.birthDate!.day.toString().padLeft(2, '0')}/${p.birthDate!.month.toString().padLeft(2, '0')}/${p.birthDate!.year}' : '',
    );
    _status = p.isAlive ? 'ALIVE' : 'DECEASED';
    const knownPrivacy = ['FAMILY_ONLY', 'MEMBERS_ONLY', 'PUBLIC'];
    _privacy = knownPrivacy.contains(p.privacy) ? p.privacy : 'FAMILY_ONLY';
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _birthPlaceCtrl.dispose();
    _dateCtrl.dispose();
    _phoneCtrl.dispose();
    _professionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.edit_note, size: 22),
          SizedBox(width: 8),
          Text('Modifier la fiche', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _firstNameCtrl,
                  decoration: const InputDecoration(labelText: 'Prénom *', prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastNameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom *', prefixIcon: Icon(Icons.badge_outlined)),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _dateCtrl,
                      decoration: const InputDecoration(labelText: 'Date de naissance', prefixIcon: Icon(Icons.calendar_today_outlined), hintText: 'JJ/MM/AAAA'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Status — plain DropdownButton (no FormField) to avoid deprecated value issue
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Statut', prefixIcon: Icon(Icons.favorite_outline)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _status,
                      isDense: true,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'ALIVE', child: Text('Vivant(e)')),
                        DropdownMenuItem(value: 'DECEASED', child: Text('Décédé(e)')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _status = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _birthPlaceCtrl,
                  decoration: const InputDecoration(labelText: 'Lieu de résidence', prefixIcon: Icon(Icons.location_on_outlined)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _professionCtrl,
                  decoration: const InputDecoration(labelText: 'Profession', prefixIcon: Icon(Icons.work_outline)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Téléphone', prefixIcon: Icon(Icons.phone_outlined)),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                // Privacy — plain DropdownButton
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Visibilité', prefixIcon: Icon(Icons.visibility_outlined)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _privacy,
                      isDense: true,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'FAMILY_ONLY', child: Text('Famille uniquement')),
                        DropdownMenuItem(value: 'MEMBERS_ONLY', child: Text('Membres du village')),
                        DropdownMenuItem(value: 'PUBLIC', child: Text('Public')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _privacy = v);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: GwTokens.gold, foregroundColor: GwTokens.dark.ink),
          child: _loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Enregistrer'),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(1985),
      firstDate: DateTime(1800),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _dateCtrl.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final api = ref.read(genealogyApiServiceProvider);
      final data = <String, dynamic>{
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'isAlive': _status == 'ALIVE',
        'privacy': _privacy,
      };
      if (_birthDate != null) {
        data['birthDate'] = _birthDate!.toIso8601String().split('T').first;
      }
      if (_birthPlaceCtrl.text.trim().isNotEmpty) {
        data['birthPlace'] = _birthPlaceCtrl.text.trim();
      }
      if (_professionCtrl.text.trim().isNotEmpty) {
        data['profession'] = _professionCtrl.text.trim();
      }
      if (_phoneCtrl.text.trim().isNotEmpty) {
        data['phone'] = _phoneCtrl.text.trim();
      }

      await api.updatePerson(widget.person.id, data);
      ref.invalidate(familyTreeProvider(widget.treeOwnerId));

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fiche mise à jour')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
