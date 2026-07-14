import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/features/genealogy/models/ai_suggestion.dart';
import 'package:gwangmeu/features/genealogy/models/family_tree.dart';
import 'package:gwangmeu/features/genealogy/models/genealogy_union.dart';
import 'package:gwangmeu/features/genealogy/models/person_genealogy.dart';
import 'package:gwangmeu/features/genealogy/services/genealogy_api_service.dart';
import 'package:gwangmeu/features/profile/profile_notifier.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/genealogy/state/ai_insights.dart';
import 'package:gwangmeu/features/genealogy/state/migration_journey.dart';
import 'package:gwangmeu/features/genealogy/state/tree_view_state.dart';
import 'package:gwangmeu/features/genealogy/widgets/dialogs/add_person_dialog.dart';
import 'package:gwangmeu/features/genealogy/widgets/dialogs/add_union_dialog.dart';
import 'package:gwangmeu/features/genealogy/widgets/dialogs/griot_dialog.dart';
import 'package:gwangmeu/features/genealogy/widgets/dialogs/origin_cascade_selector.dart';
import 'package:gwangmeu/shared/widgets/gw_dialog.dart';
import 'package:gwangmeu/features/geo/geo_notifier.dart';
import 'package:gwangmeu/shared/models/country_model.dart';
import 'package:gwangmeu/shared/widgets/country_selector.dart';

/// Défilement inratable pour le panneau : molette, trackpad ET glisser à la
/// souris (le drag souris est désactivé par défaut sur Flutter web/desktop).
class _PanelScrollBehavior extends MaterialScrollBehavior {
  const _PanelScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

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
                  tree: tree,
                  selectedId: selectedPersonId,
                  treeOwnerId: personId,
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

class _PersonTab extends StatefulWidget {
  final FamilyTree tree;
  final String? selectedId;
  final String treeOwnerId;

  const _PersonTab({
    required this.tree,
    required this.selectedId,
    required this.treeOwnerId,
  });

  @override
  State<_PersonTab> createState() => _PersonTabState();
}

class _PersonTabState extends State<_PersonTab> {
  // Contrôleur dédié : barre de défilement TOUJOURS visible et extent borné
  // (SingleChildScrollView, pas de recyclage ListView → le contenu ne
  // « disparaît » plus au scroll et on peut toujours remonter).
  final ScrollController _scrollCtrl = ScrollController();

  FamilyTree get tree => widget.tree;
  String? get selectedId => widget.selectedId;
  String get treeOwnerId => widget.treeOwnerId;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

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
        // ── Contenu défilant (borné, barre visible, molette + drag souris) ──
        Expanded(
          child: ScrollConfiguration(
            behavior: const _PanelScrollBehavior(),
            child: Scrollbar(
              controller: _scrollCtrl,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                primary: false,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PersonHeader(
                    person: person,
                    isSubject: person.id == tree.subject.id,
                  ),
                  // ── Gestion du foyer (2b) : EN TÊTE pour le chef ──
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
                  _LifeFiche(person: person),
                  const SizedBox(height: 16),
                  _MiniCardsRow(
                    person: person,
                    tree: tree,
                    unions: personUnions,
                  ),
                ],
                ),
              ),
            ),
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

    // ── Méta : l'ORIGINE d'abord (ancre de la lignée). La résidence
    //    n'apparaît qu'en second segment discret, si différente. ──
    final originPlace =
        _cleanText(person.originVillage) ?? _cleanText(person.originCity);
    final originCountry = _cleanText(person.originCountry);
    String? originLine;
    if (originPlace != null) {
      originLine = originCountry != null
          ? 'Originaire de $originPlace, ${_countryDisplay(originCountry)}'
          : 'Originaire de $originPlace';
    }
    String? residenceSegment;
    if (originLine != null) {
      final resCity = _cleanText(person.residenceCity);
      final resCountry = _cleanText(person.residenceCountry);
      final sameCountry = resCountry != null &&
          originCountry != null &&
          resCountry.toUpperCase() == originCountry.toUpperCase();
      final resLabel =
          resCity ?? (resCountry != null ? _countryDisplay(resCountry) : null);
      final sameCity = resCity != null &&
          resCity.toLowerCase() == originPlace!.toLowerCase();
      if (resLabel != null && !sameCity && !(resCity == null && sameCountry)) {
        residenceSegment = 'vit à $resLabel';
      }
    }

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
        if (originLine != null) ...[
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: originLine,
                  style: GwType.ui(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: t.stoneDim,
                  ),
                ),
                if (residenceSegment != null)
                  TextSpan(
                    text: ' · $residenceSegment',
                    style: GwType.ui(fontSize: 11.5, color: t.stoneFaint),
                  ),
              ],
            ),
            textAlign: TextAlign.center,
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

// ── Helpers origine / pays (ISO-3166 alpha-2) : drapeau + libellé ──

/// Trim + null si vide — normalise les champs texte optionnels.
String? _cleanText(String? v) {
  final s = v?.trim();
  return (s == null || s.isEmpty) ? null : s;
}

/// Drapeau émoji à partir d'un code ISO-2 (« CM » → 🇨🇲), '' si invalide.
String _flagEmoji(String iso2) {
  final code = iso2.trim().toUpperCase();
  if (code.length != 2 || code.codeUnits.any((c) => c < 0x41 || c > 0x5A)) {
    return '';
  }
  return String.fromCharCodes(code.codeUnits.map((c) => 0x1F1E6 + (c - 0x41)));
}

/// Libellés FR des pays fréquents (repli : code ISO brut).
const Map<String, String> _countryNamesFr = {
  'CM': 'Cameroun',
  'FR': 'France',
  'BE': 'Belgique',
  'DE': 'Allemagne',
  'GB': 'Royaume-Uni',
  'US': 'États-Unis',
  'CA': 'Canada',
  'SN': 'Sénégal',
  'CI': "Côte d'Ivoire",
  'GA': 'Gabon',
  'TD': 'Tchad',
  'NG': 'Nigeria',
  'GH': 'Ghana',
  'CG': 'Congo',
  'CD': 'RD Congo',
  'CF': 'Centrafrique',
  'GQ': 'Guinée équatoriale',
  'IT': 'Italie',
  'ES': 'Espagne',
  'PT': 'Portugal',
  'CH': 'Suisse',
  'NL': 'Pays-Bas',
  'MA': 'Maroc',
  'DZ': 'Algérie',
  'TN': 'Tunisie',
  'ZA': 'Afrique du Sud',
  'AU': 'Australie',
  'CN': 'Chine',
  'JP': 'Japon',
};

/// « 🇨🇲 Cameroun » — drapeau + libellé pour un code ISO-2.
String _countryDisplay(String iso2) {
  final code = iso2.trim().toUpperCase();
  final name = _countryNamesFr[code] ?? code;
  final flag = _flagEmoji(code);
  return flag.isEmpty ? name : '$flag $name';
}

/// Une ligne de fiche : libellé + valeur. [anchor] = champ d'ORIGINE
/// (ancre de la lignée) : à null il affiche « À renseigner » au lieu
/// d'être masqué comme les autres champs.
class _FicheField {
  final String label;
  final String? value;
  final bool anchor;
  const _FicheField(this.label, this.value, {this.anchor = false});
}

/// Fiche de vie réorganisée en DEUX blocs :
/// « ORIGINE — ANCRE DE LA LIGNÉE » (village, ville, région, pays d'origine,
/// clan, totem, langue, naissance) et « ÉVOLUTION — AUJOURD'HUI »
/// (résidence, profession, religion, statut marital, contacts).
class _LifeFiche extends StatelessWidget {
  final PersonGenealogy person;

  const _LifeFiche({required this.person});

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);

    final originCountry = _cleanText(person.originCountry);
    final originFields = <_FicheField>[
      _FicheField("Village d'origine", _cleanText(person.originVillage),
          anchor: true),
      _FicheField("Ville d'origine", _cleanText(person.originCity),
          anchor: true),
      _FicheField("Région d'origine", _cleanText(person.originRegion),
          anchor: true),
      _FicheField(
        "Pays d'origine",
        originCountry != null ? _countryDisplay(originCountry) : null,
        anchor: true,
      ),
      _FicheField('Clan', _cleanText(person.clan)),
      _FicheField('Totem', _cleanText(person.totem)),
      _FicheField('Langue maternelle', _cleanText(person.nativeLanguage)),
      _FicheField('Lieu de naissance', _cleanText(person.birthPlace)),
    ];

    final resCity = _cleanText(person.residenceCity);
    final resCountry = _cleanText(person.residenceCountry);
    final residence = [
      if (resCity != null) resCity,
      if (resCountry != null) _countryDisplay(resCountry),
    ].join(' · ');
    final phone = _cleanText(person.phone);
    final email = _cleanText(person.email);
    final contacts = [
      if (phone != null) phone,
      if (email != null) email,
    ].join(' · ');
    final evolutionFields = <_FicheField>[
      _FicheField('Résidence', residence.isEmpty ? null : residence),
      _FicheField('Profession', _cleanText(person.profession)),
      _FicheField('Religion', _cleanText(person.religion)),
      _FicheField('Statut marital', _cleanText(person.maritalStatus)),
      _FicheField('Contacts', contacts.isEmpty ? null : contacts),
    ];

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
          _FicheSection(
            title: 'ORIGINE — ANCRE DE LA LIGNÉE',
            titleColor: t.goldText,
            fields: originFields,
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: t.line),
          const SizedBox(height: 12),
          _FicheSection(
            title: "ÉVOLUTION — AUJOURD'HUI",
            titleColor: t.sageText,
            fields: evolutionFields,
          ),
        ],
      ),
    );
  }
}

/// Section de fiche : intitulé mono MAJ + lignes libellé/valeur.
/// Valeur nulle : « À renseigner » (italique gris discret) pour les champs
/// [anchor] (origine), ligne masquée pour les autres — comme avant.
class _FicheSection extends StatelessWidget {
  final String title;
  final Color titleColor;
  final List<_FicheField> fields;

  const _FicheSection({
    required this.title,
    required this.titleColor,
    required this.fields,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final visible = fields.where((f) => f.value != null || f.anchor).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GwType.mono(
            fontSize: 9.5,
            letterSpacing: 2,
            color: titleColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        if (visible.isEmpty)
          Text(
            'Aucun élément renseigné.',
            style: GwType.ui(fontSize: 11.5, color: t.stoneFaint),
          )
        else
          ...List.generate(visible.length, (i) {
            final f = visible[i];
            final missing = f.value == null;
            return Padding(
              padding:
                  EdgeInsets.only(bottom: i == visible.length - 1 ? 0 : 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 112,
                    child: Text(
                      f.label,
                      style: GwType.ui(fontSize: 11, color: t.stoneDim),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: missing
                        ? Text(
                            'À renseigner',
                            style: GwType.ui(
                              fontSize: 11.5,
                              color: t.stoneFaint,
                            ).copyWith(fontStyle: FontStyle.italic),
                          )
                        : Text(
                            f.value!,
                            style: GwType.ui(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: t.stone,
                            ),
                          ),
                  ),
                ],
              ),
            );
          }),
      ],
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
  // PWA : showGwDialog rend un bottom-sheet plein écran sur mobile et un dialog
  // centré sur desktop/web (même appli, tous les form-factors).
  showGwDialog(
    context,
    builder: (_) => _InlineEditDialog(person: person, treeOwnerId: treeOwnerId),
  );
}

/// Fixed action buttons at the bottom of the person tab.
class _FixedActions extends ConsumerWidget {
  final PersonGenealogy person;
  final String treeOwnerId;

  const _FixedActions({
    required this.person,
    required this.treeOwnerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    // Brun patrimonial de la charte (#3b2a16) pour le bouton secondaire fort.
    const brown = Color(0xFF3B2A16);
    // Édition réservée à SA propre fiche (compte lié) ou à une fiche sans compte
    // (ajoutée/gérée par l'utilisateur). JAMAIS la fiche d'un AUTRE compte réel.
    // Le backend applique déjà la même règle (createdBy OU userId) ; ici on
    // masque le bouton pour ne même pas le proposer.
    final myUserId = ref.watch(profileNotifierProvider).valueOrNull?.id;
    final canEditPerson = person.userId == null ||
        (myUserId != null && person.userId == myUserId);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: t.inkCard,
        border: Border(top: BorderSide(color: t.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Modifier la fiche (or plein) — seulement si autorisé ──
          if (canEditPerson) ...[
            _FixedActionBtn(
              icon: Symbols.edit,
              label: 'Modifier la fiche',
              backgroundColor: GwTokens.gold,
              foregroundColor: GwTokens.inkOnGold,
              onTap: () => _showEditDialog(context, person, treeOwnerId),
            ),
            const SizedBox(height: 6),
          ],

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
    final heirs = _successionOf(sorted);
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

        // ── Ordre de succession (dérivé des enfants, drag décoratif) ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
          decoration: BoxDecoration(
            color: t.inkCard,
            borderRadius: BorderRadius.circular(GwTokens.rCard),
            border: Border.all(color: t.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ORDRE DE SUCCESSION',
                style: GwType.mono(
                    fontSize: 9,
                    letterSpacing: 2,
                    color: t.stoneFaint,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              if (heirs.isEmpty)
                Text(
                  'Aucun successeur identifié.',
                  style: GwType.ui(fontSize: 11.5, color: t.stoneDim),
                )
              else
                for (int i = 0; i < heirs.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _SuccessionRow(
                    rank: i + 1,
                    person: heirs[i].$1,
                    motherFirstName: _wifeFirstNameOf(
                        sorted[heirs[i].$2], heirs[i].$2 + 1),
                    foyerColor: _foyerColorOf(heirs[i].$2),
                    isEldest: i == 0,
                  ),
                ],
              const SizedBox(height: 10),
              Text(
                'Glissez pour réordonner. La transmission demande la '
                'validation de 2 témoins du clan.',
                style: GwType.ui(fontSize: 11, color: t.stoneFaint),
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
              for (int i = 0; i < sorted.length; i++) ...[
                // Séparateur fin ENTRE les lignes (pas après la dernière).
                if (i > 0) Divider(height: 1, thickness: 1, color: t.line),
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
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── + Ajouter une épouse / union (contour pointillé or) ──
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
                onTap: () => _safeDialog(
                  context,
                  AddUnionDialog(
                      person: person, tree: tree, treeOwnerId: treeOwnerId),
                ),
                borderRadius: BorderRadius.circular(GwTokens.rBtn),
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

  /// Ordre de succession DÉRIVÉ (pas de table dédiée) : enfants du chef tous
  /// foyers confondus — rattachés aux épouses via unionId/motherId (même
  /// logique que [_childCountOf]) — triés par naissance croissante (aîné·e
  /// d'abord, dates nulles à la fin). Ne retient que les 3 premiers.
  /// Chaque entrée : (enfant, index de l'union dans la liste triée).
  List<(PersonGenealogy, int)> _successionOf(List<GenealogyUnion> sorted) {
    final entries = <(PersonGenealogy, int)>[];
    for (final c in tree.children) {
      for (int i = 0; i < sorted.length; i++) {
        final u = sorted[i];
        final matches = (c.unionId != null && c.unionId == u.id) ||
            (c.motherId != null && c.motherId == u.wifeId);
        if (matches) {
          entries.add((c, i));
          break;
        }
      }
    }
    entries.sort((a, b) {
      final da = a.$1.birthDate;
      final db = b.$1.birthDate;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });
    return entries.take(3).toList();
  }

  /// Prénom de l'épouse d'une union (fallback « épouse {rang} » si inconnu).
  String _wifeFirstNameOf(GenealogyUnion u, int rank) {
    final name = u.wife?.firstName.trim();
    return (name != null && name.isNotEmpty) ? name : 'épouse $rank';
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

/// Ligne « successeur » (maquette 2b) : rang mono or, badge initiales 30 px
/// teinté de la couleur du foyer maternel, nom gras, sous-ligne
/// « Foyer {prénom mère} [· aîné·e] », poignée ⋮⋮ décorative — le drag
/// N'EST PAS fonctionnel, comme la maquette.
class _SuccessionRow extends StatelessWidget {
  final int rank;
  final PersonGenealogy person;
  final String motherFirstName;
  final Color foyerColor;
  final bool isEldest;

  const _SuccessionRow({
    required this.rank,
    required this.person,
    required this.motherFirstName,
    required this.foyerColor,
    required this.isEldest,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final initials =
        '${person.firstName.isNotEmpty ? person.firstName[0] : ''}${person.lastName.isNotEmpty ? person.lastName[0] : ''}'
            .toUpperCase();
    final subtitle =
        isEldest ? 'Foyer $motherFirstName · aîné·e' : 'Foyer $motherFirstName';

    return Row(
      children: [
        // Rang en mono or.
        SizedBox(
          width: 14,
          child: Text(
            '$rank',
            style: GwType.mono(
                fontSize: 11,
                letterSpacing: 0,
                color: t.goldText,
                fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 6),
        // Badge initiales 30 px teinté de la couleur du foyer de la mère.
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: foyerColor.withValues(alpha: 0.16),
            border: Border.all(color: foyerColor.withValues(alpha: 0.45)),
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: GwType.display(
                fontSize: 11, fontWeight: FontWeight.w700, color: t.stone),
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
                style: GwType.ui(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: t.stone),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GwType.ui(fontSize: 11, color: t.stoneDim),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        // Poignée ⋮⋮ décorative (drag non fonctionnel).
        Icon(Symbols.drag_indicator, size: 16, color: t.stoneFaint),
      ],
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
class _MigrationTab extends StatefulWidget {
  final FamilyTree tree;
  final String? selectedId;
  final String treeOwnerId;

  const _MigrationTab({
    required this.tree,
    required this.selectedId,
    required this.treeOwnerId,
  });

  @override
  State<_MigrationTab> createState() => _MigrationTabState();
}

class _MigrationTabState extends State<_MigrationTab> {
  // Défilement borné + barre visible (même correctif que l'onglet Personne :
  // plus de contenu qui disparaît, remontée toujours possible).
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tree = widget.tree;
    final selectedId = widget.selectedId;
    final t = GwTokens.of(context);
    const brown = Color(0xFF3B2A16);
    const cream = Color(0xFFF0EBE1);

    // Personne affichée : la sélection si elle existe, sinon le sujet.
    final person = (selectedId != null
            ? _findPersonInTree(tree, selectedId)
            : null) ??
        tree.subject;
    final journey = buildMigrationJourney(tree, person);

    return ScrollConfiguration(
      behavior: const _PanelScrollBehavior(),
      child: Scrollbar(
      controller: _scrollCtrl,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollCtrl,
        primary: false,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
        ),
      ),
      ),
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

// ── IA tab (maquette 4a « Affluent IA » + 4c « Veille de l'arbre ») ──

/// Snackbar flottante générique de l'onglet IA.
void _iaSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}

/// Initiales (2 lettres max) d'une personne, « ? » si inconnue.
String _initialsOf(PersonGenealogy? p) {
  if (p == null) return '?';
  final f = p.firstName.isNotEmpty ? p.firstName[0] : '';
  final l = p.lastName.isNotEmpty ? p.lastName[0] : '';
  final s = '$f$l'.toUpperCase();
  return s.isEmpty ? '?' : s;
}

/// Onglet « ✦ IA » : panneau contextuel « Affluent IA » (récit généré,
/// liens probables réels, incohérences) + « Veille de l'arbre »
/// (complétude, doublons) — tout est calculé localement par l'analyseur
/// [buildTreeInsights] / [buildPersonNarrative] sur les données réelles.
class _IaTab extends ConsumerStatefulWidget {
  final FamilyTree tree;
  final String? selectedId;
  final String treeOwnerId;

  const _IaTab({
    required this.tree,
    required this.selectedId,
    required this.treeOwnerId,
  });

  @override
  ConsumerState<_IaTab> createState() => _IaTabState();
}

class _IaTabState extends ConsumerState<_IaTab> {
  // Même correctif de défilement que les onglets Personne/Migration :
  // barre toujours visible, molette + drag souris, extent borné.
  final ScrollController _scrollCtrl = ScrollController();
  final GlobalKey _inconsistenciesKey = GlobalKey();
  bool _savingNarrative = false;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final tree = widget.tree;
    // Personne analysée : la sélection si elle existe, sinon le sujet.
    final person = (widget.selectedId != null
            ? _findPersonInTree(tree, widget.selectedId!)
            : null) ??
        tree.subject;
    // Analyse réelle de l'arbre — calculée une fois par build.
    final insights = buildTreeInsights(tree);
    final narrative = buildPersonNarrative(tree, person);
    final suggestions = tree.pendingSuggestions;

    return Column(
      children: [
        Expanded(
          child: ScrollConfiguration(
            behavior: const _PanelScrollBehavior(),
            child: Scrollbar(
              controller: _scrollCtrl,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                primary: false,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── 1) En-tête « Affluent IA » ──
                    _IaHeader(person: person),
                    const SizedBox(height: 20),

                    // ── 2) Récit généré ──
                    _NarrativeCard(
                      narrative: narrative,
                      saving: _savingNarrative,
                      onRegenerate: () => setState(() {}),
                      onListen: () => _iaSnack(
                          context, 'Lecture audio — bientôt disponible'),
                      onAddToFiche: () =>
                          _addNarrativeToFiche(person, narrative),
                    ),
                    const SizedBox(height: 16),

                    // ── 3) Liens probables (suggestions IA réelles) ──
                    _ProbableLinksCard(
                      suggestions: suggestions,
                      onAccept: (s) => _review(s.id, true),
                      onReject: (s) => _review(s.id, false),
                    ),

                    // ── 4) Incohérences détectées ──
                    if (insights.inconsistencies.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Column(
                        key: _inconsistenciesKey,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (int i = 0;
                              i < insights.inconsistencies.length;
                              i++) ...[
                            if (i > 0) const SizedBox(height: 10),
                            _InconsistencyCard(
                              inconsistency: insights.inconsistencies[i],
                              onFix: () => _fixInconsistency(
                                  insights.inconsistencies[i]),
                            ),
                          ],
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),

                    // ── 5) Veille de l'arbre (maquette 4c) ──
                    _TreeWatchSection(
                      insights: insights,
                      lineageName: tree.subject.lastName,
                      onCompleteFive: () => _iaSnack(context,
                          'Compléter en 5 questions — bientôt disponible'),
                      onMerge: () => _iaSnack(context,
                          'Fusion des doublons — bientôt disponible'),
                      onVerify: _scrollToInconsistencies,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── 6) Parler au Griot (fixe en bas) ──
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: t.inkCard,
            border: Border(top: BorderSide(color: t.line)),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 38,
            child: Material(
              color: const Color(0xFF3B2A16),
              borderRadius: BorderRadius.circular(GwTokens.rBtn),
              child: InkWell(
                onTap: () =>
                    showGriotDialog(context, tree, widget.treeOwnerId),
                borderRadius: BorderRadius.circular(GwTokens.rBtn),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🗣', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 7),
                    Text(
                      'Parler au Griot',
                      style: GwType.ui(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF0EBE1),
                      ),
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

  Future<void> _review(String id, bool accepted) async {
    try {
      await ref
          .read(genealogyApiServiceProvider)
          .reviewSuggestion(id, accepted);
      ref.invalidate(familyTreeProvider(widget.treeOwnerId));
      if (mounted) {
        _iaSnack(context, accepted ? 'Lien vérifié et relié' : 'Suggestion ignorée');
      }
    } catch (_) {
      if (mounted) {
        _iaSnack(context, "La vérification n'a pas abouti — réessayez");
      }
    }
  }

  /// PATCH réel : enregistre le récit dans la biographie de la personne.
  Future<void> _addNarrativeToFiche(
      PersonGenealogy person, String narrative) async {
    if (_savingNarrative || narrative.trim().isEmpty) return;
    setState(() => _savingNarrative = true);
    try {
      await ref
          .read(genealogyApiServiceProvider)
          .updatePerson(person.id, {'biography': narrative});
      ref.invalidate(familyTreeProvider(widget.treeOwnerId));
      if (mounted) _iaSnack(context, 'Récit ajouté à la fiche');
    } catch (_) {
      if (mounted) {
        _iaSnack(context, "Impossible d'ajouter le récit à la fiche");
      }
    } finally {
      if (mounted) setState(() => _savingNarrative = false);
    }
  }

  /// « Corriger → » : ouvre l'édition de la personne concernée si elle est
  /// dans l'arbre, sinon la sélectionne simplement.
  void _fixInconsistency(TreeInconsistency inc) {
    final person = _findPersonInTree(widget.tree, inc.personId);
    if (person != null) {
      _showEditDialog(context, person, widget.treeOwnerId);
    } else {
      ref.read(treeViewProvider.notifier).selectPerson(inc.personId);
    }
  }

  void _scrollToInconsistencies() {
    final ctx = _inconsistenciesKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        alignment: 0.05,
      );
    }
  }
}

/// 1) En-tête « Affluent IA » : pastille or ✦, titre serif, sous-ligne
/// contextuelle, pilule mono « À JOUR » (sage).
class _IaHeader extends StatelessWidget {
  final PersonGenealogy person;

  const _IaHeader({required this.person});

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: GwTokens.gold,
            borderRadius: BorderRadius.circular(11),
            boxShadow: [
              BoxShadow(
                color: GwTokens.gold.withValues(alpha: 0.3),
                blurRadius: 10,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            '✦',
            style: TextStyle(fontSize: 16, color: GwTokens.inkOnGold),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Affluent IA',
                style: GwType.display(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: t.stone,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'analyse de la fiche de '
                '${person.firstName} ${person.lastName}'.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GwType.ui(fontSize: 11, color: t.stoneDim),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _MonoPill(label: 'À JOUR', color: t.sageText, dotColor: GwTokens.sage),
      ],
    );
  }
}

/// Bouton compact 32 px de l'onglet IA (plein ou contour), avec état occupé.
class _IaBtn extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final Color? borderColor;
  final VoidCallback onTap;
  final bool busy;

  const _IaBtn({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.borderColor,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: busy ? null : onTap,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border:
                  borderColor != null ? Border.all(color: borderColor!) : null,
            ),
            child: busy
                ? SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foreground,
                    ),
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: GwType.ui(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: foreground,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// 2) Carte « RÉCIT GÉNÉRÉ » : récit de l'analyseur en Fraunces italique
/// entre guillemets français, lien « Régénérer ↻ » et actions
/// « Écouter 🎙 » / « Ajouter à la fiche » (PATCH réel).
class _NarrativeCard extends StatelessWidget {
  final String narrative;
  final bool saving;
  final VoidCallback onRegenerate;
  final VoidCallback onListen;
  final VoidCallback onAddToFiche;

  const _NarrativeCard({
    required this.narrative,
    required this.saving,
    required this.onRegenerate,
    required this.onListen,
    required this.onAddToFiche,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.inkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'RÉCIT GÉNÉRÉ',
                  style: GwType.mono(
                    fontSize: 9.5,
                    letterSpacing: 2,
                    color: t.stoneFaint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              InkWell(
                onTap: onRegenerate,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Régénérer ↻',
                    style: GwType.ui(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: t.goldText,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '« $narrative »',
            style: GwType.quote(
              fontSize: 13.5,
              color: t.stone,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _IaBtn(
                  label: 'Écouter 🎙',
                  background: GwTokens.gold,
                  foreground: GwTokens.inkOnGold,
                  onTap: onListen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _IaBtn(
                  label: 'Ajouter à la fiche',
                  background: Colors.transparent,
                  foreground: t.goldText,
                  borderColor: t.goldLine,
                  busy: saving,
                  onTap: onAddToFiche,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 3) Carte « LIENS PROBABLES DÉTECTÉS » : suggestions IA réelles
/// (tree.pendingSuggestions) avec confiance en or + barre de progression.
class _ProbableLinksCard extends StatelessWidget {
  final List<AiSuggestion> suggestions;
  final void Function(AiSuggestion) onAccept;
  final void Function(AiSuggestion) onReject;

  const _ProbableLinksCard({
    required this.suggestions,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.inkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LIENS PROBABLES DÉTECTÉS',
            style: GwType.mono(
              fontSize: 9.5,
              letterSpacing: 2,
              color: t.stoneFaint,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          if (suggestions.isEmpty)
            Text(
              "Aucun lien probable pour l'instant.",
              style: GwType.ui(fontSize: 11.5, color: t.stoneDim),
            )
          else
            for (int i = 0; i < suggestions.length; i++) ...[
              if (i > 0) ...[
                const SizedBox(height: 4),
                Divider(height: 1, thickness: 1, color: t.line),
                const SizedBox(height: 10),
              ],
              _SuggestionRow(
                suggestion: suggestions[i],
                onAccept: () => onAccept(suggestions[i]),
                onReject: () => onReject(suggestions[i]),
              ),
            ],
        ],
      ),
    );
  }
}

/// Une ligne de lien probable : badge initiales 32 px, nom gras, relation,
/// % de confiance or + barre fine, actions « Vérifier & relier » / « Ignorer ».
class _SuggestionRow extends StatelessWidget {
  final AiSuggestion suggestion;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _SuggestionRow({
    required this.suggestion,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final a = suggestion.personA;
    final b = suggestion.personB;
    final aName = a != null
        ? '${a.firstName} ${a.lastName}'.trim()
        : 'Personne inconnue';
    final name = b != null ? '$aName ↔ ${b.firstName}' : aName;
    final confidence = suggestion.confidence.clamp(0.0, 1.0);
    final pct = (confidence * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // Badge initiales 32 px, teinté or.
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GwTokens.gold.withValues(alpha: 0.14),
                border:
                    Border.all(color: GwTokens.gold.withValues(alpha: 0.45)),
              ),
              alignment: Alignment.center,
              child: Text(
                _initialsOf(a),
                style: GwType.display(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: t.stone,
                ),
              ),
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
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: t.stone,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    suggestion.suggestedRelation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GwType.ui(fontSize: 11, color: t.stoneDim),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$pct %',
              style: GwType.ui(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: t.goldText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Fine barre de progression or.
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: confidence,
            backgroundColor: t.line,
            valueColor: const AlwaysStoppedAnimation(GwTokens.gold),
            minHeight: 3,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _IaBtn(
                label: 'Vérifier & relier',
                background: GwTokens.gold,
                foreground: GwTokens.inkOnGold,
                onTap: onAccept,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onReject,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: Text(
                  'Ignorer',
                  style: GwType.ui(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: t.stoneDim,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 4) Carte incohérence : fond ember 8 % (avertissement doux, jamais de
/// rouge dur), icône ⚠, titre gras, détail gris, lien « Corriger → ».
class _InconsistencyCard extends StatelessWidget {
  final TreeInconsistency inconsistency;
  final VoidCallback onFix;

  const _InconsistencyCard({
    required this.inconsistency,
    required this.onFix,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GwTokens.ember.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GwTokens.ember.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Symbols.warning, size: 15, color: t.emberText),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inconsistency.title,
                  style: GwType.ui(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: t.stone,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  inconsistency.detail,
                  style: GwType.ui(
                    fontSize: 11.5,
                    color: t.stoneDim,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: onFix,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 2, vertical: 2),
                    child: Text(
                      'Corriger →',
                      style: GwType.ui(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: t.emberText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 5) Section « VEILLE DE L'ARBRE » (maquette 4c) : anneau de complétude,
/// manques principaux, bouton pointillé « Compléter en 5 questions » et
/// mini-tuiles doublons (rose) / incohérences (ember).
class _TreeWatchSection extends StatelessWidget {
  final TreeInsights insights;
  final String lineageName;
  final VoidCallback onCompleteFive;
  final VoidCallback onMerge;
  final VoidCallback onVerify;

  const _TreeWatchSection({
    required this.insights,
    required this.lineageName,
    required this.onCompleteFive,
    required this.onMerge,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final pct = insights.completenessPct.clamp(0, 100);
    final dupCount = insights.duplicates.length;
    final incCount = insights.inconsistencies.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "VEILLE DE L'ARBRE",
          style: GwType.mono(
            fontSize: 10,
            letterSpacing: 2,
            color: t.stoneFaint,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),

        // ── Complétude : anneau or + manques principaux ──
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: t.inkCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: CustomPaint(
                      painter: _CompletenessRingPainter(
                        fraction: pct / 100,
                        trackColor: t.line,
                        arcColor: GwTokens.gold,
                      ),
                      child: Center(
                        child: Text(
                          '$pct%',
                          style: GwType.display(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: t.stone,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Complétude de la lignée $lineageName',
                          style: GwType.ui(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: t.stone,
                          ),
                        ),
                        if (insights.missingHighlights.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          for (final h in insights.missingHighlights)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                '· $h',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GwType.ui(
                                    fontSize: 11, color: t.stoneDim),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Compléter en 5 questions (pointillé or) ──
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
                      onTap: onCompleteFive,
                      borderRadius: BorderRadius.circular(GwTokens.rBtn),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Symbols.help, size: 14, color: t.goldText),
                          const SizedBox(width: 5),
                          Text(
                            'Compléter en 5 questions',
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
        ),

        // ── Mini-tuiles doublons / incohérences (masquées à 0) ──
        if (dupCount > 0 || incCount > 0) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (dupCount > 0)
                Expanded(
                  child: _WatchTile(
                    count: dupCount,
                    label: dupCount > 1
                        ? 'Doublons probables'
                        : 'Doublon probable',
                    tint: GwTokens.rose,
                    linkLabel: 'Fusionner →',
                    onTap: onMerge,
                  ),
                ),
              if (dupCount > 0 && incCount > 0) const SizedBox(width: 12),
              if (incCount > 0)
                Expanded(
                  child: _WatchTile(
                    count: incCount,
                    label: incCount > 1 ? 'Incohérences' : 'Incohérence',
                    tint: GwTokens.ember,
                    linkText: t.emberText,
                    linkLabel: 'Vérifier →',
                    onTap: onVerify,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Mini-tuile de veille : grand nombre serif teinté, libellé, sous-lien.
class _WatchTile extends StatelessWidget {
  final int count;
  final String label;
  final Color tint;
  final Color? linkText;
  final String linkLabel;
  final VoidCallback onTap;

  const _WatchTile({
    required this.count,
    required this.label,
    required this.tint,
    required this.linkLabel,
    required this.onTap,
    this.linkText,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final link = linkText ?? tint;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tint.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count',
            style: GwType.display(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: link,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GwType.ui(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: t.stone,
            ),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                linkLabel,
                style: GwType.ui(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: link,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Anneau de complétude : arc or sur piste [trackColor], extrémités rondes.
class _CompletenessRingPainter extends CustomPainter {
  final double fraction;
  final Color trackColor;
  final Color arcColor;

  const _CompletenessRingPainter({
    required this.fraction,
    required this.trackColor,
    required this.arcColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 5.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - stroke) / 2;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, track);

    final f = fraction.clamp(0.0, 1.0);
    if (f <= 0) return;
    final arc = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * f,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _CompletenessRingPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.arcColor != arcColor;
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
  late final TextEditingController _dateCtrl;
  // ── Origine — ancre de la lignée ──
  late final TextEditingController _originVillageCtrl;
  late final TextEditingController _originCityCtrl;
  late final TextEditingController _originRegionCtrl;
  // Pays d'origine — stocké en ISO-2 (CountryModel.iso2).
  CountryModel? _originCountry;
  late final String? _initialOriginCountryIso2;
  late final TextEditingController _clanCtrl;
  late final TextEditingController _totemCtrl;
  late final TextEditingController _languageCtrl;
  late final TextEditingController _birthPlaceCtrl;
  // ── Évolution — aujourd'hui ──
  late final TextEditingController _residenceCityCtrl;
  // Pays de résidence — stocké en ISO-2 (CountryModel.iso2).
  CountryModel? _residenceCountry;
  late final String? _initialResidenceCountryIso2;
  late final TextEditingController _professionCtrl;
  late final TextEditingController _religionCtrl;
  late final TextEditingController _maritalStatusCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
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
    _originVillageCtrl = TextEditingController(text: p.originVillage ?? '');
    _originCityCtrl = TextEditingController(text: p.originCity ?? '');
    _originRegionCtrl = TextEditingController(text: p.originRegion ?? '');
    _initialOriginCountryIso2 = p.originCountry?.trim().toUpperCase();
    _clanCtrl = TextEditingController(text: p.clan ?? '');
    _totemCtrl = TextEditingController(text: p.totem ?? '');
    _languageCtrl = TextEditingController(text: p.nativeLanguage ?? '');
    _birthPlaceCtrl = TextEditingController(text: p.birthPlace ?? '');
    _residenceCityCtrl = TextEditingController(text: p.residenceCity ?? '');
    _initialResidenceCountryIso2 = p.residenceCountry?.trim().toUpperCase();
    _professionCtrl = TextEditingController(text: p.profession ?? '');
    _religionCtrl = TextEditingController(text: p.religion ?? '');
    _maritalStatusCtrl = TextEditingController(text: p.maritalStatus ?? '');
    _phoneCtrl = TextEditingController(text: p.phone ?? '');
    _emailCtrl = TextEditingController(text: p.email ?? '');
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
    _dateCtrl.dispose();
    _originVillageCtrl.dispose();
    _originCityCtrl.dispose();
    _originRegionCtrl.dispose();
    _clanCtrl.dispose();
    _totemCtrl.dispose();
    _languageCtrl.dispose();
    _birthPlaceCtrl.dispose();
    _residenceCityCtrl.dispose();
    _professionCtrl.dispose();
    _religionCtrl.dispose();
    _maritalStatusCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  /// Intitulé de section mono MAJ (mêmes intitulés que la fiche de vie).
  /// Eyebrow de section « éditorial » : chiffre romain italique (Fraunces) +
  /// libellé mono + filet dégradé (un fil qui s'estompe). Couleurs GwTokens.
  Widget _eyebrow(String roman, String label, Color color) {
    final t = GwTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Row(
        children: [
          Text('$roman.', style: GwType.quote(fontSize: 15, color: color)),
          const SizedBox(width: 9),
          Text(label.toUpperCase(),
              style: GwType.mono(
                  fontSize: 10, letterSpacing: 2.4, color: t.stoneDim)),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient:
                    LinearGradient(colors: [t.line, Colors.transparent]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Puces vivantes de l'origine (Village · Département · Région) alimentées
  /// par les champs texte, mises à jour à chaque sélection dans le référentiel.
  Widget _originChips(GwTokens t) {
    final chips = <Widget>[];
    void add(String k, String val, bool primary) {
      if (val.trim().isEmpty) return;
      chips.add(Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
        decoration: BoxDecoration(
          color: primary ? t.goldBg : t.inkLift,
          borderRadius: BorderRadius.circular(GwTokens.rPill),
          border: Border.all(color: primary ? t.goldLine : t.line),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(k.toUpperCase(),
              style: GwType.mono(
                  fontSize: 8.5, letterSpacing: 1.2, color: t.stoneFaint)),
          const SizedBox(width: 7),
          Text(val.trim(),
              style: GwType.ui(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: primary ? t.goldText : t.stone)),
        ]),
      ));
    }

    add('Village', _originVillageCtrl.text, true);
    add('Département', _originCityCtrl.text, false);
    add('Région', _originRegionCtrl.text, false);
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }

  /// Retrouve un CountryModel par ISO-2 (insensible à la casse).
  CountryModel? _findByIso2(List<CountryModel> countries, String? iso2) {
    if (iso2 == null || iso2.isEmpty) return null;
    final target = iso2.toUpperCase();
    for (final c in countries) {
      if ((c.iso2 ?? '').toUpperCase() == target) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    // Pré-remplissage des sélecteurs de pays dès que la liste est chargée.
    final countries = ref.watch(countriesNotifierProvider).valueOrNull;
    if (countries != null) {
      _originCountry ??= _findByIso2(countries, _initialOriginCountryIso2);
      _residenceCountry ??= _findByIso2(countries, _initialResidenceCountryIso2);
    }
    return GwDialog(
      title: 'Modifier la fiche',
      icon: Symbols.edit,
      subtitle: '${widget.person.firstName} ${widget.person.lastName}'.trim(),
      maxWidth: 560,
      actions: [
        GwDialogAction(
          label: 'Annuler',
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
        ),
        GwDialogAction(
          label: 'Enregistrer',
          icon: Symbols.check,
          primary: true,
          loading: _loading,
          onPressed: _loading ? null : _submit,
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
                _hero(context, t),
                const SizedBox(height: 4),
                _eyebrow('i', 'Identité', t.goldText),
                TextFormField(
                  controller: _firstNameCtrl,
                  decoration: const InputDecoration(labelText: 'Prénom *', prefixIcon: Icon(Symbols.person)),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastNameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom *', prefixIcon: Icon(Symbols.badge)),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                  onChanged: (_) => setState(() {}),
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
                _pillField(context, t, Symbols.favorite, 'Statut', const {
                  'ALIVE': 'Vivant(e)',
                  'DECEASED': 'In memoriam',
                }, _status, (v) => setState(() => _status = v)),

                // ── ORIGINE — ANCRE DE LA LIGNÉE ──
                _eyebrow('ii', 'Origine — ancre de la lignée', t.goldText),
                Text(
                    'Cherchez la chefferie dans le référentiel — c\'est ce qui rattache la fiche à sa lignée.',
                    style:
                        GwType.ui(fontSize: 12, color: t.stoneDim, height: 1.4)),
                const SizedBox(height: 10),
                // Panneau « archive » incrusté : recherche référentielle.
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: t.inkDeep,
                    borderRadius: BorderRadius.circular(GwTokens.rCard),
                    border: Border.all(color: t.goldLine),
                  ),
                  child: OriginCascadeSelector(
                    initial: OriginSelection(
                      regionName: _originRegionCtrl.text.trim().isEmpty
                          ? null
                          : _originRegionCtrl.text.trim(),
                      departmentName: _originCityCtrl.text.trim().isEmpty
                          ? null
                          : _originCityCtrl.text.trim(),
                      chefferieName: _originVillageCtrl.text.trim().isEmpty
                          ? null
                          : _originVillageCtrl.text.trim(),
                    ),
                    onChanged: (sel) {
                      setState(() {
                        if (sel.chefferieName != null) {
                          _originVillageCtrl.text = sel.chefferieName!;
                        }
                        final city =
                            sel.arrondissementName ?? sel.departmentName;
                        if (city != null) _originCityCtrl.text = city;
                        if (sel.regionName != null) {
                          _originRegionCtrl.text = sel.regionName!;
                        }
                      });
                    },
                  ),
                ),
                _originChips(t),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _originVillageCtrl,
                  decoration: const InputDecoration(labelText: "Village d'origine", prefixIcon: Icon(Symbols.holiday_village)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _originCityCtrl,
                  decoration: const InputDecoration(labelText: "Ville d'origine", prefixIcon: Icon(Symbols.location_city)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _originRegionCtrl,
                  decoration: const InputDecoration(labelText: "Région d'origine", prefixIcon: Icon(Symbols.map)),
                ),
                const SizedBox(height: 12),
                CountrySelector(
                  label: "Pays d'origine",
                  hint: 'Choisir un pays',
                  value: _originCountry,
                  onChanged: (c) => setState(() => _originCountry = c),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _clanCtrl,
                  decoration: const InputDecoration(labelText: 'Clan', prefixIcon: Icon(Symbols.groups)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _totemCtrl,
                  decoration: const InputDecoration(labelText: 'Totem', prefixIcon: Icon(Symbols.pets)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _languageCtrl,
                  decoration: const InputDecoration(labelText: 'Langue maternelle', prefixIcon: Icon(Symbols.language)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _birthPlaceCtrl,
                  decoration: const InputDecoration(labelText: 'Lieu de naissance', prefixIcon: Icon(Symbols.location_on)),
                ),

                // ── ÉVOLUTION — AUJOURD'HUI ──
                _eyebrow('iii', 'Vie — aujourd\'hui', t.sageText),
                TextFormField(
                  controller: _residenceCityCtrl,
                  decoration: const InputDecoration(labelText: 'Ville de résidence', prefixIcon: Icon(Symbols.home)),
                ),
                const SizedBox(height: 12),
                CountrySelector(
                  label: 'Pays de résidence',
                  hint: 'Choisir un pays',
                  value: _residenceCountry,
                  onChanged: (c) => setState(() => _residenceCountry = c),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _professionCtrl,
                  decoration: const InputDecoration(labelText: 'Profession', prefixIcon: Icon(Symbols.work)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _religionCtrl,
                  decoration: const InputDecoration(labelText: 'Religion', prefixIcon: Icon(Symbols.church)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _maritalStatusCtrl,
                  decoration: const InputDecoration(labelText: 'Statut marital', prefixIcon: Icon(Symbols.favorite)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Téléphone', prefixIcon: Icon(Symbols.call)),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Symbols.mail)),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _pillField(context, t, Symbols.visibility, 'Visibilité', const {
                  'FAMILY_ONLY': 'Famille',
                  'MEMBERS_ONLY': 'Village',
                  'PUBLIC': 'Public',
                }, _privacy, (v) => setState(() => _privacy = v)),
          ],
        ),
      ),
    );
  }

  /// Hero « médaillon » : disque or (dégradé conique) + initiales serif vivantes,
  /// sur un fond de fils de chaîne tissés (motif Tissage). Couleurs GwTokens.
  Widget _hero(BuildContext context, GwTokens t) {
    final f = _firstNameCtrl.text.trim();
    final l = _lastNameCtrl.text.trim();
    final ini =
        ((f.isNotEmpty ? f[0] : '') + (l.isNotEmpty ? l[0] : '')).toUpperCase();
    final full = '$f $l'.trim();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.goldGlow, t.goldBg],
        ),
        borderRadius: BorderRadius.circular(GwTokens.rCardLg),
        border: Border.all(color: t.goldLine),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(GwTokens.rCardLg),
              child: CustomPaint(painter: _LoomAccentPainter()),
            ),
          ),
          Row(
            children: [
              // Médaillon : anneau or conique + disque ink + initiales.
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const SweepGradient(
                    startAngle: 3.6,
                    endAngle: 3.6 + 6.283,
                    colors: [
                      GwTokens.goldDeep,
                      GwTokens.goldLight,
                      GwTokens.gold,
                      GwTokens.goldDeep,
                    ],
                    stops: [0.0, 0.35, 0.72, 1.0],
                  ),
                  boxShadow: [BoxShadow(color: t.goldGlow, blurRadius: 22)],
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: t.inkCard,
                    border: Border.all(color: t.goldLine),
                  ),
                  alignment: Alignment.center,
                  child: Text(ini.isEmpty ? '?' : ini,
                      style: GwType.display(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: t.goldText)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(full.isEmpty ? 'Nouvelle fiche' : full,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GwType.display(fontSize: 19, color: t.stone)),
                    const SizedBox(height: 3),
                    Text('FICHE GÉNÉALOGIQUE',
                        style: GwType.mono(
                            fontSize: 9, letterSpacing: 2, color: t.goldText)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Champ « pilules » (choix unique) : libellé mono + pilules or tactiles.
  Widget _pillField(BuildContext context, GwTokens t, IconData icon,
      String label, Map<String, String> options, String selected,
      ValueChanged<String> onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 15, color: t.stoneDim),
          const SizedBox(width: 7),
          Text(label.toUpperCase(),
              style: GwType.mono(
                  fontSize: 10, letterSpacing: 1.5, color: t.stoneDim)),
        ]),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.entries.map((e) {
            final active = e.key == selected;
            return GestureDetector(
              onTap: () => onSelect(e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  gradient: active
                      ? const LinearGradient(
                          colors: [GwTokens.goldLight, GwTokens.gold])
                      : null,
                  color: active ? null : t.inkLift,
                  borderRadius: BorderRadius.circular(GwTokens.rPill),
                  border:
                      Border.all(color: active ? Colors.transparent : t.line),
                ),
                child: Text(e.value,
                    style: GwType.ui(
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? GwTokens.inkOnGold : t.stoneMid)),
              ),
            );
          }).toList(),
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
      final p = widget.person;
      final data = <String, dynamic>{
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'isAlive': _status == 'ALIVE',
        'privacy': _privacy,
      };
      if (_birthDate != null) {
        data['birthDate'] = _birthDate!.toIso8601String().split('T').first;
      }

      // Seuls les champs modifiés ET non vides partent (clés camelCase).
      void addIfChanged(String key, String raw, String? original,
          {bool upper = false}) {
        var v = raw.trim();
        if (upper) v = v.toUpperCase();
        if (v.isEmpty) return;
        if (v == (original ?? '').trim()) return;
        data[key] = v;
      }

      // ── Origine — ancre de la lignée ──
      addIfChanged('originVillage', _originVillageCtrl.text, p.originVillage);
      addIfChanged('originCity', _originCityCtrl.text, p.originCity);
      addIfChanged('originRegion', _originRegionCtrl.text, p.originRegion);
      // Pays d'origine — envoyer l'ISO-2 du pays sélectionné s'il a changé.
      final originIso2 = _originCountry?.iso2?.toUpperCase();
      if (originIso2 != null &&
          originIso2.isNotEmpty &&
          originIso2 != (_initialOriginCountryIso2 ?? '')) {
        data['originCountry'] = originIso2;
      }
      addIfChanged('clan', _clanCtrl.text, p.clan);
      addIfChanged('totem', _totemCtrl.text, p.totem);
      addIfChanged('nativeLanguage', _languageCtrl.text, p.nativeLanguage);
      addIfChanged('birthPlace', _birthPlaceCtrl.text, p.birthPlace);
      // ── Évolution — aujourd'hui ──
      addIfChanged('residenceCity', _residenceCityCtrl.text, p.residenceCity);
      // Pays de résidence — envoyer l'ISO-2 du pays sélectionné s'il a changé.
      final residenceIso2 = _residenceCountry?.iso2?.toUpperCase();
      if (residenceIso2 != null &&
          residenceIso2.isNotEmpty &&
          residenceIso2 != (_initialResidenceCountryIso2 ?? '')) {
        data['residenceCountry'] = residenceIso2;
      }
      addIfChanged('profession', _professionCtrl.text, p.profession);
      addIfChanged('religion', _religionCtrl.text, p.religion);
      addIfChanged('maritalStatus', _maritalStatusCtrl.text, p.maritalStatus);
      addIfChanged('phone', _phoneCtrl.text, p.phone);
      addIfChanged('email', _emailCtrl.text, p.email);

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

/// Fond décoratif « fils de chaîne » (motif Tissage) du hero de la fiche :
/// fils verticaux or discrets + petites trames. Uniquement des couleurs GwTokens.
class _LoomAccentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final warp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const n = 8;
    for (int i = 0; i < n; i++) {
      final x = size.width * (i + 0.5) / n;
      warp.color = GwTokens.gold.withValues(alpha: i.isEven ? 0.08 : 0.05);
      final path = Path();
      for (double y = 0; y <= size.height; y += 4) {
        final px = x + 1.3 * math.sin(y / 20 + i);
        if (y == 0) {
          path.moveTo(px, y);
        } else {
          path.lineTo(px, y);
        }
      }
      canvas.drawPath(path, warp);
    }
    final weft = Paint()..color = GwTokens.gold.withValues(alpha: 0.07);
    for (int i = 0; i < n; i++) {
      final x = size.width * (i + 0.5) / n;
      for (double y = (i.isEven ? 6.0 : 16.0); y < size.height; y += 26) {
        canvas.drawRect(Rect.fromLTWH(x - 3, y, 6, 1.3), weft);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LoomAccentPainter oldDelegate) => false;
}
