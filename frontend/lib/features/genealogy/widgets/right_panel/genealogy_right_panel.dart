import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/features/genealogy/models/ai_suggestion.dart';
import 'package:gwangmeu/features/genealogy/models/family_tree.dart';
import 'package:gwangmeu/features/genealogy/models/genealogy_union.dart';
import 'package:gwangmeu/features/genealogy/models/person_genealogy.dart';
import 'package:gwangmeu/features/genealogy/services/genealogy_api_service.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/genealogy/state/migration_journey.dart';
import 'package:gwangmeu/features/genealogy/state/tree_view_state.dart';
import 'package:gwangmeu/features/genealogy/widgets/dialogs/add_person_dialog.dart';
import 'package:gwangmeu/features/genealogy/widgets/dialogs/add_union_dialog.dart';

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
    final t = GwTokens.of(context);
    // select() : rebuild uniquement si l'onglet ou la sélection changent
    // (le hover de l'arbre ne rebuild plus ce panneau).
    final (rightTab, selectedPersonId) = ref.watch(
      treeViewProvider.select((s) => (s.rightTab, s.selectedPersonId)),
    );
    final notifier = ref.read(treeViewProvider.notifier);

    return Container(
      width: 380.0,
      color: t.inkCard,
      child: Column(
        children: [
          // ── Onglets ──
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: t.line)),
            ),
            child: Row(
              children: [
                _Tab(
                  label: 'PERSONNE',
                  selected: rightTab == RightTab.personne,
                  onTap: () => notifier.setRightTab(RightTab.personne),
                ),
                _Tab(
                  label: 'MIGRATION',
                  selected: rightTab == RightTab.migration,
                  onTap: () => notifier.setRightTab(RightTab.migration),
                ),
                _Tab(
                  label: '✦ IA',
                  selected: rightTab == RightTab.ia,
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
            child: switch (rightTab) {
              RightTab.personne => _PersonTab(
                  tree: tree,
                  selectedId: selectedPersonId,
                  treeOwnerId: personId,
                ),
              RightTab.migration => _MigrationTab(
                  tree: tree,
                  selectedId: selectedPersonId,
                  treeOwnerId: personId,
                ),
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
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final fg = selected ? GwTokens.gold : t.stoneDim;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
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
              Text(
                label,
                style: GwType.mono(
                  fontSize: 10.5,
                  letterSpacing: 1.5,
                  color: fg,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: GwTokens.sage,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge!,
                    style: GwType.mono(
                      fontSize: 9,
                      letterSpacing: 0,
                      color: const Color(0xFFF0EBE1),
                      fontWeight: FontWeight.w700,
                    ),
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
    final t = GwTokens.of(context);
    // Aucun clic → on affiche le SUJET par défaut (plus d'écran vide) :
    // la fiche de vie et la gestion du foyer sont visibles immédiatement.
    final person = _findPerson(selectedId ?? tree.subject.id) ?? tree.subject;
    if (selectedId != null && _findPerson(selectedId!) == null) {
      return Center(
        child: Text('Personne introuvable', style: TextStyle(color: t.stoneDim)),
      );
    }

    // Unions rattachées à cette personne (mari OU épouse).
    final personUnions = tree.unions
        .where((u) => u.husbandId == person.id || u.wifeId == person.id)
        .toList();
    // Chef de foyer polygame : >= 2 unions comme mari (maquette 2b).
    final chiefUnions =
        personUnions.where((u) => u.husbandId == person.id).toList();
    final isChief = person.gender == 'MALE' && chiefUnions.length >= 2;

    return Column(
      children: [
        // ── Contenu défilant ──
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            children: [
              _PersonHeader(
                person: person,
                isSubject: person.id == tree.subject.id,
              ),
              // ── Gestion du foyer (maquette 2b) : EN TÊTE pour le chef ──
              if (isChief) ...[
                const SizedBox(height: 20),
                _FoyerManagement(
                  person: person,
                  unions: chiefUnions,
                  tree: tree,
                  treeOwnerId: treeOwnerId,
                ),
              ],
              const SizedBox(height: 20),
              _LifeFiche(
                person: person,
                unions: personUnions,
              ),
              const SizedBox(height: 16),
              _MiniCardsRow(
                person: person,
                tree: tree,
                unions: personUnions,
              ),
            ],
          ),
        ),

        // ── Actions fixes en bas ──
        _FixedActions(
          person: person,
          treeOwnerId: treeOwnerId,
        ),
      ],
    );
  }

  PersonGenealogy? _findPerson(String id) {
    final all = <PersonGenealogy>[
      tree.subject,
      ...tree.father,
      ...tree.mother,
      ...tree.paternalGP,
      ...tree.maternalGP,
      ...tree.siblings.map((s) => s.person),
      ...tree.children,
      ...tree.uncles,
      // Conjoint·es embarqué·es dans les unions (co-épouses des ascendants) :
      // sinon un clic sur une co-épouse affiche « Personne introuvable ».
      for (final u in tree.unions) ...[
        if (u.husband != null) u.husband!,
        if (u.wife != null) u.wife!,
      ],
    ];
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// En-tête « fiche de vie » : gros badge à initiales centré (anneau or,
/// point vert « vivant·e »), nom en serif, pilule mono clan + statut.
class _PersonHeader extends StatelessWidget {
  final PersonGenealogy person;
  final bool isSubject;

  const _PersonHeader({required this.person, required this.isSubject});

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final initials =
        '${person.firstName.isNotEmpty ? person.firstName[0] : ''}${person.lastName.isNotEmpty ? person.lastName[0] : ''}'
            .toUpperCase();
    // Rose pour une lignée alliée (femme non-sujette), or sinon.
    final ringColor = isSubject
        ? GwTokens.gold
        : (person.gender == 'FEMALE' ? GwTokens.rose : GwTokens.gold);

    return Column(
      children: [
        // ── Badge circulaire à initiales (compact) ──
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: t.inkLift,
                border: Border.all(color: ringColor, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: ringColor.withValues(alpha: 0.22),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: person.photoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        person.photoUrl!,
                        width: 67,
                        height: 67,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Text(
                      initials,
                      style: GwType.display(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        color: t.stone,
                      ),
                    ),
            ),
            // Point vert « vivant·e » en bas-droite.
            if (person.isAlive)
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: GwTokens.sage,
                    border: Border.all(color: t.inkCard, width: 2.5),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Nom en serif centré ──
        Text(
          '${person.firstName} ${person.lastName}',
          textAlign: TextAlign.center,
          style: GwType.display(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: t.stone,
          ),
        ),
        if (person.maidenName != null && person.maidenName!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            'née ${person.maidenName}',
            textAlign: TextAlign.center,
            style: GwType.quote(fontSize: 13, color: t.stoneDim),
          ),
        ],
        const SizedBox(height: 10),

        // ── Pilules mono : clan + statut vivant/décédé ──
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            if (person.clan != null && person.clan!.isNotEmpty)
              _MonoPill(label: person.clan!.toUpperCase(), color: t.goldText),
            _MonoPill(
              label: person.isAlive
                  ? (person.gender == 'FEMALE' ? 'VIVANTE' : 'VIVANT')
                  : (person.gender == 'FEMALE' ? 'DÉCÉDÉE' : 'DÉCÉDÉ'),
              color: person.isAlive ? t.sageText : t.stoneDim,
              dotColor: person.isAlive ? GwTokens.sage : t.stoneDim,
            ),
          ],
        ),
      ],
    );
  }
}

/// Pilule mono (petites capitales) avec point optionnel — clan, statut…
class _MonoPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color? dotColor;

  const _MonoPill({required this.label, required this.color, this.dotColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(GwTokens.rPill),
        border: Border.all(color: color.withValues(alpha: 0.30)),
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
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: GwType.mono(
              fontSize: 10,
              letterSpacing: 1.5,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Un évènement de vie : puce ronde colorée + titre gras + sous-ligne grise.
class _LifeEvent {
  final Color dotColor;
  final String title;
  final String subtitle;
  const _LifeEvent({
    required this.dotColor,
    required this.title,
    required this.subtitle,
  });
}

/// Bloc « FICHE DE VIE » : construit la timeline à partir des vraies données
/// (naissance, unions, résidence). N'affiche que les évènements disponibles.
class _LifeFiche extends StatelessWidget {
  final PersonGenealogy person;
  final List<GenealogyUnion> unions;

  const _LifeFiche({required this.person, required this.unions});

  List<_LifeEvent> _buildEvents() {
    final events = <_LifeEvent>[];

    // ── Naissance ──
    if (person.birthDate != null || person.birthPlace != null) {
      final year = person.birthDate?.year;
      events.add(_LifeEvent(
        dotColor: GwTokens.gold,
        title: year != null ? 'Naissance — $year' : 'Naissance',
        subtitle: person.birthPlace ?? '—',
      ));
    }

    // ── Union(s) ──
    for (final u in unions) {
      final partner = u.husbandId == person.id ? u.wife : u.husband;
      final partnerName = partner != null
          ? '${partner.firstName} ${partner.lastName}'.trim()
          : null;
      final year = u.startDate?.year;
      final title = year != null ? 'Union — $year' : 'Union';
      final parts = <String>[];
      if (partnerName != null && partnerName.isNotEmpty) {
        parts.add('avec $partnerName');
      }
      parts.add(u.isActive ? 'en cours' : 'terminée');
      events.add(_LifeEvent(
        dotColor: GwTokens.rose,
        title: title,
        subtitle: parts.join(' · '),
      ));
    }

    // ── Résidence / langue ──
    final residence = person.residenceCountry;
    final language = person.nativeLanguage;
    if ((residence != null && residence.isNotEmpty) ||
        (language != null && language.isNotEmpty)) {
      final parts = <String>[];
      if (residence != null && residence.isNotEmpty) parts.add(residence);
      if (language != null && language.isNotEmpty) {
        parts.add('$language (langue)');
      }
      events.add(_LifeEvent(
        dotColor: GwTokens.sage,
        title: 'Résidence — auj.',
        subtitle: parts.join(' · '),
      ));
    }

    return events;
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final events = _buildEvents();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.ink,
        borderRadius: BorderRadius.circular(GwTokens.rCard),
        border: Border.all(color: t.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FICHE DE VIE',
            style: GwType.mono(
              fontSize: 9.5,
              letterSpacing: 2,
              color: t.stoneFaint,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            Text(
              'Aucun évènement de vie renseigné.',
              style: GwType.ui(fontSize: 12.5, color: t.stoneDim),
            )
          else
            ...List.generate(events.length, (i) {
              final e = events[i];
              return Padding(
                padding: EdgeInsets.only(
                    bottom: i == events.length - 1 ? 0 : 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: e.dotColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.title,
                            style: GwType.ui(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: t.stone,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            e.subtitle,
                            style:
                                GwType.ui(fontSize: 11.5, color: t.stoneDim),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

/// Deux mini-cartes côte à côte : « Profession » et « Union(s) ».
class _MiniCardsRow extends StatelessWidget {
  final PersonGenealogy person;
  final FamilyTree tree;
  final List<GenealogyUnion> unions;

  const _MiniCardsRow({
    required this.person,
    required this.tree,
    required this.unions,
  });

  @override
  Widget build(BuildContext context) {
    // Enfants du sujet uniquement (les autres personnes n'exposent pas leurs
    // enfants dans l'arbre courant).
    final childCount =
        person.id == tree.subject.id ? tree.children.length : 0;
    final unionCount = unions.length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _MiniCard(
            label: 'PROFESSION',
            value: (person.profession != null &&
                    person.profession!.isNotEmpty)
                ? person.profession!
                : '—',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniCard(
            label: 'UNION(S)',
            value: childCount > 0
                ? '$unionCount · $childCount enfant${childCount > 1 ? 's' : ''}'
                : '$unionCount',
          ),
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String label;
  final String value;

  const _MiniCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: t.inkCard,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        border: Border.all(color: t.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GwType.mono(
              fontSize: 8.5,
              letterSpacing: 1.5,
              color: t.stoneFaint,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GwType.ui(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: t.stone,
            ),
          ),
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
    final t = GwTokens.of(context);
    // Brun patrimonial de la charte (#3b2a16) pour le bouton secondaire fort.
    const brown = Color(0xFF3B2A16);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: t.inkCard,
        border: Border(top: BorderSide(color: t.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Modifier la fiche (or plein) ──
          _FixedActionBtn(
            icon: Symbols.edit,
            label: 'Modifier la fiche',
            backgroundColor: GwTokens.gold,
            foregroundColor: GwTokens.inkOnGold,
            onTap: () => _showEditDialog(context, person, treeOwnerId),
          ),
          const SizedBox(height: 6),

          // ── Voir carte de migration (brun plein) ──
          _FixedActionBtn(
            icon: Symbols.flight_takeoff,
            label: 'Voir carte de migration',
            backgroundColor: brown,
            foregroundColor: const Color(0xFFF0EBE1),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Carte de migration bientôt disponible'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(height: 6),

          // ── Ajouter un enfant (contour) ──
          _FixedActionBtn(
            icon: Symbols.add,
            label: 'Ajouter un enfant',
            backgroundColor: Colors.transparent,
            foregroundColor: t.goldText,
            borderColor: t.goldLine,
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
    // Boutons « soft » miniaturisés : 36 px, typo 12, icône 15.
    return SizedBox(
      width: double.infinity,
      height: 36,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(GwTokens.rBtn),
              border: borderColor != null
                  ? Border.all(color: borderColor!)
                  : null,
            ),
            // Icône alignée verticalement au texte, contenu centré.
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 15, color: foregroundColor),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GwType.ui(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: foregroundColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Gestion du foyer (maquette 2b) ───────────────────────────

/// Couleur de foyer par rang d'union (1 → or, 2 → rose, 3 → vert, cycle).
Color _foyerColorOf(int index) =>
    const [GwTokens.gold, GwTokens.rose, GwTokens.sage][index % 3];

/// Panneau « Gestion du foyer » : carte sombre chef de famille + liste
/// « Épouses & foyers » (point de couleur, rang, année, enfants) + ajout.
class _FoyerManagement extends ConsumerWidget {
  final PersonGenealogy person;
  final List<GenealogyUnion> unions;
  final FamilyTree tree;
  final String treeOwnerId;

  const _FoyerManagement({
    required this.person,
    required this.unions,
    required this.tree,
    required this.treeOwnerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    const brown = Color(0xFF3B2A16);
    const cream = Color(0xFFF0EBE1);
    final sorted = [...unions]..sort((a, b) => a.unionOrder.compareTo(b.unionOrder));
    final initials =
        '${person.firstName.isNotEmpty ? person.firstName[0] : ''}${person.lastName.isNotEmpty ? person.lastName[0] : ''}'
            .toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GESTION DU FOYER',
          style: GwType.mono(
              fontSize: 10,
              letterSpacing: 2,
              color: t.stoneFaint,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),

        // ── Carte sombre : chef de famille actuel ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: brown,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Symbols.crown, size: 13, color: GwTokens.gold),
                  const SizedBox(width: 6),
                  Text(
                    'CHEF DE FAMILLE ACTUEL',
                    style: GwType.mono(
                        fontSize: 9,
                        letterSpacing: 2,
                        color: cream.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                        color: GwTokens.gold, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: GwType.display(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: brown),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${person.firstName} ${person.lastName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GwType.display(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: cream),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Chef du foyer · ${sorted.length} unions',
                          style: GwType.ui(
                              fontSize: 11.5,
                              color: cream.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _FoyerBtn(
                      label: 'Transmettre le rôle',
                      background: GwTokens.gold,
                      foreground: brown,
                      onTap: () => _soon(context, 'Transmission du rôle'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _FoyerBtn(
                      label: 'Historique',
                      background: Colors.transparent,
                      foreground: cream,
                      borderColor: cream.withValues(alpha: 0.4),
                      onTap: () => _soon(context, 'Historique du foyer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Épouses & foyers ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
          decoration: BoxDecoration(
            color: t.inkCard,
            borderRadius: BorderRadius.circular(GwTokens.rCard),
            border: Border.all(color: t.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ÉPOUSES & FOYERS',
                style: GwType.mono(
                    fontSize: 9,
                    letterSpacing: 2,
                    color: t.stoneFaint,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              for (int i = 0; i < sorted.length; i++)
                _WifeRow(
                  union: sorted[i],
                  rank: i + 1,
                  color: _foyerColorOf(i),
                  childCount: _childCountOf(sorted[i]),
                  onTap: () {
                    final wifeId = sorted[i].wifeId;
                    ref.read(treeViewProvider.notifier).selectPerson(wifeId);
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── + Ajouter une épouse / union (contour pointillé or) ──
        SizedBox(
          width: double.infinity,
          height: 34,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(GwTokens.rBtn),
            child: InkWell(
              onTap: () => _safeDialog(
                context,
                AddUnionDialog(
                    person: person, tree: tree, treeOwnerId: treeOwnerId),
              ),
              borderRadius: BorderRadius.circular(GwTokens.rBtn),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(GwTokens.rBtn),
                  border: Border.all(color: t.goldLine),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Symbols.add, size: 14, color: t.goldText),
                    const SizedBox(width: 5),
                    Text(
                      'Ajouter une épouse / union',
                      style: GwType.ui(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: t.goldText),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Enfants rattachés à cette union (unionId prioritaire, sinon motherId).
  int _childCountOf(GenealogyUnion u) {
    return tree.children.where((c) {
      if (c.unionId != null && c.unionId == u.id) return true;
      return c.motherId != null && c.motherId == u.wifeId;
    }).length;
  }

  void _soon(BuildContext context, String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$what — bientôt disponible'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Ligne « épouse » : point couleur foyer, nom gras, méta, chevron.
class _WifeRow extends StatelessWidget {
  final GenealogyUnion union;
  final int rank;
  final Color color;
  final int childCount;
  final VoidCallback onTap;

  const _WifeRow({
    required this.union,
    required this.rank,
    required this.color,
    required this.childCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final wife = union.wife;
    final name = wife != null
        ? '${wife.firstName} ${wife.lastName}'.trim()
        : 'Épouse $rank';
    final parts = <String>[
      rank == 1 ? '1re union' : '${rank}e union',
      if (union.startDate != null) '${union.startDate!.year}',
      if (childCount > 0) '$childCount enfant${childCount > 1 ? 's' : ''}',
      if (!union.isActive) 'terminée',
    ];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GwType.ui(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: t.stone),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    parts.join(' · '),
                    style: GwType.ui(fontSize: 11, color: t.stoneDim),
                  ),
                ],
              ),
            ),
            Icon(Symbols.chevron_right, size: 18, color: t.stoneFaint),
          ],
        ),
      ),
    );
  }
}

/// Bouton compact de la carte chef (or plein ou contour crème).
class _FoyerBtn extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final Color? borderColor;
  final VoidCallback onTap;

  const _FoyerBtn({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    // Boutons compacts de la carte chef : 32 px, typo 11.5.
    return SizedBox(
      height: 32,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border:
                  borderColor != null ? Border.all(color: borderColor!) : null,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: GwType.ui(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: foreground),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Migration tab (maquette 5a — panneau droit) ──

/// Snackbar flottante générique du panneau Migration.
void _migrationSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Retrouve une personne dans toutes les branches de l'arbre (même logique
/// que `_PersonTab._findPerson`, factorisée pour l'onglet Migration).
PersonGenealogy? _findPersonInTree(FamilyTree tree, String id) {
  final all = <PersonGenealogy>[
    tree.subject,
    ...tree.father,
    ...tree.mother,
    ...tree.paternalGP,
    ...tree.maternalGP,
    ...tree.siblings.map((s) => s.person),
    ...tree.children,
    ...tree.uncles,
    for (final u in tree.unions) ...[
      if (u.husband != null) u.husband!,
      if (u.wife != null) u.wife!,
    ],
  ];
  try {
    return all.firstWhere((p) => p.id == id);
  } catch (_) {
    return null;
  }
}

/// Onglet « Migration » : parcours de migration de la personne sélectionnée
/// (sinon du sujet) — badge, timeline « PARCOURS DE MIGRATION », alliances
/// territoriales et actions carte (maquette 5a).
class _MigrationTab extends StatelessWidget {
  final FamilyTree tree;
  final String? selectedId;
  final String treeOwnerId;

  const _MigrationTab({
    required this.tree,
    required this.selectedId,
    required this.treeOwnerId,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    const brown = Color(0xFF3B2A16);
    const cream = Color(0xFFF0EBE1);

    // Personne affichée : la sélection si elle existe, sinon le sujet.
    final person = (selectedId != null
            ? _findPersonInTree(tree, selectedId!)
            : null) ??
        tree.subject;
    final journey = buildMigrationJourney(tree, person);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      children: [
        _MigrationHeader(person: person, tree: tree, journey: journey),
        const SizedBox(height: 24),
        _MigrationTimelineCard(journey: journey),
        const SizedBox(height: 16),
        _MigrationAlliancesCard(alliances: journey.alliances),
        const SizedBox(height: 20),

        // ── Actions (dans la zone défilante) ──
        _FixedActionBtn(
          icon: Symbols.travel_explore,
          label: 'Voir toute la famille sur la carte',
          backgroundColor: brown,
          foregroundColor: cream,
          onTap: () => _migrationSnack(
            context,
            'Bascule sur la carte — utilisez le toggle « Toute la famille »',
          ),
        ),
        const SizedBox(height: 8),
        _FixedActionBtn(
          icon: Symbols.ios_share,
          label: 'Exporter le parcours',
          backgroundColor: Colors.transparent,
          foregroundColor: t.goldText,
          borderColor: t.goldLine,
          onTap: () => _migrationSnack(
            context,
            'Export du parcours — bientôt disponible',
          ),
        ),
      ],
    );
  }
}

/// En-tête : badge initiales 56 px anneau or (+ point vert si vivant·e),
/// nom en serif, sous-ligne « Foyer {mère} · Concession {père} ».
class _MigrationHeader extends StatelessWidget {
  final PersonGenealogy person;
  final FamilyTree tree;
  final MigrationJourney journey;

  const _MigrationHeader({
    required this.person,
    required this.tree,
    required this.journey,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final initials =
        '${person.firstName.isNotEmpty ? person.firstName[0] : ''}${person.lastName.isNotEmpty ? person.lastName[0] : ''}'
            .toUpperCase();

    // Sous-ligne : composants disponibles uniquement.
    final mother = tree.mother.isNotEmpty ? tree.mother.first : null;
    final subParts = <String>[
      if (mother != null && mother.firstName.trim().isNotEmpty)
        'Foyer ${mother.firstName.trim()}',
      if (journey.pilierConcession != null)
        'Concession ${journey.pilierConcession}',
    ];

    return Column(
      children: [
        // ── Badge initiales 56 px, anneau or ──
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: t.inkLift,
                border: Border.all(color: GwTokens.gold, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: GwTokens.gold.withValues(alpha: 0.22),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: GwType.display(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: t.stone,
                ),
              ),
            ),
            if (person.isAlive)
              Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: GwTokens.sage,
                    border: Border.all(color: t.inkCard, width: 2.5),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Nom serif centré ──
        Text(
          '${person.firstName} ${person.lastName}',
          textAlign: TextAlign.center,
          style: GwType.display(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: t.stone,
          ),
        ),
        if (subParts.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subParts.join(' · '),
            textAlign: TextAlign.center,
            style: GwType.ui(fontSize: 12.5, color: t.stoneDim),
          ),
        ],
      ],
    );
  }
}

/// Carte « PARCOURS DE MIGRATION » : timeline verticale à puces colorées
/// (or pour les étapes, vert pour la résidence actuelle) + bouton pointillé
/// or « + Ajouter une étape ».
class _MigrationTimelineCard extends StatelessWidget {
  final MigrationJourney journey;

  const _MigrationTimelineCard({required this.journey});

  /// « {Lieu} — {année | depuis année | —} ».
  String _titleOf(MigrationStep s) {
    if (s.kind == MigrationStepKind.residence) {
      return s.year != null ? '${s.place} — depuis ${s.year}' : '${s.place} — auj.';
    }
    return s.year != null ? '${s.place} — ${s.year}' : '${s.place} — —';
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final steps = journey.steps;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.ink,
        borderRadius: BorderRadius.circular(GwTokens.rCard),
        border: Border.all(color: t.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PARCOURS DE MIGRATION',
            style: GwType.mono(
              fontSize: 10,
              letterSpacing: 2,
              color: t.stoneFaint,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          if (steps.isEmpty)
            Text(
              'Aucune étape de migration renseignée.',
              style: GwType.ui(fontSize: 12.5, color: t.stoneDim),
            )
          else
            ...List.generate(steps.length, (i) {
              final s = steps[i];
              final dotColor = s.kind == MigrationStepKind.residence
                  ? GwTokens.sage
                  : GwTokens.gold;
              return Padding(
                padding:
                    EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: dotColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _titleOf(s),
                            style: GwType.ui(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: t.stone,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.subtitle,
                            style:
                                GwType.ui(fontSize: 12.5, color: t.stoneDim),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 14),

          // ── + Ajouter une étape (contour pointillé or) ──
          SizedBox(
            width: double.infinity,
            height: 34,
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: t.goldLine,
                radius: GwTokens.rBtn,
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(GwTokens.rBtn),
                child: InkWell(
                  onTap: () => _migrationSnack(
                    context,
                    'Ajout d\'étape — bientôt disponible',
                  ),
                  borderRadius: BorderRadius.circular(GwTokens.rBtn),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Symbols.add, size: 14, color: t.goldText),
                      const SizedBox(width: 5),
                      Text(
                        'Ajouter une étape',
                        style: GwType.ui(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: t.goldText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte « ALLIANCES SUR LA CARTE » : point rose (maternelle) ou vert
/// (par union) + village en gras + type à droite.
class _MigrationAlliancesCard extends StatelessWidget {
  final List<MigrationAlliance> alliances;

  const _MigrationAlliancesCard({required this.alliances});

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.ink,
        borderRadius: BorderRadius.circular(GwTokens.rCard),
        border: Border.all(color: t.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ALLIANCES SUR LA CARTE',
            style: GwType.mono(
              fontSize: 10,
              letterSpacing: 2,
              color: t.stoneFaint,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          if (alliances.isEmpty)
            Text(
              'Aucune alliance sur la carte',
              style: GwType.ui(fontSize: 12.5, color: t.stoneDim),
            )
          else
            ...List.generate(alliances.length, (i) {
              final a = alliances[i];
              final color = a.kind == AllianceKind.maternelle
                  ? GwTokens.rose
                  : GwTokens.sage;
              final typeLabel =
                  a.kind == AllianceKind.maternelle ? 'maternelle' : 'par union';
              return Padding(
                padding:
                    EdgeInsets.only(bottom: i == alliances.length - 1 ? 0 : 12),
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        a.place,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GwType.ui(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: t.stone,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      typeLabel,
                      style: GwType.ui(fontSize: 12, color: color),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

/// Trace un contour arrondi en pointillés (bouton « + Ajouter une étape »).
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(radius),
      ));
    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

// ── IA tab ──

class _IaTab extends ConsumerWidget {
  final List<AiSuggestion> suggestions;
  final String personId;

  const _IaTab({required this.suggestions, required this.personId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    if (suggestions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Symbols.auto_awesome, size: 40, color: t.stoneDim),
              const SizedBox(height: 8),
              Text(
                'Aucune suggestion',
                style: TextStyle(color: t.stone, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'L\'IA analysera votre arbre et proposera des liens potentiels.',
                textAlign: TextAlign.center,
                style: TextStyle(color: t.stoneDim, fontSize: 11),
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
    final t = GwTokens.of(context);
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
        color: t.inkCard,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: GwTokens.sage.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Relation
          Row(
            children: [
              const Icon(Symbols.auto_awesome, size: 14, color: GwTokens.sage),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${suggestion.personA?.firstName ?? "?"} ↔ ${suggestion.personB?.firstName ?? "?"}',
                  style: TextStyle(color: t.stone, fontSize: 12, fontWeight: FontWeight.w600),
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
            style: TextStyle(color: t.stoneMid, fontSize: 11),
          ),

          // Confidence bar
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: suggestion.confidence,
              backgroundColor: t.inkHigh,
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
                      Text('• ', style: TextStyle(color: t.stoneDim, fontSize: 10)),
                      Expanded(
                        child: Text(r, style: TextStyle(color: t.stoneMid, fontSize: 10)),
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
                icon: const Icon(Symbols.close, size: 14),
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
                icon: const Icon(Symbols.check, size: 14),
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
          Icon(Symbols.edit_note, size: 22),
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
                  decoration: const InputDecoration(labelText: 'Prénom *', prefixIcon: Icon(Symbols.person)),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastNameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom *', prefixIcon: Icon(Symbols.badge)),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _dateCtrl,
                      decoration: const InputDecoration(labelText: 'Date de naissance', prefixIcon: Icon(Symbols.calendar_today), hintText: 'JJ/MM/AAAA'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Status — plain DropdownButton (no FormField) to avoid deprecated value issue
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Statut', prefixIcon: Icon(Symbols.favorite)),
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
                  decoration: const InputDecoration(labelText: 'Lieu de résidence', prefixIcon: Icon(Symbols.location_on)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _professionCtrl,
                  decoration: const InputDecoration(labelText: 'Profession', prefixIcon: Icon(Symbols.work)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Téléphone', prefixIcon: Icon(Symbols.call)),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                // Privacy — plain DropdownButton
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Visibilité', prefixIcon: Icon(Symbols.visibility)),
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
          style: ElevatedButton.styleFrom(
              backgroundColor: GwTokens.gold,
              foregroundColor: const Color(0xFF0C0B0F)),
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
