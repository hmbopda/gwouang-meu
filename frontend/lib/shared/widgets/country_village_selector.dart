import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/geo/geo_notifier.dart';
import '../models/country_model.dart';
import '../models/village_model.dart';

/// Widget réutilisable pour sélectionner un pays d'origine puis un ou plusieurs villages.
/// Supporte le mode multi-select avec recherche intégrée.
class CountryVillageSelector extends ConsumerStatefulWidget {
  const CountryVillageSelector({
    super.key,
    this.selectedCountry,
    this.selectedVillage,
    this.selectedVillages = const [],
    this.onCountryChanged,
    this.onVillageChanged,
    this.onVillagesChanged,
    this.countryLabel = 'Pays d\'origine',
    this.villageLabel = 'Village d\'appartenance',
    this.isDense = false,
    this.multiSelect = false,
  });

  final CountryModel? selectedCountry;

  /// For single-select mode (backward compat)
  final VillageModel? selectedVillage;
  final ValueChanged<VillageModel?>? onVillageChanged;

  /// For multi-select mode
  final List<VillageModel> selectedVillages;
  final ValueChanged<List<VillageModel>>? onVillagesChanged;

  final ValueChanged<CountryModel?>? onCountryChanged;
  final String countryLabel;
  final String villageLabel;
  final bool isDense;
  final bool multiSelect;

  @override
  ConsumerState<CountryVillageSelector> createState() =>
      _CountryVillageSelectorState();
}

class _CountryVillageSelectorState
    extends ConsumerState<CountryVillageSelector> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCountryDropdown(),
        SizedBox(height: widget.isDense ? 8 : 12),
        if (widget.multiSelect)
          _buildVillageMultiSelect()
        else
          _buildVillageDropdown(),
      ],
    );
  }

  Widget _buildCountryDropdown() {
    final countriesAsync = ref.watch(countriesNotifierProvider);
    return countriesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
      data: (countries) => DropdownButtonFormField<CountryModel>(
        initialValue: widget.selectedCountry,
        decoration: InputDecoration(
          labelText: widget.countryLabel,
          prefixIcon: const Icon(Icons.public_outlined),
          isDense: widget.isDense,
        ),
        isExpanded: true,
        items: countries
            .map((c) => DropdownMenuItem(
                  value: c,
                  child: Text('${c.flagEmoji ?? ''} ${c.name}'),
                ))
            .toList(),
        onChanged: (c) {
          widget.onCountryChanged?.call(c);
          widget.onVillageChanged?.call(null);
          widget.onVillagesChanged?.call([]);
          _searchCtrl.clear();
          setState(() => _searchQuery = '');
        },
      ),
    );
  }

  // ── Single-select (legacy) ──
  Widget _buildVillageDropdown() {
    final villagesAsync = ref.watch(
      villagesByCountryNotifierProvider(widget.selectedCountry?.isoCode),
    );
    return villagesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
      data: (villages) {
        if (villages.isEmpty && widget.selectedCountry != null) {
          return InputDecorator(
            decoration: InputDecoration(
              labelText: widget.villageLabel,
              prefixIcon: const Icon(Icons.location_on_outlined),
              isDense: widget.isDense,
            ),
            child: Text(
              'Aucun village pour ce pays',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          );
        }
        if (villages.isEmpty) return const SizedBox.shrink();
        return DropdownButtonFormField<VillageModel>(
          initialValue: widget.selectedVillage,
          decoration: InputDecoration(
            labelText: widget.villageLabel,
            prefixIcon: const Icon(Icons.location_on_outlined),
            isDense: widget.isDense,
          ),
          isExpanded: true,
          items: villages
              .map((v) => DropdownMenuItem(
                    value: v,
                    child: Text(
                      v.region != null ? '${v.name} (${v.region})' : v.name,
                    ),
                  ))
              .toList(),
          onChanged: (v) => widget.onVillageChanged?.call(v),
        );
      },
    );
  }

  // ── Multi-select with search ──
  Widget _buildVillageMultiSelect() {
    final villagesAsync = ref.watch(
      villagesByCountryNotifierProvider(widget.selectedCountry?.isoCode),
    );

    return villagesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
      data: (allVillages) {
        if (allVillages.isEmpty && widget.selectedCountry != null) {
          return InputDecorator(
            decoration: InputDecoration(
              labelText: widget.villageLabel,
              prefixIcon: const Icon(Icons.location_on_outlined),
              isDense: widget.isDense,
            ),
            child: Text(
              'Aucun village pour ce pays',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          );
        }
        if (allVillages.isEmpty) return const SizedBox.shrink();

        final selectedIds = widget.selectedVillages.map((v) => v.id).toSet();
        final filtered = _searchQuery.isEmpty
            ? allVillages
            : allVillages.where((v) {
                final q = _searchQuery.toLowerCase();
                return v.name.toLowerCase().contains(q) ||
                    (v.region?.toLowerCase().contains(q) ?? false);
              }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected chips
            if (widget.selectedVillages.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: widget.selectedVillages.map((v) {
                  return Chip(
                    label: Text(
                      v.region != null ? '${v.name} (${v.region})' : v.name,
                      style: const TextStyle(fontSize: 12),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      final updated = widget.selectedVillages
                          .where((sv) => sv.id != v.id)
                          .toList();
                      widget.onVillagesChanged?.call(updated);
                    },
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],

            // Search field
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Rechercher un village...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                prefixIcon:
                    Icon(Icons.search, size: 20, color: Colors.grey[500]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
            const SizedBox(height: 6),

            // Count
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                '${filtered.length} village${filtered.length > 1 ? 's' : ''}'
                '${widget.selectedVillages.isNotEmpty ? ' — ${widget.selectedVillages.length} selectionne${widget.selectedVillages.length > 1 ? 's' : ''}' : ''}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ),

            // List (max height 200)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Aucun village correspondant',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  : Scrollbar(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final v = filtered[index];
                          final isSelected = selectedIds.contains(v.id);
                          return InkWell(
                            onTap: () {
                              List<VillageModel> updated;
                              if (isSelected) {
                                updated = widget.selectedVillages
                                    .where((sv) => sv.id != v.id)
                                    .toList();
                              } else {
                                updated = [...widget.selectedVillages, v];
                              }
                              widget.onVillagesChanged?.call(updated);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                        .withAlpha(80)
                                    : null,
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade200,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.check_box
                                        : Icons.check_box_outline_blank,
                                    size: 20,
                                    color: isSelected
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                        : Colors.grey[400],
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          v.name,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                        ),
                                        if (v.region != null)
                                          Text(
                                            v.region!,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
