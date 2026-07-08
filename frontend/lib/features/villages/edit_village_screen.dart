import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/theme/app_theme.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/villages/create_village_screen.dart'
    show VillageFormField;
import 'package:gwangmeu/shared/models/village_model.dart';
import 'package:gwangmeu/features/villages/villages_notifier.dart';

// ═══════════════════════════════════════════════════════
// MODIFIER UN VILLAGE — formulaire « Tissage »
// Champs modifiables via PUT /api/v1/villages/{id}.
// Fond t.ink, titre Fraunces, inputs inkLift rayon 14
// (VillageFormField mutualisé), bouton or, showGwToast.
// ═══════════════════════════════════════════════════════

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
        showGwToast(context, 'Village mis à jour');
        Navigator.of(context).pop(true);
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
      if (mounted) setState(() => _saving = false);
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
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Description
                    VillageFormField(
                      controller: _descCtrl,
                      label: 'Description',
                      hint: 'Décrivez votre village…',
                      icon: Symbols.info,
                      maxLines: 4,
                      maxLength: 2000,
                    ),
                    const SizedBox(height: 16),

                    // URL image de couverture
                    VillageFormField(
                      controller: _coverCtrl,
                      label: 'URL image de couverture',
                      hint: 'https://…',
                      icon: Symbols.image,
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),

                    // Année de fondation & population
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: VillageFormField(
                            controller: _foundedCtrl,
                            label: 'Fondation',
                            hint: 'ex : 1850',
                            icon: Symbols.calendar_today,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: VillageFormField(
                            controller: _populationCtrl,
                            label: 'Population',
                            hint: 'ex : 5000',
                            icon: Symbols.group,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Résumé historique
                    VillageFormField(
                      controller: _historyCtrl,
                      label: 'Résumé historique',
                      hint: "Racontez l'histoire de votre village…",
                      icon: Symbols.auto_stories,
                      maxLines: 8,
                      maxLength: 5000,
                    ),
                    const SizedBox(height: 16),

                    // Aperçu de la couverture
                    if (_coverCtrl.text.trim().isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 2, bottom: 8),
                        child: Text(
                          'APERÇU COUVERTURE',
                          style: GwType.mono(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: t.stoneDim),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(GwTokens.rBtn),
                        child: Image.network(
                          _coverCtrl.text.trim(),
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 160,
                            decoration: BoxDecoration(
                              color: GwTokens.emberBg,
                              borderRadius: BorderRadius.circular(GwTokens.rBtn),
                              border: Border.all(color: GwTokens.emberLine),
                            ),
                            child: Center(
                              child: Text(
                                'Image invalide',
                                style: GwType.ui(
                                    fontSize: 14, color: t.emberText),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
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
      padding: const EdgeInsets.fromLTRB(8, 6, 16, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: GwTokens.tapTarget,
            height: GwTokens.tapTarget,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Symbols.arrow_back, size: 24, color: t.stone),
              tooltip: 'Retour',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Modifier ${widget.village.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GwType.display(fontSize: 20, color: t.stone),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _saving ? null : _save,
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _saving
                    ? GwTokens.gold.withValues(alpha: 0.5)
                    : GwTokens.gold,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF0C0B0F)),
                    )
                  : Text(
                      'Enregistrer',
                      style: GwType.ui(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0C0B0F)),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
