import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gwangmeu/shared/models/country_model.dart';
import 'package:gwangmeu/shared/models/language_model.dart';
import 'package:gwangmeu/shared/models/village_model.dart';
import 'package:gwangmeu/shared/widgets/country_village_selector.dart';
import 'package:gwangmeu/shared/widgets/person_lookup_widget.dart';
import 'package:gwangmeu/features/geo/geo_notifier.dart';
import 'package:gwangmeu/features/genealogy/models/family_tree.dart';
import 'package:gwangmeu/features/genealogy/models/person_genealogy.dart';
import 'package:gwangmeu/features/genealogy/services/genealogy_api_service.dart';

/// Dialog pour ajouter une union (mariage/dot) a une personne.
/// Si la personne est MALE → elle est le mari, on sélectionne l'épouse.
/// Si la personne est FEMALE → elle est l'épouse, on sélectionne le mari.
class AddUnionDialog extends ConsumerStatefulWidget {
  const AddUnionDialog({
    super.key,
    required this.person,
    required this.tree,
    required this.treeOwnerId,
  });

  final PersonGenealogy person;
  final FamilyTree tree;
  final String treeOwnerId;

  @override
  ConsumerState<AddUnionDialog> createState() => _AddUnionDialogState();
}

class _AddUnionDialogState extends ConsumerState<AddUnionDialog> {
  final _formKey = GlobalKey<FormState>();

  // Spouse selection : 'existing' | 'lookup' | 'create'
  String _spouseMode = 'lookup';
  PersonGenealogy? _selectedSpouse;
  // _lookupEmail / _lookupPhone supprimés — valeurs transmises directement aux controllers

  // New spouse fields
  final _spouseFirstNameCtrl = TextEditingController();
  final _spouseLastNameCtrl = TextEditingController();
  final _spouseMaidenNameCtrl = TextEditingController();
  final _spouseClanCtrl = TextEditingController();
  final _spouseTotemCtrl = TextEditingController();
  final _spouseEmailCtrl = TextEditingController();
  final _spousePhoneCtrl = TextEditingController();
  final _spouseBirthPlaceCtrl = TextEditingController();
  final _spouseResidenceCtrl = TextEditingController();
  final _spouseReligionCtrl = TextEditingController();
  final _spouseProfessionCtrl = TextEditingController();
  final _spouseBirthDateCtrl = TextEditingController();
  DateTime? _spouseBirthDate;
  CountryModel? _spouseCountry;
  List<VillageModel> _spouseVillages = [];
  LanguageModel? _spouseLanguage;
  bool _spouseIsAlive = true;
  bool _sendInvitation = true;

  // Union details — multi-select (dot + civil + religieux, etc.)
  final Set<String> _unionTypes = {'TRADITIONAL'};
  DateTime? _startDate;
  final _startDateCtrl = TextEditingController();
  bool _isDotPaid = false;
  DateTime? _dotDate;
  final _dotDateCtrl = TextEditingController();
  final _dotDescriptionCtrl = TextEditingController();

  bool _loading = false;

  static const _unionTypeOptions = {
    'TRADITIONAL': 'Traditionnelle',
    'DOT': 'Dot',
    'CIVIL': 'Civile (Mairie)',
    'RELIGIOUS': 'Religieuse (Église)',
    'CONCUBINAGE': 'Concubinage',
  };

  bool get _isMale => widget.person.gender == 'MALE';
  String get _spouseLabel => _isMale ? 'épouse' : 'époux';

  /// Candidates = personnes du genre opposé dans l'arbre qui ne sont pas déjà
  /// en union avec la personne sélectionnée.
  List<PersonGenealogy> get _spouseCandidates {
    final targetGender = _isMale ? 'FEMALE' : 'MALE';
    final existingSpouseIds = widget.tree.unions
        .where((u) => u.isActive)
        .map((u) => _isMale ? u.wifeId : u.husbandId)
        .toSet();

    final all = <PersonGenealogy>[
      ...widget.tree.father,
      ...widget.tree.mother,
      ...widget.tree.paternalGP,
      ...widget.tree.maternalGP,
      ...widget.tree.siblings.map((s) => s.person),
      ...widget.tree.children,
      ...widget.tree.uncles,
    ];

    return all
        .where((p) =>
            p.gender == targetGender &&
            p.id != widget.person.id &&
            !existingSpouseIds.contains(p.id))
        .toSet()
        .toList();
  }

  int get _currentUnionCount =>
      widget.tree.unions.where((u) => u.isActive).length;

  @override
  void dispose() {
    _spouseFirstNameCtrl.dispose();
    _spouseLastNameCtrl.dispose();
    _spouseMaidenNameCtrl.dispose();
    _spouseClanCtrl.dispose();
    _spouseTotemCtrl.dispose();
    _spouseEmailCtrl.dispose();
    _spousePhoneCtrl.dispose();
    _spouseBirthPlaceCtrl.dispose();
    _spouseResidenceCtrl.dispose();
    _spouseReligionCtrl.dispose();
    _spouseProfessionCtrl.dispose();
    _spouseBirthDateCtrl.dispose();
    _startDateCtrl.dispose();
    _dotDateCtrl.dispose();
    _dotDescriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _unionTypes.isNotEmpty &&
        (_spouseMode == 'create' ? true : _selectedSpouse != null);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.favorite, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ajouter une union',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                Text(
                  'Pour ${widget.person.firstName} ${widget.person.lastName}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (_currentUnionCount > 0)
                  Text(
                    '$_currentUnionCount union(s) active(s) — rang ${_currentUnionCount + 1}',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: _buildForm(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton.icon(
          onPressed: (_loading || !canSubmit) ? null : _submit,
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.favorite, size: 16),
          label: const Text('Créer l\'union'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Sélection du conjoint ──
        Text(
          'Choisir l\'$_spouseLabel',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),

        // Toggle: recherche / existant dans arbre / créer
        Row(
          children: [
            Expanded(
              child: _ToggleCard(
                icon: Icons.search,
                label: 'Rechercher\n(email/tel)',
                selected: _spouseMode == 'lookup',
                onTap: () => setState(() => _spouseMode = 'lookup'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _ToggleCard(
                icon: Icons.person_search,
                label: 'Dans l\'arbre',
                selected: _spouseMode == 'existing',
                onTap: () => setState(() => _spouseMode = 'existing'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _ToggleCard(
                icon: Icons.person_add,
                label: 'Creer nouvelle',
                selected: _spouseMode == 'create',
                onTap: () => setState(() => _spouseMode = 'create'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_spouseMode == 'lookup') ...[
          PersonLookupWidget(
            label: 'Rechercher l\'$_spouseLabel par email/telephone',
            requiredGender: _isMale ? 'FEMALE' : 'MALE',
            onPersonSelected: (person) {
              setState(() {
                _selectedSpouse = person;
                _spouseMode = 'existing';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${person.firstName} ${person.lastName} selectionne(e)'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              );
            },
            onCreateNew: (email, phone) {
              setState(() {
                _spouseEmailCtrl.text = email;
                _spousePhoneCtrl.text = phone;
                _spouseMode = 'create';
              });
            },
          ),
        ] else if (_spouseMode == 'create') ...[
          _buildNewSpouseForm(),
        ] else ...[
          if (_spouseCandidates.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Aucun(e) $_spouseLabel disponible dans l\'arbre. Utilisez la recherche ou creez une nouvelle personne.',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            )
          else
            ..._spouseCandidates.map((p) => _SpouseTile(
                  person: p,
                  selected: _selectedSpouse?.id == p.id,
                  onTap: () =>
                      setState(() => _selectedSpouse = p),
                )),
        ],

        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),

        // ── Type d'union ──
        const Text(
          'Détails de l\'union',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 12),

        // Multi-select union types
        ..._unionTypeOptions.entries.map((e) => CheckboxListTile(
              value: _unionTypes.contains(e.key),
              title: Text(e.value, style: const TextStyle(fontSize: 13)),
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _unionTypes.add(e.key);
                  } else {
                    _unionTypes.remove(e.key);
                  }
                  if (e.key == 'DOT') {
                    _isDotPaid = _unionTypes.contains('DOT');
                  }
                });
              },
            )),
        if (_unionTypes.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text('Sélectionnez au moins un type',
                style: TextStyle(color: Colors.red, fontSize: 11)),
          ),
        const SizedBox(height: 12),

        // Date de début
        GestureDetector(
          onTap: () => _pickDate(field: 'start'),
          child: AbsorbPointer(
            child: TextFormField(
              controller: _startDateCtrl,
              decoration: const InputDecoration(
                labelText: 'Date de l\'union',
                prefixIcon: Icon(Icons.calendar_today_outlined),
                hintText: 'JJ/MM/AAAA',
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Dot ──
        SwitchListTile(
          title: const Text('Dot payée ?'),
          subtitle: Text(
            _isDotPaid
                ? 'Les détails de la dot seront enregistrés'
                : 'La dot n\'a pas encore été versée',
            style: TextStyle(
                fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
          ),
          value: _isDotPaid,
          activeThumbColor: Theme.of(context).colorScheme.primary,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => setState(() => _isDotPaid = v),
        ),

        if (_isDotPaid) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _pickDate(field: 'dot'),
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _dotDateCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Date de la dot',
                        prefixIcon: Icon(Icons.event_outlined),
                        hintText: 'JJ/MM/AAAA',
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _dotDescriptionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description de la dot',
                    prefixIcon: Icon(Icons.description_outlined),
                    hintText: 'Ex: 10 chèvres, bijoux...',
                    isDense: true,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],

        // ── Info rang polygamie ──
        if (_currentUnionCount > 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cette union sera enregistrée au rang ${_currentUnionCount + 1}. '
                    '${widget.person.firstName} a déjà $_currentUnionCount union(s) active(s).',
                    style:
                        const TextStyle(fontSize: 11, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Formulaire complet pour créer un nouveau conjoint
  Widget _buildNewSpouseForm() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations de l\'$_spouseLabel',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 12),

          // Prénom + Nom (ligne)
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _spouseFirstNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Prénom *',
                    prefixIcon: Icon(Icons.person_outline),
                    isDense: true,
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _spouseLastNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom *',
                    prefixIcon: Icon(Icons.badge_outlined),
                    isDense: true,
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Nom de jeune fille (si épouse)
          if (_isMale)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextFormField(
                controller: _spouseMaidenNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom de jeune fille',
                  prefixIcon: Icon(Icons.person_outline),
                  isDense: true,
                ),
              ),
            ),

          // Clan + Totem
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _spouseClanCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Clan',
                    prefixIcon: Icon(Icons.groups_outlined),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _spouseTotemCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Totem',
                    prefixIcon: Icon(Icons.pets_outlined),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Date de naissance
          GestureDetector(
            onTap: () => _pickDate(field: 'birth'),
            child: AbsorbPointer(
              child: TextFormField(
                controller: _spouseBirthDateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Date de naissance',
                  prefixIcon: Icon(Icons.cake_outlined),
                  hintText: 'JJ/MM/AAAA',
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Lieu de naissance (texte libre)
          TextFormField(
            controller: _spouseBirthPlaceCtrl,
            decoration: const InputDecoration(
              labelText: 'Lieu de naissance',
              prefixIcon: Icon(Icons.location_city_outlined),
              hintText: 'Ex: Douala, Paris...',
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),

          // Pays d'origine + Village d'appartenance
          CountryVillageSelector(
            selectedCountry: _spouseCountry,
            selectedVillages: _spouseVillages,
            multiSelect: true,
            onCountryChanged: (c) => setState(() {
              _spouseCountry = c;
              _spouseVillages = [];
              _spouseLanguage = null;
            }),
            onVillagesChanged: (v) => setState(() => _spouseVillages = v),
            isDense: true,
          ),
          const SizedBox(height: 10),

          // Langue + Religion
          Row(
            children: [
              Expanded(child: _buildSpouseLanguageDropdown()),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _spouseReligionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Religion',
                    prefixIcon: Icon(Icons.church_outlined),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Profession + Résidence
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _spouseProfessionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Profession',
                    prefixIcon: Icon(Icons.work_outline),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _spouseResidenceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Lieu de résidence',
                    prefixIcon: Icon(Icons.home_outlined),
                    hintText: 'Ex: Paris, Douala...',
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Vivant(e) ?
          SwitchListTile(
            title: Text('${_isMale ? 'Elle' : 'Il'} est en vie ?'),
            value: _spouseIsAlive,
            activeThumbColor: Theme.of(context).colorScheme.primary,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() {
              _spouseIsAlive = v;
              if (!v) _sendInvitation = false;
            }),
          ),

          // Contact + invitation (seulement si vivant)
          if (_spouseIsAlive) ...[
            const Divider(),
            const SizedBox(height: 4),
            Text(
              'Contact (pour invitation)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),

            // Email + Téléphone
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _spouseEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      isDense: true,
                    ),
                    validator: (v) {
                      if (v != null && v.isNotEmpty && !v.contains('@')) {
                        return 'Email invalide';
                      }
                      if (_sendInvitation && (v == null || v.isEmpty)) {
                        return 'Email requis pour l\'invitation';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _spousePhoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Téléphone',
                      prefixIcon: Icon(Icons.phone_outlined),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Toggle invitation
            CheckboxListTile(
              value: _sendInvitation,
              title: const Text(
                'Envoyer une invitation par email',
                style: TextStyle(fontSize: 13),
              ),
              subtitle: Text(
                'Un email sera envoyé pour créer son compte et confirmer le lien',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              activeColor: Theme.of(context).colorScheme.primary,
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (v) => setState(() => _sendInvitation = v ?? false),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpouseLanguageDropdown() {
    final langAsync = ref.watch(
      languagesByCountryNotifierProvider(_spouseCountry?.isoCode),
    );
    return langAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
      data: (languages) {
        if (languages.isEmpty) return const SizedBox.shrink();
        return DropdownButtonFormField<LanguageModel>(
          value: _spouseLanguage,
          decoration: const InputDecoration(
            labelText: 'Langue maternelle',
            prefixIcon: Icon(Icons.translate),
            isDense: true,
          ),
          isExpanded: true,
          items: languages
              .map((l) => DropdownMenuItem(
                    value: l,
                    child: Text(l.name, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (l) => setState(() => _spouseLanguage = l),
        );
      },
    );
  }

  Future<void> _pickDate({required String field}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: field == 'birth' ? DateTime(1990) : DateTime.now(),
      firstDate: DateTime(1800),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final formatted =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      setState(() {
        switch (field) {
          case 'start':
            _startDate = picked;
            _startDateCtrl.text = formatted;
            break;
          case 'dot':
            _dotDate = picked;
            _dotDateCtrl.text = formatted;
            break;
          case 'birth':
            _spouseBirthDate = picked;
            _spouseBirthDateCtrl.text = formatted;
            break;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final api = ref.read(genealogyApiServiceProvider);
      String spouseId;

      if (_spouseMode == 'create') {
        // Créer la personne avec toutes les infos
        final spouseGender = _isMale ? 'FEMALE' : 'MALE';
        final personData = <String, dynamic>{
          'firstName': _spouseFirstNameCtrl.text.trim(),
          'lastName': _spouseLastNameCtrl.text.trim(),
          'gender': spouseGender,
        };

        // Si décédé(e), on envoie deathDate pour que isAlive() retourne false
        if (!_spouseIsAlive) {
          personData['deathDate'] = '1900-01-01';
        }

        if (_spouseMaidenNameCtrl.text.trim().isNotEmpty) {
          personData['maidenName'] = _spouseMaidenNameCtrl.text.trim();
        }
        if (_spouseClanCtrl.text.trim().isNotEmpty) {
          personData['clan'] = _spouseClanCtrl.text.trim();
        }
        if (_spouseTotemCtrl.text.trim().isNotEmpty) {
          personData['totem'] = _spouseTotemCtrl.text.trim();
        }
        if (_spouseLanguage != null) {
          personData['nativeLanguage'] = _spouseLanguage!.name;
        }
        if (_spouseEmailCtrl.text.trim().isNotEmpty) {
          personData['email'] = _spouseEmailCtrl.text.trim();
        }
        if (_spousePhoneCtrl.text.trim().isNotEmpty) {
          personData['phone'] = _spousePhoneCtrl.text.trim();
        }
        if (_spouseReligionCtrl.text.trim().isNotEmpty) {
          personData['religion'] = _spouseReligionCtrl.text.trim();
        }
        if (_spouseProfessionCtrl.text.trim().isNotEmpty) {
          personData['profession'] = _spouseProfessionCtrl.text.trim();
        }
        if (_spouseBirthPlaceCtrl.text.trim().isNotEmpty) {
          personData['birthPlace'] = _spouseBirthPlaceCtrl.text.trim();
        }
        if (_spouseVillages.isNotEmpty) {
          personData['villageIds'] = _spouseVillages.map((v) => v.id).toList();
        }
        if (_spouseBirthDate != null) {
          personData['birthDate'] =
              _spouseBirthDate!.toIso8601String().split('T').first;
        }

        final created = await api.createPerson(personData);
        spouseId = created.id;

        // Envoyer une invitation si demandé
        if (_sendInvitation && _spouseIsAlive && _spouseEmailCtrl.text.trim().isNotEmpty) {
          try {
            await api.invitePerson(
              personId: spouseId,
              email: _spouseEmailCtrl.text.trim(),
              phone: _spousePhoneCtrl.text.trim().isNotEmpty
                  ? _spousePhoneCtrl.text.trim()
                  : null,
              invitationType: 'SPOUSE',
            );
          } catch (inviteError) {
            // L'invitation a échoué mais la personne est créée — on continue
            debugPrint('Invitation failed: $inviteError');
          }
        }
      } else {
        spouseId = _selectedSpouse!.id;
      }

      // Construire la requête d'union
      final husbandId = _isMale ? widget.person.id : spouseId;
      final wifeId = _isMale ? spouseId : widget.person.id;

      final data = <String, dynamic>{
        'husbandId': husbandId,
        'wifeId': wifeId,
        'unionTypes': _unionTypes.toList(),
        'isDotPaid': _isDotPaid,
      };

      if (_startDate != null) {
        data['startDate'] =
            _startDate!.toIso8601String().split('T').first;
      }
      if (_isDotPaid && _dotDate != null) {
        data['dotDate'] =
            _dotDate!.toIso8601String().split('T').first;
      }
      if (_isDotPaid && _dotDescriptionCtrl.text.trim().isNotEmpty) {
        data['dotDescription'] = _dotDescriptionCtrl.text.trim();
      }

      await api.createUnion(data);

      // Invalider l'arbre pour rafraîchir
      ref.invalidate(familyTreeProvider(widget.treeOwnerId));

      if (mounted) {
        Navigator.of(context).pop();
        final msg = _spouseMode == 'create' && _sendInvitation && _spouseIsAlive && _spouseEmailCtrl.text.trim().isNotEmpty
            ? 'Union créée ! Invitation envoyée à ${_spouseEmailCtrl.text.trim()}'
            : 'Union créée avec succès';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ── Helper widgets ──

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? accent : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 24, color: selected ? accent : Colors.grey),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
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

class _SpouseTile extends StatelessWidget {
  const _SpouseTile({
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
        '${person.firstName.isNotEmpty ? person.firstName[0] : ''}${person.lastName.isNotEmpty ? person.lastName[0] : ''}'
            .toUpperCase();

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
            color: selected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
                : null,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: person.gender == 'MALE'
                    ? Colors.blue.shade100
                    : Colors.pink.shade100,
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: person.gender == 'MALE'
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
                      '${person.firstName} ${person.lastName}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (person.clan != null && person.clan!.isNotEmpty)
                      Text(
                        'Clan: ${person.clan}',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
