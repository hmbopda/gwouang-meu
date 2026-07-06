import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gwangmeu/core/network/api_client.dart';
import 'package:gwangmeu/core/router/breadcrumb_provider.dart';
import 'package:gwangmeu/core/router/route_names.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/shared/widgets/loading_overlay.dart';
import 'package:gwangmeu/features/home/home_screen.dart';

// Provider de recherche globale
final _searchQueryProvider = StateProvider<String>((ref) => '');

final _searchResultsProvider = FutureProvider.autoDispose<List<_SearchResult>>((ref) async {
  final query = ref.watch(_searchQueryProvider);
  if (query.length < 2) return [];

  final client = ref.read(apiClientProvider);
  final json = await client.get('/api/v1/geo/search', queryParameters: {'q': query});
  final data = json['data'] as List<dynamic>? ?? [];
  return data.map((e) => _SearchResult.fromJson(e as Map<String, dynamic>)).toList();
});

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(_searchQueryProvider);
    final resultsAsync = ref.watch(_searchResultsProvider);

    final desktop = isDesktopLayout(context);

    final body = query.length < 2
        ? _emptyState()
        : resultsAsync.when(
            loading: () => const ShimmerList(count: 6, cardHeight: 72),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_outlined, size: 48, color: GwTokens.dark.stoneDim),
                  const SizedBox(height: 12),
                  Text('Recherche indisponible', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: GwTokens.dark.stoneMid)),
                ],
              ),
            ),
            data: (results) => results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 48, color: GwTokens.dark.stoneDim),
                        const SizedBox(height: 12),
                        Text('Aucun résultat pour "$query"', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: GwTokens.dark.stoneMid)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) => _ResultTile(
                      result: results[i],
                      onTap: () => _navigate(context, results[i]),
                    ),
                  ),
          );

    if (desktop) return body;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: false,
          style: TextStyle(color: GwTokens.dark.stone),
          decoration: InputDecoration(
            hintText: 'Rechercher village, pays, continent...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: GwTokens.dark.stoneDim),
          ),
          onChanged: (v) => ref.read(_searchQueryProvider.notifier).state = v,
        ),
        actions: [
          if (query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _ctrl.clear();
                ref.read(_searchQueryProvider.notifier).state = '';
              },
            ),
        ],
      ),
      body: body,
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.travel_explore, size: 72, color: GwTokens.dark.stoneDim),
          const SizedBox(height: 16),
          Text(
            'Explorez l\'Afrique\nVillages · Pays · Continents',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: GwTokens.dark.stoneMid),
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, _SearchResult result) {
    if (result.type == 'VILLAGE' && result.id != null) {
      ref.read(breadcrumbProvider.notifier).reset(const BreadcrumbEntry(label: 'Recherche', route: Routes.search));
      ref.read(breadcrumbProvider.notifier).push(BreadcrumbEntry(label: result.name, route: Routes.villageDetail(result.id!)));
      context.push(Routes.villageDetail(result.id!));
    }
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.result, required this.onTap});
  final _SearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _icon(context),
      title: Text(result.name, style: Theme.of(context).textTheme.titleMedium),
      subtitle: result.parentName != null
          ? Text(result.parentName!, style: Theme.of(context).textTheme.bodySmall)
          : null,
      trailing: _badge(),
      onTap: onTap,
    );
  }

  Widget _icon(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final color = switch (result.type) {
      'VILLAGE' => accent,
      'COUNTRY' => GwTokens.sage,
      _ => GwTokens.azure,
    };
    final icon = switch (result.type) {
      'VILLAGE' => Icons.location_city_outlined,
      'COUNTRY' => Icons.flag_outlined,
      _ => Icons.public_outlined,
    };
    return CircleAvatar(
      backgroundColor: color.withAlpha(30),
      child: Icon(icon, color: color, size: 18),
    );
  }

  Widget _badge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: GwTokens.dark.inkLift,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        result.type,
        style: TextStyle(fontSize: 10, color: GwTokens.dark.stoneMid),
      ),
    );
  }
}

class _SearchResult {
  final String? id;
  final String type;
  final String name;
  final String? code;
  final String? parentName;

  const _SearchResult({this.id, required this.type, required this.name, this.code, this.parentName});

  factory _SearchResult.fromJson(Map<String, dynamic> json) => _SearchResult(
        id: json['id'] as String?,
        type: json['type'] as String? ?? 'UNKNOWN',
        name: json['name'] as String? ?? '',
        code: json['code'] as String?,
        parentName: json['parentName'] as String?,
      );
}
