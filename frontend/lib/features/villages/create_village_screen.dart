import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gwangmeu/core/theme/app_theme.dart';
import 'package:gwangmeu/features/villages/villages_notifier.dart';

class CreateVillageScreen extends ConsumerStatefulWidget {
  const CreateVillageScreen({super.key});

  @override
  ConsumerState<CreateVillageScreen> createState() => _CreateVillageScreenState();
}

class _CreateVillageScreenState extends ConsumerState<CreateVillageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _dialectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _countryCtrl.dispose();
    _regionCtrl.dispose();
    _dialectCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final village = await ref.read(villagesNotifierProvider.notifier).createVillage(
            name: _nameCtrl.text.trim(),
            country: _countryCtrl.text.trim().toUpperCase(),
            region: _regionCtrl.text.trim().isNotEmpty ? _regionCtrl.text.trim() : null,
            primaryDialect: _dialectCtrl.text.trim().isNotEmpty ? _dialectCtrl.text.trim() : null,
            description: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Village "${village.name}" créé !'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        context.pop();
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
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un village'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accent.withAlpha(10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withAlpha(40)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_location_alt_outlined, color: accent, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ajoutez votre village pour rassembler sa communauté',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Nom *
              _buildField(
                controller: _nameCtrl,
                label: 'Nom du village *',
                hint: 'ex: Bafia, Foumbot Royal...',
                icon: Icons.location_city_outlined,
                validator: (v) =>
                    v == null || v.trim().length < 2 ? 'Minimum 2 caractères' : null,
              ),
              const SizedBox(height: 16),

              // Pays *
              _buildField(
                controller: _countryCtrl,
                label: 'Code pays (ISO alpha-3) *',
                hint: 'ex: CMR, NGA, SEN...',
                icon: Icons.flag_outlined,
                maxLength: 3,
                textCapitalization: TextCapitalization.characters,
                validator: (v) =>
                    v == null || v.trim().length < 2 ? 'Code pays requis (2-3 lettres)' : null,
              ),
              const SizedBox(height: 16),

              // Région
              _buildField(
                controller: _regionCtrl,
                label: 'Région',
                hint: 'ex: Centre, Littoral, Ouest...',
                icon: Icons.map_outlined,
              ),
              const SizedBox(height: 16),

              // Dialecte
              _buildField(
                controller: _dialectCtrl,
                label: 'Dialecte principal',
                hint: 'ex: Bassa, Beti, Bamoun...',
                icon: Icons.record_voice_over_outlined,
              ),
              const SizedBox(height: 16),

              // Description
              _buildField(
                controller: _descCtrl,
                label: 'Description',
                hint: 'Décrivez brièvement votre village...',
                icon: Icons.notes_outlined,
                maxLines: 4,
              ),
              const SizedBox(height: 32),

              // Submit
              FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text(
                        'Créer le village',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outline.withAlpha(60)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
