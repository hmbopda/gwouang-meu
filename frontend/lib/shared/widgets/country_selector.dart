import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/geo/geo_notifier.dart';
import 'package:gwangmeu/shared/models/country_model.dart';
import 'package:gwangmeu/shared/widgets/gw_dialog.dart';

/// Sélecteur de pays réutilisable — style Tissage (GwTokens / GwType).
///
/// La liste compte ~241 pays : un `DropdownButton` simple est inutilisable.
/// Ce widget affiche un champ tappable (drapeau + nom du pays sélectionné, ou
/// un placeholder) qui ouvre une feuille modale avec une barre de recherche
/// (filtre par nom, insensible aux accents) et une liste défilante.
///
/// L'app affiche le **nom + drapeau** et stocke le **code ISO** :
/// - pour une personne → utiliser [CountryModel.iso2] (ISO-2, ex 'CM') ;
/// - pour un village → utiliser [CountryModel.isoCode] (ISO-3, ex 'CMR').
///
/// La sélection remonte via [onChanged] ; le stockage du bon code reste à la
/// charge de l'appelant.
class CountrySelector extends ConsumerWidget {
  const CountrySelector({
    super.key,
    this.value,
    required this.onChanged,
    this.label,
    this.hint,
  });

  /// Pays actuellement sélectionné (null = aucun).
  final CountryModel? value;

  /// Appelé quand l'utilisateur choisit un pays dans la feuille modale.
  final ValueChanged<CountryModel> onChanged;

  /// Libellé du champ (ex « Pays d'origine »).
  final String? label;

  /// Placeholder quand aucun pays n'est sélectionné.
  final String? hint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final countriesAsync = ref.watch(countriesNotifierProvider);

    return countriesAsync.when(
      loading: () => LinearProgressIndicator(
          color: t.goldText, backgroundColor: t.inkLift),
      error: (_, __) => const SizedBox.shrink(),
      data: (countries) {
        final selected = value;
        return InkWell(
          onTap: () async {
            final picked = await showModalBottomSheet<CountryModel>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _CountryPickerSheet(
                countries: countries,
                selected: selected,
              ),
            );
            if (picked != null) onChanged(picked);
          },
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          child: InputDecorator(
            decoration: gwInputDecoration(
              context,
              label: label,
              prefixIcon: Symbols.public,
              suffixIcon: Icon(Symbols.expand_more, size: 20, color: t.stoneDim),
            ),
            child: Text(
              selected != null
                  ? '${selected.flagEmoji ?? ''} ${selected.name}'.trim()
                  : (hint ?? 'Choisir un pays'),
              overflow: TextOverflow.ellipsis,
              style: GwType.ui(
                fontSize: 14,
                color: selected != null ? t.stone : t.stoneDim,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Feuille modale : barre de recherche + liste défilante drapeau + nom.
class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({
    required this.countries,
    required this.selected,
  });

  final List<CountryModel> countries;
  final CountryModel? selected;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Normalise pour une recherche insensible aux accents et à la casse.
  static String _normalize(String s) {
    const from = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿœæ';
    const to = 'aaaaaaceeeeiiiinooooouuuuyyoeae';
    final lower = s.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final ch = String.fromCharCode(rune);
      final idx = from.indexOf(ch);
      buffer.write(idx >= 0 ? to[idx] : ch);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final q = _normalize(_query.trim());
    final filtered = q.isEmpty
        ? widget.countries
        : widget.countries
            .where((c) => _normalize(c.name).contains(q))
            .toList();

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          decoration: BoxDecoration(
            color: t.inkCard,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(GwTokens.rCard)),
            border: Border.all(color: t.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              // Poignée.
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: t.lineMid,
                  borderRadius: BorderRadius.circular(GwTokens.rPill),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Choisir un pays',
                      style: GwType.ui(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: t.stone),
                    ),
                    const Spacer(),
                    Text(
                      '${filtered.length}',
                      style: GwType.mono(fontSize: 12, color: t.stoneDim),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  style: GwType.ui(fontSize: 14, color: t.stone),
                  decoration: gwInputDecoration(
                    context,
                    hint: 'Rechercher un pays...',
                    prefixIcon: Symbols.search,
                    dense: true,
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: Icon(Symbols.close,
                                size: 18, color: t.stoneDim),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Aucun pays correspondant',
                          style: GwType.ui(fontSize: 14, color: t.stoneDim),
                        ),
                      )
                    : Scrollbar(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final c = filtered[index];
                            final isSel = widget.selected?.id == c.id;
                            return InkWell(
                              onTap: () => Navigator.of(context).pop(c),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSel ? t.goldBg : null,
                                  border: Border(
                                    bottom: BorderSide(color: t.line, width: 0.5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      c.flagEmoji ?? '🏳️',
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        c.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: GwType.ui(
                                          fontSize: 14,
                                          fontWeight: isSel
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: isSel ? t.goldText : t.stone,
                                        ),
                                      ),
                                    ),
                                    if (isSel)
                                      Icon(Symbols.check,
                                          size: 18, color: t.goldText),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
