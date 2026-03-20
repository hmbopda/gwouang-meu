import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:gwangmeu/shared/models/country_model.dart';
import 'package:gwangmeu/shared/models/language_model.dart';
import 'package:gwangmeu/shared/models/village_model.dart';
import 'package:gwangmeu/shared/widgets/country_village_selector.dart';
import 'package:gwangmeu/shared/widgets/person_lookup_widget.dart';
import 'package:gwangmeu/features/geo/geo_notifier.dart';
import 'package:gwangmeu/features/genealogy/genealogy_notifier.dart';
import 'package:gwangmeu/features/genealogy/models/clan_model.dart';
import 'package:gwangmeu/features/genealogy/models/genealogy_union.dart';
import 'package:gwangmeu/features/genealogy/models/person_genealogy.dart';
import 'package:gwangmeu/features/genealogy/services/genealogy_api_service.dart';

enum AddPersonStep { chooseAction, lookupContact, selectClan, selectPerson, createForm, checkDuplicate, selectCoParent }

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
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _gender = 'MALE';
  bool _isAlive = true;
  bool _loading = false;
  CountryModel? _selectedCountry;
  List<VillageModel> _selectedVillages = [];
  LanguageModel? _selectedLanguage;
  String? _selectedPhoneCode;
  DateTime? _birthDate;

  // Deduplication
  List<PersonGenealogy> _duplicateCandidates = [];

  // Co-parent selection
  List<GenealogyUnion> _parentUnions = [];
  PersonGenealogy? _selectedCoParent;
  String? _existingPersonId;

  @override
  void initState() {
    super.initState();
    _role = widget.isParent ? 'FATHER' : 'FATHER';
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _clanCtrl.dispose();
    _totemCtrl.dispose();
    _birthPlaceCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String get _genderFilter => _role == 'FATHER' ? 'MALE' : 'FEMALE';
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

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(title),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildStepContent(),
              ),
            ),
            const Divider(height: 1),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
      child: Row(
        children: [
          Icon(
            widget.isParent ? Icons.person_add_alt_1 : Icons.child_care,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                if (_step != AddPersonStep.chooseAction)
                  Text(
                    _stepSubtitle(),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  String _stepSubtitle() {
    switch (_step) {
      case AddPersonStep.chooseAction:
        return '';
      case AddPersonStep.lookupContact:
        return 'Recherche par email / telephone';
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.isParent) ...[
          const Text(
            'Quel role parental ?',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ChoiceChipCard(
                  icon: Icons.man,
                  label: 'Pere',
                  selected: _role == 'FATHER',
                  onTap: () => setState(() => _role = 'FATHER'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ChoiceChipCard(
                  icon: Icons.woman,
                  label: 'Mere',
                  selected: _role == 'MOTHER',
                  onTap: () => setState(() => _role = 'MOTHER'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
        const Text(
          'Comment souhaitez-vous proceder ?',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 12),
        _ActionTile(
          icon: Icons.email_outlined,
          title: 'Rechercher par email / telephone',
          subtitle: 'Verifier si la personne existe deja en base',
          onTap: () => setState(() => _step = AddPersonStep.lookupContact),
        ),
        const SizedBox(height: 10),
        _ActionTile(
          icon: Icons.search,
          title: 'Parcourir les grandes familles',
          subtitle: 'Rechercher dans les villages',
          onTap: _goToSelectClan,
        ),
        const SizedBox(height: 10),
        _ActionTile(
          icon: Icons.person_add,
          title: 'Creer une nouvelle personne',
          subtitle: 'Remplir les informations manuellement',
          onTap: () => setState(() {
            _gender = _role == 'FATHER' ? 'MALE' : 'FEMALE';
            _step = AddPersonStep.createForm;
          }),
        ),
      ],
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
          _gender = _role == 'FATHER' ? 'MALE' : 'FEMALE';
          _step = AddPersonStep.createForm;
        });
      },
    );
  }

  Future<void> _goToSelectClan() async {
    final myPerson = ref.read(genealogyNotifierProvider).valueOrNull;
    if (myPerson == null || myPerson.villageIds.isEmpty) {
      setState(() {
        _gender = _role == 'FATHER' ? 'MALE' : 'FEMALE';
        _step = AddPersonStep.createForm;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun village associe. Veuillez creer la personne manuellement.'),
            backgroundColor: Colors.orange,
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
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildSelectClan() {
    if (_searchLoading) {
      return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
    }

    if (_clans.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.family_restroom, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          const Text(
            'Aucune grande famille trouvee dans vos villages.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => setState(() {
              _gender = _role == 'FATHER' ? 'MALE' : 'FEMALE';
              _step = AddPersonStep.createForm;
            }),
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Creer manuellement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.black,
            ),
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
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          'Selectionnez la grande famille ou cliquez "Voir tous" pour afficher toutes les personnes.',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        _ActionTile(
          icon: Icons.people_outline,
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
          child: TextButton.icon(
            onPressed: () => setState(() {
              _gender = _role == 'FATHER' ? 'MALE' : 'FEMALE';
              _step = AddPersonStep.createForm;
            }),
            icon: const Icon(Icons.person_add, size: 16),
            label: const Text('Je ne trouve pas, creer manuellement'),
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
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
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
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildSelectPerson() {
    if (_searchLoading) {
      return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
    }

    final clanLabel = _selectedClan != null
        ? 'Grande famille "${_selectedClan!.name}"'
        : 'Toutes les personnes';

    if (_searchResults.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_search, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            'Aucun(e) ${_genderLabel.toLowerCase()} trouve(e) dans $clanLabel.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => setState(() => _step = AddPersonStep.selectClan),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Retour'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => setState(() {
                  _gender = _role == 'FATHER' ? 'MALE' : 'FEMALE';
                  _step = AddPersonStep.createForm;
                }),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Creer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.black,
                ),
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
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          'Selectionnez la personne a lier comme ${widget.isParent ? "parent" : "enfant"}.',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        ...(_searchResults.map((person) => _PersonTile(
              person: person,
              selected: _selectedPerson?.id == person.id,
              onTap: () => setState(() => _selectedPerson = person),
            ))),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: () => setState(() {
              _gender = _role == 'FATHER' ? 'MALE' : 'FEMALE';
              _step = AddPersonStep.createForm;
            }),
            icon: const Icon(Icons.person_add, size: 16),
            label: const Text('Je ne trouve pas, creer manuellement'),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _firstNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Prenom *',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _lastNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nom *',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _gender,
            decoration: const InputDecoration(
              labelText: 'Genre *',
              prefixIcon: Icon(Icons.wc_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'MALE', child: Text('Homme')),
              DropdownMenuItem(value: 'FEMALE', child: Text('Femme')),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _gender = v;
                if (widget.isParent) {
                  _role = v == 'MALE' ? 'FATHER' : 'MOTHER';
                }
              });
            },
          ),
          if (widget.isParent) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: const InputDecoration(
                labelText: 'Role parental *',
                prefixIcon: Icon(Icons.family_restroom),
              ),
              items: const [
                DropdownMenuItem(value: 'FATHER', child: Text('Pere')),
                DropdownMenuItem(value: 'MOTHER', child: Text('Mere')),
              ],
              onChanged: (v) => setState(() => _role = v ?? _role),
            ),
          ],
          const SizedBox(height: 12),
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
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date de naissance',
                prefixIcon: Icon(Icons.cake_outlined),
              ),
              child: Text(
                _birthDate != null
                    ? DateFormat('dd/MM/yyyy').format(_birthDate!)
                    : 'Selectionner une date',
                style: TextStyle(
                  color: _birthDate != null ? null : Colors.grey[600],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _clanCtrl,
            decoration: const InputDecoration(
              labelText: 'Clan / Grande famille',
              prefixIcon: Icon(Icons.shield_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _totemCtrl,
            decoration: const InputDecoration(
              labelText: 'Totem',
              prefixIcon: Icon(Icons.pets_outlined),
            ),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          _buildLanguageDropdown(),
          const SizedBox(height: 12),
          TextFormField(
            controller: _birthPlaceCtrl,
            decoration: const InputDecoration(
              labelText: 'Lieu de naissance',
              prefixIcon: Icon(Icons.location_city_outlined),
              hintText: 'Ex: Douala, Paris, Yaoundé...',
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Encore en vie ?'),
            subtitle: Text(
              _isAlive
                  ? 'Vous pourrez lui envoyer une invitation'
                  : 'La personne est decedee',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            value: _isAlive,
            activeThumbColor: Theme.of(context).colorScheme.primary,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _isAlive = v),
          ),
          if (_isAlive && _showValidationSection) ...[
            const SizedBox(height: 8),
            Builder(builder: (context) {
              final accent = Theme.of(context).colorScheme.primary;
              return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.send_outlined, size: 16, color: accent),
                      const SizedBox(width: 6),
                      Text(
                        'Lien de validation',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Un lien de validation sera envoye a cette personne pour qu\'elle confirme son identite et cree son compte.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  if (_showEmail) ...[
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        prefixIcon: Icon(Icons.email_outlined),
                        isDense: true,
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
            );
            }),
          ],
          if (_isAlive && !_showValidationSection && !widget.isParent) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withAlpha(40)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cet enfant a moins de 4 ans. Aucun email ni telephone n\'est requis. '
                      'Les parents pourront modifier ses informations depuis leur compte.',
                      style: TextStyle(fontSize: 11, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLanguageDropdown() {
    final langAsync = ref.watch(
      languagesByCountryNotifierProvider(_selectedCountry?.isoCode),
    );
    return langAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
      data: (languages) {
        if (languages.isEmpty) return const SizedBox.shrink();
        return DropdownButtonFormField<LanguageModel>(
          value: _selectedLanguage,
          decoration: const InputDecoration(
            labelText: 'Langue maternelle',
            prefixIcon: Icon(Icons.translate_outlined),
          ),
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
                    ),
                  ))
              .toList(),
          onChanged: (l) => setState(() => _selectedLanguage = l),
        );
      },
    );
  }

  Widget _buildPhoneRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            value: _selectedPhoneCode,
            decoration: const InputDecoration(
              labelText: 'Indicatif',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            ),
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
            decoration: const InputDecoration(
              labelText: 'Téléphone',
              prefixIcon: Icon(Icons.phone_outlined),
              isDense: true,
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
                  style: const TextStyle(fontSize: 13),
                ),
              ))
          .toList(),
      orElse: () => [],
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_step != AddPersonStep.chooseAction)
            TextButton.icon(
              onPressed: _loading ? null : _goBack,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Retour'),
            ),
          TextButton(
            onPressed: _loading ? null : () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          if (_step == AddPersonStep.selectPerson && _selectedPerson != null)
            ElevatedButton(
              onPressed: _loading ? null : _linkSelectedPerson,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.black,
              ),
              child: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Confirmer'),
            ),
          if (_step == AddPersonStep.createForm)
            ElevatedButton(
              onPressed: _loading ? null : _onCreateFormNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.black,
              ),
              child: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Suivant'),
            ),
          if (_step == AddPersonStep.checkDuplicate)
            ElevatedButton(
              onPressed: _loading ? null : _onDuplicateSkip,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.black,
              ),
              child: const Text('Creer quand meme'),
            ),
          if (_step == AddPersonStep.selectCoParent)
            ElevatedButton(
              onPressed: _loading ? null : _submitCreate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.black,
              ),
              child: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_selectedCoParent != null ? 'Enregistrer' : 'Sans co-parent'),
            ),
        ],
      ),
    );
  }

  void _goBack() {
    setState(() {
      switch (_step) {
        case AddPersonStep.lookupContact:
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
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withAlpha(60)),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber, size: 20, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nous avons trouve des personnes similaires. '
                  'S\'agit-il de la meme personne ?',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...(_duplicateCandidates.map((person) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _existingPersonId = person.id;
                  });
                  _proceedAfterDuplicateCheck();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: person.gender == 'MALE'
                            ? Colors.blue.shade100
                            : Colors.pink.shade100,
                        child: Text(
                          '${person.firstName.isNotEmpty ? person.firstName[0] : ''}${person.lastName.isNotEmpty ? person.lastName[0] : ''}'
                              .toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: person.gender == 'MALE'
                                ? Colors.blue.shade700
                                : Colors.pink.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${person.firstName} ${person.lastName}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            if (person.birthDate != null)
                              Text(
                                'Ne(e) le ${DateFormat('dd/MM/yyyy').format(person.birthDate!)}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            if (person.clan != null && person.clan!.isNotEmpty)
                              Text(
                                'Clan: ${person.clan}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ))),
      ],
    );
  }

  Widget _buildSelectCoParent() {
    if (_parentUnions.isEmpty) {
      return const Center(child: Text('Aucune union trouvee'));
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
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'Aucun conjoint trouve dans les unions.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha(15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withAlpha(40)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Selectionnez le co-parent de cet enfant. '
                  'Une demande de confirmation lui sera envoyee. '
                  'Vous pouvez aussi passer cette etape.',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Conjoints',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...(spouses.map((spouse) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: () => setState(() {
                  _selectedCoParent = _selectedCoParent?.id == spouse.id ? null : spouse;
                }),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedCoParent?.id == spouse.id
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade200,
                      width: _selectedCoParent?.id == spouse.id ? 2 : 1,
                    ),
                    color: _selectedCoParent?.id == spouse.id
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
                        : null,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: spouse.gender == 'MALE'
                            ? Colors.blue.shade100
                            : Colors.pink.shade100,
                        child: Text(
                          '${spouse.firstName.isNotEmpty ? spouse.firstName[0] : ''}${spouse.lastName.isNotEmpty ? spouse.lastName[0] : ''}'
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: spouse.gender == 'MALE'
                                ? Colors.blue.shade700
                                : Colors.pink.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${spouse.firstName} ${spouse.lastName}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
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
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedCoParent?.id == spouse.id)
                        Icon(Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary, size: 22),
                    ],
                  ),
                ),
              ),
            ))),
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
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
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

// ── Helper widgets ──

class _ChoiceChipCard extends StatelessWidget {
  const _ChoiceChipCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? accent : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: selected ? accent : Colors.grey),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? accent : null,
              ),
            ),
          ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Icon(Icons.shield_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                clan.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${clan.personCount} pers.',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
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
    final initials =
        '${person.firstName.isNotEmpty ? person.firstName[0] : ''}${person.lastName.isNotEmpty ? person.lastName[0] : ''}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
              width: selected ? 2 : 1,
            ),
            color: selected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08) : null,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: person.gender == 'MALE'
                    ? Colors.blue.shade100
                    : Colors.pink.shade100,
                child: Text(
                  initials.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: person.gender == 'MALE' ? Colors.blue.shade700 : Colors.pink.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${person.firstName} ${person.lastName}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (person.clan != null && person.clan!.isNotEmpty)
                      Text(
                        'Clan: ${person.clan}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
