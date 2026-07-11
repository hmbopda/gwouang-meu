import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/shared/models/country_model.dart';
import 'package:gwangmeu/shared/models/language_model.dart';
import 'package:gwangmeu/shared/models/village_model.dart';
import 'package:gwangmeu/shared/widgets/country_selector.dart';
import 'package:gwangmeu/shared/widgets/country_village_selector.dart';
import 'package:gwangmeu/shared/widgets/gw_dialog.dart';
import 'package:gwangmeu/shared/widgets/person_lookup_widget.dart';
import 'package:gwangmeu/features/geo/geo_notifier.dart';
import 'package:gwangmeu/features/genealogy/genealogy_notifier.dart';
import 'package:gwangmeu/features/genealogy/models/clan_model.dart';
import 'package:gwangmeu/features/genealogy/models/genealogy_union.dart';
import 'package:gwangmeu/features/genealogy/models/person_genealogy.dart';
import 'package:gwangmeu/features/genealogy/services/genealogy_api_service.dart';
import 'package:gwangmeu/features/genealogy/widgets/dialogs/origin_cascade_selector.dart';

enum AddPersonStep { chooseAction, lookupContact, selectFromTree, selectClan, selectPerson, createForm, checkDuplicate, selectCoParent }

class AddPersonDialog extends ConsumerStatefulWidget {
  const AddPersonDialog({
    super.key,
    required this.personId,
    required this.isParent,
  });

  final String personId;
  final bool isParent;

  @override
  ConsumerState<AddPersonDialog> createState() => _AddPersonDialogState();
}

class _AddPersonDialogState extends ConsumerState<AddPersonDialog> {
  AddPersonStep _step = AddPersonStep.chooseAction;
  String _role = 'FATHER';

  List<ClanModel> _clans = [];
  ClanModel? _selectedClan;
  List<PersonGenealogy> _searchResults = [];
  PersonGenealogy? _selectedPerson;
  bool _searchLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _clanCtrl = TextEditingController();
  final _totemCtrl = TextEditingController();
  final _birthPlaceCtrl = TextEditingController();
  // Origine — ancre de la lignée (référentiel territorial en cascade).
  OriginSelection _origin = const OriginSelection();
  // Résidence actuelle — évolution (migration, situation actuelle).
  final _residenceCityCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  // Genre initialise en fonction du role par defaut dans initState (deduit du
  // role parental / conjoint). Ne jamais laisser 'MALE' par accident quand le
  // contexte designe une femme (mere / epouse).
  String _gender = 'MALE';
  bool _isAlive = true;
  bool _loading = false;
  CountryModel? _selectedCountry;
  List<VillageModel> _selectedVillages = [];
  LanguageModel? _selectedLanguage;
  // Pays d'origine (ISO-2) — l'arbre s'ancre sur l'origine, pas la résidence.
  CountryModel? _originCountry;
  // Pays de résidence actuelle — évolution uniquement (droit des unions).
  CountryModel? _residenceCountry;
  // Section « Résidence actuelle » repliée par défaut (discrète).
  bool _residenceExpanded = false;
  String? _selectedPhoneCode;
  DateTime? _birthDate;
  // Date de deces : reste NULL tant que l'utilisateur n'a pas explicitement
  // marque la personne decedee ET choisi une date. Ne JAMAIS auto-remplir
  // (pas de valeur par defaut, pas de min du date picker utilise comme date).
  DateTime? _deathDate;

  // Deduplication
  List<PersonGenealogy> _duplicateCandidates = [];

  // Co-parent selection
  List<GenealogyUnion> _parentUnions = [];
  PersonGenealogy? _selectedCoParent;
  String? _existingPersonId;

  @override
  void initState() {
    super.initState();
    _role = 'FATHER';
    // Le genre suit toujours le role choisi : on ne laisse jamais 'MALE'
    // par accident lorsque le contexte designera une femme.
    _gender = _genderForRole(_role);
  }

  /// Genre coherent avec le role : FATHER -> MALE, MOTHER -> FEMALE.
  /// Source unique de verite pour deduire le genre par defaut d'un role.
  String _genderForRole(String role) => role == 'FATHER' ? 'MALE' : 'FEMALE';

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _clanCtrl.dispose();
    _totemCtrl.dispose();
    _birthPlaceCtrl.dispose();
    _residenceCityCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String get _genderFilter => _genderForRole(_role);
  String get _genderLabel => _role == 'FATHER' ? 'Homme' : 'Femme';

  /// Calculates child age from _birthDate (null if no birth date set).
  int? get _childAge {
    if (_birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - _birthDate!.year;
    if (now.month < _birthDate!.month ||
        (now.month == _birthDate!.month && now.day < _birthDate!.day)) {
      age--;
    }
    return age < 0 ? 0 : age;
  }

  /// Whether to show email field (child adding mode).
  bool get _showEmail {
    if (widget.isParent) return true;
    final age = _childAge;
    if (age == null) return true;
    return age >= 4;
  }

  /// Whether to show phone field (child adding mode).
  bool get _showPhone {
    if (widget.isParent) return true;
    final age = _childAge;
    if (age == null) return true;
    return age >= 12;
  }

  /// Whether to show the entire "Lien de validation" section.
  bool get _showValidationSection {
    if (widget.isParent) return true;
    final age = _childAge;
    if (age == null) return true;
    return age >= 4;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isParent ? 'Ajouter un parent' : 'Ajouter un enfant';

    return GwDialog(
      title: title,
      subtitle: _step != AddPersonStep.chooseAction ? _stepSubtitle() : null,
      icon: widget.isParent ? Symbols.person_add : Symbols.family_restroom,
      actions: _dialogActions(),
      child: _buildStepContent(),
    );
  }

  List<GwDialogAction> _dialogActions() {
    return [
      if (_step != AddPersonStep.chooseAction)
        GwDialogAction(
          label: 'Retour',
          icon: Symbols.arrow_back,
          onPressed: _loading ? null : _goBack,
        ),
      GwDialogAction(
        label: 'Annuler',
        onPressed: _loading ? null : () => Navigator.of(context).pop(),
      ),
      if ((_step == AddPersonStep.selectPerson ||
              _step == AddPersonStep.selectFromTree) &&
          _selectedPerson != null)
        GwDialogAction(
          label: 'Confirmer',
          primary: true,
          loading: _loading,
          onPressed: _loading ? null : _linkSelectedPerson,
        ),
      if (_step == AddPersonStep.createForm)
        GwDialogAction(
          label: 'Suivant',
          primary: true,
          loading: _loading,
          onPressed: _loading ? null : _onCreateFormNext,
        ),
      if (_step == AddPersonStep.checkDuplicate)
        GwDialogAction(
          label: 'Creer quand meme',
          primary: true,
          onPressed: _loading ? null : _onDuplicateSkip,
        ),
      if (_step == AddPersonStep.selectCoParent)
        GwDialogAction(
          label: _selectedCoParent != null ? 'Enregistrer' : 'Sans co-parent',
          primary: true,
          loading: _loading,
          onPressed: _loading ? null : _submitCreate,
        ),
    ];
  }

  String _stepSubtitle() {
    switch (_step) {
      case AddPersonStep.chooseAction:
        return '';
      case AddPersonStep.lookupContact:
        return 'Recherche par email / telephone';
      case AddPersonStep.selectFromTree:
        return 'Membres de votre arbre';
      case AddPersonStep.selectClan:
        return 'Etape 1/2 — Choisir une grande famille';
      case AddPersonStep.selectPerson:
        return 'Etape 2/2 — Selectionner la personne';
      case AddPersonStep.createForm:
        return 'Creer une nouvelle personne';
      case AddPersonStep.checkDuplicate:
        return 'Personne(s) similaire(s) trouvee(s)';
      case AddPersonStep.selectCoParent:
        return 'Selectionner le co-parent (optionnel)';
    }
  }

  Widget _buildStepContent() {
    switch (_step) {
      case AddPersonStep.chooseAction:
        return _buildChooseAction();
      case AddPersonStep.lookupContact:
        return _buildLookupContact();
      case AddPersonStep.selectFromTree:
        return _buildSelectFromTree();
      case AddPersonStep.selectClan:
        return _buildSelectClan();
      case AddPersonStep.selectPerson:
        return _buildSelectPerson();
      case AddPersonStep.createForm:
        return _buildCreateForm();
      case AddPersonStep.checkDuplicate:
        return _buildCheckDuplicate();
      case AddPersonStep.selectCoParent:
        return _buildSelectCoParent();
    }
  }

  Widget _buildChooseAction() {
    final t = GwTokens.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.isParent) ...[
          Text(
            'Quel role parental ?',
            style: GwType.ui(
                fontSize: 14, fontWeight: FontWeight.w600, color: t.stone),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GwChoicePill(
                  icon: Symbols.man,
                  label: 'Pere',
                  expand: true,
                  selected: _role == 'FATHER',
                  onTap: () => setState(() => _role = 'FATHER'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GwChoicePill(
                  icon: Symbols.woman,
                  label: 'Mere',
                  expand: true,
                  selected: _role == 'MOTHER',
                  onTap: () => setState(() => _role = 'MOTHER'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
        Text(
          'Comment souhaitez-vous proceder ?',
          style: GwType.ui(
              fontSize: 14, fontWeight: FontWeight.w600, color: t.stone),
        ),
        const SizedBox(height: 12),
        _ActionTile(
          icon: Symbols.family_restroom,
          title: 'Choisir dans mon arbre',
          subtitle: 'Lier une personne deja enregistree',
          onTap: () => setState(() => _step = AddPersonStep.selectFromTree),
        ),
        const SizedBox(height: 10),
        _ActionTile(
          icon: Symbols.mail,
          title: 'Rechercher par email / telephone',
          subtitle: 'Verifier si la personne existe deja en base',
          onTap: () => setState(() => _step = AddPersonStep.lookupContact),
        ),
        const SizedBox(height: 10),
        _ActionTile(
          icon: Symbols.search,
          title: 'Parcourir les grandes familles',
          subtitle: 'Rechercher dans les villages',
          onTap: _goToSelectClan,
        ),
        const SizedBox(height: 10),
        _ActionTile(
          icon: Symbols.person_add,
          title: 'Creer une nouvelle personne',
          subtitle: 'Remplir les informations manuellement',
          onTap: () => setState(() {
            _gender = _genderForRole(_role);
            _step = AddPersonStep.createForm;
          }),
        ),
      ],
    );
  }

  Widget _buildSelectFromTree() {
    final t = GwTokens.of(context);
    final myPerson = ref.watch(genealogyNotifierProvider).valueOrNull;
    if (myPerson == null) {
      return Center(child: CircularProgressIndicator(color: t.goldText));
    }

    final treeAsync = ref.watch(familyTreeProvider(myPerson.id));

    return treeAsync.when(
      loading: () =>
          Center(child: CircularProgressIndicator(color: t.goldText)),
      error: (e, _) => Center(
        child: Text('Erreur: $e',
            style: GwType.ui(fontSize: 14, color: t.emberText)),
      ),
      data: (tree) {
        // Collecter tous les membres de l'arbre sauf le sujet lui-même et la personne courante
        final all = <PersonGenealogy>[
          ...tree.father,
          ...tree.mother,
          ...tree.paternalGP,
          ...tree.maternalGP,
          ...tree.children,
          ...tree.cousins,
          ...tree.uncles,
          ...tree.siblings.map((s) => s.person),
          for (final u in tree.unions) ...[
            if (u.husband != null) u.husband!,
            if (u.wife != null) u.wife!,
          ],
        ];

        // Dédupliquer et exclure le sujet et la personne courante
        final seen = <String>{myPerson.id, widget.personId};
        final candidates = all.where((p) => seen.add(p.id)).toList();

        // Filtrer par genre selon le rôle
        final filtered = candidates
            .where((p) => p.gender == _genderFilter)
            .toList();

        if (filtered.isEmpty) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Symbols.group, size: 44, color: t.stoneDim),
              const SizedBox(height: 12),
              Text(
                'Aucun(e) ${_genderLabel.toLowerCase()} trouve(e) dans votre arbre.',
                textAlign: TextAlign.center,
                style: GwType.ui(fontSize: 14, color: t.stoneMid),
              ),
              const SizedBox(height: 16),
              _GoldButton(
                icon: Symbols.person_add,
                label: 'Creer manuellement',
                onTap: () => setState(() {
                  _gender = _genderForRole(_role);
                  _step = AddPersonStep.createForm;
                }),
              ),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Membres de votre arbre — ${filtered.length} ${_genderLabel.toLowerCase()}(s)',
              style: GwType.ui(
                  fontSize: 14, fontWeight: FontWeight.w600, color: t.stone),
            ),
            const SizedBox(height: 4),
            Text(
              'Selectionnez la personne a lier comme ${widget.isParent ? "parent" : "enfant"}.',
              style: GwType.ui(fontSize: 12, color: t.stoneMid),
            ),
            const SizedBox(height: 12),
            ...filtered.map((person) => _PersonTile(
                  person: person,
                  selected: _selectedPerson?.id == person.id,
                  onTap: () => setState(() => _selectedPerson = person),
                )),
          ],
        );
      },
    );
  }

  Widget _buildLookupContact() {
    return PersonLookupWidget(
      label: 'Rechercher le ${widget.isParent ? "parent" : "enfant"} par email/telephone',
      onPersonSelected: (person) {
        setState(() {
          _selectedPerson = person;
          _step = AddPersonStep.selectPerson;
          _searchResults = [person];
        });
      },
      onCreateNew: (email, phone) {
        setState(() {
          _emailCtrl.text = email;
          _phoneCtrl.text = phone;
          _gender = _genderForRole(_role);
          _step = AddPersonStep.createForm;
        });
      },
    );
  }

  Future<void> _goToSelectClan() async {
    final myPerson = ref.read(genealogyNotifierProvider).valueOrNull;
    if (myPerson == null || myPerson.villageIds.isEmpty) {
      setState(() {
        _gender = _genderForRole(_role);
        _step = AddPersonStep.createForm;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun village associe. Veuillez creer la personne manuellement.'),
            backgroundColor: GwTokens.ember,
          ),
        );
      }
      return;
    }

    setState(() => _searchLoading = true);

    try {
      final api = ref.read(genealogyApiServiceProvider);
      final allClans = <ClanModel>[];
      for (final villageId in myPerson.villageIds) {
        final clans = await api.getClansByVillage(villageId);
        allClans.addAll(clans);
      }

      setState(() {
        _clans = allClans;
        _searchLoading = false;
        _step = AddPersonStep.selectClan;
      });
    } catch (e) {
      setState(() => _searchLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: GwTokens.ember),
        );
      }
    }
  }

  Widget _buildSelectClan() {
    final t = GwTokens.of(context);
    if (_searchLoading) {
      return Center(child: CircularProgressIndicator(color: t.goldText));
    }

    if (_clans.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Symbols.family_restroom, size: 44, color: t.stoneDim),
          const SizedBox(height: 12),
          Text(
            'Aucune grande famille trouvee dans vos villages.',
            textAlign: TextAlign.center,
            style: GwType.ui(fontSize: 14, color: t.stoneMid),
          ),
          const SizedBox(height: 16),
          _GoldButton(
            icon: Symbols.person_add,
            label: 'Creer manuellement',
            onTap: () => setState(() {
              _gender = _genderForRole(_role);
              _step = AddPersonStep.createForm;
            }),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Grandes familles disponibles (${_clans.length})',
          style: GwType.ui(
              fontSize: 14, fontWeight: FontWeight.w600, color: t.stone),
        ),
        const SizedBox(height: 4),
        Text(
          'Selectionnez la grande famille ou cliquez "Voir tous" pour afficher toutes les personnes.',
          style: GwType.ui(fontSize: 12, color: t.stoneMid),
        ),
        const SizedBox(height: 12),
        _ActionTile(
          icon: Symbols.group,
          title: 'Voir toutes les personnes (${_genderLabel}s)',
          subtitle: 'Sans filtrer par grande famille',
          onTap: () => _loadPersonsAllVillages(),
        ),
        const SizedBox(height: 8),
        ...(_clans.map((clan) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _ClanTile(
                clan: clan,
                onTap: () => _loadPersonsByClan(clan),
              ),
            ))),
        const SizedBox(height: 12),
        Center(
          child: _GoldTextButton(
            icon: Symbols.person_add,
            label: 'Je ne trouve pas, creer manuellement',
            onTap: () => setState(() {
              _gender = _genderForRole(_role);
              _step = AddPersonStep.createForm;
            }),
          ),
        ),
      ],
    );
  }

  Future<void> _loadPersonsByClan(ClanModel clan) async {
    setState(() {
      _selectedClan = clan;
      _searchLoading = true;
    });

    try {
      final api = ref.read(genealogyApiServiceProvider);
      final persons = await api.getPersonsByClan(clan.id, gender: _genderFilter);
      setState(() {
        _searchResults = persons;
        _searchLoading = false;
        _step = AddPersonStep.selectPerson;
      });
    } catch (e) {
      setState(() => _searchLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: GwTokens.ember),
        );
      }
    }
  }

  Future<void> _loadPersonsAllVillages() async {
    setState(() {
      _selectedClan = null;
      _searchLoading = true;
    });

    try {
      final api = ref.read(genealogyApiServiceProvider);
      final myPerson = ref.read(genealogyNotifierProvider).valueOrNull;
      final allPersons = <PersonGenealogy>[];
      for (final villageId in (myPerson?.villageIds ?? <String>[])) {
        final persons = await api.getPersonsByVillageAndGender(villageId, _genderFilter);
        allPersons.addAll(persons);
      }
      final seen = <String>{};
      final unique = allPersons.where((p) => seen.add(p.id)).toList();

      setState(() {
        _searchResults = unique;
        _searchLoading = false;
        _step = AddPersonStep.selectPerson;
      });
    } catch (e) {
      setState(() => _searchLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: GwTokens.ember),
        );
      }
    }
  }

  Widget _buildSelectPerson() {
    final t = GwTokens.of(context);
    if (_searchLoading) {
      return Center(child: CircularProgressIndicator(color: t.goldText));
    }

    final clanLabel = _selectedClan != null
        ? 'Grande famille "${_selectedClan!.name}"'
        : 'Toutes les personnes';

    if (_searchResults.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Symbols.person_search, size: 44, color: t.stoneDim),
          const SizedBox(height: 12),
          Text(
            'Aucun(e) ${_genderLabel.toLowerCase()} trouve(e) dans $clanLabel.',
            textAlign: TextAlign.center,
            style: GwType.ui(fontSize: 14, color: t.stoneMid),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _GoldTextButton(
                icon: Symbols.arrow_back,
                label: 'Retour',
                onTap: () =>
                    setState(() => _step = AddPersonStep.selectClan),
              ),
              const SizedBox(width: 12),
              _GoldButton(
                icon: Symbols.person_add,
                label: 'Creer',
                onTap: () => setState(() {
                  _gender = _genderForRole(_role);
                  _step = AddPersonStep.createForm;
                }),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$clanLabel — ${_searchResults.length} ${_genderLabel.toLowerCase()}(s)',
          style: GwType.ui(
              fontSize: 14, fontWeight: FontWeight.w600, color: t.stone),
        ),
        const SizedBox(height: 4),
        Text(
          'Selectionnez la personne a lier comme ${widget.isParent ? "parent" : "enfant"}.',
          style: GwType.ui(fontSize: 12, color: t.stoneMid),
        ),
        const SizedBox(height: 12),
        ...(_searchResults.map((person) => _PersonTile(
              person: person,
              selected: _selectedPerson?.id == person.id,
              onTap: () => setState(() => _selectedPerson = person),
            ))),
        const SizedBox(height: 12),
        Center(
          child: _GoldTextButton(
            icon: Symbols.person_add,
            label: 'Je ne trouve pas, creer manuellement',
            onTap: () => setState(() {
              _gender = _genderForRole(_role);
              _step = AddPersonStep.createForm;
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateForm() {
    final t = GwTokens.of(context);
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FormSectionHeader(label: 'IDENTITÉ'),
          const SizedBox(height: 10),
          TextFormField(
            controller: _firstNameCtrl,
            style: GwType.ui(fontSize: 14, color: t.stone),
            decoration: gwInputDecoration(
              context,
              label: 'Prenom *',
              prefixIcon: Symbols.person,
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _lastNameCtrl,
            style: GwType.ui(fontSize: 14, color: t.stone),
            decoration: gwInputDecoration(
              context,
              label: 'Nom *',
              prefixIcon: Symbols.badge,
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
          ),
          const SizedBox(height: 14),
          Text('Genre *',
              style: GwType.ui(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: t.stoneMid)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GwChoicePill(
                  icon: Symbols.man,
                  label: 'Homme',
                  expand: true,
                  selected: _gender == 'MALE',
                  onTap: () => setState(() {
                    _gender = 'MALE';
                    if (widget.isParent) _role = 'FATHER';
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GwChoicePill(
                  icon: Symbols.woman,
                  label: 'Femme',
                  expand: true,
                  selected: _gender == 'FEMALE',
                  onTap: () => setState(() {
                    _gender = 'FEMALE';
                    if (widget.isParent) _role = 'MOTHER';
                  }),
                ),
              ),
            ],
          ),
          if (widget.isParent) ...[
            const SizedBox(height: 14),
            Text('Role parental *',
                style: GwType.ui(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: t.stoneMid)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GwChoicePill(
                    icon: Symbols.man,
                    label: 'Pere',
                    expand: true,
                    selected: _role == 'FATHER',
                    onTap: () => setState(() => _role = 'FATHER'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GwChoicePill(
                    icon: Symbols.woman,
                    label: 'Mere',
                    expand: true,
                    selected: _role == 'MOTHER',
                    onTap: () => setState(() => _role = 'MOTHER'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),

          // ── NAISSANCE : un fait — ni origine, ni résidence ──
          const _FormSectionHeader(label: 'NAISSANCE'),
          const SizedBox(height: 10),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _birthDate ?? DateTime(2000),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _birthDate = picked);
            },
            borderRadius: BorderRadius.circular(GwTokens.rBtn),
            child: InputDecorator(
              decoration: gwInputDecoration(
                context,
                label: 'Date de naissance',
                prefixIcon: Symbols.cake,
              ),
              child: Text(
                _birthDate != null
                    ? DateFormat('dd/MM/yyyy').format(_birthDate!)
                    : 'Selectionner une date',
                style: GwType.ui(
                  fontSize: 14,
                  color: _birthDate != null ? t.stone : t.stoneDim,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _birthPlaceCtrl,
            style: GwType.ui(fontSize: 14, color: t.stone),
            decoration: gwInputDecoration(
              context,
              label: 'Lieu de naissance',
              prefixIcon: Symbols.location_city,
              hint: 'Ex: Douala, Paris, Yaoundé...',
            ),
          ),
          const SizedBox(height: 20),

          // ── ORIGINE : c'est ici que la lignée s'ancre ──
          const _FormSectionHeader(label: 'ORIGINE — ANCRE DE LA LIGNÉE'),
          const SizedBox(height: 4),
          Text(
            'La lignée s\'ancre sur l\'origine : village, ville, région, pays.',
            style: GwType.ui(fontSize: 12, color: t.stoneDim),
          ),
          const SizedBox(height: 10),
          CountryVillageSelector(
            selectedCountry: _selectedCountry,
            selectedVillages: _selectedVillages,
            multiSelect: true,
            onCountryChanged: (c) => setState(() {
              _selectedCountry = c;
              _selectedVillages = [];
              _selectedLanguage = null;
            }),
            onVillagesChanged: (v) => setState(() => _selectedVillages = v),
          ),
          const SizedBox(height: 14),
          // Référentiel territorial camerounais en cascade — remplace les
          // anciens champs libres Région / Ville / Village d'origine.
          OriginCascadeSelector(
            initial: _origin,
            onChanged: (sel) => _origin = sel,
          ),
          const SizedBox(height: 12),
          CountrySelector(
            label: 'Pays d\'origine',
            value: _originCountry,
            onChanged: (c) => setState(() => _originCountry = c),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _clanCtrl,
                  style: GwType.ui(fontSize: 14, color: t.stone),
                  decoration: gwInputDecoration(
                    context,
                    label: 'Clan / Grande famille',
                    prefixIcon: Symbols.shield,
                    dense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _totemCtrl,
                  style: GwType.ui(fontSize: 14, color: t.stone),
                  decoration: gwInputDecoration(
                    context,
                    label: 'Totem',
                    prefixIcon: Symbols.pets,
                    dense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildLanguageDropdown(),
          const SizedBox(height: 20),

          // ── RÉSIDENCE ACTUELLE : évolution, repliée par défaut ──
          InkWell(
            onTap: () =>
                setState(() => _residenceExpanded = !_residenceExpanded),
            borderRadius: BorderRadius.circular(GwTokens.rBtn),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Expanded(
                    child: _FormSectionHeader(
                        label: 'RÉSIDENCE ACTUELLE — ÉVOLUTION'),
                  ),
                  Icon(
                    _residenceExpanded
                        ? Symbols.expand_less
                        : Symbols.expand_more,
                    size: 18,
                    color: t.stoneDim,
                  ),
                ],
              ),
            ),
          ),
          if (_residenceExpanded) ...[
            const SizedBox(height: 4),
            Text(
              'Migration et situation actuelle — distincte de l\'origine. '
              'Sert au droit applicable des unions.',
              style: GwType.ui(fontSize: 12, color: t.stoneDim),
            ),
            const SizedBox(height: 10),
            CountrySelector(
              label: 'Pays de résidence',
              value: _residenceCountry,
              onChanged: (c) => setState(() => _residenceCountry = c),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _residenceCityCtrl,
              style: GwType.ui(fontSize: 14, color: t.stone),
              decoration: gwInputDecoration(
                context,
                label: 'Ville de résidence',
                prefixIcon: Symbols.home,
                hint: 'Ex: Paris, Douala...',
              ),
            ),
          ],
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text('Encore en vie ?',
                style: GwType.ui(fontSize: 14, color: t.stone)),
            subtitle: Text(
              _isAlive
                  ? 'Vous pourrez lui envoyer une invitation'
                  : 'La personne est decedee',
              style: GwType.ui(fontSize: 12, color: t.stoneMid),
            ),
            value: _isAlive,
            activeThumbColor: GwTokens.gold,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() {
              _isAlive = v;
              // Repasser en vie efface toute date de deces saisie : on ne
              // conserve jamais une date de deces pour une personne vivante.
              if (_isAlive) _deathDate = null;
            }),
          ),
          if (!_isAlive) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  // initialDate = date affichee a l'ouverture du picker ;
                  // ce n'est PAS une valeur enregistree. Tant que
                  // l'utilisateur n'a pas valide, _deathDate reste NULL.
                  initialDate: _deathDate ?? DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                // On n'enregistre la date QUE si l'utilisateur en choisit une.
                if (picked != null) setState(() => _deathDate = picked);
              },
              borderRadius: BorderRadius.circular(GwTokens.rBtn),
              child: InputDecorator(
                decoration: gwInputDecoration(
                  context,
                  label: 'Date de deces (optionnel)',
                  prefixIcon: Symbols.event_busy,
                ),
                child: Text(
                  _deathDate != null
                      ? DateFormat('dd/MM/yyyy').format(_deathDate!)
                      : 'Selectionner une date',
                  style: GwType.ui(
                    fontSize: 14,
                    color: _deathDate != null ? t.stone : t.stoneDim,
                  ),
                ),
              ),
            ),
          ],
          if (_isAlive && _showValidationSection) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: t.goldBg,
                borderRadius: BorderRadius.circular(GwTokens.rBtn),
                border: Border.all(color: t.goldLine),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Symbols.send, size: 16, color: t.goldText),
                      const SizedBox(width: 6),
                      Text(
                        'Lien de validation',
                        style: GwType.ui(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: t.goldText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Un lien de validation sera envoye a cette personne pour qu\'elle confirme son identite et cree son compte.',
                    style: GwType.ui(fontSize: 12, color: t.stoneMid),
                  ),
                  if (_showEmail) ...[
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _emailCtrl,
                      style: GwType.ui(fontSize: 14, color: t.stone),
                      decoration: gwInputDecoration(
                        context,
                        label: 'Email *',
                        prefixIcon: Symbols.mail,
                        dense: true,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (!_isAlive || !_showEmail) return null;
                        if (v == null || v.trim().isEmpty) {
                          return 'L\'email est requis';
                        }
                        final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                        if (!emailRegex.hasMatch(v.trim())) {
                          return 'Veuillez entrer un email valide';
                        }
                        return null;
                      },
                    ),
                  ],
                  if (_showPhone) ...[
                    const SizedBox(height: 8),
                    _buildPhoneRow(),
                  ],
                ],
              ),
            ),
          ],
          if (_isAlive && !_showValidationSection && !widget.isParent) ...[
            const SizedBox(height: 8),
            const GwInfoBanner(
              tone: GwBannerTone.azure,
              text: 'Cet enfant a moins de 4 ans. Aucun email ni telephone n\'est requis. '
                  'Les parents pourront modifier ses informations depuis leur compte.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLanguageDropdown() {
    final t = GwTokens.of(context);
    final langAsync = ref.watch(
      languagesByCountryNotifierProvider(_selectedCountry?.isoCode),
    );
    return langAsync.when(
      loading: () => LinearProgressIndicator(
          color: t.goldText, backgroundColor: t.inkLift),
      error: (_, __) => const SizedBox.shrink(),
      data: (languages) {
        if (languages.isEmpty) return const SizedBox.shrink();
        return DropdownButtonFormField<LanguageModel>(
          key: ValueKey(
              'lang_${_selectedCountry?.isoCode}_${_selectedLanguage?.name}'),
          initialValue: _selectedLanguage,
          decoration: gwInputDecoration(
            context,
            label: 'Langue maternelle',
            prefixIcon: Symbols.translate,
          ),
          dropdownColor: t.inkCard,
          style: GwType.ui(fontSize: 14, color: t.stone),
          isExpanded: true,
          items: languages
              .map((l) => DropdownMenuItem(
                    value: l,
                    child: Text(
                      l.official
                          ? '${l.name} (officielle)'
                          : l.nameLocal != null
                              ? '${l.name} — ${l.nameLocal}'
                              : l.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: (l) => setState(() => _selectedLanguage = l),
        );
      },
    );
  }

  Widget _buildPhoneRow() {
    final t = GwTokens.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            key: ValueKey('phonecode_$_selectedPhoneCode'),
            initialValue: _selectedPhoneCode,
            decoration: gwInputDecoration(
              context,
              label: 'Indicatif',
              dense: true,
            ),
            dropdownColor: t.inkCard,
            style: GwType.ui(fontSize: 13, color: t.stone),
            isExpanded: true,
            items: _buildPhoneCodeItems(),
            onChanged: (v) => setState(() => _selectedPhoneCode = v),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: _phoneCtrl,
            style: GwType.ui(fontSize: 14, color: t.stone),
            decoration: gwInputDecoration(
              context,
              label: 'Téléphone',
              prefixIcon: Symbols.call,
              dense: true,
            ),
            keyboardType: TextInputType.phone,
          ),
        ),
      ],
    );
  }

  List<DropdownMenuItem<String>> _buildPhoneCodeItems() {
    final countriesAsync = ref.watch(countriesNotifierProvider);
    return countriesAsync.maybeWhen(
      data: (countries) => countries
          .where((c) => c.phoneCode != null && c.phoneCode!.isNotEmpty)
          .map((c) => DropdownMenuItem(
                value: c.phoneCode,
                child: Text(
                  '${c.flagEmoji ?? ''} ${c.phoneCode}',
                  style: GwType.ui(fontSize: 13),
                ),
              ))
          .toList(),
      orElse: () => [],
    );
  }

  void _goBack() {
    setState(() {
      switch (_step) {
        case AddPersonStep.lookupContact:
          _step = AddPersonStep.chooseAction;
        case AddPersonStep.selectFromTree:
          _selectedPerson = null;
          _step = AddPersonStep.chooseAction;
        case AddPersonStep.selectClan:
          _step = AddPersonStep.chooseAction;
        case AddPersonStep.selectPerson:
          _selectedPerson = null;
          _step = AddPersonStep.selectClan;
        case AddPersonStep.createForm:
          _step = AddPersonStep.chooseAction;
        case AddPersonStep.checkDuplicate:
          _duplicateCandidates = [];
          _step = AddPersonStep.createForm;
        case AddPersonStep.selectCoParent:
          _selectedCoParent = null;
          _step = AddPersonStep.createForm;
        case AddPersonStep.chooseAction:
          break;
      }
    });
  }

  Future<void> _linkSelectedPerson() async {
    if (_selectedPerson == null) return;
    setState(() => _loading = true);

    try {
      final notifier = ref.read(genealogyNotifierProvider.notifier);

      if (widget.isParent) {
        await notifier.linkExistingParent(
          childId: widget.personId,
          existingPersonId: _selectedPerson!.id,
          role: _role,
        );
      } else {
        await notifier.linkExistingChild(
          parentId: widget.personId,
          existingPersonId: _selectedPerson!.id,
          parentRole: _role,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        final name = '${_selectedPerson!.firstName} ${_selectedPerson!.lastName}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name lie(e) comme ${widget.isParent ? "parent" : "enfant"}'),
            backgroundColor: GwTokens.sage,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: GwTokens.ember),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Depuis le formulaire de creation, verifie les doublons avant de continuer.
  Future<void> _onCreateFormNext() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final api = ref.read(genealogyApiServiceProvider);
      final firstName = _firstNameCtrl.text.trim();
      final lastName = _lastNameCtrl.text.trim();
      final email = _emailCtrl.text.trim();
      final birthDateStr = _birthDate != null
          ? DateFormat('yyyy-MM-dd').format(_birthDate!)
          : null;

      // Verifier les doublons uniquement si on a assez d'infos
      if (email.isNotEmpty || birthDateStr != null) {
        final candidates = await api.checkDuplicate(
          firstName: firstName,
          lastName: lastName,
          gender: _gender,
          birthDate: birthDateStr,
          email: email.isNotEmpty ? email : null,
        );

        if (candidates.isNotEmpty) {
          setState(() {
            _duplicateCandidates = candidates;
            _step = AddPersonStep.checkDuplicate;
          });
          return;
        }
      }

      // Pas de doublon → co-parent ou creation directe
      _proceedAfterDuplicateCheck();
    } catch (e) {
      // En cas d'erreur sur check-duplicate, on continue quand meme
      _proceedAfterDuplicateCheck();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// L'utilisateur a choisi de ne pas utiliser un doublon.
  void _onDuplicateSkip() {
    _existingPersonId = null;
    _proceedAfterDuplicateCheck();
  }

  /// Apres la verification des doublons, aller a la selection du co-parent
  /// (si ajout d'enfant) ou directement creer.
  void _proceedAfterDuplicateCheck() {
    if (!widget.isParent) {
      // Charger les unions du parent pour la selection du co-parent
      _loadParentUnions();
    } else {
      _submitCreate();
    }
  }

  Future<void> _loadParentUnions() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(genealogyApiServiceProvider);
      final unions = await api.getUnionsByPerson(widget.personId);
      if (unions.isEmpty) {
        // Pas d'unions → creer directement sans co-parent
        _submitCreate();
        return;
      }
      setState(() {
        _parentUnions = unions;
        _selectedCoParent = null;
        _step = AddPersonStep.selectCoParent;
      });
    } catch (e) {
      // En cas d'erreur, on continue sans co-parent
      _submitCreate();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildCheckDuplicate() {
    final t = GwTokens.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GwInfoBanner(
          tone: GwBannerTone.ember,
          text: 'Nous avons trouve des personnes similaires. '
              'S\'agit-il de la meme personne ?',
        ),
        const SizedBox(height: 16),
        ...(_duplicateCandidates.map((person) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: t.inkLift,
                borderRadius: BorderRadius.circular(GwTokens.rBtn),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _existingPersonId = person.id;
                    });
                    _proceedAfterDuplicateCheck();
                  },
                  borderRadius: BorderRadius.circular(GwTokens.rBtn),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(GwTokens.rBtn),
                      border: Border.all(color: t.line),
                    ),
                    child: Row(
                      children: [
                        _GenderAvatar(person: person, radius: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${person.firstName} ${person.lastName}',
                                style: GwType.ui(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: t.stone),
                              ),
                              if (person.birthDate != null)
                                Text(
                                  'Ne(e) le ${DateFormat('dd/MM/yyyy').format(person.birthDate!)}',
                                  style: GwType.ui(
                                      fontSize: 12, color: t.stoneMid),
                                ),
                              if (person.clan != null && person.clan!.isNotEmpty)
                                Text(
                                  'Clan: ${person.clan}',
                                  style: GwType.ui(
                                      fontSize: 12, color: t.stoneMid),
                                ),
                            ],
                          ),
                        ),
                        Icon(Symbols.chevron_right,
                            size: 20, color: t.stoneDim),
                      ],
                    ),
                  ),
                ),
              ),
            ))),
      ],
    );
  }

  Widget _buildSelectCoParent() {
    final t = GwTokens.of(context);
    if (_parentUnions.isEmpty) {
      return Center(
        child: Text('Aucune union trouvee',
            style: GwType.ui(fontSize: 14, color: t.stoneMid)),
      );
    }

    // Extraire les conjoints (partenaires actuels et ex)
    final spouses = <PersonGenealogy>[];
    for (final union in _parentUnions) {
      final spouse = union.husbandId == widget.personId ? union.wife : union.husband;
      if (spouse != null && !spouses.any((s) => s.id == spouse.id)) {
        spouses.add(spouse);
      }
    }

    if (spouses.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Symbols.group, size: 44, color: t.stoneDim),
          const SizedBox(height: 12),
          Text(
            'Aucun conjoint trouve dans les unions.',
            textAlign: TextAlign.center,
            style: GwType.ui(fontSize: 14, color: t.stoneMid),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GwInfoBanner(
          tone: GwBannerTone.azure,
          text: 'Selectionnez le co-parent de cet enfant. '
              'Une demande de confirmation lui sera envoyee. '
              'Vous pouvez aussi passer cette etape.',
        ),
        const SizedBox(height: 16),
        Text(
          'Conjoints',
          style: GwType.ui(
              fontSize: 14, fontWeight: FontWeight.w600, color: t.stone),
        ),
        const SizedBox(height: 8),
        ...(spouses.map((spouse) {
          final selected = _selectedCoParent?.id == spouse.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Material(
              color: selected ? t.goldBg : t.inkLift,
              borderRadius: BorderRadius.circular(GwTokens.rBtn),
              child: InkWell(
                onTap: () => setState(() {
                  _selectedCoParent = selected ? null : spouse;
                }),
                borderRadius: BorderRadius.circular(GwTokens.rBtn),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(GwTokens.rBtn),
                    border: Border.all(
                      color: selected ? t.goldLine : t.line,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      _GenderAvatar(person: spouse, radius: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${spouse.firstName} ${spouse.lastName}',
                              style: GwType.ui(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: t.stone),
                            ),
                            Text(
                              _parentUnions
                                      .where((u) =>
                                          u.husbandId == spouse.id ||
                                          u.wifeId == spouse.id)
                                      .first
                                      .isActive
                                  ? 'Conjoint(e) actuel(le)'
                                  : 'Ex-conjoint(e)',
                              style:
                                  GwType.ui(fontSize: 12, color: t.stoneMid),
                            ),
                          ],
                        ),
                      ),
                      if (selected)
                        Icon(Symbols.check_circle,
                            fill: 1, color: t.goldText, size: 22),
                    ],
                  ),
                ),
              ),
            ),
          );
        })),
      ],
    );
  }

  Future<void> _submitCreate() async {
    setState(() => _loading = true);

    try {
      final notifier = ref.read(genealogyNotifierProvider.notifier);
      final email = _emailCtrl.text.trim();
      final rawPhone = _phoneCtrl.text.trim();
      final phoneCode = _selectedCountry?.phoneCode ?? '';
      final phone = rawPhone.isNotEmpty ? '$phoneCode$rawPhone' : '';
      final nativeLanguage = _selectedLanguage?.name;
      final birthDateStr = _birthDate != null
          ? DateFormat('yyyy-MM-dd').format(_birthDate!)
          : null;

      final birthPlace = _birthPlaceCtrl.text.trim().isNotEmpty
          ? _birthPlaceCtrl.text.trim()
          : null;
      final villageIds = _selectedVillages.isNotEmpty
          ? _selectedVillages.map((v) => v.id).toList()
          : null;

      // Origine — ancre de la lignée (référentiel territorial en cascade).
      String? nonEmpty(TextEditingController c) =>
          c.text.trim().isNotEmpty ? c.text.trim() : null;
      // Mapping référentiel → champs backend :
      //   originRegion  = région ; originVillage = chefferie / village ;
      //   originCity    = commune/arrondissement, sinon département.
      final originVillage = _origin.chefferieName;
      final originCity =
          _origin.arrondissementName ?? _origin.departmentName;
      final originRegion = _origin.regionName;
      // Pays d'origine : les fiches persons stockent l'ISO-2 (CountryModel.iso2,
      // ex 'CM'), pas l'ISO-3. Défaut Cameroun ('CM') si non choisi.
      final originCountry = _originCountry?.iso2 ?? 'CM';
      // Résidence — évolution. Persons stockent aussi l'ISO-2.
      final residenceCity = nonEmpty(_residenceCityCtrl);
      final residenceCountry = _residenceCountry?.iso2;

      if (widget.isParent) {
        await notifier.addParent(
          childId: widget.personId,
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          gender: _gender,
          role: _role,
          clan: _clanCtrl.text.trim().isNotEmpty ? _clanCtrl.text.trim() : null,
          totem: _totemCtrl.text.trim().isNotEmpty ? _totemCtrl.text.trim() : null,
          nativeLanguage: nativeLanguage,
          birthPlace: birthPlace,
          villageIds: villageIds,
          originVillage: originVillage,
          originCity: originCity,
          originRegion: originRegion,
          originCountry: originCountry,
          residenceCity: residenceCity,
          residenceCountry: residenceCountry,
          sendInvite: _isAlive,
          email: _isAlive ? email : null,
          phone: _isAlive && phone.isNotEmpty ? phone : null,
        );
      } else {
        await notifier.addChild(
          parentId: widget.personId,
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          gender: _gender,
          parentRole: _role,
          clan: _clanCtrl.text.trim().isNotEmpty ? _clanCtrl.text.trim() : null,
          totem: _totemCtrl.text.trim().isNotEmpty ? _totemCtrl.text.trim() : null,
          nativeLanguage: nativeLanguage,
          birthPlace: birthPlace,
          birthDate: birthDateStr,
          villageIds: villageIds,
          originVillage: originVillage,
          originCity: originCity,
          originRegion: originRegion,
          originCountry: originCountry,
          residenceCity: residenceCity,
          residenceCountry: residenceCountry,
          sendInvite: _isAlive && _showValidationSection,
          email: _isAlive && _showEmail ? email : null,
          phone: _isAlive && _showPhone && phone.isNotEmpty ? phone : null,
          coParentPersonId: _selectedCoParent?.id,
          existingPersonId: _existingPersonId,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        final msg = widget.isParent ? 'Parent ajoute' : 'Enfant ajoute';
        final extra = _selectedCoParent != null
            ? ' — demande envoyee au co-parent'
            : _isAlive
                ? ' — lien de validation envoye'
                : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$msg$extra'),
            backgroundColor: GwTokens.sage,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: GwTokens.ember),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ── Helper widgets ──

/// Intitulé de section du formulaire : mono MAJUSCULES, letterSpacing 1.6,
/// suivi d'un filet discret (charte Tissage / GwTokens).
class _FormSectionHeader extends StatelessWidget {
  const _FormSectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Row(
      children: [
        Text(
          label,
          style: GwType.mono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
            color: t.goldText,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: t.line)),
      ],
    );
  }
}

/// Bouton or plein inline (hauteur 48, rayon 14).
class _GoldButton extends StatelessWidget {
  const _GoldButton({
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    const inkOnGold = Color(0xFF0C0B0F);
    return SizedBox(
      height: 48,
      child: Material(
        color: GwTokens.gold,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: inkOnGold),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: GwType.ui(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: inkOnGold,
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

/// Bouton texte discret or (cible ≥ 44 px).
class _GoldTextButton extends StatelessWidget {
  const _GoldTextButton({
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: t.goldText,
        minimumSize: const Size(GwTokens.tapTarget, GwTokens.tapTarget),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: t.goldText),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GwType.ui(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: t.goldText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar initiales : azure (homme) / rose (femme), initiales Fraunces.
class _GenderAvatar extends StatelessWidget {
  const _GenderAvatar({required this.person, this.radius = 18});

  final PersonGenealogy person;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final isMale = person.gender == 'MALE';
    final initials =
        '${person.firstName.isNotEmpty ? person.firstName[0] : ''}${person.lastName.isNotEmpty ? person.lastName[0] : ''}'
            .toUpperCase();
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: isMale ? GwTokens.azureBg : GwTokens.roseBg,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        border: Border.all(
            color: isMale ? GwTokens.azureLine : GwTokens.roseLine),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GwType.display(
          fontSize: radius * 0.72,
          fontWeight: FontWeight.w700,
          color: isMale ? t.azureText : GwTokens.rose,
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Material(
      color: t.inkLift,
      borderRadius: BorderRadius.circular(GwTokens.rBtn),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GwTokens.rBtn),
            border: Border.all(color: t.line),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: t.goldBg,
                  borderRadius: BorderRadius.circular(GwTokens.rBtn),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: t.goldText, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GwType.ui(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: t.stone)),
                    Text(subtitle,
                        style: GwType.ui(fontSize: 12, color: t.stoneMid)),
                  ],
                ),
              ),
              Icon(Symbols.chevron_right, size: 20, color: t.stoneDim),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClanTile extends StatelessWidget {
  const _ClanTile({required this.clan, required this.onTap});

  final ClanModel clan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Material(
      color: t.inkLift,
      borderRadius: BorderRadius.circular(GwTokens.rBtn),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GwTokens.rBtn),
            border: Border.all(color: t.line),
          ),
          child: Row(
            children: [
              Icon(Symbols.shield, size: 20, color: t.goldText),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  clan.name,
                  style: GwType.ui(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: t.stone),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: t.goldBg,
                  borderRadius: BorderRadius.circular(GwTokens.rPill),
                ),
                child: Text(
                  '${clan.personCount} pers.',
                  style: GwType.mono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: t.goldText),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Symbols.chevron_right, size: 18, color: t.stoneDim),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({
    required this.person,
    required this.selected,
    required this.onTap,
  });

  final PersonGenealogy person;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? t.goldBg : t.inkLift,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(GwTokens.rBtn),
              border: Border.all(
                color: selected ? t.goldLine : t.line,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                _GenderAvatar(person: person, radius: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${person.firstName} ${person.lastName}',
                        style: GwType.ui(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: t.stone),
                      ),
                      if (person.clan != null && person.clan!.isNotEmpty)
                        Text(
                          'Clan: ${person.clan}',
                          style: GwType.ui(fontSize: 12, color: t.stoneMid),
                        ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Symbols.check_circle,
                      fill: 1, color: t.goldText, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
