import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/shared/models/country_model.dart';
import 'package:gwangmeu/shared/models/language_model.dart';
import 'package:gwangmeu/shared/models/village_model.dart';
import 'package:gwangmeu/shared/widgets/country_village_selector.dart';
import 'package:gwangmeu/shared/widgets/gw_dialog.dart';
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

    final subtitleParts = [
      'Pour ${widget.person.firstName} ${widget.person.lastName}',
      if (_currentUnionCount > 0)
        '$_currentUnionCount union(s) active(s) — rang ${_currentUnionCount + 1}',
    ];

    return GwDialog(
      title: 'Ajouter une union',
      subtitle: subtitleParts.join('\n'),
      icon: Symbols.favorite,
      maxWidth: 560,
      actions: [
        GwDialogAction(
          label: 'Annuler',
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
        ),
        GwDialogAction(
          label: 'Créer l\'union',
          icon: Symbols.favorite,
          primary: true,
          loading: _loading,
          onPressed: (_loading || !canSubmit) ? null : _submit,
        ),
      ],
      child: Form(
        key: _formKey,
        child: _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    final t = GwTokens.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Sélection du conjoint ──
        Text(
          'Choisir l\'$_spouseLabel',
          style: GwType.ui(
              fontSize: 14, fontWeight: FontWeight.w600, color: t.stone),
        ),
        const SizedBox(height: 8),

        // Toggle: recherche / existant dans arbre / créer
        Row(
          children: [
            Expanded(
              child: GwChoicePill(
                icon: Symbols.search,
                label: 'Rechercher',
                expand: true,
                selected: _spouseMode == 'lookup',
                onTap: () => setState(() => _spouseMode = 'lookup'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: GwChoicePill(
                icon: Symbols.person_search,
                label: 'Dans l\'arbre',
                expand: true,
                selected: _spouseMode == 'existing',
                onTap: () => setState(() => _spouseMode = 'existing'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: GwChoicePill(
                icon: Symbols.person_add,
                label: 'Creer',
                expand: true,
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
                  backgroundColor: GwTokens.sage,
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
            GwInfoBanner(
              tone: GwBannerTone.ember,
              icon: Symbols.info,
              text:
                  'Aucun(e) $_spouseLabel disponible dans l\'arbre. Utilisez la recherche ou creez une nouvelle personne.',
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
        Container(height: 1, color: t.line),
        const SizedBox(height: 12),

        // ── Type d'union ──
        Text(
          'Détails de l\'union',
          style: GwType.ui(
              fontSize: 14, fontWeight: FontWeight.w600, color: t.stone),
        ),
        const SizedBox(height: 12),

        // Multi-select union types (pilules or)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _unionTypeOptions.entries
              .map((e) => GwChoicePill(
                    label: e.value,
                    selected: _unionTypes.contains(e.key),
                    onTap: () {
                      setState(() {
                        if (_unionTypes.contains(e.key)) {
                          _unionTypes.remove(e.key);
                        } else {
                          _unionTypes.add(e.key);
                        }
                        if (e.key == 'DOT') {
                          _isDotPaid = _unionTypes.contains('DOT');
                        }
                      });
                    },
                  ))
              .toList(),
        ),
        if (_unionTypes.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Sélectionnez au moins un type',
                style: GwType.ui(fontSize: 12, color: t.emberText)),
          ),
        const SizedBox(height: 14),

        // Date de début
        GestureDetector(
          onTap: () => _pickDate(field: 'start'),
          child: AbsorbPointer(
            child: TextFormField(
              controller: _startDateCtrl,
              style: GwType.ui(fontSize: 14, color: t.stone),
              decoration: gwInputDecoration(
                context,
                label: 'Date de l\'union',
                prefixIcon: Symbols.calendar_today,
                hint: 'JJ/MM/AAAA',
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Dot ──
        SwitchListTile(
          title: Text('Dot payée ?',
              style: GwType.ui(fontSize: 14, color: t.stone)),
          subtitle: Text(
            _isDotPaid
                ? 'Les détails de la dot seront enregistrés'
                : 'La dot n\'a pas encore été versée',
            style: GwType.ui(fontSize: 12, color: t.stoneMid),
          ),
          value: _isDotPaid,
          activeThumbColor: GwTokens.gold,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => setState(() => _isDotPaid = v),
        ),

        if (_isDotPaid) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: t.goldBg,
              borderRadius: BorderRadius.circular(GwTokens.rBtn),
              border: Border.all(color: t.goldLine),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _pickDate(field: 'dot'),
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _dotDateCtrl,
                      style: GwType.ui(fontSize: 14, color: t.stone),
                      decoration: gwInputDecoration(
                        context,
                        label: 'Date de la dot',
                        prefixIcon: Symbols.event,
                        hint: 'JJ/MM/AAAA',
                        dense: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _dotDescriptionCtrl,
                  style: GwType.ui(fontSize: 14, color: t.stone),
                  decoration: gwInputDecoration(
                    context,
                    label: 'Description de la dot',
                    prefixIcon: Symbols.description,
                    hint: 'Ex: 10 chèvres, bijoux...',
                    dense: true,
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
          GwInfoBanner(
            tone: GwBannerTone.azure,
            text:
                'Cette union sera enregistrée au rang ${_currentUnionCount + 1}. '
                '${widget.person.firstName} a déjà $_currentUnionCount union(s) active(s).',
          ),
        ],
      ],
    );
  }

  /// Formulaire complet pour créer un nouveau conjoint
  Widget _buildNewSpouseForm() {
    final t = GwTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GwTokens.rCard),
        border: Border.all(color: t.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations de l\'$_spouseLabel',
            style: GwType.ui(
                fontSize: 13, fontWeight: FontWeight.w600, color: t.stone),
          ),
          const SizedBox(height: 12),

          // Prénom + Nom (ligne)
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _spouseFirstNameCtrl,
                  style: GwType.ui(fontSize: 14, color: t.stone),
                  decoration: gwInputDecoration(
                    context,
                    label: 'Prénom *',
                    prefixIcon: Symbols.person,
                    dense: true,
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _spouseLastNameCtrl,
                  style: GwType.ui(fontSize: 14, color: t.stone),
                  decoration: gwInputDecoration(
                    context,
                    label: 'Nom *',
                    prefixIcon: Symbols.badge,
                    dense: true,
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
                style: GwType.ui(fontSize: 14, color: t.stone),
                decoration: gwInputDecoration(
                  context,
                  label: 'Nom de jeune fille',
                  prefixIcon: Symbols.person,
                  dense: true,
                ),
              ),
            ),

          // Clan + Totem
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _spouseClanCtrl,
                  style: GwType.ui(fontSize: 14, color: t.stone),
                  decoration: gwInputDecoration(
                    context,
                    label: 'Clan',
                    prefixIcon: Symbols.groups,
                    dense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _spouseTotemCtrl,
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
          const SizedBox(height: 10),

          // Date de naissance
          GestureDetector(
            onTap: () => _pickDate(field: 'birth'),
            child: AbsorbPointer(
              child: TextFormField(
                controller: _spouseBirthDateCtrl,
                style: GwType.ui(fontSize: 14, color: t.stone),
                decoration: gwInputDecoration(
                  context,
                  label: 'Date de naissance',
                  prefixIcon: Symbols.cake,
                  hint: 'JJ/MM/AAAA',
                  dense: true,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Lieu de naissance (texte libre)
          TextFormField(
            controller: _spouseBirthPlaceCtrl,
            style: GwType.ui(fontSize: 14, color: t.stone),
            decoration: gwInputDecoration(
              context,
              label: 'Lieu de naissance',
              prefixIcon: Symbols.location_city,
              hint: 'Ex: Douala, Paris...',
              dense: true,
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
                  style: GwType.ui(fontSize: 14, color: t.stone),
                  decoration: gwInputDecoration(
                    context,
                    label: 'Religion',
                    prefixIcon: Symbols.church,
                    dense: true,
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
                  style: GwType.ui(fontSize: 14, color: t.stone),
                  decoration: gwInputDecoration(
                    context,
                    label: 'Profession',
                    prefixIcon: Symbols.work,
                    dense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _spouseResidenceCtrl,
                  style: GwType.ui(fontSize: 14, color: t.stone),
                  decoration: gwInputDecoration(
                    context,
                    label: 'Lieu de résidence',
                    prefixIcon: Symbols.home,
                    hint: 'Ex: Paris, Douala...',
                    dense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Vivant(e) ?
          SwitchListTile(
            title: Text('${_isMale ? 'Elle' : 'Il'} est en vie ?',
                style: GwType.ui(fontSize: 14, color: t.stone)),
            value: _spouseIsAlive,
            activeThumbColor: GwTokens.gold,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() {
              _spouseIsAlive = v;
              if (!v) _sendInvitation = false;
            }),
          ),

          // Contact + invitation (seulement si vivant)
          if (_spouseIsAlive) ...[
            Container(height: 1, color: t.line),
            const SizedBox(height: 10),
            Text(
              'Contact (pour invitation)',
              style: GwType.ui(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: t.stoneMid,
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
                    style: GwType.ui(fontSize: 14, color: t.stone),
                    decoration: gwInputDecoration(
                      context,
                      label: 'Email',
                      prefixIcon: Symbols.mail,
                      dense: true,
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
                    style: GwType.ui(fontSize: 14, color: t.stone),
                    decoration: gwInputDecoration(
                      context,
                      label: 'Téléphone',
                      prefixIcon: Symbols.call,
                      dense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Toggle invitation
            CheckboxListTile(
              value: _sendInvitation,
              title: Text(
                'Envoyer une invitation par email',
                style: GwType.ui(fontSize: 13, color: t.stone),
              ),
              subtitle: Text(
                'Un email sera envoyé pour créer son compte et confirmer le lien',
                style: GwType.ui(fontSize: 12, color: t.stoneMid),
              ),
              activeColor: GwTokens.gold,
              checkColor: const Color(0xFF0C0B0F),
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
    final t = GwTokens.of(context);
    final langAsync = ref.watch(
      languagesByCountryNotifierProvider(_spouseCountry?.isoCode),
    );
    return langAsync.when(
      loading: () => LinearProgressIndicator(
          color: t.goldText, backgroundColor: t.inkLift),
      error: (_, __) => const SizedBox.shrink(),
      data: (languages) {
        if (languages.isEmpty) return const SizedBox.shrink();
        return DropdownButtonFormField<LanguageModel>(
          key: ValueKey(
              'spouselang_${_spouseCountry?.isoCode}_${_spouseLanguage?.name}'),
          initialValue: _spouseLanguage,
          decoration: gwInputDecoration(
            context,
            label: 'Langue maternelle',
            prefixIcon: Symbols.translate,
            dense: true,
          ),
          dropdownColor: t.inkCard,
          style: GwType.ui(fontSize: 14, color: t.stone),
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
            backgroundColor: GwTokens.sage,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: GwTokens.ember,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ── Helper widgets ──

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
    final t = GwTokens.of(context);
    final isMale = person.gender == 'MALE';
    final initials =
        '${person.firstName.isNotEmpty ? person.firstName[0] : ''}${person.lastName.isNotEmpty ? person.lastName[0] : ''}'
            .toUpperCase();

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
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isMale ? GwTokens.azureBg : GwTokens.roseBg,
                    borderRadius: BorderRadius.circular(GwTokens.rBtn),
                    border: Border.all(
                        color:
                            isMale ? GwTokens.azureLine : GwTokens.roseLine),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: GwType.display(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isMale ? t.azureText : GwTokens.rose,
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
