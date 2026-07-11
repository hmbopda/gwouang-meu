import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/shared/models/country_model.dart';
import 'package:gwangmeu/shared/models/language_model.dart';
import 'package:gwangmeu/shared/widgets/country_selector.dart';
import 'package:gwangmeu/features/genealogy/widgets/dialogs/origin_cascade_selector.dart';
import 'package:gwangmeu/features/genealogy/models/person_genealogy.dart';
import 'package:gwangmeu/features/genealogy/services/genealogy_api_service.dart';
import 'package:gwangmeu/features/geo/geo_notifier.dart';
import 'package:gwangmeu/features/profile/profile_notifier.dart';

/// Formulaire complet d'edition du profil — ouvert en bottom sheet plein ecran.
/// Style « Tissage » : titres Fraunces, labels JetBrains Mono MAJUSCULES,
/// inputs inkLift rayon 14 focus or, choix en pilules goldBg/goldLine.
class ProfileEditSheet extends ConsumerStatefulWidget {
  const ProfileEditSheet({super.key});

  @override
  ConsumerState<ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends ConsumerState<ProfileEditSheet> {
  final _formKey = GlobalKey<FormState>();
  int _currentSection = 0;

  // ── Controleurs ──────────────────────────────────────────────────────────
  // Identite
  final _displayNameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  // Parents (Person entities from genealogy)
  PersonGenealogy? _selectedFather;
  PersonGenealogy? _selectedMother;

  // Inline parent creation
  String? _creatingParentFor; // 'FATHER' or 'MOTHER', null = not creating
  final _createFormKey = GlobalKey<FormState>();
  final _createFirstNameCtrl = TextEditingController();
  final _createLastNameCtrl = TextEditingController();
  final _createClanCtrl = TextEditingController();
  final _createEmailCtrl = TextEditingController();
  bool _createIsAlive = true;
  bool _createLoading = false;

  // Situation familiale
  String? _maritalStatus;
  final _childrenCountCtrl = TextEditingController();
  String? _matrimonialRegime;

  // Origines & Culture
  CountryModel? _selectedCountry;
  String? _selectedCountryIso; // pour charger les langues
  // Origine référentielle (ancre de la lignée) — atteint n'importe quelle
  // chefferie du référentiel (dont Bandenkop).
  OriginSelection _originSelection = const OriginSelection();
  final _originVillageFreeCtrl = TextEditingController(); // pays hors référentiel
  LanguageModel? _selectedLanguage;
  final List<String> _selectedClans = [];
  final _clanInputCtrl = TextEditingController();
  final _tribeCtrl = TextEditingController();

  // Vie professionnelle & Residence
  final _professionCtrl = TextEditingController();
  final _employerCtrl = TextEditingController();
  final _residenceCityCtrl = TextEditingController();
  // Pays de résidence — stocké côté user par NOM (cohérent avec `country`).
  CountryModel? _selectedResidenceCountry;
  String? _initialResidenceCountryName;

  // Preferences
  String? _diet;

  // Parents chargés depuis l'arbre
  bool _parentsLoading = false;

  // Enfants
  final List<PersonGenealogy> _children = [];
  bool _childrenLoading = false;
  // Inline child creation
  bool _creatingChild = false;
  final _createChildFormKey = GlobalKey<FormState>();
  final _createChildFirstNameCtrl = TextEditingController();
  final _createChildLastNameCtrl = TextEditingController();
  final _createChildClanCtrl = TextEditingController();
  final _createChildEmailCtrl = TextEditingController();
  String _createChildGender = 'MALE';
  DateTime? _createChildBirthDate;
  bool _createChildLoading = false;

  List<String> get _sections {
    final base = ['Identite', 'Parents', 'Famille'];
    final declared = int.tryParse(_childrenCountCtrl.text.trim()) ?? 0;
    // Afficher l'onglet si enfants déclarés OU enfants déjà liés
    if (declared > 0 || _children.isNotEmpty) base.add('Enfants');
    base.addAll(['Origines', 'Residence & Metier']);
    return base;
  }

  static const _maritalOptions = [
    'Celibataire',
    'Marie(e)',
    'Concubinage',
    'Divorce(e)',
    'Veuf / Veuve',
  ];

  static const _regimeOptions = [
    'Monogamie',
    'Polygamie',
    'Communaute de biens',
    'Separation de biens',
    'Non applicable',
  ];

  static const _dietOptions = [
    'Omnivore',
    'Vegetarien',
    'Vegan',
    'Halal',
    'Sans gluten',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-remplir les champs avec les donnees existantes du profil
    final profileState = ref.read(profileNotifierProvider);
    final user = profileState.valueOrNull;
    if (user != null) {
      // Identite
      _displayNameCtrl.text = user.displayName ?? '';
      _bioCtrl.text = user.bio ?? '';
      // Parents — loaded as PersonGenealogy from genealogy tree
      // Famille
      _maritalStatus = user.maritalStatus;
      _matrimonialRegime = user.matrimonialRegime;
      if (user.childrenCount != null) {
        _childrenCountCtrl.text = user.childrenCount.toString();
      }
      _diet = user.diet;
      // Origines — la langue sera pre-selectionnee dans _buildOriginsSection
      _tribeCtrl.text = user.tribe ?? '';
      if (user.clan != null && user.clan!.isNotEmpty) {
        _selectedClans.addAll(user.clan!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
      }
      // Origine référentielle (ancre de la lignée)
      _originSelection = OriginSelection(
        regionName: user.originRegion,
        departmentName: user.originDepartment,
        arrondissementName: user.originArrondissement,
        chefferieName: user.originVillage,
      );
      _originVillageFreeCtrl.text = user.originVillage ?? '';
      // Residence & Metier
      _professionCtrl.text = user.profession ?? '';
      _employerCtrl.text = user.employer ?? '';
      _residenceCityCtrl.text = user.residenceCity ?? '';
      _initialResidenceCountryName = user.residenceCountry;
    }
    // Charger parents + enfants liés après le premier frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLinkedFamilyTree());
  }

  Future<void> _loadLinkedFamilyTree() async {
    if (!mounted) return;
    setState(() {
      _parentsLoading = true;
      _childrenLoading = true;
    });
    try {
      final api = ref.read(genealogyApiServiceProvider);
      final myPerson = await api.getMyPerson();
      final tree = await api.getFullTree(myPerson.id);
      if (!mounted) return;
      setState(() {
        // Parents — prendre le premier de chaque liste (père/mère)
        if (_selectedFather == null && tree.father.isNotEmpty) {
          _selectedFather = tree.father.first;
        }
        if (_selectedMother == null && tree.mother.isNotEmpty) {
          _selectedMother = tree.mother.first;
        }
        // Enfants liés
        _children.clear();
        _children.addAll(tree.children);
        // Mettre à jour childrenCount si dépassé
        final declared = int.tryParse(_childrenCountCtrl.text.trim()) ?? 0;
        if (tree.children.length > declared) {
          _childrenCountCtrl.text = tree.children.length.toString();
        }
      });
    } catch (_) {
      // ignore
    } finally {
      if (mounted) {
        setState(() {
          _parentsLoading = false;
          _childrenLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _bioCtrl.dispose();
    _childrenCountCtrl.dispose();
    _clanInputCtrl.dispose();
    _tribeCtrl.dispose();
    _originVillageFreeCtrl.dispose();
    _professionCtrl.dispose();
    _employerCtrl.dispose();
    _residenceCityCtrl.dispose();
    _createFirstNameCtrl.dispose();
    _createLastNameCtrl.dispose();
    _createClanCtrl.dispose();
    _createEmailCtrl.dispose();
    _createChildFirstNameCtrl.dispose();
    _createChildLastNameCtrl.dispose();
    _createChildClanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: t.ink,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(GwTokens.rCardLg)),
        border: Border(top: BorderSide(color: t.line)),
      ),
      child: Column(
        children: [
          // ── Handle + Header ──────────────────────────────────────────────
          _buildHeader(context),
          // ── Section tabs ─────────────────────────────────────────────────
          _buildSectionTabs(context),
          // ── Form body ────────────────────────────────────────────────────
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomInset),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _buildCurrentSection(context),
                ),
              ),
            ),
          ),
          // ── Bottom actions ───────────────────────────────────────────────
          _buildBottomBar(context),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // HEADER — titre Fraunces + fermer 44 px
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(BuildContext context) {
    final t = GwTokens.of(context);
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: t.lineMid,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 10, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Modifier mon profil',
                  style: GwType.display(fontSize: 21, color: t.stone),
                ),
              ),
              SizedBox(
                width: GwTokens.tapTarget,
                height: GwTokens.tapTarget,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(Symbols.close, size: 24, color: t.stoneMid),
                  tooltip: 'Fermer',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SECTION TABS — pilules or
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildSectionTabs(BuildContext context) {
    final t = GwTokens.of(context);
    return SizedBox(
      height: GwTokens.tapTarget,
      child: Padding(
        padding: const EdgeInsets.only(top: 0),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _sections.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final active = i == _currentSection;
            return GestureDetector(
              onTap: () => setState(() => _currentSection = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? t.goldBg : t.inkLift,
                  borderRadius: BorderRadius.circular(GwTokens.rPill),
                  border: Border.all(color: active ? t.goldLine : t.line),
                ),
                child: Text(
                  _sections[i],
                  style: GwType.ui(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? t.goldText : t.stoneMid,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SECTION CONTENT
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildCurrentSection(BuildContext context) {
    final sectionName = _sections[_currentSection];
    switch (sectionName) {
      case 'Identite':
        return _buildIdentitySection(context);
      case 'Parents':
        return _buildParentsSection(context);
      case 'Famille':
        return _buildFamilySection(context);
      case 'Enfants':
        return _buildChildrenSection(context);
      case 'Origines':
        return _buildOriginsSection(context);
      case 'Residence & Metier':
        return _buildResidenceSection(context);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── 1. Identite ──────────────────────────────────────────────────────────

  Widget _buildIdentitySection(BuildContext context) {
    return Column(
      key: const ValueKey('identity'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, Symbols.person, 'Informations personnelles'),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _displayNameCtrl,
          label: 'Nom complet',
          hint: 'Ex: Jean-Pierre Mbopda',
          icon: Symbols.badge,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _bioCtrl,
          label: 'Bio / A propos',
          hint: 'Parlez de vous en quelques mots...',
          icon: Symbols.notes,
          maxLines: 3,
          maxLength: 200,
        ),
      ],
    );
  }

  // ── 2. Parents ───────────────────────────────────────────────────────────

  Widget _buildParentsSection(BuildContext context) {
    final t = GwTokens.of(context);
    return Column(
      key: const ValueKey('parents'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, Symbols.family_restroom, 'Informations parentales'),
        const SizedBox(height: 8),
        if (_parentsLoading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: GwTokens.gold),
                ),
                const SizedBox(width: 8),
                Text(
                  'Chargement des parents liés...',
                  style: GwType.ui(fontSize: 12, color: t.stoneDim),
                ),
              ],
            ),
          )
        else
          Text(
            _selectedFather == null && _selectedMother == null
                ? 'Sélectionnez un membre existant d\'un de vos clans ou créez une nouvelle fiche.'
                : 'Parents liés à votre arbre généalogique. Vous pouvez modifier leurs informations.',
            style: GwType.ui(fontSize: 12, color: t.stoneDim),
          ),
        const SizedBox(height: 16),
        _parentCard(
          context,
          title: 'Père',
          icon: Symbols.man,
          selectedPerson: _selectedFather,
          gender: 'MALE',
          role: 'FATHER',
          onSelected: (p) => setState(() => _selectedFather = p),
          onCleared: () => setState(() => _selectedFather = null),
          onEdit: _selectedFather != null
              ? () => _showEditParentDialog(context, _selectedFather!, 'FATHER')
              : null,
        ),
        const SizedBox(height: 16),
        _parentCard(
          context,
          title: 'Mère',
          icon: Symbols.woman,
          selectedPerson: _selectedMother,
          gender: 'FEMALE',
          role: 'MOTHER',
          onSelected: (p) => setState(() => _selectedMother = p),
          onCleared: () => setState(() => _selectedMother = null),
          onEdit: _selectedMother != null
              ? () => _showEditParentDialog(context, _selectedMother!, 'MOTHER')
              : null,
        ),
      ],
    );
  }

  Widget _parentCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required PersonGenealogy? selectedPerson,
    required String gender,
    required String role,
    required ValueChanged<PersonGenealogy> onSelected,
    required VoidCallback onCleared,
    required VoidCallback? onEdit,
  }) {
    final t = GwTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.inkCard,
        borderRadius: BorderRadius.circular(GwTokens.rCard),
        border: Border.all(color: t.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: t.goldText, fill: 1),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: GwType.mono(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: t.stoneMid,
                ),
              ),
              const Spacer(),
              if (selectedPerson != null)
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 32),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: t.goldBg,
                      borderRadius: BorderRadius.circular(GwTokens.rPill),
                      border: Border.all(color: t.goldLine),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Symbols.edit, size: 14, color: t.goldText),
                        const SizedBox(width: 4),
                        Text('Modifier', style: GwType.ui(fontSize: 12, color: t.goldText)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (selectedPerson != null) ...[
            // Show selected person
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: t.goldBg,
                borderRadius: BorderRadius.circular(GwTokens.rBtn),
                border: Border.all(color: t.goldLine),
              ),
              child: Row(
                children: [
                  _initialAvatar(context, selectedPerson.firstName, radius: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${selectedPerson.firstName} ${selectedPerson.lastName}',
                          style: GwType.ui(fontSize: 14, fontWeight: FontWeight.w600, color: t.stone),
                        ),
                        if (selectedPerson.clan != null)
                          Text(
                            'Clan: ${selectedPerson.clan}',
                            style: GwType.ui(fontSize: 12, color: t.stoneMid),
                          ),
                      ],
                    ),
                  ),
                  Icon(Symbols.check_circle, color: t.goldText, size: 20, fill: 1),
                ],
              ),
            ),
          ] else if (_creatingParentFor == role) ...[
            // Inline creation form
            _buildInlineCreateForm(gender, role, onSelected),
          ] else if (selectedPerson == null) ...[
            // Boutons d'ajout uniquement si aucun parent lié
            Row(
              children: [
                Expanded(
                  child: _actionBtn(
                    context,
                    icon: Symbols.search,
                    label: 'Chercher dans le clan',
                    onTap: () => _showSearchParentDialog(context, gender, role, onSelected),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _actionBtn(
                    context,
                    icon: Symbols.person_add,
                    label: 'Créer une fiche',
                    onTap: () => _startInlineCreate(role),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionBtn(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    final t = GwTokens.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: t.inkLift,
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          border: Border.all(color: t.line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: t.goldText),
            const SizedBox(height: 6),
            Text(
              label,
              style: GwType.ui(fontSize: 12, fontWeight: FontWeight.w600, color: t.stone),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditParentDialog(BuildContext context, PersonGenealogy parent, String role) {
    final firstNameCtrl = TextEditingController(text: parent.firstName);
    final lastNameCtrl = TextEditingController(text: parent.lastName);
    final clanCtrl = TextEditingController(text: parent.clan ?? '');
    bool loading = false;

    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (dCtx) => StatefulBuilder(
        builder: (dCtx, setDState) {
          final t = GwTokens.of(dCtx);
          return _tissageDialog(
            dCtx,
            icon: Symbols.edit,
            title: role == 'FATHER' ? 'Modifier le père' : 'Modifier la mère',
            children: [
              TextField(
                controller: firstNameCtrl,
                style: GwType.ui(fontSize: 14, color: t.stone),
                decoration: _decor(dCtx, label: 'Prénom', icon: Symbols.person),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: lastNameCtrl,
                style: GwType.ui(fontSize: 14, color: t.stone),
                decoration: _decor(dCtx, label: 'Nom', icon: Symbols.badge),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: clanCtrl,
                style: GwType.ui(fontSize: 14, color: t.stone),
                decoration: _decor(dCtx, label: 'Clan', icon: Symbols.shield),
              ),
            ],
            actions: [
              _dialogPrimaryBtn(
                dCtx,
                label: 'Enregistrer',
                icon: Symbols.check,
                loading: loading,
                onPressed: loading
                    ? null
                    : () async {
                        setDState(() => loading = true);
                        try {
                          final api = ref.read(genealogyApiServiceProvider);
                          final updated = await api.updatePerson(parent.id, {
                            'firstName': firstNameCtrl.text.trim(),
                            'lastName': lastNameCtrl.text.trim(),
                            if (clanCtrl.text.trim().isNotEmpty) 'clan': clanCtrl.text.trim(),
                          });
                          if (mounted) {
                            setState(() {
                              if (role == 'FATHER') _selectedFather = updated;
                              if (role == 'MOTHER') _selectedMother = updated;
                            });
                          }
                          if (dCtx.mounted) Navigator.of(dCtx, rootNavigator: true).pop();
                        } catch (e) {
                          if (dCtx.mounted) {
                            ScaffoldMessenger.of(dCtx).showSnackBar(
                              SnackBar(
                                content: Text('Erreur: $e',
                                    style: GwType.ui(fontSize: 14, color: Colors.white)),
                                backgroundColor: GwTokens.ember,
                              ),
                            );
                          }
                        } finally {
                          if (dCtx.mounted) setDState(() => loading = false);
                        }
                      },
              ),
              _dialogGhostBtn(
                dCtx,
                label: 'Annuler',
                onPressed: loading ? null : () => Navigator.of(dCtx, rootNavigator: true).pop(),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSearchParentDialog(BuildContext context, String gender, String role, ValueChanged<PersonGenealogy> onSelected) {
    if (_selectedClans.isEmpty) {
      showDialog(
        context: context,
        useRootNavigator: true,
        builder: (dCtx) => _tissageDialog(
          dCtx,
          icon: Symbols.shield,
          title: 'Clan requis',
          children: [
            Text(
              'Veuillez d\'abord renseigner au moins un clan dans l\'onglet Origines avant de rechercher un parent.',
              style: GwType.ui(fontSize: 14, color: GwTokens.of(dCtx).stoneMid, height: 1.5),
            ),
          ],
          actions: [
            _dialogPrimaryBtn(
              dCtx,
              label: 'Aller aux Origines',
              icon: Symbols.arrow_forward,
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                final originesIndex = _sections.indexOf('Origines');
                if (originesIndex >= 0) setState(() => _currentSection = originesIndex);
              },
            ),
            _dialogGhostBtn(
              dCtx,
              label: 'Fermer',
              onPressed: () => Navigator.of(dCtx, rootNavigator: true).pop(),
            ),
          ],
        ),
      );
      return;
    }
    // Si un seul clan, rechercher directement ; sinon laisser choisir
    if (_selectedClans.length == 1) {
      _openSearchDialog(context, _selectedClans.first, gender, onSelected);
    } else {
      showDialog(
        context: context,
        useRootNavigator: true,
        builder: (dCtx) => _clanPickerDialog(
          dCtx,
          onClanPicked: (clan) {
            Navigator.of(context, rootNavigator: true).pop();
            _openSearchDialog(context, clan, gender, onSelected);
          },
        ),
      );
    }
  }

  /// Dialog de choix de clan — remplace le SimpleDialog historique.
  Widget _clanPickerDialog(BuildContext dCtx, {required ValueChanged<String> onClanPicked}) {
    final t = GwTokens.of(dCtx);
    return _tissageDialog(
      dCtx,
      icon: Symbols.shield,
      title: 'Dans quel clan chercher ?',
      children: [
        for (final clan in _selectedClans) ...[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onClanPicked(clan),
            child: Container(
              constraints: const BoxConstraints(minHeight: GwTokens.tapTarget),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: t.inkLift,
                borderRadius: BorderRadius.circular(GwTokens.rBtn),
                border: Border.all(color: t.line),
              ),
              child: Row(
                children: [
                  Icon(Symbols.shield, size: 18, color: t.goldText),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(clan, style: GwType.ui(fontSize: 15, color: t.stone)),
                  ),
                  Icon(Symbols.chevron_right, size: 20, color: t.stoneDim),
                ],
              ),
            ),
          ),
        ],
      ],
      actions: [
        _dialogGhostBtn(
          dCtx,
          label: 'Fermer',
          onPressed: () => Navigator.of(dCtx, rootNavigator: true).pop(),
        ),
      ],
    );
  }

  void _openSearchDialog(BuildContext context, String clan, String gender, ValueChanged<PersonGenealogy> onSelected) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (_) => _SearchParentDialog(
        clan: clan,
        gender: gender,
        onSelected: (person) {
          onSelected(person);
          Navigator.of(context, rootNavigator: true).pop();
        },
      ),
    );
  }

  void _startInlineCreate(String role) {
    _createFirstNameCtrl.clear();
    _createLastNameCtrl.clear();
    _createClanCtrl.text = _selectedClans.join(', ');
    _createEmailCtrl.clear();
    _createIsAlive = true;
    _createLoading = false;
    setState(() => _creatingParentFor = role);
  }

  Widget _buildInlineCreateForm(String gender, String role, ValueChanged<PersonGenealogy> onSelected) {
    final t = GwTokens.of(context);
    final title = gender == 'MALE' ? 'Nouvelle fiche Pere' : 'Nouvelle fiche Mere';
    return Form(
      key: _createFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                gender == 'MALE' ? Symbols.man : Symbols.woman,
                size: 16,
                color: t.goldText,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: GwType.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: t.goldText,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _createLoading ? null : () => setState(() => _creatingParentFor = null),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(Symbols.close, size: 18, color: t.stoneDim),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _createFirstNameCtrl,
            style: GwType.ui(fontSize: 14, color: t.stone),
            decoration: _decor(context, label: 'Prenom *', icon: Symbols.person),
            validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _createLastNameCtrl,
            style: GwType.ui(fontSize: 14, color: t.stone),
            decoration: _decor(context, label: 'Nom *', icon: Symbols.badge),
            validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _createClanCtrl,
            style: GwType.ui(fontSize: 14, color: t.stone),
            decoration: _decor(context, label: 'Clan', icon: Symbols.shield),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: t.inkLift,
              borderRadius: BorderRadius.circular(GwTokens.rBtn),
              border: Border.all(color: t.line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Encore en vie ?',
                        style: GwType.ui(fontSize: 14, fontWeight: FontWeight.w600, color: t.stone),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _createIsAlive
                            ? 'Un lien de validation sera envoye'
                            : 'La personne est decedee',
                        style: GwType.ui(fontSize: 12, color: t.stoneDim),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _createIsAlive,
                  activeThumbColor: GwTokens.gold,
                  activeTrackColor: t.goldBg,
                  onChanged: (v) => setState(() => _createIsAlive = v),
                ),
              ],
            ),
          ),
          if (_createIsAlive) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: _createEmailCtrl,
              style: GwType.ui(fontSize: 14, color: t.stone),
              decoration: _decor(
                context,
                label: 'Email *',
                icon: Symbols.mail,
                helper: 'Pour envoyer le lien d\'invitation',
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (!_createIsAlive) return null;
                if (v == null || v.trim().isEmpty) return 'Requis pour une personne vivante';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) return 'Email invalide';
                return null;
              },
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _secondaryBtn(
                  context,
                  label: 'Annuler',
                  onPressed: _createLoading ? null : () => setState(() => _creatingParentFor = null),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _primaryBtn(
                  context,
                  label: 'Creer',
                  icon: Symbols.check,
                  loading: _createLoading,
                  onPressed: _createLoading ? null : () => _submitInlineCreate(gender, role, onSelected),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitInlineCreate(String gender, String role, ValueChanged<PersonGenealogy> onSelected) async {
    if (!_createFormKey.currentState!.validate()) return;
    setState(() => _createLoading = true);
    try {
      final api = ref.read(genealogyApiServiceProvider);
      final person = await api.createPerson({
        'firstName': _createFirstNameCtrl.text.trim(),
        'lastName': _createLastNameCtrl.text.trim(),
        'gender': gender,
        if (_createClanCtrl.text.trim().isNotEmpty) 'clan': _createClanCtrl.text.trim(),
      });
      if (_createIsAlive && _createEmailCtrl.text.trim().isNotEmpty) {
        await api.invitePerson(
          personId: person.id,
          email: _createEmailCtrl.text.trim(),
        );
      }
      if (mounted) {
        setState(() => _creatingParentFor = null);
        onSelected(person);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Erreur: $e', GwTokens.ember);
      }
    } finally {
      if (mounted) setState(() => _createLoading = false);
    }
  }

  // ── 3. Famille ───────────────────────────────────────────────────────────

  Widget _buildFamilySection(BuildContext context) {
    return Column(
      key: const ValueKey('family'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, Symbols.favorite, 'Situation familiale'),
        const SizedBox(height: 16),
        _buildPillChoice(
          label: 'Situation maritale',
          icon: Symbols.favorite,
          value: _maritalStatus,
          options: _maritalOptions,
          onChanged: (v) => setState(() => _maritalStatus = v),
        ),
        const SizedBox(height: 18),
        _buildPillChoice(
          label: 'Regime matrimonial',
          icon: Symbols.gavel,
          value: _matrimonialRegime,
          options: _regimeOptions,
          onChanged: (v) => setState(() => _matrimonialRegime = v),
        ),
        const SizedBox(height: 18),
        _buildTextField(
          controller: _childrenCountCtrl,
          label: 'Nombre d\'enfants',
          hint: '0',
          icon: Symbols.child_care,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() {
            // Ajuste _currentSection si l'onglet Enfants disparait
            if (_currentSection >= _sections.length) {
              _currentSection = _sections.length - 1;
            }
          }),
        ),
        const SizedBox(height: 18),
        _buildPillChoice(
          label: 'Regime alimentaire',
          icon: Symbols.restaurant,
          value: _diet,
          options: _dietOptions,
          onChanged: (v) => setState(() => _diet = v),
        ),
      ],
    );
  }

  // ── 3b. Enfants ─────────────────────────────────────────────────────────

  Widget _buildChildrenSection(BuildContext context) {
    final t = GwTokens.of(context);
    final declared = int.tryParse(_childrenCountCtrl.text.trim()) ?? 0;
    final linked = _children.length;
    // Afficher le plus grand des deux : liés ou déclarés
    final displayed = linked > declared ? linked : declared;
    return Column(
      key: const ValueKey('children'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, Symbols.child_care, 'Mes enfants'),
        const SizedBox(height: 8),
        if (_childrenLoading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: GwTokens.gold),
                ),
                const SizedBox(width: 8),
                Text(
                  'Chargement des enfants liés...',
                  style: GwType.ui(fontSize: 12, color: t.stoneDim),
                ),
              ],
            ),
          )
        else
          Text(
            displayed == 0
                ? 'Aucun enfant déclaré. Ajoutez leurs fiches pour les lier à votre arbre.'
                : '$displayed enfant${displayed > 1 ? 's' : ''} (${linked > 0 ? '$linked lié${linked > 1 ? 's' : ''} à votre arbre' : 'aucun lié encore'}).',
            style: GwType.ui(fontSize: 12, color: t.stoneDim),
          ),
        const SizedBox(height: 16),
        // Liste des enfants deja lies
        ..._children.asMap().entries.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _childCard(context, entry.value, entry.key),
        )),
        // Formulaire inline de creation
        if (_creatingChild) ...[
          _buildInlineChildCreateForm(),
        ] else ...[
          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: _actionBtn(
                  context,
                  icon: Symbols.search,
                  label: 'Chercher existant',
                  onTap: () => _showSearchChildDialog(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionBtn(
                  context,
                  icon: Symbols.person_add,
                  label: 'Creer une fiche',
                  onTap: _startInlineChildCreate,
                ),
              ),
            ],
          ),
        ],
        if (_children.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: t.goldBg,
              borderRadius: BorderRadius.circular(GwTokens.rBtn),
              border: Border.all(color: t.goldLine),
            ),
            child: Row(
              children: [
                Icon(Symbols.info, size: 16, color: t.goldText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_children.length} enfant${_children.length > 1 ? 's' : ''} ajoute${_children.length > 1 ? 's' : ''}. '
                    'Ils seront lies a votre arbre genealogique.',
                    style: GwType.ui(fontSize: 12, color: t.stoneMid),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _childCard(BuildContext context, PersonGenealogy child, int index) {
    final t = GwTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.inkCard,
        borderRadius: BorderRadius.circular(GwTokens.rCard),
        border: Border.all(color: t.goldLine),
      ),
      child: Row(
        children: [
          _initialAvatar(context, child.firstName, radius: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${child.firstName} ${child.lastName}',
                  style: GwType.ui(fontSize: 14, fontWeight: FontWeight.w600, color: t.stone),
                ),
                Text(
                  child.gender == 'MALE' ? 'Fils' : 'Fille',
                  style: GwType.ui(fontSize: 12, color: t.stoneMid),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _children.removeAt(index)),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: GwTokens.emberBg,
                borderRadius: BorderRadius.circular(GwTokens.rBtn - 4),
                border: Border.all(color: GwTokens.emberLine),
              ),
              child: Icon(Symbols.close, size: 16, color: t.emberText),
            ),
          ),
        ],
      ),
    );
  }

  void _startInlineChildCreate() {
    _createChildFirstNameCtrl.clear();
    _createChildLastNameCtrl.clear();
    _createChildClanCtrl.text = _selectedClans.join(', ');
    _createChildEmailCtrl.clear();
    _createChildGender = 'MALE';
    _createChildBirthDate = null;
    _createChildLoading = false;
    setState(() => _creatingChild = true);
  }

  Widget _buildInlineChildCreateForm() {
    final t = GwTokens.of(context);
    return Form(
      key: _createChildFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Symbols.child_care, size: 16, color: t.goldText),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'NOUVEL ENFANT',
                  style: GwType.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: t.goldText,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _createChildLoading ? null : () => setState(() => _creatingChild = false),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(Symbols.close, size: 18, color: t.stoneDim),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _createChildFirstNameCtrl,
            style: GwType.ui(fontSize: 14, color: t.stone),
            decoration: _decor(context, label: 'Prenom *', icon: Symbols.person),
            validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _createChildLastNameCtrl,
            style: GwType.ui(fontSize: 14, color: t.stone),
            decoration: _decor(context, label: 'Nom *', icon: Symbols.badge),
            validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _createChildClanCtrl,
            style: GwType.ui(fontSize: 14, color: t.stone),
            decoration: _decor(context, label: 'Clan', icon: Symbols.shield),
          ),
          const SizedBox(height: 10),
          // Date de naissance — champ datepicker stylé
          _buildDateField(
            context,
            label: 'Date de naissance',
            value: _createChildBirthDate,
            onTap: () async {
              final picked = await _pickDate(
                context,
                initialDate: _createChildBirthDate ?? DateTime(2000),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _createChildBirthDate = picked);
            },
          ),
          const SizedBox(height: 10),
          // Email
          TextFormField(
            controller: _createChildEmailCtrl,
            style: GwType.ui(fontSize: 14, color: t.stone),
            decoration: _decor(
              context,
              label: 'Email',
              icon: Symbols.mail,
              helper: 'Pour la deduplication et l\'invitation',
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          // Genre — pilules
          Text(
            'GENRE',
            style: GwType.mono(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: t.stoneDim,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(
                context,
                label: 'Fils',
                active: _createChildGender == 'MALE',
                onTap: () => setState(() => _createChildGender = 'MALE'),
              ),
              _pill(
                context,
                label: 'Fille',
                active: _createChildGender == 'FEMALE',
                onTap: () => setState(() => _createChildGender = 'FEMALE'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _secondaryBtn(
                  context,
                  label: 'Annuler',
                  onPressed: _createChildLoading ? null : () => setState(() => _creatingChild = false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _primaryBtn(
                  context,
                  label: 'Creer',
                  icon: Symbols.check,
                  loading: _createChildLoading,
                  onPressed: _createChildLoading ? null : _submitInlineChildCreate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitInlineChildCreate() async {
    if (!_createChildFormKey.currentState!.validate()) return;
    setState(() => _createChildLoading = true);
    try {
      final api = ref.read(genealogyApiServiceProvider);
      final myPerson = await api.getMyPerson();

      // Appel atomique : creation personne + lien parent-enfant en une seule transaction
      final child = await api.createChild(
        parentId: myPerson.id,
        firstName: _createChildFirstNameCtrl.text.trim(),
        lastName: _createChildLastNameCtrl.text.trim(),
        gender: _createChildGender,
        birthDate: _createChildBirthDate != null
            ? '${_createChildBirthDate!.year}-${_createChildBirthDate!.month.toString().padLeft(2, '0')}-${_createChildBirthDate!.day.toString().padLeft(2, '0')}'
            : null,
        clan: _createChildClanCtrl.text.trim().isNotEmpty ? _createChildClanCtrl.text.trim() : null,
        email: _createChildEmailCtrl.text.trim().isNotEmpty ? _createChildEmailCtrl.text.trim() : null,
      );

      if (mounted) {
        setState(() {
          _children.add(child);
          _creatingChild = false;
          // Mettre à jour le compteur si le nb liés dépasse la valeur déclarée
          final declared = int.tryParse(_childrenCountCtrl.text.trim()) ?? 0;
          if (_children.length > declared) {
            _childrenCountCtrl.text = _children.length.toString();
          }
        });
        _showSnack('${child.firstName} ajoute(e) et lie(e) a votre arbre', GwTokens.sage);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Erreur: $e', GwTokens.ember);
      }
    } finally {
      if (mounted) setState(() => _createChildLoading = false);
    }
  }

  void _showSearchChildDialog(BuildContext context) {
    if (_selectedClans.isEmpty) {
      showDialog(
        context: context,
        useRootNavigator: true,
        builder: (dCtx) => _tissageDialog(
          dCtx,
          icon: Symbols.shield,
          title: 'Clan requis',
          children: [
            Text(
              'Veuillez d\'abord renseigner au moins un clan dans l\'onglet Origines.',
              style: GwType.ui(fontSize: 14, color: GwTokens.of(dCtx).stoneMid, height: 1.5),
            ),
          ],
          actions: [
            _dialogPrimaryBtn(
              dCtx,
              label: 'Aller aux Origines',
              icon: Symbols.arrow_forward,
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                final originesIndex = _sections.indexOf('Origines');
                if (originesIndex >= 0) setState(() => _currentSection = originesIndex);
              },
            ),
            _dialogGhostBtn(
              dCtx,
              label: 'Fermer',
              onPressed: () => Navigator.of(dCtx, rootNavigator: true).pop(),
            ),
          ],
        ),
      );
      return;
    }
    final clan = _selectedClans.length == 1 ? _selectedClans.first : null;
    if (clan != null) {
      _openSearchChildDialog(context, clan);
    } else {
      showDialog(
        context: context,
        useRootNavigator: true,
        builder: (dCtx) => _clanPickerDialog(
          dCtx,
          onClanPicked: (c) {
            Navigator.of(context, rootNavigator: true).pop();
            _openSearchChildDialog(context, c);
          },
        ),
      );
    }
  }

  void _openSearchChildDialog(BuildContext context, String clan) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (_) => _SearchParentDialog(
        clan: clan,
        gender: '', // pas de filtre genre pour les enfants
        onSelected: (person) async {
          // Lier immediatement l'enfant au parent
          try {
            final api = ref.read(genealogyApiServiceProvider);
            final myPerson = await api.getMyPerson();
            await api.linkParentChild(
              parentId: myPerson.id,
              childId: person.id,
              role: myPerson.gender == 'FEMALE' ? 'MOTHER' : 'FATHER',
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${person.firstName} lie(e) comme enfant',
                    style: GwType.ui(fontSize: 14, color: Colors.white),
                  ),
                  backgroundColor: GwTokens.sage,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GwTokens.rBtn)),
                ),
              );
            }
          } catch (e) {
            debugPrint('Erreur linkParentChild enfant existant: $e');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Erreur liaison: $e',
                    style: GwType.ui(fontSize: 14, color: Colors.white),
                  ),
                  backgroundColor: GwTokens.ember,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GwTokens.rBtn)),
                ),
              );
            }
          }
          setState(() {
            _children.add(person);
            final declared = int.tryParse(_childrenCountCtrl.text.trim()) ?? 0;
            if (_children.length > declared) {
              _childrenCountCtrl.text = _children.length.toString();
            }
          });
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        },
      ),
    );
  }

  // ── 4. Origines ──────────────────────────────────────────────────────────

  Widget _buildOriginsSection(BuildContext context) {
    // Pre-selectionner le pays si deja renseigne dans le profil
    if (_selectedCountry == null) {
      final countriesAsync = ref.read(countriesNotifierProvider);
      countriesAsync.whenData((countries) {
        final user = ref.read(profileNotifierProvider).valueOrNull;
        if (user?.country != null) {
          final match = countries.where((c) => c.name == user!.country).toList();
          if (match.isNotEmpty) {
            _selectedCountry = match.first;
            _selectedCountryIso = match.first.isoCode;
          }
        }
      });
    }

    return Column(
      key: const ValueKey('origins'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, Symbols.public, 'Origines & Culture'),
        const SizedBox(height: 16),

        // Pays d'origine — sélecteur mondial (par nom, code ISO stocké en back).
        CountrySelector(
          label: 'Pays d\'origine',
          hint: 'Choisir un pays',
          value: _selectedCountry,
          onChanged: (c) => setState(() {
            _selectedCountry = c;
            _selectedCountryIso = c.isoCode;
            _selectedLanguage = null;
          }),
        ),
        const SizedBox(height: 16),

        // Village / chefferie d'origine — issu du référentiel (atteint Bandenkop).
        _buildOriginReferentiel(context),

        // Langue maternelle (visible seulement si un pays est selectionne)
        if (_selectedCountryIso != null) ...[
          const SizedBox(height: 18),
          _buildLanguagePills(context),
        ],
        const SizedBox(height: 18),
        _buildTextField(
          controller: _tribeCtrl,
          label: 'Ethnie / Tribu',
          hint: 'Ex: Bassa',
          icon: Symbols.groups,
        ),
        const SizedBox(height: 18),
        _buildClanMultiSelect(context),
      ],
    );
  }

  /// Village / chefferie d'origine issu du référentiel territorial (atteint
  /// n'importe quelle chefferie, dont Bandenkop). Pour un pays hors référentiel,
  /// repli sur une saisie libre.
  Widget _buildOriginReferentiel(BuildContext context) {
    final t = GwTokens.of(context);
    final iso2 = _selectedCountry?.iso2?.toUpperCase();
    final isCameroon = iso2 == null || iso2 == 'CM';

    final header = Row(
      children: [
        Icon(Symbols.forest, size: 16, color: t.goldText),
        const SizedBox(width: 8),
        Text(
          'VILLAGE / CHEFFERIE D\'ORIGINE',
          style: GwType.mono(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: t.stoneDim,
          ),
        ),
      ],
    );

    if (!isCameroon) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 10),
          _buildTextField(
            controller: _originVillageFreeCtrl,
            label: 'Village / ville d\'origine',
            hint: 'Saisir le nom',
            icon: Symbols.forest,
            onChanged: (v) => _originSelection = OriginSelection(
              chefferieName: v.trim().isEmpty ? null : v.trim(),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        const SizedBox(height: 10),
        OriginCascadeSelector(
          initial: _originSelection,
          onChanged: (sel) => _originSelection = sel,
        ),
      ],
    );
  }

  Widget _buildClanMultiSelect(BuildContext context) {
    final t = GwTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Symbols.account_tree, size: 16, color: t.goldText),
            const SizedBox(width: 8),
            Text(
              'CLANS',
              style: GwType.mono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: t.stoneDim,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Pilules des clans selectionnes
        if (_selectedClans.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedClans.map((clan) => Container(
              constraints: const BoxConstraints(minHeight: 40),
              padding: const EdgeInsets.only(left: 14, right: 6),
              decoration: BoxDecoration(
                color: t.goldBg,
                borderRadius: BorderRadius.circular(GwTokens.rPill),
                border: Border.all(color: t.goldLine),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(clan, style: GwType.ui(fontSize: 13, fontWeight: FontWeight.w600, color: t.goldText)),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => setState(() => _selectedClans.remove(clan)),
                    child: SizedBox(
                      width: 30,
                      height: 40,
                      child: Icon(Symbols.close, size: 16, color: t.goldText),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        const SizedBox(height: 10),
        // Champ de saisie + bouton ajouter
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _clanInputCtrl,
                style: GwType.ui(fontSize: 14, color: t.stone),
                decoration: _decor(context, label: 'Ajouter un clan', hint: 'Ex: Bakoko'),
                onSubmitted: (_) => _addClan(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _addClan,
              child: Container(
                width: GwTokens.tapTarget,
                height: GwTokens.tapTarget,
                decoration: BoxDecoration(
                  color: GwTokens.gold,
                  borderRadius: BorderRadius.circular(GwTokens.rBtn),
                ),
                child: const Icon(Symbols.add, size: 22, color: Colors.black),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _addClan() {
    final name = _clanInputCtrl.text.trim();
    if (name.isEmpty) return;
    if (_selectedClans.contains(name)) {
      _clanInputCtrl.clear();
      return;
    }
    setState(() {
      _selectedClans.add(name);
      _clanInputCtrl.clear();
    });
  }

  Widget _buildLanguagePills(BuildContext context) {
    final t = GwTokens.of(context);
    final languagesAsync = ref.watch(languagesByCountryNotifierProvider(_selectedCountryIso));

    return languagesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(color: GwTokens.gold),
      ),
      error: (_, __) => Text(
        'Impossible de charger les langues',
        style: GwType.ui(fontSize: 13, color: t.emberText),
      ),
      data: (languages) {
        if (languages.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Aucune langue enregistree pour ce pays',
              style: GwType.ui(fontSize: 13, color: t.stoneDim),
            ),
          );
        }
        // Pre-selectionner la langue si deja renseignee dans le profil
        if (_selectedLanguage == null) {
          final user = ref.read(profileNotifierProvider).valueOrNull;
          if (user?.nativeLanguage != null) {
            final match = languages.where((l) => l.name == user!.nativeLanguage).toList();
            if (match.isNotEmpty) {
              _selectedLanguage = match.first;
            }
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Symbols.record_voice_over, size: 16, color: t.goldText),
                const SizedBox(width: 8),
                Text(
                  'LANGUE MATERNELLE',
                  style: GwType.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    color: t.stoneDim,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: languages.map((l) {
                final label = l.official ? '${l.name} (officielle)' : l.name;
                final active = _selectedLanguage == l ||
                    (_selectedLanguage != null && _selectedLanguage!.name == l.name);
                return _pill(
                  context,
                  label: label,
                  active: active,
                  onTap: () => setState(() => _selectedLanguage = l),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  // ── 5. Residence & Metier ────────────────────────────────────────────────

  Widget _buildResidenceSection(BuildContext context) {
    // Pré-sélectionner le pays de résidence déjà renseigné (stocké par nom).
    if (_selectedResidenceCountry == null &&
        _initialResidenceCountryName != null &&
        _initialResidenceCountryName!.trim().isNotEmpty) {
      final target = _initialResidenceCountryName!.trim().toLowerCase();
      ref.read(countriesNotifierProvider).whenData((countries) {
        final match = countries.where((c) {
          return c.name.toLowerCase() == target ||
              (c.iso2 ?? '').toLowerCase() == target ||
              c.isoCode.toLowerCase() == target;
        }).toList();
        if (match.isNotEmpty) _selectedResidenceCountry = match.first;
      });
    }

    return Column(
      key: const ValueKey('residence'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, Symbols.work, 'Residence & Vie professionnelle'),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _residenceCityCtrl,
          label: 'Ville de residence',
          hint: 'Ex: Paris',
          icon: Symbols.location_city,
        ),
        const SizedBox(height: 14),
        CountrySelector(
          label: 'Pays de residence',
          hint: 'Choisir un pays',
          value: _selectedResidenceCountry,
          onChanged: (c) => setState(() => _selectedResidenceCountry = c),
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _professionCtrl,
          label: 'Profession / Metier',
          hint: 'Ex: Ingenieur logiciel',
          icon: Symbols.engineering,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _employerCtrl,
          label: 'Employeur / Entreprise',
          hint: 'Ex: Nom de l\'entreprise',
          icon: Symbols.domain,
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BOTTOM BAR
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildBottomBar(BuildContext context) {
    final t = GwTokens.of(context);
    final isLast = _currentSection == _sections.length - 1;
    final isFirst = _currentSection == 0;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: t.inkCard,
        border: Border(top: BorderSide(color: t.line)),
      ),
      child: Row(
        children: [
          if (!isFirst)
            Expanded(
              child: _secondaryBtn(
                context,
                label: 'Precedent',
                icon: Symbols.arrow_back,
                onPressed: () => setState(() => _currentSection--),
              ),
            ),
          if (!isFirst) const SizedBox(width: 12),
          Expanded(
            child: _primaryBtn(
              context,
              label: isLast ? 'Enregistrer' : 'Suivant',
              icon: isLast ? Symbols.check : Symbols.arrow_forward,
              onPressed: isLast ? _handleSave : () => setState(() => _currentSection++),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SAVE
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _handleSave() async {
    final data = <String, dynamic>{
      // Identite (camelCase pour matcher le backend Spring Boot)
      if (_displayNameCtrl.text.trim().isNotEmpty)
        'displayName': _displayNameCtrl.text.trim(),
      if (_bioCtrl.text.trim().isNotEmpty)
        'bio': _bioCtrl.text.trim(),
      // Origines — pays (nom pour affichage + ISO-2 comme ancre) et
      // origine référentielle (région → département → commune → chefferie).
      if (_selectedCountry != null) 'country': _selectedCountry!.name,
      if (_selectedCountry?.iso2 != null) 'originCountry': _selectedCountry!.iso2,
      if (_originSelection.regionName != null)
        'originRegion': _originSelection.regionName,
      if (_originSelection.departmentName != null)
        'originDepartment': _originSelection.departmentName,
      if (_originSelection.arrondissementName != null)
        'originArrondissement': _originSelection.arrondissementName,
      if (_originSelection.chefferieName != null)
        'originVillage': _originSelection.chefferieName,
      if (_selectedLanguage != null)
        'nativeLanguage': _selectedLanguage!.name,
      if (_tribeCtrl.text.trim().isNotEmpty)
        'tribe': _tribeCtrl.text.trim(),
      if (_selectedClans.isNotEmpty)
        'clan': _selectedClans.join(', '),
      // Parents (noms stockes dans users pour affichage rapide)
      if (_selectedFather != null)
        'fatherName': '${_selectedFather!.firstName} ${_selectedFather!.lastName}',
      if (_selectedMother != null)
        'motherName': '${_selectedMother!.firstName} ${_selectedMother!.lastName}',
      // Famille
      if (_maritalStatus != null) 'maritalStatus': _maritalStatus,
      if (_matrimonialRegime != null) 'matrimonialRegime': _matrimonialRegime,
      if (_childrenCountCtrl.text.trim().isNotEmpty)
        'childrenCount': int.tryParse(_childrenCountCtrl.text.trim()) ?? 0,
      if (_diet != null) 'diet': _diet,
      // Residence & Metier
      if (_professionCtrl.text.trim().isNotEmpty)
        'profession': _professionCtrl.text.trim(),
      if (_employerCtrl.text.trim().isNotEmpty)
        'employer': _employerCtrl.text.trim(),
      if (_residenceCityCtrl.text.trim().isNotEmpty)
        'residenceCity': _residenceCityCtrl.text.trim(),
      // Pays de résidence — envoyé par NOM (cohérent avec le champ `country`).
      if (_selectedResidenceCountry != null)
        'residenceCountry': _selectedResidenceCountry!.name,
    };

    if (data.isEmpty && _selectedFather == null && _selectedMother == null) {
      Navigator.of(context).pop();
      return;
    }

    // 1. Update profile fields
    if (data.isNotEmpty) {
      await ref.read(profileNotifierProvider.notifier).updateProfile(data);
      if (!mounted) return;
    }

    // 2. Link parents and children in genealogy tree
    try {
      final api = ref.read(genealogyApiServiceProvider);
      final myPerson = await api.getMyPerson();
      if (_selectedFather != null) {
        await api.linkParentChild(
          parentId: _selectedFather!.id,
          childId: myPerson.id,
          role: 'FATHER',
        );
      }
      if (_selectedMother != null) {
        await api.linkParentChild(
          parentId: _selectedMother!.id,
          childId: myPerson.id,
          role: 'MOTHER',
        );
      }
      for (final child in _children) {
        await api.linkParentChild(
          parentId: myPerson.id,
          childId: child.id,
          role: myPerson.gender == 'FEMALE' ? 'MOTHER' : 'FATHER',
        );
      }
    } catch (e) {
      debugPrint('Erreur liaison parent/enfant: $e');
    }

    if (!mounted) return;

    final profileState = ref.read(profileNotifierProvider);
    if (profileState.hasError) {
      _showSnack('Erreur lors de la mise a jour du profil', GwTokens.ember);
    } else {
      _showSnack('Profil mis a jour', GwTokens.sage);
      Navigator.of(context).pop();
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SHARED WIDGETS — style « Tissage »
  // ════════════════════════════════════════════════════════════════════════════

  /// Header de section : tuile or + label JetBrains Mono MAJUSCULES.
  Widget _sectionHeader(BuildContext context, IconData icon, String title) {
    final t = GwTokens.of(context);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: t.goldBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.goldLine),
          ),
          child: Icon(icon, size: 20, color: t.goldText, fill: 1),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: GwType.mono(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: t.goldText,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Tous les champs sont optionnels',
                style: GwType.ui(fontSize: 12, color: t.stoneDim),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Décoration commune des inputs — inkLift, rayon 14, focus or.
  InputDecoration _decor(
    BuildContext context, {
    required String label,
    String? hint,
    IconData? icon,
    String? helper,
  }) {
    final t = GwTokens.of(context);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      labelStyle: GwType.ui(fontSize: 13, color: t.stoneDim),
      hintStyle: GwType.ui(fontSize: 13, color: t.stoneFaint),
      helperStyle: GwType.ui(fontSize: 12, color: t.stoneFaint),
      counterStyle: GwType.mono(fontSize: 12, letterSpacing: 0.5, color: t.stoneFaint),
      errorStyle: GwType.ui(fontSize: 12, color: t.emberText),
      prefixIcon: icon != null ? Icon(icon, size: 18, color: t.stoneDim) : null,
      filled: true,
      fillColor: t.inkLift,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        borderSide: BorderSide(color: t.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        borderSide: BorderSide(color: t.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        borderSide: const BorderSide(color: GwTokens.gold, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        borderSide: const BorderSide(color: GwTokens.ember),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        borderSide: const BorderSide(color: GwTokens.ember, width: 1.5),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) {
    final t = GwTokens.of(context);
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: GwType.ui(fontSize: 14, color: t.stone),
      decoration: _decor(context, label: label, hint: hint, icon: icon),
    );
  }

  /// Groupe de choix en pilules goldBg/goldLine (remplace les dropdowns).
  Widget _buildPillChoice({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    final t = GwTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: t.goldText),
            const SizedBox(width: 8),
            Text(
              label.toUpperCase(),
              style: GwType.mono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: t.stoneDim,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            return _pill(
              context,
              label: option,
              active: value == option,
              onTap: () => onChanged(option),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Pilule sélectionnable — active : goldBg/goldLine, inactive : inkLift.
  Widget _pill(
    BuildContext context, {
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final t = GwTokens.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minHeight: GwTokens.tapTarget),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? t.goldBg : t.inkLift,
          borderRadius: BorderRadius.circular(GwTokens.rPill),
          border: Border.all(color: active ? t.goldLine : t.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (active) ...[
              Icon(Symbols.check, size: 15, color: t.goldText, fill: 1),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GwType.ui(
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? t.goldText : t.stoneMid,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Champ date stylé — ouvre un datepicker thémé or.
  Widget _buildDateField(
    BuildContext context, {
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    final t = GwTokens.of(context);
    final text = value != null
        ? '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}'
        : 'JJ/MM/AAAA';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: t.inkLift,
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          border: Border.all(color: t.line),
        ),
        child: Row(
          children: [
            Icon(Symbols.cake, size: 18, color: t.stoneDim),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GwType.ui(fontSize: 12, color: t.stoneDim)),
                  const SizedBox(height: 2),
                  Text(
                    text,
                    style: GwType.ui(
                      fontSize: 14,
                      color: value != null ? t.stone : t.stoneFaint,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Symbols.calendar_month, size: 18, color: t.goldText),
          ],
        ),
      ),
    );
  }

  /// Datepicker thémé « Tissage » (accent or, fond inkCard, rayon 20).
  Future<DateTime?> _pickDate(
    BuildContext context, {
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('fr'),
      builder: (dCtx, child) {
        final t = GwTokens.of(dCtx);
        return Theme(
          data: Theme.of(dCtx).copyWith(
            colorScheme: Theme.of(dCtx).colorScheme.copyWith(
                  primary: GwTokens.gold,
                  onPrimary: Colors.black,
                  surface: t.inkCard,
                  onSurface: t.stone,
                ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: t.inkCard,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(GwTokens.rCardLg),
              ),
              headerHeadlineStyle: GwType.display(fontSize: 24, color: t.stone),
              weekdayStyle: GwType.mono(fontSize: 11, color: t.stoneDim),
              dayStyle: GwType.ui(fontSize: 14),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  /// Avatar à initiale Fraunces sur fond or.
  Widget _initialAvatar(BuildContext context, String name, {double radius = 20}) {
    final t = GwTokens.of(context);
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: t.goldBg,
        shape: BoxShape.circle,
        border: Border.all(color: t.goldLine),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: GwType.display(fontSize: radius * 0.85, color: t.goldText),
      ),
    );
  }

  /// Bouton primaire or plein — 50 px, rayon 14.
  Widget _primaryBtn(
    BuildContext context, {
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool loading = false,
  }) {
    return SizedBox(
      height: 50,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: GwTokens.gold,
          foregroundColor: Colors.black,
          disabledBackgroundColor: GwTokens.gold.withAlpha(110),
          disabledForegroundColor: Colors.black54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GwTokens.rBtn),
          ),
          textStyle: GwType.ui(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                ],
              ),
      ),
    );
  }

  /// Bouton secondaire — inkLift, bordure, 50 px, rayon 14.
  Widget _secondaryBtn(
    BuildContext context, {
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
  }) {
    final t = GwTokens.of(context);
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: t.inkLift,
          foregroundColor: t.stone,
          side: BorderSide(color: t.lineMid),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GwTokens.rBtn),
          ),
          textStyle: GwType.ui(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  /// Snackbar stylée.
  void _showSnack(String message, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GwType.ui(fontSize: 14, color: Colors.white)),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GwTokens.rBtn)),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// DIALOGS « TISSAGE » — specs GwDialog appliquées inline :
// fond inkCard rayon 20, titre Fraunces, actions or/ember 50 px.
// ════════════════════════════════════════════════════════════════════════════════

Widget _tissageDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required List<Widget> children,
  required List<Widget> actions,
}) {
  final t = GwTokens.of(context);
  return Dialog(
    backgroundColor: t.inkCard,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GwTokens.rCardLg),
      side: BorderSide(color: t.line),
    ),
    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: t.goldBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: t.goldLine),
                  ),
                  child: Icon(icon, size: 22, color: t.goldText, fill: 1),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title, style: GwType.display(fontSize: 18, color: t.stone)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
            const SizedBox(height: 18),
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              actions[i],
            ],
          ],
        ),
      ),
    ),
  );
}

Widget _dialogPrimaryBtn(
  BuildContext context, {
  required String label,
  required VoidCallback? onPressed,
  IconData? icon,
  bool loading = false,
}) {
  return SizedBox(
    width: double.infinity,
    height: 50,
    child: FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: GwTokens.gold,
        foregroundColor: Colors.black,
        disabledBackgroundColor: GwTokens.gold.withAlpha(110),
        disabledForegroundColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
        ),
        textStyle: GwType.ui(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      child: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                ],
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              ],
            ),
    ),
  );
}

Widget _dialogGhostBtn(
  BuildContext context, {
  required String label,
  required VoidCallback? onPressed,
}) {
  final t = GwTokens.of(context);
  return SizedBox(
    width: double.infinity,
    height: 46,
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: t.stoneMid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
        ),
        textStyle: GwType.ui(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    ),
  );
}

/// Ouvre le formulaire de modification du profil en bottom sheet.
void showProfileEditSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const ProfileEditSheet(),
  );
}

// ════════════════════════════════════════════════════════════════════════════════
// SEARCH PARENT DIALOG
// ════════════════════════════════════════════════════════════════════════════════

class _SearchParentDialog extends ConsumerStatefulWidget {
  const _SearchParentDialog({
    required this.clan,
    required this.gender,
    required this.onSelected,
  });

  final String clan;
  final String gender;
  final ValueChanged<PersonGenealogy> onSelected;

  @override
  ConsumerState<_SearchParentDialog> createState() => _SearchParentDialogState();
}

class _SearchParentDialogState extends ConsumerState<_SearchParentDialog> {
  final _searchCtrl = TextEditingController();
  List<PersonGenealogy> _results = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    try {
      final api = ref.read(genealogyApiServiceProvider);
      final all = await api.searchPersonsByClan(widget.clan, query: query);
      setState(() {
        _results = widget.gender.isEmpty ? all : all.where((p) => p.gender == widget.gender).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _results = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final title = widget.gender.isEmpty
        ? 'Rechercher un enfant'
        : widget.gender == 'MALE'
            ? 'Rechercher un pere'
            : 'Rechercher une mere';

    return Dialog(
      backgroundColor: t.inkCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GwTokens.rCardLg),
        side: BorderSide(color: t.line),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre Fraunces + tuile or
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: t.goldBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: t.goldLine),
                    ),
                    child: Icon(Symbols.search, size: 22, color: t.goldText, fill: 1),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(title, style: GwType.display(fontSize: 18, color: t.stone)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      style: GwType.ui(fontSize: 14, color: t.stone),
                      decoration: InputDecoration(
                        hintText: 'Rechercher par nom...',
                        hintStyle: GwType.ui(fontSize: 13, color: t.stoneFaint),
                        prefixIcon: Icon(Symbols.person_search, size: 20, color: t.stoneDim),
                        suffixIcon: IconButton(
                          icon: Icon(Symbols.search, size: 20, color: t.goldText),
                          tooltip: 'Rechercher',
                          onPressed: () => _search(_searchCtrl.text.trim()),
                        ),
                        filled: true,
                        fillColor: t.inkLift,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(GwTokens.rBtn),
                          borderSide: BorderSide(color: t.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(GwTokens.rBtn),
                          borderSide: BorderSide(color: t.line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(GwTokens.rBtn),
                          borderSide: const BorderSide(color: GwTokens.gold, width: 1.5),
                        ),
                      ),
                      onSubmitted: (v) => _search(v.trim()),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'CLAN · ${widget.clan.toUpperCase()}',
                        style: GwType.mono(
                          fontSize: 11,
                          letterSpacing: 1.5,
                          color: t.stoneDim,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _loading
                          ? const Center(
                              child: CircularProgressIndicator(color: GwTokens.gold),
                            )
                          : _results.isEmpty
                              ? Center(
                                  child: Text(
                                    'Aucun membre trouve dans ce clan',
                                    style: GwType.ui(fontSize: 13, color: t.stoneDim),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: _results.length,
                                  separatorBuilder: (_, __) => Divider(height: 1, color: t.line),
                                  itemBuilder: (_, i) {
                                    final p = _results[i];
                                    return InkWell(
                                      borderRadius: BorderRadius.circular(GwTokens.rBtn),
                                      onTap: () => widget.onSelected(p),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: t.goldBg,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: t.goldLine),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                p.firstName[0].toUpperCase(),
                                                style: GwType.display(fontSize: 16, color: t.goldText),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${p.firstName} ${p.lastName}',
                                                    style: GwType.ui(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                      color: t.stone,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    [
                                                      if (p.clan != null) 'Clan: ${p.clan}',
                                                      if (p.birthDate != null) 'Ne(e): ${p.birthDate!.year}',
                                                    ].join(' - '),
                                                    style: GwType.ui(fontSize: 12, color: t.stoneMid),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(Symbols.add_circle, size: 22, color: t.goldText),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _dialogGhostBtn(
                context,
                label: 'Fermer',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
