import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:gwangmeu/features/genealogy/genealogy_notifier.dart';
import 'package:gwangmeu/features/genealogy/models/person_genealogy.dart';
import 'package:gwangmeu/features/genealogy/services/genealogy_api_service.dart';

/// Popup dialog showing person details (father, mother, birth date, etc.)
/// when the user clicks on a tree node.
class PersonDetailPopup extends ConsumerStatefulWidget {
  final PersonGenealogy person;

  const PersonDetailPopup({super.key, required this.person});

  @override
  ConsumerState<PersonDetailPopup> createState() => _PersonDetailPopupState();
}

class _PersonDetailPopupState extends ConsumerState<PersonDetailPopup> {
  List<PersonGenealogy>? _parents;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadParents();
  }

  Future<void> _loadParents() async {
    try {
      final api = ref.read(genealogyApiServiceProvider);
      final parents = await api.getParents(widget.person.id);
      if (mounted) {
        setState(() {
          _parents = parents;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  PersonGenealogy? get _father =>
      _parents?.where((p) => p.gender == 'MALE').firstOrNull;

  PersonGenealogy? get _mother =>
      _parents?.where((p) => p.gender == 'FEMALE').firstOrNull;

  int? get _personAge {
    final bd = widget.person.birthDate;
    if (bd == null) return null;
    final now = DateTime.now();
    int age = now.year - bd.year;
    if (now.month < bd.month ||
        (now.month == bd.month && now.day < bd.day)) {
      age--;
    }
    return age;
  }

  bool get _isCurrentUserParent {
    final myPerson = ref.read(genealogyNotifierProvider).valueOrNull;
    if (myPerson == null || _parents == null) return false;
    return _parents!.any((p) => p.id == myPerson.id);
  }

  bool get _canEdit {
    final age = _personAge;
    if (age == null) return false;
    return age < 4 && _isCurrentUserParent;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.person;
    final accent = Theme.of(context).colorScheme.primary;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  _avatar(p),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${p.firstName} ${p.lastName}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (p.clan != null && p.clan!.isNotEmpty)
                          Text(
                            'Clan ${p.clan}',
                            style: TextStyle(
                              fontSize: 12,
                              color: accent,
                              fontWeight: FontWeight.w500,
                            ),
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
            ),
            const Divider(height: 1),

            // Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Person info
                  _infoTile(
                    Icons.wc,
                    'Genre',
                    p.gender == 'MALE' ? 'Homme' : 'Femme',
                  ),
                  if (p.birthDate != null)
                    _infoTile(
                      Icons.cake_outlined,
                      'Date de naissance',
                      DateFormat('dd/MM/yyyy').format(p.birthDate!),
                    ),
                  if (p.birthPlace != null && p.birthPlace!.isNotEmpty)
                    _infoTile(
                      Icons.location_city_outlined,
                      'Lieu de naissance',
                      p.birthPlace!,
                    ),
                  if (p.totem != null && p.totem!.isNotEmpty)
                    _infoTile(Icons.pets, 'Totem', p.totem!),
                  if (!p.isAlive)
                    _infoTile(Icons.brightness_3, 'Statut', 'Decede(e)'),

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Parents section
                  const Text(
                    'Parents',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (_error != null)
                    Text(
                      'Erreur de chargement des parents',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[400],
                      ),
                    )
                  else ...[
                    _parentTile(
                      icon: Icons.man,
                      label: 'Pere',
                      person: _father,
                    ),
                    const SizedBox(height: 6),
                    _parentTile(
                      icon: Icons.woman,
                      label: 'Mere',
                      person: _mother,
                    ),
                  ],
                ],
              ),
            ),

            const Divider(height: 1),

            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  if (_canEdit)
                    OutlinedButton.icon(
                      onPressed: () => _onEditChild(context),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Modifier la fiche'),
                    ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fermer'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(PersonGenealogy p) {
    final initials =
        '${p.firstName.isNotEmpty ? p.firstName[0] : ''}${p.lastName.isNotEmpty ? p.lastName[0] : ''}';
    return CircleAvatar(
      radius: 24,
      backgroundColor: p.gender == 'MALE'
          ? Colors.blue.shade100
          : Colors.pink.shade100,
      backgroundImage: p.photoUrl != null ? NetworkImage(p.photoUrl!) : null,
      child: p.photoUrl == null
          ? Text(
              initials.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: p.gender == 'MALE'
                    ? Colors.blue.shade700
                    : Colors.pink.shade700,
              ),
            )
          : null,
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _parentTile({
    required IconData icon,
    required String label,
    required PersonGenealogy? person,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        color: Colors.grey.shade50,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                Text(
                  person != null
                      ? '${person.firstName} ${person.lastName}'
                      : 'Non renseigne',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: person != null ? null : Colors.grey[400],
                    fontStyle:
                        person != null ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onEditChild(BuildContext context) {
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (_) => _ChildEditDialog(
        person: widget.person,
        parents: _parents ?? [],
      ),
    );
  }
}

/// Dialog for editing a child's info (when child < 4 years).
/// Submits a modification request that the co-parent must validate.
class _ChildEditDialog extends ConsumerStatefulWidget {
  final PersonGenealogy person;
  final List<PersonGenealogy> parents;

  const _ChildEditDialog({
    required this.person,
    required this.parents,
  });

  @override
  ConsumerState<_ChildEditDialog> createState() => _ChildEditDialogState();
}

class _ChildEditDialogState extends ConsumerState<_ChildEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _birthPlaceCtrl;
  late final TextEditingController _clanCtrl;
  late final TextEditingController _totemCtrl;
  DateTime? _birthDate;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.person.firstName);
    _lastNameCtrl = TextEditingController(text: widget.person.lastName);
    _birthPlaceCtrl =
        TextEditingController(text: widget.person.birthPlace ?? '');
    _clanCtrl = TextEditingController(text: widget.person.clan ?? '');
    _totemCtrl = TextEditingController(text: widget.person.totem ?? '');
    _birthDate = widget.person.birthDate;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _birthPlaceCtrl.dispose();
    _clanCtrl.dispose();
    _totemCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
              child: Row(
                children: [
                  Icon(Icons.edit_outlined,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Modifier la fiche',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${widget.person.firstName} ${widget.person.lastName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
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
            ),
            const Divider(height: 1),

            // Info banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(10),
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
                        'La modification sera envoyee a l\'autre parent '
                        'pour validation avant d\'etre appliquee.',
                        style: TextStyle(fontSize: 11, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _firstNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Prenom',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Requis' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _lastNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nom',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Requis' : null,
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _birthDate ?? DateTime(2022),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => _birthDate = picked);
                          }
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
                              color:
                                  _birthDate != null ? null : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _birthPlaceCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Lieu de naissance',
                          prefixIcon: Icon(Icons.location_city_outlined),
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
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),

            // Actions
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _loading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.black,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Envoyer la modification'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final api = ref.read(genealogyApiServiceProvider);
      final changes = <String, dynamic>{};

      if (_firstNameCtrl.text.trim() != widget.person.firstName) {
        changes['firstName'] = _firstNameCtrl.text.trim();
      }
      if (_lastNameCtrl.text.trim() != widget.person.lastName) {
        changes['lastName'] = _lastNameCtrl.text.trim();
      }
      if (_birthDate != widget.person.birthDate && _birthDate != null) {
        changes['birthDate'] = DateFormat('yyyy-MM-dd').format(_birthDate!);
      }
      final bp = _birthPlaceCtrl.text.trim();
      if (bp != (widget.person.birthPlace ?? '')) {
        changes['birthPlace'] = bp.isEmpty ? null : bp;
      }
      final clan = _clanCtrl.text.trim();
      if (clan != (widget.person.clan ?? '')) {
        changes['clan'] = clan.isEmpty ? null : clan;
      }
      final totem = _totemCtrl.text.trim();
      if (totem != (widget.person.totem ?? '')) {
        changes['totem'] = totem.isEmpty ? null : totem;
      }

      if (changes.isEmpty) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucune modification detectee'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      await api.requestChildModification(widget.person.id, changes);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Demande de modification envoyee au co-parent',
            ),
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
