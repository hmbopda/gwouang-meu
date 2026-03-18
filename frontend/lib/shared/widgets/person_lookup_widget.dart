import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/genealogy/models/person_genealogy.dart';
import '../../features/notifications/services/notification_api_service.dart';

/// Widget de recherche par email/phone avant création d'une personne.
/// Affiche les résultats trouvés pour sélection ou propose la création.
///
/// Flow : Saisie email/phone → Recherche → Si trouvé → Sélection
///                                        → Si pas trouvé → Création
class PersonLookupWidget extends ConsumerStatefulWidget {
  const PersonLookupWidget({
    super.key,
    required this.onPersonSelected,
    required this.onCreateNew,
    this.requiredGender,
    this.label = 'Rechercher une personne',
  });

  /// Appelé quand l'utilisateur sélectionne une personne existante.
  final ValueChanged<PersonGenealogy> onPersonSelected;

  /// Appelé quand la personne n'est pas trouvée et l'utilisateur veut créer.
  /// Passe l'email et le phone saisis.
  final void Function(String email, String phone) onCreateNew;

  /// Filtrer par genre (optionnel).
  final String? requiredGender;

  final String label;

  @override
  ConsumerState<PersonLookupWidget> createState() => _PersonLookupWidgetState();
}

class _PersonLookupWidgetState extends ConsumerState<PersonLookupWidget> {
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _searching = false;
  bool _searched = false;
  List<PersonGenealogy> _results = [];

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          'Saisissez l\'email et/ou le telephone pour verifier si la personne existe deja.',
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        const SizedBox(height: 10),

        // Email + Phone
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telephone',
                  prefixIcon: Icon(Icons.phone_outlined),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Bouton recherche
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _canSearch ? _search : null,
            icon: _searching
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black))
                : const Icon(Icons.search, size: 16),
            label: const Text('Rechercher'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),

        // Résultats
        if (_searched) ...[
          const SizedBox(height: 12),
          if (_results.isNotEmpty) ...[
            Text(
              '${_results.length} personne(s) trouvee(s) :',
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.green),
            ),
            const SizedBox(height: 6),
            ..._results.map((p) => _ResultTile(
                  person: p,
                  onTap: () => widget.onPersonSelected(p),
                )),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => widget.onCreateNew(
                _emailCtrl.text.trim(),
                _phoneCtrl.text.trim(),
              ),
              icon: const Icon(Icons.person_add, size: 16),
              label: const Text(
                'Ce n\'est pas la bonne personne — creer une nouvelle',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withAlpha(60)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Aucune personne trouvee avec ces coordonnees.',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => widget.onCreateNew(
                  _emailCtrl.text.trim(),
                  _phoneCtrl.text.trim(),
                ),
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text('Creer cette personne'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  bool get _canSearch =>
      !_searching &&
      (_emailCtrl.text.trim().isNotEmpty || _phoneCtrl.text.trim().isNotEmpty);

  Future<void> _search() async {
    setState(() {
      _searching = true;
      _searched = false;
      _results = [];
    });

    try {
      final results = await ref
          .read(notificationApiServiceProvider)
          .lookupPersons(
            email: _emailCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
          );

      // Filtrer par genre si requis
      final filtered = widget.requiredGender != null
          ? results
              .where((p) => p.gender == widget.requiredGender)
              .toList()
          : results;

      setState(() {
        _results = filtered;
        _searched = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de recherche: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.person, required this.onTap});
  final PersonGenealogy person;
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
            border: Border.all(color: Colors.grey.shade200),
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
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
