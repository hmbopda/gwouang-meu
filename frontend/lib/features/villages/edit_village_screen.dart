import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/village_model.dart';
import 'villages_notifier.dart';

/// Écran d'édition village — champs modifiables via PUT /api/v1/villages/{id}
class EditVillageScreen extends ConsumerStatefulWidget {
  const EditVillageScreen({super.key, required this.village});
  final VillageModel village;

  @override
  ConsumerState<EditVillageScreen> createState() => _EditVillageScreenState();
}

class _EditVillageScreenState extends ConsumerState<EditVillageScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descCtrl;
  late final TextEditingController _coverCtrl;
  late final TextEditingController _foundedCtrl;
  late final TextEditingController _populationCtrl;
  late final TextEditingController _historyCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final v = widget.village;
    _descCtrl = TextEditingController(text: v.description ?? '');
    _coverCtrl = TextEditingController(text: v.coverImageUrl ?? '');
    _foundedCtrl = TextEditingController(text: v.foundedYear?.toString() ?? '');
    _populationCtrl = TextEditingController(text: v.populationEstimate?.toString() ?? '');
    _historyCtrl = TextEditingController(text: v.historicalSummary ?? '');
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _coverCtrl.dispose();
    _foundedCtrl.dispose();
    _populationCtrl.dispose();
    _historyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await ref.read(villagesNotifierProvider.notifier).updateVillage(
            villageId: widget.village.id,
            description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
            coverImageUrl: _coverCtrl.text.trim().isEmpty ? null : _coverCtrl.text.trim(),
            foundedYear: int.tryParse(_foundedCtrl.text.trim()),
            populationEstimate: int.tryParse(_populationCtrl.text.trim()),
            historicalSummary: _historyCtrl.text.trim().isEmpty ? null : _historyCtrl.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Village mis à jour'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('Modifier ${widget.village.name}'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: accent),
                  )
                : Text('Enregistrer', style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Description
            _buildField(
              controller: _descCtrl,
              label: 'Description',
              hint: 'Décrivez votre village...',
              icon: Icons.info_outline,
              maxLines: 4,
              maxLength: 2000,
            ),
            const SizedBox(height: 16),

            // Cover image URL
            _buildField(
              controller: _coverCtrl,
              label: 'URL image de couverture',
              hint: 'https://...',
              icon: Icons.image_outlined,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            // Founded year & Population (side by side)
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _foundedCtrl,
                    label: 'Année de fondation',
                    hint: 'ex: 1850',
                    icon: Icons.calendar_today_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _populationCtrl,
                    label: 'Population estimée',
                    hint: 'ex: 5000',
                    icon: Icons.people_outline,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Historical summary
            _buildField(
              controller: _historyCtrl,
              label: 'Résumé historique',
              hint: "Racontez l'histoire de votre village...",
              icon: Icons.auto_stories_outlined,
              maxLines: 8,
              maxLength: 5000,
            ),
            const SizedBox(height: 16),

            // Preview cover
            if (_coverCtrl.text.trim().isNotEmpty) ...[
              Text('Aperçu couverture', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _coverCtrl.text.trim(),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('Image invalide', style: TextStyle(color: AppColors.error)),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textHint),
            filled: true,
            fillColor: theme.colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.outline.withAlpha(30)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.outline.withAlpha(30)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
