import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/shared/models/country_model.dart';
import 'package:gwangmeu/shared/models/village_model.dart';
import 'package:gwangmeu/shared/widgets/country_village_selector.dart';
import 'package:gwangmeu/shared/widgets/country_selector.dart';
import 'package:gwangmeu/shared/widgets/gw_dialog.dart';
import 'package:gwangmeu/features/genealogy/widgets/dialogs/origin_cascade_selector.dart';
import 'package:gwangmeu/features/genealogy/models/person_genealogy.dart';
import 'package:gwangmeu/features/genealogy/services/genealogy_api_service.dart';

/// Dialog « Modifier la fiche » — refonte Tissage : hero de la personne,
/// cartes douces regroupées, pilules tactiles pour le statut et la visibilité,
/// et sélection intégrée du village (communauté + origine référentielle).
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

  static const _statusOptions = {
    'ALIVE': 'Vivant(e)',
    'DECEASED': 'In memoriam',
  };

  static const _privacyOptions = {
    'FAMILY_ONLY': 'Famille',
    'MEMBERS_ONLY': 'Village',
    'PUBLIC': 'Public',
  };

  @override
  void initState() {
    super.initState();
    final p = widget.person;
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
    _privacy =
        _privacyOptions.containsKey(p.privacy) ? p.privacy : 'FAMILY_ONLY';
    // Origine référentielle (ancre de la lignée) — pré-remplissage.
    _origin = OriginSelection(
      regionName: p.originRegion,
      departmentName: p.originCity,
      chefferieName: p.originVillage,
    );
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
    final p = widget.person;
    return GwDialog(
      title: 'Modifier la fiche',
      subtitle: '${p.firstName} ${p.lastName}'.trim(),
      icon: Symbols.edit,
      maxWidth: 540,
      contentPadding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
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
      child: Form(key: _formKey, child: _buildForm(context)),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hero(context),
        const SizedBox(height: 14),

        // ── Identité ──
        _card(context, icon: Symbols.badge, title: 'Identité', children: [
          Row(
            children: [
              Expanded(
                child: _field(_firstNameCtrl, 'Prénom',
                    icon: Symbols.person, validator: _req),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _field(_lastNameCtrl, 'Nom',
                    icon: Symbols.badge, validator: _req),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _dateField(context),
          const SizedBox(height: 12),
          _pillLabel(context, Symbols.favorite, 'Statut'),
          const SizedBox(height: 8),
          _pillGroup(context, _statusOptions, _status,
              (v) => setState(() => _status = v)),
        ]),
        const SizedBox(height: 12),

        // ── Origine & village (sélection intégrée) ──
        _card(context,
            icon: Symbols.forest,
            title: 'Origine & village',
            subtitle:
                'Le village d\'origine ancre la lignée. Tapez son nom (ex : Bandenkop).',
            children: [
              OriginCascadeSelector(
                initial: _origin,
                onChanged: (sel) => _origin = sel,
              ),
              const SizedBox(height: 10),
              CountrySelector(
                label: 'Pays d\'origine',
                value: _originCountry,
                onChanged: (c) => setState(() => _originCountry = c),
              ),
              const SizedBox(height: 12),
              _pillLabel(
                  context, Symbols.holiday_village, 'Village(s) d\'appartenance'),
              const SizedBox(height: 8),
              CountryVillageSelector(
                selectedCountry: _selectedCountry,
                selectedVillages: _selectedVillages,
                multiSelect: true,
                onCountryChanged: (c) => setState(() {
                  _selectedCountry = c;
                  _selectedVillages = [];
                }),
                onVillagesChanged: (v) =>
                    setState(() => _selectedVillages = v),
              ),
            ]),
        const SizedBox(height: 12),

        // ── Naissance & vie ──
        _card(context, icon: Symbols.home, title: 'Naissance & vie', children: [
          _field(_birthPlaceCtrl, 'Lieu de naissance',
              icon: Symbols.location_city, hint: 'Ex : Douala, Paris…'),
          const SizedBox(height: 8),
          _field(_residenceCtrl, 'Résidence actuelle',
              icon: Symbols.location_on, hint: 'Ex : Paris, Bruxelles…'),
          const SizedBox(height: 8),
          _field(_professionCtrl, 'Profession', icon: Symbols.work),
        ]),
        const SizedBox(height: 12),

        // ── Récit ──
        _card(context, icon: Symbols.notes, title: 'Récit', children: [
          _field(_bioCtrl, 'Biographie',
              icon: Symbols.notes, maxLines: 4, alignTop: true),
        ]),
        const SizedBox(height: 12),

        // ── Visibilité ──
        _card(context, icon: Symbols.visibility, title: 'Visibilité', children: [
          _pillGroup(context, _privacyOptions, _privacy,
              (v) => setState(() => _privacy = v)),
        ]),
      ],
    );
  }

  // ── Hero : avatar (initiales, dégradé or) + nom ──
  Widget _hero(BuildContext context) {
    final t = GwTokens.of(context);
    final p = widget.person;
    final initials = _initials(p.firstName, p.lastName);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.goldGlow,
        borderRadius: BorderRadius.circular(GwTokens.rCardLg),
        border: Border.all(color: t.goldLine),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient:
                  LinearGradient(colors: [GwTokens.goldLight, GwTokens.gold]),
            ),
            alignment: Alignment.center,
            child: Text(initials,
                style: GwType.display(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: GwTokens.inkOnGold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${p.firstName} ${p.lastName}'.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GwType.display(fontSize: 18, color: t.stone)),
                const SizedBox(height: 2),
                Text('Fiche généalogique',
                    style: GwType.mono(
                        fontSize: 10, letterSpacing: 1.5, color: t.stoneDim)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Carte de section douce ──
  Widget _card(BuildContext context,
      {required IconData icon,
      required String title,
      String? subtitle,
      required List<Widget> children}) {
    final t = GwTokens.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.inkCard,
        borderRadius: BorderRadius.circular(GwTokens.rCardLg),
        border: Border.all(color: t.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: t.goldText),
              const SizedBox(width: 8),
              Text(title.toUpperCase(),
                  style: GwType.mono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                      color: t.stoneDim)),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle,
                style: GwType.ui(fontSize: 12, color: t.stoneDim, height: 1.4)),
          ],
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _pillLabel(BuildContext context, IconData icon, String text) {
    final t = GwTokens.of(context);
    return Row(
      children: [
        Icon(icon, size: 15, color: t.stoneDim),
        const SizedBox(width: 7),
        Text(text.toUpperCase(),
            style: GwType.mono(
                fontSize: 10, letterSpacing: 1.5, color: t.stoneDim)),
      ],
    );
  }

  // ── Champ de saisie Tissage ──
  Widget _field(TextEditingController ctrl, String label,
      {IconData? icon,
      String? hint,
      String? Function(String?)? validator,
      int maxLines = 1,
      bool alignTop = false}) {
    final t = GwTokens.of(context);
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      style: GwType.ui(fontSize: 14, color: t.stone),
      decoration: gwInputDecoration(
        context,
        label: label,
        hint: hint,
        prefixIcon: icon,
        dense: true,
        alignLabelWithHint: alignTop,
      ),
      validator: validator,
    );
  }

  // ── Champ date (tap → sélecteur) ──
  Widget _dateField(BuildContext context) {
    final t = GwTokens.of(context);
    return GestureDetector(
      onTap: _pickDate,
      child: AbsorbPointer(
        child: TextFormField(
          controller: _dateCtrl,
          style: GwType.ui(fontSize: 14, color: t.stone),
          decoration: gwInputDecoration(
            context,
            label: 'Date de naissance',
            hint: 'JJ/MM/AAAA',
            prefixIcon: Symbols.event,
            dense: true,
          ),
        ),
      ),
    );
  }

  // ── Groupe de pilules (choix unique) ──
  Widget _pillGroup(BuildContext context, Map<String, String> options,
      String selected, ValueChanged<String> onSelect) {
    final t = GwTokens.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.entries.map((e) {
        final active = e.key == selected;
        return GestureDetector(
          onTap: () => onSelect(e.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: active ? t.goldBg : t.inkLift,
              borderRadius: BorderRadius.circular(GwTokens.rPill),
              border: Border.all(color: active ? t.goldLine : t.line),
            ),
            child: Text(e.value,
                style: GwType.ui(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? t.goldText : t.stoneMid)),
          ),
        );
      }).toList(),
    );
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Requis' : null;

  String _initials(String first, String last) {
    final f = first.trim();
    final l = last.trim();
    final s =
        ((f.isNotEmpty ? f[0] : '') + (l.isNotEmpty ? l[0] : '')).toUpperCase();
    return s.isEmpty ? '?' : s;
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
      if (_residenceCtrl.text.trim().isNotEmpty) {
        data['residenceCity'] = _residenceCtrl.text.trim();
      }
      if (_professionCtrl.text.trim().isNotEmpty) {
        data['profession'] = _professionCtrl.text.trim();
      }
      if (_bioCtrl.text.trim().isNotEmpty) {
        data['biography'] = _bioCtrl.text.trim();
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
            content: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Symbols.check_circle, size: 18, color: Colors.white),
              const SizedBox(width: 10),
              Text('Fiche mise à jour',
                  style: GwType.ui(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ]),
            backgroundColor: GwTokens.sage,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(GwTokens.rPill)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e',
                style: GwType.ui(fontSize: 14, color: Colors.white)),
            backgroundColor: GwTokens.ember,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(GwTokens.rPill)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
