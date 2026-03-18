import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/country_model.dart';
import '../../shared/models/language_model.dart';
import '../../shared/models/village_model.dart';
import '../../shared/widgets/country_village_selector.dart';
import '../../shared/widgets/gwang_button.dart';
import '../genealogy/models/person_genealogy.dart';
import '../genealogy/services/genealogy_api_service.dart';
import '../geo/geo_notifier.dart';
import 'profile_notifier.dart';

/// Formulaire complet d'edition du profil — ouvert en bottom sheet plein ecran.
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
  String? _selectedCountryIso; // pour charger les villages
  List<VillageModel> _selectedVillages = [];
  LanguageModel? _selectedLanguage;
  final List<String> _selectedClans = [];
  final _clanInputCtrl = TextEditingController();
  final _tribeCtrl = TextEditingController();

  // Vie professionnelle & Residence
  final _professionCtrl = TextEditingController();
  final _employerCtrl = TextEditingController();
  final _residenceCityCtrl = TextEditingController();
  final _residenceCountryCtrl = TextEditingController();

  // Preferences
  String? _diet;

  // Enfants
  final List<PersonGenealogy> _children = [];
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
    final count = int.tryParse(_childrenCountCtrl.text.trim()) ?? 0;
    if (count > 0) base.add('Enfants');
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
      // Residence & Metier
      _professionCtrl.text = user.profession ?? '';
      _employerCtrl.text = user.employer ?? '';
      _residenceCityCtrl.text = user.residenceCity ?? '';
      _residenceCountryCtrl.text = user.residenceCountry ?? '';
    }
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _bioCtrl.dispose();
    _childrenCountCtrl.dispose();
    _clanInputCtrl.dispose();
    _tribeCtrl.dispose();
    _professionCtrl.dispose();
    _employerCtrl.dispose();
    _residenceCityCtrl.dispose();
    _residenceCountryCtrl.dispose();
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
  // HEADER
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.textHint.withAlpha(80),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Modifier mon profil',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SECTION TABS
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildSectionTabs(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 12),
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
                color: active ? accent : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: active ? accent : AppColors.textHint.withAlpha(60),
                ),
              ),
              child: Text(
                _sections[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? Colors.black : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
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
        _sectionHeader(context, Icons.person_outline, 'Informations personnelles'),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _displayNameCtrl,
          label: 'Nom complet',
          hint: 'Ex: Jean-Pierre Mbopda',
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _bioCtrl,
          label: 'Bio / A propos',
          hint: 'Parlez de vous en quelques mots...',
          icon: Icons.short_text,
          maxLines: 3,
          maxLength: 200,
        ),
      ],
    );
  }

  // ── 2. Parents ───────────────────────────────────────────────────────────

  Widget _buildParentsSection(BuildContext context) {
    return Column(
      key: const ValueKey('parents'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, Icons.family_restroom, 'Informations parentales'),
        const SizedBox(height: 8),
        Text(
          'Selectionnez un membre existant d\'un de vos clans ou creez une nouvelle fiche.',
          style: TextStyle(fontSize: 12, color: AppColors.textHint),
        ),
        const SizedBox(height: 16),
        _parentCard(
          context,
          title: 'Pere',
          icon: Icons.man_outlined,
          selectedPerson: _selectedFather,
          gender: 'MALE',
          role: 'FATHER',
          onSelected: (p) => setState(() => _selectedFather = p),
          onCleared: () => setState(() => _selectedFather = null),
        ),
        const SizedBox(height: 16),
        _parentCard(
          context,
          title: 'Mere',
          icon: Icons.woman_outlined,
          selectedPerson: _selectedMother,
          gender: 'FEMALE',
          role: 'MOTHER',
          onSelected: (p) => setState(() => _selectedMother = p),
          onCleared: () => setState(() => _selectedMother = null),
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
  }) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (selectedPerson != null)
                GestureDetector(
                  onTap: onCleared,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close, size: 14, color: AppColors.error),
                        SizedBox(width: 4),
                        Text('Retirer', style: TextStyle(fontSize: 11, color: AppColors.error)),
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
                color: accent.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accent.withAlpha(40)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: accent.withAlpha(30),
                    child: Text(
                      selectedPerson.firstName[0].toUpperCase(),
                      style: TextStyle(color: accent, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${selectedPerson.firstName} ${selectedPerson.lastName}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        if (selectedPerson.clan != null)
                          Text(
                            'Clan: ${selectedPerson.clan}',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.check_circle, color: accent, size: 20),
                ],
              ),
            ),
          ] else if (_creatingParentFor == role) ...[
            // Inline creation form
            _buildInlineCreateForm(gender, role, onSelected),
          ] else ...[
            // Two action buttons: search existing or create new
            Row(
              children: [
                Expanded(
                  child: _actionBtn(
                    context,
                    icon: Icons.search,
                    label: 'Chercher dans le clan',
                    onTap: () => _showSearchParentDialog(context, gender, role, onSelected),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _actionBtn(
                    context,
                    icon: Icons.person_add_alt_1,
                    label: 'Creer une fiche',
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
    final accent = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(40),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withAlpha(40)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: accent),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchParentDialog(BuildContext context, String gender, String role, ValueChanged<PersonGenealogy> onSelected) {
    final accent = Theme.of(context).colorScheme.primary;
    if (_selectedClans.isEmpty) {
      showDialog(
        context: context,
        useRootNavigator: true,
        builder: (_) => AlertDialog(
          title: const Text('Clan requis'),
          content: const Text('Veuillez d\'abord renseigner au moins un clan dans l\'onglet Origines avant de rechercher un parent.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                setState(() => _currentSection = 3);
              },
              child: Text('Aller aux Origines', style: TextStyle(color: accent)),
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
        builder: (_) => SimpleDialog(
          title: const Text('Dans quel clan chercher ?'),
          children: _selectedClans.map((clan) => SimpleDialogOption(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              _openSearchDialog(context, clan, gender, onSelected);
            },
            child: Text(clan, style: const TextStyle(fontSize: 15)),
          )).toList(),
        ),
      );
    }
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
    final accent = Theme.of(context).colorScheme.primary;
    final title = gender == 'MALE' ? 'Nouvelle fiche Pere' : 'Nouvelle fiche Mere';
    return Form(
      key: _createFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                gender == 'MALE' ? Icons.man_outlined : Icons.woman_outlined,
                size: 16,
                color: accent,
              ),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: accent)),
              const Spacer(),
              GestureDetector(
                onTap: _createLoading ? null : () => setState(() => _creatingParentFor = null),
                child: const Icon(Icons.close, size: 18, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _createFirstNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Prenom *',
              prefixIcon: Icon(Icons.person_outline),
              isDense: true,
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _createLastNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nom *',
              prefixIcon: Icon(Icons.badge_outlined),
              isDense: true,
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _createClanCtrl,
            decoration: const InputDecoration(
              labelText: 'Clan',
              prefixIcon: Icon(Icons.shield_outlined),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            title: const Text('Encore en vie ?', style: TextStyle(fontSize: 14)),
            subtitle: Text(
              _createIsAlive
                  ? 'Un lien de validation sera envoye'
                  : 'La personne est decedee',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            value: _createIsAlive,
            activeColor: accent,
            contentPadding: EdgeInsets.zero,
            dense: true,
            onChanged: (v) => setState(() => _createIsAlive = v),
          ),
          if (_createIsAlive) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: _createEmailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email *',
                prefixIcon: Icon(Icons.email_outlined),
                isDense: true,
                helperText: 'Pour envoyer le lien d\'invitation',
                helperStyle: TextStyle(fontSize: 10),
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
                child: OutlinedButton(
                  onPressed: _createLoading ? null : () => setState(() => _creatingParentFor = null),
                  child: const Text('Annuler', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _createLoading ? null : () => _submitInlineCreate(gender, role, onSelected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.black,
                  ),
                  child: _createLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Creer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _createLoading = false);
    }
  }

  // ── 3. Famille ───────────────────────────────────────────────────────────

  Widget _buildFamilySection(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Column(
      key: const ValueKey('family'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, Icons.favorite_outline, 'Situation familiale'),
        const SizedBox(height: 16),
        _buildDropdown(
          label: 'Situation maritale',
          icon: Icons.favorite_border,
          value: _maritalStatus,
          items: _maritalOptions,
          onChanged: (v) => setState(() => _maritalStatus = v),
        ),
        const SizedBox(height: 14),
        _buildDropdown(
          label: 'Regime matrimonial',
          icon: Icons.gavel_outlined,
          value: _matrimonialRegime,
          items: _regimeOptions,
          onChanged: (v) => setState(() => _matrimonialRegime = v),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _childrenCountCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 14),
          onChanged: (_) => setState(() {
            // Ajuste _currentSection si l'onglet Enfants disparait
            if (_currentSection >= _sections.length) {
              _currentSection = _sections.length - 1;
            }
          }),
          decoration: InputDecoration(
            labelText: 'Nombre d\'enfants',
            hintText: '0',
            prefixIcon: const Icon(Icons.child_care_outlined, size: 18),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(40),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(40)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(40)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accent, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildDropdown(
          label: 'Regime alimentaire',
          icon: Icons.restaurant_outlined,
          value: _diet,
          items: _dietOptions,
          onChanged: (v) => setState(() => _diet = v),
        ),
      ],
    );
  }

  // ── 3b. Enfants ─────────────────────────────────────────────────────────

  Widget _buildChildrenSection(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final count = int.tryParse(_childrenCountCtrl.text.trim()) ?? 0;
    return Column(
      key: const ValueKey('children'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, Icons.child_care, 'Mes enfants'),
        const SizedBox(height: 8),
        Text(
          'Vous avez declare $count enfant${count > 1 ? 's' : ''}. '
          'Ajoutez leurs fiches pour les lier a votre arbre.',
          style: TextStyle(fontSize: 12, color: AppColors.textHint),
        ),
        const SizedBox(height: 16),
        // Liste des enfants deja ajoutes
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
                  icon: Icons.search,
                  label: 'Chercher existant',
                  onTap: () => _showSearchChildDialog(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionBtn(
                  context,
                  icon: Icons.person_add_alt_1,
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
              color: accent.withAlpha(10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withAlpha(30)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_children.length} enfant${_children.length > 1 ? 's' : ''} ajoute${_children.length > 1 ? 's' : ''}. '
                    'Ils seront lies a votre arbre genealogique.',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
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
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withAlpha(40)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: accent.withAlpha(30),
            child: Text(
              child.firstName[0].toUpperCase(),
              style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${child.firstName} ${child.lastName}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  child.gender == 'MALE' ? 'Fils' : 'Fille',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _children.removeAt(index)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close, size: 14, color: AppColors.error),
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
    final accent = Theme.of(context).colorScheme.primary;
    return Form(
      key: _createChildFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.child_care, size: 16, color: accent),
              const SizedBox(width: 6),
              Text('Nouvel enfant', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: accent)),
              const Spacer(),
              GestureDetector(
                onTap: _createChildLoading ? null : () => setState(() => _creatingChild = false),
                child: const Icon(Icons.close, size: 18, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _createChildFirstNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Prenom *',
              prefixIcon: Icon(Icons.person_outline),
              isDense: true,
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _createChildLastNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nom *',
              prefixIcon: Icon(Icons.badge_outlined),
              isDense: true,
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _createChildClanCtrl,
            decoration: const InputDecoration(
              labelText: 'Clan',
              prefixIcon: Icon(Icons.shield_outlined),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          // Date de naissance
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _createChildBirthDate ?? DateTime(2000),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
                locale: const Locale('fr'),
              );
              if (picked != null) setState(() => _createChildBirthDate = picked);
            },
            child: AbsorbPointer(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Date de naissance',
                  prefixIcon: const Icon(Icons.cake_outlined),
                  isDense: true,
                  hintText: _createChildBirthDate != null
                      ? '${_createChildBirthDate!.day.toString().padLeft(2, '0')}/${_createChildBirthDate!.month.toString().padLeft(2, '0')}/${_createChildBirthDate!.year}'
                      : 'JJ/MM/AAAA',
                ),
                controller: TextEditingController(
                  text: _createChildBirthDate != null
                      ? '${_createChildBirthDate!.day.toString().padLeft(2, '0')}/${_createChildBirthDate!.month.toString().padLeft(2, '0')}/${_createChildBirthDate!.year}'
                      : '',
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Email
          TextFormField(
            controller: _createChildEmailCtrl,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
              isDense: true,
              helperText: 'Pour la deduplication et l\'invitation',
              helperStyle: TextStyle(fontSize: 10),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 10),
          // Genre
          Row(
            children: [
              const Text('Genre :', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text('Fils'),
                selected: _createChildGender == 'MALE',
                onSelected: (_) => setState(() => _createChildGender = 'MALE'),
                selectedColor: accent.withAlpha(40),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Fille'),
                selected: _createChildGender == 'FEMALE',
                onSelected: (_) => setState(() => _createChildGender = 'FEMALE'),
                selectedColor: accent.withAlpha(40),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _createChildLoading ? null : () => setState(() => _creatingChild = false),
                  child: const Text('Annuler', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _createChildLoading ? null : _submitInlineChildCreate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.black,
                  ),
                  child: _createChildLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Creer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${child.firstName} ajoute(e) et lie(e) a votre arbre'),
            backgroundColor: const Color(0xFFC8A020),
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
      if (mounted) setState(() => _createChildLoading = false);
    }
  }

  void _showSearchChildDialog(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    if (_selectedClans.isEmpty) {
      showDialog(
        context: context,
        useRootNavigator: true,
        builder: (_) => AlertDialog(
          title: const Text('Clan requis'),
          content: const Text('Veuillez d\'abord renseigner au moins un clan dans l\'onglet Origines.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                final originesIndex = _sections.indexOf('Origines');
                if (originesIndex >= 0) setState(() => _currentSection = originesIndex);
              },
              child: Text('Aller aux Origines', style: TextStyle(color: accent)),
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
        builder: (_) => SimpleDialog(
          title: const Text('Dans quel clan chercher ?'),
          children: _selectedClans.map((c) => SimpleDialogOption(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              _openSearchChildDialog(context, c);
            },
            child: Text(c, style: const TextStyle(fontSize: 15)),
          )).toList(),
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
                  content: Text('${person.firstName} lie(e) comme enfant'),
                  backgroundColor: const Color(0xFFC8A020),
                ),
              );
            }
          } catch (e) {
            debugPrint('Erreur linkParentChild enfant existant: $e');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erreur liaison: $e'), backgroundColor: Colors.red),
              );
            }
          }
          setState(() => _children.add(person));
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
        _sectionHeader(context, Icons.public, 'Origines & Culture'),
        const SizedBox(height: 16),

        CountryVillageSelector(
          selectedCountry: _selectedCountry,
          selectedVillages: _selectedVillages,
          multiSelect: true,
          countryLabel: 'Pays d\'origine',
          villageLabel: 'Village(s) d\'origine',
          onCountryChanged: (c) => setState(() {
            _selectedCountry = c;
            _selectedCountryIso = c?.isoCode;
            _selectedVillages = [];
            _selectedLanguage = null;
          }),
          onVillagesChanged: (v) => setState(() => _selectedVillages = v),
        ),

        // Langue maternelle (visible seulement si un pays est selectionne)
        if (_selectedCountryIso != null) ...[
          const SizedBox(height: 14),
          _buildLanguageDropdown(context),
        ],
        const SizedBox(height: 14),
        _buildTextField(
          controller: _tribeCtrl,
          label: 'Ethnie / Tribu',
          hint: 'Ex: Bassa',
          icon: Icons.groups_outlined,
        ),
        const SizedBox(height: 14),
        _buildClanMultiSelect(context),
      ],
    );
  }

  Widget _buildClanMultiSelect(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.account_tree_outlined, size: 18, color: accent),
            const SizedBox(width: 8),
            Text(
              'Clans',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Chips des clans selectionnes
        if (_selectedClans.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _selectedClans.map((clan) => Chip(
              label: Text(clan, style: const TextStyle(fontSize: 13)),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => setState(() => _selectedClans.remove(clan)),
              backgroundColor: accent.withAlpha(20),
              side: BorderSide(color: accent.withAlpha(60)),
            )).toList(),
          ),
        const SizedBox(height: 8),
        // Champ de saisie + bouton ajouter
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _clanInputCtrl,
                decoration: InputDecoration(
                  hintText: 'Ex: Bakoko',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onSubmitted: (_) => _addClan(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _addClan,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add, size: 20, color: Colors.black),
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

  Widget _buildLanguageDropdown(BuildContext context) {
    final languagesAsync = ref.watch(languagesByCountryNotifierProvider(_selectedCountryIso));

    return languagesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      ),
      error: (_, __) => const Text('Impossible de charger les langues'),
      data: (languages) {
        if (languages.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Aucune langue enregistree pour ce pays',
              style: TextStyle(color: AppColors.textHint, fontSize: 13),
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
        return _buildDropdownTyped<LanguageModel>(
          label: 'Langue maternelle',
          icon: Icons.record_voice_over_outlined,
          value: _selectedLanguage,
          items: languages,
          itemLabel: (l) => l.official ? '${l.name} (officielle)' : l.name,
          onChanged: (v) => setState(() => _selectedLanguage = v),
        );
      },
    );
  }

  // ── 5. Residence & Metier ────────────────────────────────────────────────

  Widget _buildResidenceSection(BuildContext context) {
    return Column(
      key: const ValueKey('residence'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, Icons.work_outline, 'Residence & Vie professionnelle'),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _residenceCityCtrl,
          label: 'Ville de residence',
          hint: 'Ex: Paris',
          icon: Icons.location_city_outlined,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _residenceCountryCtrl,
          label: 'Pays de residence',
          hint: 'Ex: France',
          icon: Icons.map_outlined,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _professionCtrl,
          label: 'Profession / Metier',
          hint: 'Ex: Ingenieur logiciel',
          icon: Icons.engineering_outlined,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _employerCtrl,
          label: 'Employeur / Entreprise',
          hint: 'Ex: Nom de l\'entreprise',
          icon: Icons.business_outlined,
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BOTTOM BAR
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildBottomBar(BuildContext context) {
    final isLast = _currentSection == _sections.length - 1;
    final isFirst = _currentSection == 0;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(30)),
        ),
      ),
      child: Row(
        children: [
          if (!isFirst)
            Expanded(
              child: GwangButton(
                label: 'Precedent',
                variant: GwangButtonVariant.outline,
                icon: Icons.arrow_back,
                onPressed: () => setState(() => _currentSection--),
              ),
            ),
          if (!isFirst) const SizedBox(width: 12),
          Expanded(
            flex: isFirst ? 1 : 1,
            child: GwangButton(
              label: isLast ? 'Enregistrer' : 'Suivant',
              icon: isLast ? Icons.check : Icons.arrow_forward,
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
    final accent = Theme.of(context).colorScheme.primary;
    final data = <String, dynamic>{
      // Identite (camelCase pour matcher le backend Spring Boot)
      if (_displayNameCtrl.text.trim().isNotEmpty)
        'displayName': _displayNameCtrl.text.trim(),
      if (_bioCtrl.text.trim().isNotEmpty)
        'bio': _bioCtrl.text.trim(),
      // Origines
      if (_selectedCountry != null) 'country': _selectedCountry!.name,
      if (_selectedLanguage != null)
        'nativeLanguage': _selectedLanguage!.name,
      if (_selectedVillages.isNotEmpty)
        'villageIds': _selectedVillages.map((v) => v.id).toList(),
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
      if (_residenceCountryCtrl.text.trim().isNotEmpty)
        'residenceCountry': _residenceCountryCtrl.text.trim(),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erreur lors de la mise a jour du profil'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profil mis a jour'),
          backgroundColor: accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ════════════════════════════════════════════════════════════════════════════

  Widget _sectionHeader(BuildContext context, IconData icon, String title) {
    final accent = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accent.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                'Tous les champs sont optionnels',
                style: TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
            ],
          ),
        ),
      ],
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
  }) {
    final accent = Theme.of(context).colorScheme.primary;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(40),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(40)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(40)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final accent = Theme.of(context).colorScheme.primary;
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(40),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(40)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(40)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
      onChanged: onChanged,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
    );
  }

  Widget _buildDropdownTyped<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    final accent = Theme.of(context).colorScheme.primary;
    return DropdownButtonFormField<T>(
      value: items.contains(value) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(40),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(40)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(40)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(itemLabel(e), style: const TextStyle(fontSize: 14)))).toList(),
      onChanged: onChanged,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
    );
  }
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
    final accent = Theme.of(context).colorScheme.primary;
    final title = widget.gender.isEmpty
        ? 'Rechercher un enfant'
        : widget.gender == 'MALE'
            ? 'Rechercher un pere'
            : 'Rechercher une mere';

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.search, color: accent),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16)),
        ],
      ),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom...',
                prefixIcon: const Icon(Icons.person_search, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, size: 20),
                  onPressed: () => _search(_searchCtrl.text.trim()),
                ),
                isDense: true,
              ),
              onSubmitted: (v) => _search(v.trim()),
            ),
            const SizedBox(height: 8),
            Text(
              'Clan: ${widget.clan}',
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: accent))
                  : _results.isEmpty
                      ? Center(
                          child: Text(
                            'Aucun membre trouve dans ce clan',
                            style: TextStyle(color: AppColors.textHint, fontSize: 13),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _results.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final p = _results[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: accent.withAlpha(30),
                                child: Text(
                                  p.firstName[0].toUpperCase(),
                                  style: TextStyle(color: accent, fontWeight: FontWeight.w700),
                                ),
                              ),
                              title: Text('${p.firstName} ${p.lastName}'),
                              subtitle: Text(
                                [
                                  if (p.clan != null) 'Clan: ${p.clan}',
                                  if (p.birthDate != null) 'Ne(e): ${p.birthDate!.year}',
                                ].join(' - '),
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Icon(Icons.add_circle_outline, color: accent),
                              onTap: () => widget.onSelected(p),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}
