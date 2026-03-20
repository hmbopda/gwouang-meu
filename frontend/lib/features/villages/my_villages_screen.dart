import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gwangmeu/core/router/breadcrumb_provider.dart';
import 'package:gwangmeu/core/router/route_names.dart';
import 'package:gwangmeu/core/theme/gw_colors.dart';
import 'package:gwangmeu/shared/models/village_model.dart';
import 'package:gwangmeu/features/villages/villages_notifier.dart';

// ═══════════════════════════════════════════════
// MES VILLAGES — Maquette gwangmeu-village-v3
// Rail gauche adapté mobile : sections, gems,
// badges génération, compteurs, locks, CTA.
// ═══════════════════════════════════════════════

class MyVillagesScreen extends ConsumerWidget {
  const MyVillagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = GwColors.of(context);
    final myVillagesAsync = ref.watch(myVillagesNotifierProvider);
    final allVillagesAsync = ref.watch(villagesNotifierProvider);

    return Scaffold(
      backgroundColor: c.inkDeep,
      body: myVillagesAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: c.gold),
        ),
        error: (e, _) => _buildError(context, ref),
        data: (myVillages) {
          // Tous les villages pour la section "Autres"
          final allVillages = allVillagesAsync.valueOrNull ?? [];
          final myIds = myVillages.map((v) => v.id).toSet();
          final otherVillages = allVillages.where((v) => !myIds.contains(v.id)).toList();

          return _MyVillagesBody(
            myVillages: myVillages,
            otherVillages: otherVillages,
          );
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref) {
    final c = GwColors.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 40, color: c.stoneDim),
          const SizedBox(height: 12),
          Text('Impossible de charger',
              style: TextStyle(color: c.stoneDim, fontSize: 13)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => ref.invalidate(myVillagesNotifierProvider),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: c.goldFaint,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: c.goldLine),
              ),
              child: Text('Réessayer',
                  style: TextStyle(color: c.gold, fontSize: 12, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Body
// ─────────────────────────────────────────

class _MyVillagesBody extends StatelessWidget {
  const _MyVillagesBody({required this.myVillages, required this.otherVillages});
  final List<VillageModel> myVillages;
  final List<VillageModel> otherVillages;

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    final gemColors = [c.gold, c.sage, c.azure, c.ember, c.goldLight];

    return CustomScrollView(
      slivers: [
        // ── Header ──
        _buildHeader(context),

        // ── Section : Accès confirmé ──
        if (myVillages.isNotEmpty) ...[
          _sectionLabel(context, 'Accès confirmé'),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _VillageItem(
                village: myVillages[i],
                gemColor: gemColors[i % gemColors.length],
                genLabel: 'G${i + 1}',
                isActive: i == 0,
              ),
              childCount: myVillages.length,
            ),
          ),
        ],

        // ── Separator ──
        const SliverToBoxAdapter(child: _Rule()),

        // ── Section : À débloquer ──
        _sectionLabel(context, 'À débloquer'),
        SliverToBoxAdapter(child: _UnlockCard()),

        // ── Separator ──
        const SliverToBoxAdapter(child: _Rule()),

        // ── Section : Autres villages ──
        _sectionLabel(context, 'Autres'),
        if (otherVillages.isEmpty)
          SliverToBoxAdapter(
            child: _ExploreItem(),
          )
        else ...[
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                if (i < otherVillages.length.clamp(0, 3)) {
                  return _VillageItem(
                    village: otherVillages[i],
                    gemColor: c.stoneFaint,
                    genLabel: null,
                    isLocked: true,
                  );
                }
                return null;
              },
              childCount: otherVillages.length.clamp(0, 3),
            ),
          ),
          SliverToBoxAdapter(child: _ExploreItem()),
        ],

        // Empty state
        if (myVillages.isEmpty)
          const SliverToBoxAdapter(child: _EmptyState()),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  SliverAppBar _buildHeader(BuildContext context) {
    final c = GwColors.of(context);
    final statusBarH = MediaQuery.of(context).padding.top;
    return SliverAppBar(
      backgroundColor: c.inkDeep,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: c.stoneMid, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      pinned: true,
      expandedHeight: 100 + statusBarH,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: c.inkDeep,
          padding: EdgeInsets.fromLTRB(20, statusBarH + 44, 20, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'MES VILLAGES',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.8,
                    color: c.stoneDim,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.push(Routes.villages),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: c.goldFaint,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: c.goldLine),
                  ),
                  child: Center(
                    child: Text('+',
                        style: TextStyle(color: c.gold, fontSize: 18, fontWeight: FontWeight.w300)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: c.line),
      ),
    );
  }

  SliverToBoxAdapter _sectionLabel(BuildContext context, String text) {
    final c = GwColors.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
            color: c.stoneFaint,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Village Item — rail item style
// ─────────────────────────────────────────

class _VillageItem extends ConsumerWidget {
  const _VillageItem({
    required this.village,
    required this.gemColor,
    this.genLabel,
    this.isActive = false,
    this.isLocked = false,
  });

  final VillageModel village;
  final Color gemColor;
  final String? genLabel;
  final bool isActive;
  final bool isLocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = GwColors.of(context);
    return GestureDetector(
      onTap: isLocked ? null : () {
        ref.read(breadcrumbProvider.notifier).push(BreadcrumbEntry(label: village.name, route: Routes.villageDetail(village.id)));
        context.push(Routes.villageDetail(village.id));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? c.goldFaint : Colors.transparent,
          border: Border(
            left: BorderSide(
              width: 2.5,
              color: isActive ? c.gold : Colors.transparent,
            ),
          ),
        ),
        child: Row(
          children: [
            // Gem (diamond shape)
            Transform.rotate(
              angle: 0.785,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: gemColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Name
            Expanded(
              child: Text(
                village.name,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                  color: isLocked
                      ? c.stoneDim
                      : isActive
                          ? c.stone
                          : c.stoneMid,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Generation badge
            if (genLabel != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: c.inkLift,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  genLabel!,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    color: c.stoneFaint,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Count or lock
            if (isLocked)
              const Text('🔒', style: TextStyle(fontSize: 12))
            else
              Text(
                _formatCount(village.memberCount),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10.5,
                  color: c.stoneFaint,
                ),
              ),

            const SizedBox(width: 4),
            if (!isLocked)
              Icon(Icons.chevron_right, size: 16, color: c.stoneFaint),
          ],
        ),
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)} ${n % 1000 > 0 ? (n % 1000).toString().padLeft(3, '0') : '000'}';
    return '$n';
  }
}

// ─────────────────────────────────────────
// Unlock Card — CTA to complete genealogy
// ─────────────────────────────────────────

class _UnlockCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: GestureDetector(
        onTap: () => context.go(Routes.genealogy),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: c.stoneFaint, style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                'Complétez votre arbre\npour débloquer G4+',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w300,
                  color: c.stoneDim,
                  height: 1.65,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '→ GÉNÉALOGIE',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9.5,
                  color: c.goldDim,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Explore Item — "Explorer + de villages"
// ─────────────────────────────────────────

class _ExploreItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return GestureDetector(
      onTap: () => context.push(Routes.villages),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Transform.rotate(
              angle: 0.785,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: c.stoneFaint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'Explorer + de villages',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: c.stoneFaint,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward, size: 14, color: c.stoneFaint),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.goldFaint,
              border: Border.all(color: c.goldLine),
            ),
            child: const Center(
              child: Text('🏘', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Vous n'avez rejoint aucun village",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: c.stone,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Explorez les villages disponibles et\nrejoignez votre communauté',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w300,
              color: c.stoneDim,
              height: 1.7,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => context.push(Routes.villages),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
              decoration: BoxDecoration(
                color: c.gold,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [BoxShadow(color: c.gold.withAlpha(60), blurRadius: 16)],
              ),
              child: Text(
                'Explorer les villages',
                style: TextStyle(
                  color: c.inkDeep,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Rule separator
// ─────────────────────────────────────────

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 1,
      color: c.line,
    );
  }
}
