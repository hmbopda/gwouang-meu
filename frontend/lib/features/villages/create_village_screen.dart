import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/theme/app_theme.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/villages/villages_notifier.dart';

// ═══════════════════════════════════════════════════════
// CRÉER UN VILLAGE — formulaire « Tissage »
// Fond t.ink, titre Fraunces, inputs inkLift rayon 14,
// bouton or plein rayon 16, toasts showGwToast.
// ═══════════════════════════════════════════════════════

/// Champ de formulaire village « Tissage » — mutualisé entre les écrans
/// de création et d'édition : label mono MAJUSCULES, input inkLift
/// rayon 14 avec icône Symbols, focus or.
class VillageFormField extends StatelessWidget {
  const VillageFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: GwType.mono(
                fontSize: 12, fontWeight: FontWeight.w500, color: t.stoneDim),
          ),
        ),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          style: GwType.ui(fontSize: 14, color: t.stone),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GwType.ui(fontSize: 14, color: t.stoneDim),
            counterStyle: GwType.mono(
                fontSize: 12, letterSpacing: 0.5, color: t.stoneFaint),
            errorStyle: GwType.ui(fontSize: 12, color: t.emberText),
            prefixIcon: maxLines == 1
                ? Icon(icon, size: 20, color: t.stoneDim)
                : Padding(
                    padding: const EdgeInsets.only(top: 14, left: 12, right: 12),
                    child: Icon(icon, size: 20, color: t.stoneDim),
                  ),
            prefixIconConstraints: maxLines == 1
                ? null
                : const BoxConstraints(minWidth: 44, minHeight: 0),
            filled: true,
            fillColor: t.inkLift,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: border(t.line),
            enabledBorder: border(t.line),
            focusedBorder: border(GwTokens.gold, 1.5),
            errorBorder: border(GwTokens.emberLine),
            focusedErrorBorder: border(GwTokens.ember, 1.5),
          ),
        ),
      ],
    );
  }
}

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
        showGwToast(context, 'Village « ${village.name} » créé');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur : $e',
              style: GwType.ui(
                  fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
            ),
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

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);

    return Scaffold(
      backgroundColor: t.ink,
      body: SafeArea(
        child: Column(
          children: [
            const GwWeaveBand(),
            _header(t),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Encart d'introduction
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: t.goldBg,
                          borderRadius: BorderRadius.circular(GwTokens.rCard),
                          border: Border.all(color: t.goldLine),
                        ),
                        child: Row(
                          children: [
                            Icon(Symbols.add_location_alt,
                                color: t.goldText, size: 26),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Ajoutez votre village pour rassembler sa communauté',
                                style: GwType.ui(
                                    fontSize: 14, color: t.stoneMid, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Nom *
                      VillageFormField(
                        controller: _nameCtrl,
                        label: 'Nom du village *',
                        hint: 'ex : Bafia, Foumbot Royal…',
                        icon: Symbols.location_city,
                        validator: (v) =>
                            v == null || v.trim().length < 2 ? 'Minimum 2 caractères' : null,
                      ),
                      const SizedBox(height: 16),

                      // Pays *
                      VillageFormField(
                        controller: _countryCtrl,
                        label: 'Code pays (ISO alpha-3) *',
                        hint: 'ex : CMR, NGA, SEN…',
                        icon: Symbols.flag,
                        maxLength: 3,
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) =>
                            v == null || v.trim().length < 2 ? 'Code pays requis (2-3 lettres)' : null,
                      ),
                      const SizedBox(height: 16),

                      // Région
                      VillageFormField(
                        controller: _regionCtrl,
                        label: 'Région',
                        hint: 'ex : Centre, Littoral, Ouest…',
                        icon: Symbols.map,
                      ),
                      const SizedBox(height: 16),

                      // Dialecte
                      VillageFormField(
                        controller: _dialectCtrl,
                        label: 'Dialecte principal',
                        hint: 'ex : Bassa, Beti, Bamoun…',
                        icon: Symbols.record_voice_over,
                      ),
                      const SizedBox(height: 16),

                      // Description
                      VillageFormField(
                        controller: _descCtrl,
                        label: 'Description',
                        hint: 'Décrivez brièvement votre village…',
                        icon: Symbols.notes,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 32),

                      // Bouton or plein
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: _loading ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: GwTokens.gold,
                            foregroundColor: const Color(0xFF0C0B0F),
                            disabledBackgroundColor:
                                GwTokens.gold.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Color(0xFF0C0B0F)),
                                )
                              : Text(
                                  'Créer le village',
                                  style: GwType.ui(
                                      fontSize: 15, fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(GwTokens t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 20, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: GwTokens.tapTarget,
            height: GwTokens.tapTarget,
            child: IconButton(
              onPressed: () => context.pop(),
              icon: Icon(Symbols.arrow_back, size: 24, color: t.stone),
              tooltip: 'Retour',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Créer un village',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GwType.display(fontSize: 20, color: t.stone),
            ),
          ),
        ],
      ),
    );
  }
}
