import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/network/api_client.dart';
import 'package:gwangmeu/core/router/breadcrumb_provider.dart';
import 'package:gwangmeu/core/router/route_names.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/home/home_screen.dart';
import 'package:gwangmeu/shared/widgets/loading_overlay.dart';

// ─────────────────────────────────────────────────────────────────
//  Providers — logique de recherche conservée
// ─────────────────────────────────────────────────────────────────

/// Requête de recherche globale.
final _searchQueryProvider = StateProvider<String>((ref) => '');

/// Portée active (Tout / Personnes / Villages / Lignées).
final _searchScopeProvider =
    StateProvider<_SearchScope>((ref) => _SearchScope.all);

final _searchResultsProvider =
    FutureProvider.autoDispose<List<_SearchResult>>((ref) async {
  final query = ref.watch(_searchQueryProvider);
  if (query.length < 2) return [];

  final client = ref.read(apiClientProvider);
  final json =
      await client.get('/api/v1/geo/search', queryParameters: {'q': query});
  final data = json['data'] as List<dynamic>? ?? [];
  return data
      .map((e) => _SearchResult.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ─────────────────────────────────────────────────────────────────
//  Portées de recherche (#3e)
// ─────────────────────────────────────────────────────────────────

enum _SearchScope {
  all('Tout'),
  people('Personnes'),
  villages('Villages'),
  lineages('Lignées');

  const _SearchScope(this.label);
  final String label;

  bool matches(String type) => switch (this) {
        all => true,
        people => type == 'PERSON',
        villages => type == 'VILLAGE',
        lineages => type == 'LINEAGE',
      };
}

/// Ordre d'affichage des sections de résultats.
const _typeOrder = ['PERSON', 'LINEAGE', 'VILLAGE', 'COUNTRY', 'CONTINENT'];

String _sectionLabel(String type) => switch (type) {
      'PERSON' => 'PERSONNES',
      'LINEAGE' => 'LIGNÉES',
      'VILLAGE' => 'VILLAGES',
      'COUNTRY' => 'PAYS',
      'CONTINENT' => 'CONTINENTS',
      _ => 'AUTRES',
    };

// ─────────────────────────────────────────────────────────────────
//  Écran « P4 Recherche » — Tissage #3e
// ─────────────────────────────────────────────────────────────────

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: ref.read(_searchQueryProvider));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final query = ref.watch(_searchQueryProvider);
    final scope = ref.watch(_searchScopeProvider);
    final resultsAsync = ref.watch(_searchResultsProvider);

    final desktop = isDesktopLayout(context);

    final results = query.length < 2
        ? _emptyState(t)
        : resultsAsync.when(
            loading: () => const ShimmerList(count: 6, cardHeight: 72),
            error: (e, _) => const _StatusMessage(
              icon: Symbols.cloud_off,
              message: 'Recherche indisponible',
            ),
            data: (all) {
              final visible =
                  all.where((r) => scope.matches(r.type)).toList();
              if (visible.isEmpty) {
                return _StatusMessage(
                  icon: Symbols.search_off,
                  message: 'Aucun résultat pour « $query »',
                );
              }
              return _resultsList(visible, query, desktop: desktop);
            },
          );

    final searchZone = Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _searchBar(t, query),
          const SizedBox(height: 8),
          _scopeChips(t, scope),
        ],
      ),
    );

    // Desktop (#2d) : on remplit la largeur donnée par la coquille (jusqu'à
    // ~1080). La zone de saisie est bornée à ~720 pour la lisibilité de la
    // frappe, mais les résultats groupés occupent toute la largeur en grille
    // 2 colonnes par section (voir [_resultsList]).
    if (desktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: searchZone,
          ),
          const SizedBox(height: 4),
          Expanded(child: results),
        ],
      );
    }

    return Scaffold(
      backgroundColor: t.ink,
      body: SafeArea(
        child: Column(
          children: [
            const GwWeaveBand(),
            _header(t),
            searchZone,
            const SizedBox(height: 4),
            Expanded(child: results),
          ],
        ),
      ),
    );
  }

  // ── Header mobile : titre Fraunces 22 + label mono ──────────────

  Widget _header(GwTokens t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recherche',
                  style: GwType.display(fontSize: 22, color: t.stone),
                ),
                Text(
                  'PERSONNES · VILLAGES · LIGNÉES',
                  style: GwType.mono(
                      fontSize: 10, color: t.stoneFaint, letterSpacing: 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Barre de recherche unique multi-entités ─────────────────────

  Widget _searchBar(GwTokens t, String query) {
    return Container(
      height: 52,
      padding: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        color: t.inkLift,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        border: Border.all(color: query.isNotEmpty ? t.goldLine : t.line),
      ),
      child: Row(
        children: [
          Icon(Symbols.search, size: 20, color: t.goldText),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _ctrl,
              autofocus: false,
              style: GwType.ui(fontSize: 15, color: t.stone),
              cursorColor: t.goldText,
              decoration: InputDecoration(
                hintText: 'Rechercher personnes, villages, lignées…',
                border: InputBorder.none,
                isCollapsed: true,
                hintStyle: GwType.ui(fontSize: 15, color: t.stoneDim),
              ),
              onChanged: (v) =>
                  ref.read(_searchQueryProvider.notifier).state = v,
            ),
          ),
          if (query.isNotEmpty)
            InkWell(
              onTap: () {
                _ctrl.clear();
                ref.read(_searchQueryProvider.notifier).state = '';
              },
              borderRadius: BorderRadius.circular(GwTokens.rBtn),
              child: SizedBox(
                width: GwTokens.tapTarget,
                height: GwTokens.tapTarget,
                child: Icon(Symbols.close, size: 18, color: t.stoneFaint),
              ),
            )
          else
            const SizedBox(width: 16),
        ],
      ),
    );
  }

  // ── Chips de portée : Tout / Personnes / Villages / Lignées ─────

  Widget _scopeChips(GwTokens t, _SearchScope active) {
    return SizedBox(
      height: GwTokens.tapTarget,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _SearchScope.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final scope = _SearchScope.values[i];
          return _ScopeChip(
            label: scope.label,
            active: scope == active,
            onTap: () =>
                ref.read(_searchScopeProvider.notifier).state = scope,
          );
        },
      ),
    );
  }

  // ── Liste des résultats, groupée par entité ─────────────────────

  Widget _resultsList(
    List<_SearchResult> visible,
    String query, {
    required bool desktop,
  }) {
    final t = GwTokens.of(context);
    final groups = <String, List<_SearchResult>>{};
    for (final r in visible) {
      groups.putIfAbsent(r.type, () => []).add(r);
    }
    final orderedTypes = [
      ..._typeOrder.where(groups.containsKey),
      ...groups.keys.where((k) => !_typeOrder.contains(k)),
    ];

    // Desktop (#2d) : résultats larges — chaque section en grille 2 colonnes
    // (maxCrossAxisExtent 540 → 2 colonnes sur la plage ~900-1180 fournie par
    // la coquille), au lieu d'une colonne étroite. Remplit la largeur donnée.
    if (desktop) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          for (final type in orderedTypes) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
              child: Text(
                '${_sectionLabel(type)} · ${groups[type]!.length}',
                style: GwType.mono(
                    fontSize: 10, color: t.stoneFaint, letterSpacing: 2),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate:
                  const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 540,
                mainAxisExtent: 70,
                crossAxisSpacing: 12,
                mainAxisSpacing: 4,
              ),
              itemCount: groups[type]!.length,
              itemBuilder: (context, i) {
                final r = groups[type]![i];
                return _ResultTile(
                  result: r,
                  query: query,
                  onTap: () => _navigate(context, r),
                );
              },
            ),
          ],
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final type in orderedTypes) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text(
              '${_sectionLabel(type)} · ${groups[type]!.length}',
              style: GwType.mono(
                  fontSize: 10, color: t.stoneFaint, letterSpacing: 2),
            ),
          ),
          for (final r in groups[type]!)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: _ResultTile(
                result: r,
                query: query,
                onTap: () => _navigate(context, r),
              ),
            ),
        ],
      ],
    );
  }

  // ── États vides ─────────────────────────────────────────────────

  Widget _emptyState(GwTokens t) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Symbols.travel_explore, size: 64, color: t.stoneDim),
          const SizedBox(height: 16),
          Text(
            'Explorez la mémoire commune',
            textAlign: TextAlign.center,
            style: GwType.ui(
                fontSize: 15, color: t.stoneMid, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Personnes · Villages · Lignées',
            textAlign: TextAlign.center,
            style: GwType.ui(fontSize: 14, color: t.stoneDim),
          ),
        ],
      ),
    );
  }

  // ── Navigation — logique conservée ──────────────────────────────

  void _navigate(BuildContext context, _SearchResult result) {
    if (result.type == 'VILLAGE' && result.id != null) {
      ref.read(breadcrumbProvider.notifier).reset(
          const BreadcrumbEntry(label: 'Recherche', route: Routes.search));
      ref.read(breadcrumbProvider.notifier).push(BreadcrumbEntry(
          label: result.name, route: Routes.villageDetail(result.id!)));
      context.push(Routes.villageDetail(result.id!));
    }
  }
}

// ─────────────────────────────────────────────────────────────────
//  Chip de portée — pilule 36 px dans une cible tactile 44 px
// ─────────────────────────────────────────────────────────────────

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GwTokens.rPill),
      child: SizedBox(
        height: GwTokens.tapTarget,
        child: Center(
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? t.goldBg : t.inkLift,
              borderRadius: BorderRadius.circular(GwTokens.rPill),
              border: active ? Border.all(color: t.goldLine) : null,
            ),
            child: Text(
              label,
              style: GwType.ui(
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? t.goldText : t.stoneMid,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Tuile résultat — initiale Fraunces teintée, <mark> or, badge mono
// ─────────────────────────────────────────────────────────────────

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.result,
    required this.query,
    required this.onTap,
  });

  final _SearchResult result;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final (initialFg, initialBg) = _initialTint(t);
    final (badgeLabel, badgeFg, badgeBg) = _badge(t);
    final initial =
        result.name.isNotEmpty ? result.name[0].toUpperCase() : '?';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Initiale Fraunces teintée par type
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: initialBg,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  initial,
                  style: GwType.display(fontSize: 17, color: initialFg),
                ),
              ),
              const SizedBox(width: 12),

              // Nom (fragment surligné or) + méta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(children: _highlight(result.name, query, t)),
                      style: GwType.ui(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: t.stone,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (result.parentName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        result.parentName!,
                        style: GwType.ui(fontSize: 12.5, color: t.stoneDim),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Badge de provenance — JetBrains Mono
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  badgeLabel,
                  style: GwType.mono(
                      fontSize: 10, color: badgeFg, letterSpacing: 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Équivalent du `<mark>` : fond or 20 %, graisse w700.
  List<TextSpan> _highlight(String text, String query, GwTokens t) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [TextSpan(text: text)];

    final lower = text.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;
    var idx = lower.indexOf(q);
    while (idx >= 0) {
      if (idx > start) spans.add(TextSpan(text: text.substring(start, idx)));
      spans.add(TextSpan(
        text: text.substring(idx, idx + q.length),
        style: TextStyle(
          backgroundColor: t.goldGlow,
          color: t.stone,
          fontWeight: FontWeight.w700,
        ),
      ));
      start = idx + q.length;
      idx = lower.indexOf(q, start);
    }
    if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
    return spans;
  }

  (Color, Color) _initialTint(GwTokens t) => switch (result.type) {
        'PERSON' => (t.goldText, t.goldBg),
        'VILLAGE' => (t.sageText, GwTokens.sageBg),
        'LINEAGE' => (GwTokens.rose, GwTokens.roseBg),
        _ => (t.azureText, GwTokens.azureBg),
      };

  (String, Color, Color) _badge(GwTokens t) {
    // Suggestion IA : badge « IA 87% » en sage.
    final confidence = result.aiConfidence;
    if (confidence != null) {
      return ('IA $confidence', t.sageText, GwTokens.sageBg);
    }
    return switch (result.type) {
      'PERSON' || 'LINEAGE' => ('LIGNÉE', t.goldText, t.goldBg),
      'VILLAGE' => ('VILLAGE', t.stoneFaint, t.inkLift),
      'COUNTRY' => ('PAYS', t.stoneFaint, t.inkLift),
      'CONTINENT' => ('CONTINENT', t.stoneFaint, t.inkLift),
      _ => (result.type, t.stoneFaint, t.inkLift),
    };
  }
}

// ─────────────────────────────────────────────────────────────────
//  Message d'état (erreur / aucun résultat)
// ─────────────────────────────────────────────────────────────────

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: t.stoneDim),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GwType.ui(fontSize: 14, color: t.stoneMid),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Modèle de résultat — logique conservée
// ─────────────────────────────────────────────────────────────────

class _SearchResult {
  final String? id;
  final String type;
  final String name;
  final String? code;
  final String? parentName;

  /// Confiance IA (« 87% ») si le résultat est une suggestion.
  final String? aiConfidence;

  const _SearchResult({
    this.id,
    required this.type,
    required this.name,
    this.code,
    this.parentName,
    this.aiConfidence,
  });

  factory _SearchResult.fromJson(Map<String, dynamic> json) => _SearchResult(
        id: json['id'] as String?,
        type: json['type'] as String? ?? 'UNKNOWN',
        name: json['name'] as String? ?? '',
        code: json['code'] as String?,
        parentName: json['parentName'] as String?,
        aiConfidence: json['confidence'] as String?,
      );
}
