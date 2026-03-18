import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/breadcrumb_provider.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/models/village_model.dart';
import '../../shared/widgets/village_card.dart';
import '../home/home_screen.dart';
import 'villages_notifier.dart';

class VillagesScreen extends ConsumerStatefulWidget {
  const VillagesScreen({super.key});

  @override
  ConsumerState<VillagesScreen> createState() => _VillagesScreenState();
}

class _VillagesScreenState extends ConsumerState<VillagesScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  bool _isSearching = false;
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final desktop = isDesktopLayout(context);
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    if (desktop) {
      return ref.watch(villagesNotifierProvider).when(
            loading: () => _shimmerGrid(),
            error: (e, _) => _errorState(ref),
            data: (villages) => _buildGrid(context, ref, villages),
          );
    }

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Rechercher un village...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.textHint),
                ),
                onChanged: (q) {
                  if (q.length >= 2 || q.isEmpty) {
                    ref.read(villagesNotifierProvider.notifier).search(q);
                  }
                },
              )
            : const Text('Villages'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() => _isSearching = !_isSearching);
              if (!_isSearching) {
                _searchCtrl.clear();
                ref.read(villagesNotifierProvider.notifier).refresh();
              }
            },
          ),
        ],
        bottom: _isSearching
            ? null
            : TabBar(
                controller: _tabCtrl,
                indicatorColor: accent,
                labelColor: accent,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 14),
                dividerColor: theme.colorScheme.outline.withAlpha(30),
                tabs: const [
                  Tab(text: 'Découvrir'),
                  Tab(text: 'Mes villages'),
                ],
              ),
      ),
      body: _isSearching
          ? _buildSearchResults()
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _DiscoverTab(),
                _MyVillagesTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.createVillage),
        backgroundColor: accent,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ── Search results (same as before) ──
  Widget _buildSearchResults() {
    final villagesState = ref.watch(villagesNotifierProvider);
    return villagesState.when(
      loading: () => _shimmerGrid(),
      error: (e, _) => _errorState(ref),
      data: (villages) => villages.isEmpty
          ? _emptyState('Aucun résultat', Icons.search_off)
          : _buildGrid(context, ref, villages),
    );
  }

  Widget _buildGrid(BuildContext context, WidgetRef ref, List<VillageModel> villages) {
    final accent = Theme.of(context).colorScheme.primary;
    return RefreshIndicator(
      color: accent,
      onRefresh: () => ref.read(villagesNotifierProvider.notifier).refresh(),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
        itemCount: villages.length,
        itemBuilder: (context, index) => VillageCard(village: villages[index]),
      ),
    );
  }

  Widget _shimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const ShimmerCard(height: 200),
    );
  }

  Widget _errorState(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 48, color: AppColors.textHint),
          const SizedBox(height: 12),
          const Text('Impossible de charger', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => ref.read(villagesNotifierProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Tab 1 — Découvrir tous les villages
// ─────────────────────────────────────────────

class _DiscoverTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final villagesState = ref.watch(villagesNotifierProvider);
    final accent = Theme.of(context).colorScheme.primary;

    return villagesState.when(
      loading: () => GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => const ShimmerCard(height: 200),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            const Text('Impossible de charger', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => ref.read(villagesNotifierProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
      data: (villages) {
        if (villages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.holiday_village_outlined, size: 48, color: AppColors.textHint),
                const SizedBox(height: 12),
                const Text('Aucun village pour le moment',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: accent,
          onRefresh: () => ref.read(villagesNotifierProvider.notifier).refresh(),
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemCount: villages.length,
            itemBuilder: (context, index) => VillageCard(village: villages[index]),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Tab 2 — Mes villages (abonnés)
// ─────────────────────────────────────────────

class _MyVillagesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myVillagesState = ref.watch(myVillagesNotifierProvider);
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return myVillagesState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            const Text('Impossible de charger', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
      data: (villages) {
        if (villages.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.holiday_village_outlined, size: 56, color: accent.withAlpha(80)),
                  const SizedBox(height: 16),
                  Text(
                    'Vous n\'avez rejoint aucun village',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Explorez l\'onglet "Découvrir" et rejoignez\nla communauté de votre village',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: accent,
          onRefresh: () async {
            ref.invalidate(myVillagesNotifierProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: villages.length,
            itemBuilder: (context, index) {
              final v = villages[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MyVillageTile(village: v),
              );
            },
          ),
        );
      },
    );
  }
}

class _MyVillageTile extends ConsumerWidget {
  const _MyVillageTile({required this.village});
  final VillageModel village;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return GestureDetector(
      onTap: () {
        ref.read(breadcrumbProvider.notifier).reset(const BreadcrumbEntry(label: 'Villages', route: Routes.villages));
        ref.read(breadcrumbProvider.notifier).push(BreadcrumbEntry(label: village.name, route: Routes.villageDetail(village.id)));
        context.push(Routes.villageDetail(village.id));
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outline.withAlpha(30)),
        ),
        child: Row(
          children: [
            // Cover image or icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: accent.withAlpha(15),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
                image: village.coverImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(village.coverImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: village.coverImageUrl == null
                  ? Icon(Icons.holiday_village_outlined, color: accent, size: 28)
                  : null,
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            village.name,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (village.verified)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.verified, color: accent, size: 16),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        village.country,
                        if (village.region != null) village.region,
                        if (village.primaryDialect != null) village.primaryDialect,
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.group_outlined, size: 14, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          '${village.memberCount} membre${village.memberCount > 1 ? 's' : ''}',
                          style: TextStyle(color: AppColors.textHint, fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withAlpha(15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Rejoint',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
