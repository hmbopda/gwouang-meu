import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/genealogy/services/geo_referentiel_service.dart';
import 'package:gwangmeu/shared/widgets/gw_dialog.dart';

/// Sélection d'origine issue du référentiel territorial (Cameroun).
/// Tous les champs sont des libellés (noms) et peuvent être `null`.
@immutable
class OriginSelection {
  const OriginSelection({
    this.regionName,
    this.departmentName,
    this.arrondissementName,
    this.chefferieName,
  });

  final String? regionName;
  final String? departmentName;
  final String? arrondissementName;
  final String? chefferieName;

  OriginSelection copyWith({
    String? regionName,
    String? departmentName,
    String? arrondissementName,
    String? chefferieName,
  }) =>
      OriginSelection(
        regionName: regionName ?? this.regionName,
        departmentName: departmentName ?? this.departmentName,
        arrondissementName: arrondissementName ?? this.arrondissementName,
        chefferieName: chefferieName ?? this.chefferieName,
      );
}

/// Sélecteur en cascade du référentiel territorial camerounais.
///
/// Quatre niveaux dépendants empilés : Région → Département →
/// Commune/Arrondissement (optionnel) → Chefferie/Village (typeahead,
/// optionnel — saisie libre possible en repli). Chaque niveau charge ses
/// données à la sélection de son parent. En cas d'échec réseau, un message
/// discret s'affiche et l'utilisateur peut saisir librement.
class OriginCascadeSelector extends ConsumerStatefulWidget {
  const OriginCascadeSelector({
    super.key,
    required this.onChanged,
    this.initial,
  });

  final ValueChanged<OriginSelection> onChanged;
  final OriginSelection? initial;

  @override
  ConsumerState<OriginCascadeSelector> createState() =>
      _OriginCascadeSelectorState();
}

class _OriginCascadeSelectorState
    extends ConsumerState<OriginCascadeSelector> {
  // Données chargées par niveau.
  List<GeoRegion> _regions = [];
  List<GeoDepartment> _departments = [];
  List<GeoArrondissement> _arrondissements = [];
  List<GeoChefferie> _chefferies = [];

  // Sélections courantes (objets référentiel).
  GeoRegion? _region;
  GeoDepartment? _department;
  GeoArrondissement? _arrondissement;

  // Chefferie / village : champ typeahead libre.
  final _chefferieCtrl = TextEditingController();
  final _chefferieFocus = FocusNode();
  bool _chefferieMenuOpen = false;
  Timer? _debounce;

  // États de chargement discrets par niveau.
  bool _loadingRegions = false;
  bool _loadingDepartments = false;
  bool _loadingArrondissements = false;
  bool _loadingChefferies = false;

  // Repli saisie libre si le référentiel est injoignable.
  bool _networkFailed = false;

  @override
  void initState() {
    super.initState();
    _chefferieCtrl.text = widget.initial?.chefferieName ?? '';
    _loadRegions();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _chefferieCtrl.dispose();
    _chefferieFocus.dispose();
    super.dispose();
  }

  GeoReferentielService get _service =>
      ref.read(geoReferentielServiceProvider);

  void _emit() {
    widget.onChanged(OriginSelection(
      regionName: _region?.name,
      departmentName: _department?.name,
      arrondissementName: _arrondissement?.name,
      chefferieName: _chefferieCtrl.text.trim().isNotEmpty
          ? _chefferieCtrl.text.trim()
          : null,
    ));
  }

  // ── Chargements en cascade ─────────────────────────────────

  Future<void> _loadRegions() async {
    setState(() {
      _loadingRegions = true;
      _networkFailed = false;
    });
    try {
      final regions = await _service.fetchRegions();
      if (!mounted) return;
      setState(() {
        _regions = regions;
        _loadingRegions = false;
        // Pré-remplissage éventuel via l'initial (par nom).
        final initName = widget.initial?.regionName;
        if (initName != null && _region == null) {
          for (final r in regions) {
            if (r.name.toLowerCase() == initName.toLowerCase()) {
              _region = r;
              break;
            }
          }
        }
      });
      if (_region != null) {
        await _loadDepartments(_region!);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingRegions = false;
        _networkFailed = true;
      });
    }
  }

  Future<void> _loadDepartments(GeoRegion region) async {
    setState(() {
      _loadingDepartments = true;
      _departments = [];
      _arrondissements = [];
      _chefferies = [];
    });
    try {
      final departments = await _service.fetchDepartments(region.code);
      if (!mounted) return;
      setState(() {
        _departments = departments;
        _loadingDepartments = false;
        final initName = widget.initial?.departmentName;
        if (initName != null && _department == null) {
          for (final d in departments) {
            if (d.name.toLowerCase() == initName.toLowerCase()) {
              _department = d;
              break;
            }
          }
        }
      });
      if (_department != null) {
        await _loadArrondissements(_department!);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingDepartments = false;
        _networkFailed = true;
      });
    }
  }

  Future<void> _loadArrondissements(GeoDepartment department) async {
    setState(() {
      _loadingArrondissements = true;
      _arrondissements = [];
    });
    try {
      final arrondissements =
          await _service.fetchArrondissements(department.code);
      if (!mounted) return;
      setState(() {
        _arrondissements = arrondissements;
        _loadingArrondissements = false;
        final initName = widget.initial?.arrondissementName;
        if (initName != null && _arrondissement == null) {
          for (final a in arrondissements) {
            if (a.name.toLowerCase() == initName.toLowerCase()) {
              _arrondissement = a;
              break;
            }
          }
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingArrondissements = false);
    }
  }

  Future<void> _loadChefferies(String query) async {
    final department = _department;
    if (department == null) return;
    setState(() => _loadingChefferies = true);
    try {
      final chefferies = await _service.fetchChefferies(
        department.code,
        query: query,
        limit: 50,
      );
      if (!mounted) return;
      setState(() {
        _chefferies = chefferies;
        _loadingChefferies = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _chefferies = [];
        _loadingChefferies = false;
      });
    }
  }

  // ── Handlers de sélection ──────────────────────────────────

  void _onRegionChanged(GeoRegion? region) {
    setState(() {
      _region = region;
      _department = null;
      _arrondissement = null;
      _departments = [];
      _arrondissements = [];
      _chefferies = [];
    });
    _emit();
    if (region != null) _loadDepartments(region);
  }

  void _onDepartmentChanged(GeoDepartment? department) {
    setState(() {
      _department = department;
      _arrondissement = null;
      _arrondissements = [];
      _chefferies = [];
    });
    _emit();
    if (department != null) _loadArrondissements(department);
  }

  void _onArrondissementChanged(GeoArrondissement? arrondissement) {
    setState(() => _arrondissement = arrondissement);
    _emit();
  }

  void _onChefferieTextChanged(String value) {
    _emit();
    _debounce?.cancel();
    if (_department == null) return;
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _loadChefferies(value);
    });
  }

  void _pickChefferie(GeoChefferie chefferie) {
    _chefferieCtrl.text = chefferie.denomination;
    _chefferieCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: _chefferieCtrl.text.length),
    );
    setState(() => _chefferieMenuOpen = false);
    _chefferieFocus.unfocus();
    _emit();
  }

  // ── UI ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);

    if (_networkFailed) {
      return _buildFreeTextFallback(t);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Région ──
        _LevelLabel(text: 'Région', loading: _loadingRegions),
        const SizedBox(height: 6),
        DropdownButtonFormField<GeoRegion>(
          key: ValueKey('geo_region_${_region?.code}'),
          initialValue: _region,
          isExpanded: true,
          dropdownColor: t.inkCard,
          style: GwType.ui(fontSize: 14, color: t.stone),
          decoration: gwInputDecoration(
            context,
            label: 'Choisir une région',
            prefixIcon: Symbols.map,
            dense: true,
          ),
          items: _regions
              .map((r) => DropdownMenuItem(
                    value: r,
                    child: Text(r.name, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: _loadingRegions ? null : _onRegionChanged,
        ),
        const SizedBox(height: 12),

        // ── Département ──
        _LevelLabel(text: 'Département', loading: _loadingDepartments),
        const SizedBox(height: 6),
        DropdownButtonFormField<GeoDepartment>(
          key: ValueKey('geo_department_${_department?.code}'),
          initialValue: _department,
          isExpanded: true,
          dropdownColor: t.inkCard,
          style: GwType.ui(fontSize: 14, color: t.stone),
          decoration: gwInputDecoration(
            context,
            label: _region == null
                ? 'Choisir d\'abord une région'
                : 'Choisir un département',
            prefixIcon: Symbols.location_city,
            dense: true,
          ),
          items: _departments
              .map((d) => DropdownMenuItem(
                    value: d,
                    child: Text(d.name, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (_region == null || _loadingDepartments)
              ? null
              : _onDepartmentChanged,
        ),
        const SizedBox(height: 12),

        // ── Commune / Arrondissement (optionnel) ──
        _LevelLabel(
          text: 'Commune / Arrondissement',
          optional: true,
          loading: _loadingArrondissements,
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<GeoArrondissement>(
          key: ValueKey('geo_arr_${_arrondissement?.code}'),
          initialValue: _arrondissement,
          isExpanded: true,
          dropdownColor: t.inkCard,
          style: GwType.ui(fontSize: 14, color: t.stone),
          decoration: gwInputDecoration(
            context,
            label: _department == null
                ? 'Choisir d\'abord un département'
                : 'Choisir une commune (optionnel)',
            prefixIcon: Symbols.holiday_village,
            dense: true,
          ),
          items: _arrondissements
              .map((a) => DropdownMenuItem(
                    value: a,
                    child: Text(a.name, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (_department == null || _loadingArrondissements)
              ? null
              : _onArrondissementChanged,
        ),
        const SizedBox(height: 12),

        // ── Chefferie / Village (typeahead, optionnel) ──
        _LevelLabel(
          text: 'Chefferie / Village',
          optional: true,
          loading: _loadingChefferies,
        ),
        const SizedBox(height: 6),
        _buildChefferieField(t),
      ],
    );
  }

  Widget _buildChefferieField(GwTokens t) {
    final department = _department;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _chefferieCtrl,
          focusNode: _chefferieFocus,
          style: GwType.ui(fontSize: 14, color: t.stone),
          decoration: gwInputDecoration(
            context,
            label: department == null
                ? 'Choisir d\'abord un département'
                : 'Rechercher ou saisir (optionnel)',
            hint: 'Ex: Bana, Bandjoun...',
            prefixIcon: Symbols.forest,
            dense: true,
            suffixIcon: _chefferieCtrl.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Symbols.close, size: 18, color: t.stoneDim),
                    onPressed: () {
                      _chefferieCtrl.clear();
                      setState(() {
                        _chefferies = [];
                        _chefferieMenuOpen = false;
                      });
                      _emit();
                    },
                  )
                : null,
          ),
          enabled: department != null,
          onTap: () {
            if (_chefferies.isNotEmpty) {
              setState(() => _chefferieMenuOpen = true);
            } else if (department != null) {
              _loadChefferies(_chefferieCtrl.text);
              setState(() => _chefferieMenuOpen = true);
            }
          },
          onChanged: (v) {
            setState(() => _chefferieMenuOpen = true);
            _onChefferieTextChanged(v);
          },
        ),
        if (_chefferieMenuOpen && department != null) _buildChefferieMenu(t),
      ],
    );
  }

  Widget _buildChefferieMenu(GwTokens t) {
    if (_loadingChefferies) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: LinearProgressIndicator(
          color: t.goldText,
          backgroundColor: t.inkLift,
          minHeight: 2,
        ),
      );
    }
    if (_chefferies.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 6, left: 4),
        child: Text(
          'Aucune chefferie trouvée — vous pouvez saisir un nom libre.',
          style: GwType.ui(fontSize: 12, color: t.stoneDim),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(top: 6),
      constraints: const BoxConstraints(maxHeight: 180),
      decoration: BoxDecoration(
        color: t.inkCard,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        border: Border.all(color: t.line),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _chefferies.length,
        itemBuilder: (context, i) {
          final c = _chefferies[i];
          final subtitle = [
            if (c.departmentName != null) c.departmentName,
            'degré ${c.degre}',
          ].join(' · ');
          return InkWell(
            onTap: () => _pickChefferie(c),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Symbols.forest, size: 16, color: t.stoneDim),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.denomination,
                          style: GwType.ui(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: t.stone),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          subtitle,
                          style:
                              GwType.ui(fontSize: 11, color: t.stoneDim),
                          overflow: TextOverflow.ellipsis,
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
    );
  }

  /// Repli saisie libre : le référentiel est injoignable, on n'empêche pas
  /// la saisie de l'origine.
  Widget _buildFreeTextFallback(GwTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Symbols.cloud_off, size: 16, color: t.stoneDim),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Référentiel indisponible — saisie libre.',
                style: GwType.ui(fontSize: 12, color: t.stoneDim),
              ),
            ),
            _GoldTextRetry(onTap: _loadRegions),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          initialValue: widget.initial?.regionName,
          style: GwType.ui(fontSize: 14, color: t.stone),
          decoration: gwInputDecoration(
            context,
            label: 'Région d\'origine',
            prefixIcon: Symbols.map,
            dense: true,
          ),
          onChanged: (v) {
            _fallbackRegion = v.trim().isNotEmpty ? v.trim() : null;
            _emitFallback();
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: widget.initial?.departmentName,
          style: GwType.ui(fontSize: 14, color: t.stone),
          decoration: gwInputDecoration(
            context,
            label: 'Département / ville d\'origine',
            prefixIcon: Symbols.location_city,
            dense: true,
          ),
          onChanged: (v) {
            _fallbackDepartment = v.trim().isNotEmpty ? v.trim() : null;
            _emitFallback();
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _chefferieCtrl,
          style: GwType.ui(fontSize: 14, color: t.stone),
          decoration: gwInputDecoration(
            context,
            label: 'Chefferie / village d\'origine',
            prefixIcon: Symbols.forest,
            dense: true,
          ),
          onChanged: (_) => _emitFallback(),
        ),
      ],
    );
  }

  // Valeurs de repli (saisie libre) hors référentiel.
  String? _fallbackRegion;
  String? _fallbackDepartment;
  final String? _fallbackArrondissement = null;

  void _emitFallback() {
    widget.onChanged(OriginSelection(
      regionName: _fallbackRegion,
      departmentName: _fallbackDepartment,
      arrondissementName: _fallbackArrondissement,
      chefferieName: _chefferieCtrl.text.trim().isNotEmpty
          ? _chefferieCtrl.text.trim()
          : null,
    ));
  }
}

/// Libellé de niveau : nom + marqueur « optionnel » + spinner discret.
class _LevelLabel extends StatelessWidget {
  const _LevelLabel({
    required this.text,
    this.optional = false,
    this.loading = false,
  });

  final String text;
  final bool optional;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Row(
      children: [
        Text(
          text,
          style: GwType.ui(
              fontSize: 12, fontWeight: FontWeight.w600, color: t.stoneMid),
        ),
        if (optional) ...[
          const SizedBox(width: 6),
          Text('· optionnel',
              style: GwType.ui(fontSize: 11, color: t.stoneDim)),
        ],
        if (loading) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.6,
              color: t.goldText,
            ),
          ),
        ],
      ],
    );
  }
}

class _GoldTextRetry extends StatelessWidget {
  const _GoldTextRetry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(Symbols.refresh, size: 16, color: t.goldText),
      label: Text('Réessayer',
          style: GwType.ui(
              fontSize: 12, fontWeight: FontWeight.w600, color: t.goldText)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
