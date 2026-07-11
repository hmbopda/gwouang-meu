import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:gwangmeu/shared/models/country_model.dart';
import 'package:gwangmeu/shared/models/village_model.dart';
import 'package:gwangmeu/shared/widgets/country_village_selector.dart';
import 'package:gwangmeu/shared/widgets/country_selector.dart';
import 'package:gwangmeu/features/genealogy/widgets/dialogs/origin_cascade_selector.dart';
import 'package:gwangmeu/features/genealogy/models/person_genealogy.dart';
import 'package:gwangmeu/features/genealogy/services/genealogy_api_service.dart';

/// Dialog to edit a person's info, pre-filled with current data.
class EditPersonDialog extends ConsumerStatefulWidget {
  final PersonGenealogy person;
  final String treeOwnerId;

  const EditPersonDialog({
    super.key,
    required this.person,
    required this.treeOwnerId,
  });

  @override
  ConsumerState<EditPersonDialog> createState() => _EditPersonDialogState();
}

class _EditPersonDialogState extends ConsumerState<EditPersonDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _birthPlaceCtrl;
  late final TextEditingController _residenceCtrl;
  late final TextEditingController _professionCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _dateCtrl;
  late String _status;
  late String _privacy;
  DateTime? _birthDate;
  CountryModel? _selectedCountry;
  List<VillageModel> _selectedVillages = [];
  // Origine référentielle (ancre de la lignée) — atteint Bandenkop.
  OriginSelection _origin = const OriginSelection();
  CountryModel? _originCountry;
  bool _loading = false;

  static const _privacyOptions = {
    'FAMILY_ONLY': 'Famille uniquement',
    'MEMBERS_ONLY': 'Membres du village uniquement',
    'PUBLIC': 'Public',
  };

  @override
  void initState() {
    super.initState();
    debugPrint('[EDIT_DIALOG] initState START');
    try {
      final p = widget.person;
      debugPrint('[EDIT_DIALOG] person: ${p.firstName} ${p.lastName}, privacy=${p.privacy}, isAlive=${p.isAlive}, birthDate=${p.birthDate}');
      _firstNameCtrl = TextEditingController(text: p.firstName);
      _lastNameCtrl = TextEditingController(text: p.lastName);
      _birthPlaceCtrl = TextEditingController(text: p.birthPlace ?? '');
      _residenceCtrl = TextEditingController();
      _professionCtrl = TextEditingController();
      _bioCtrl = TextEditingController();
      _birthDate = p.birthDate;
      _dateCtrl = TextEditingController(
        text: p.birthDate != null
            ? DateFormat('dd/MM/yyyy').format(p.birthDate!)
            : '',
      );
      _status = p.isAlive ? 'ALIVE' : 'DECEASED';
      _privacy = _privacyOptions.containsKey(p.privacy)
          ? p.privacy
          : 'FAMILY_ONLY';
      // Origine référentielle (ancre de la lignée) — pré-remplissage.
      _origin = OriginSelection(
        regionName: p.originRegion,
        departmentName: p.originCity,
        chefferieName: p.originVillage,
      );
      debugPrint('[EDIT_DIALOG] initState OK — status=$_status, privacy=$_privacy');
    } catch (e, st) {
      debugPrint('[EDIT_DIALOG] initState ERROR: $e');
      debugPrint('[EDIT_DIALOG] STACKTRACE: $st');
      rethrow;
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _birthPlaceCtrl.dispose();
    _residenceCtrl.dispose();
    _professionCtrl.dispose();
    _bioCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[EDIT_DIALOG] build START');
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildForm(),
              ),
            ),
            const Divider(height: 1),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
      child: Row(
        children: [
          Icon(Icons.edit_note, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Modifier la fiche',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Identité ──
          _sectionLabel('IDENTITÉ'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Prénom *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Requis' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lastNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom *',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Requis' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Date + Statut
          Row(
            children: [
              Expanded(child: _dateField()),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey('status_$_status'),
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Statut',
                    prefixIcon: Icon(Icons.favorite_outline),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'ALIVE', child: Text('Vivant(e)')),
                    DropdownMenuItem(
                        value: 'DECEASED', child: Text('Décédé(e)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _status = v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Lieu de naissance ──
          _sectionLabel('LIEU DE NAISSANCE'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _birthPlaceCtrl,
            decoration: const InputDecoration(
              labelText: 'Lieu de naissance',
              prefixIcon: Icon(Icons.location_city_outlined),
              hintText: 'Ex: Douala, Paris, Yaoundé...',
            ),
          ),
          const SizedBox(height: 16),

          // ── Origine ──
          _sectionLabel('PAYS & VILLAGE D\'APPARTENANCE'),
          const SizedBox(height: 8),
          CountryVillageSelector(
            selectedCountry: _selectedCountry,
            selectedVillages: _selectedVillages,
            multiSelect: true,
            onCountryChanged: (c) => setState(() {
              _selectedCountry = c;
              _selectedVillages = [];
            }),
            onVillagesChanged: (v) => setState(() => _selectedVillages = v),
          ),
          const SizedBox(height: 16),

          // ── Origine référentielle (ancre de la lignée — atteint Bandenkop) ──
          _sectionLabel('ORIGINE — ANCRE DE LA LIGNÉE'),
          const SizedBox(height: 8),
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
          const SizedBox(height: 16),

          // ── Résidence & Profession ──
          _sectionLabel('RÉSIDENCE & PROFESSION'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _residenceCtrl,
            decoration: const InputDecoration(
              labelText: 'Lieu de résidence actuel',
              prefixIcon: Icon(Icons.home_outlined),
              hintText: 'Ex: Paris, Douala, Bruxelles...',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _professionCtrl,
            decoration: const InputDecoration(
              labelText: 'Profession',
              prefixIcon: Icon(Icons.work_outline),
            ),
          ),
          const SizedBox(height: 16),

          // ── Biographie ──
          _sectionLabel('BIOGRAPHIE'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _bioCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Biographie',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),

          // ── Vie privée ──
          _sectionLabel('VIE PRIVÉE'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey('privacy_$_privacy'),
            initialValue: _privacy,
            decoration: const InputDecoration(
              labelText: 'Visibilité',
              prefixIcon: Icon(Icons.visibility_outlined),
            ),
            items: _privacyOptions.entries
                .map((e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _privacy = v);
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _dateField() {
    return GestureDetector(
      onTap: _pickDate,
      child: AbsorbPointer(
        child: TextFormField(
          controller: _dateCtrl,
          decoration: const InputDecoration(
            labelText: 'Date de naissance',
            prefixIcon: Icon(Icons.calendar_today_outlined),
            hintText: 'JJ/MM/AAAA',
          ),
        ),
      ),
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
        _dateCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _loading ? null : () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.black,
            ),
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enregistrer'),
          ),
        ],
      ),
    );
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
      if (_selectedVillages.isNotEmpty) {
        data['villageIds'] = _selectedVillages.map((v) => v.id).toList();
      }
      // Origine référentielle (ancre de la lignée).
      if (_origin.chefferieName != null) {
        data['originVillage'] = _origin.chefferieName;
      }
      final originCity = _origin.arrondissementName ?? _origin.departmentName;
      if (originCity != null) data['originCity'] = originCity;
      if (_origin.regionName != null) data['originRegion'] = _origin.regionName;
      final originCountry = _originCountry?.iso2 ?? widget.person.originCountry;
      if (originCountry != null) data['originCountry'] = originCountry;

      await api.updatePerson(widget.person.id, data);
      ref.invalidate(familyTreeProvider(widget.treeOwnerId));

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Fiche mise à jour'),
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
