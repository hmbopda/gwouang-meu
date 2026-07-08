import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/router/breadcrumb_provider.dart';
import 'package:gwangmeu/core/router/route_names.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/shared/models/village_model.dart';
import 'package:gwangmeu/features/villages/villages_notifier.dart';

// ═══════════════════════════════════════════════
// MES VILLAGES — rail adapté mobile « Tissage » :
// bande tissée, labels mono, gems, badges génération,
// compteurs, verrous Symbols, CTA généalogie.
// ═══════════════════════════════════════════════

class MyVillagesScreen extends ConsumerWidget {
  const MyVillagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = GwTokens.of(context);
    final myVillagesAsync = ref.watch(myVillagesNotifierProvider);
    final allVillagesAsync = ref.watch(villagesNotifierProvider);

    return Scaffold(
      backgroundColor: c.inkDeep,
      body: SafeArea(
        child: Column(
          children: [
            const GwWeaveBand(),
            Expanded(
              child: myVillagesAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: c.goldText),
                ),
                error: (e, _) => _buildError(context, ref),
                data: (myVillages) {
                  // Tous les villages pour la section "Autres"
                  final allVillages = allVillagesAsync.valueOrNull ?? [];
                  final myIds = myVillages.map((v) => v.id).toSet();
                  final otherVillages =
                      allVillages.where((v) => !myIds.contains(v.id)).toList();

                  return _MyVillagesBody(
                    myVillages: myVillages,
                    otherVillages: otherVillages,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref) {
    final c = GwTokens.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Symbols.wifi_off, size: 40, color: c.stoneDim),
          const SizedBox(height: 12),
          Text('Impossible de charger',
              style: GwType.ui(fontSize: 14, color: c.stoneDim)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => ref.invalidate(myVillagesNotifierProvider),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.goldBg,
                borderRadius: BorderRadius.circular(GwTokens.rBtn),
                border: Border.all(color: c.goldLine),
              ),
              child: Text('Réessayer',
                  style: GwType.ui(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.goldText)),
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
    final c = GwTokens.of(context);
    final gemColors = [c.goldText, GwTokens.sage, GwTokens.azure, GwTokens.ember, GwTokens.goldLight];

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
    final c = GwTokens.of(context);
    final statusBarH = MediaQuery.of(context).padding.top;
    return SliverAppBar(
      backgroundColor: c.inkDeep,
      leading: SizedBox(
        width: GwTokens.tapTarget,
        height: GwTokens.tapTarget,
        child: IconButton(
          icon: Icon(Symbols.arrow_back, color: c.stone, size: 22),
          tooltip: 'Retour',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      pinned: true,
      expandedHeight: 100 + statusBarH,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: c.inkDeep,
          padding: EdgeInsets.fromLTRB(20, statusBarH + 44, 12, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'MES VILLAGES',
                  style: GwType.mono(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.8,
                    color: c.stoneDim,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.push(Routes.villages),
                child: Container(
                  width: GwTokens.tapTarget,
                  height: GwTokens.tapTarget,
                  alignment: Alignment.center,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c.goldBg,
                      borderRadius: BorderRadius.circular(GwTokens.rBtn),
                      border: Border.all(color: c.goldLine),
                    ),
                    child: Icon(Symbols.add, size: 18, color: c.goldText),
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
    final c = GwTokens.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        child: Text(
          text.toUpperCase(),
          style: GwType.mono(
            fontSize: 12,
            fontWeight: FontWeight.w500,
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
    final c = GwTokens.of(context);
    return GestureDetector(
      onTap: isLocked ? null : () {
        ref.read(breadcrumbProvider.notifier).push(BreadcrumbEntry(label: village.name, route: Routes.villageDetail(village.id)));
        context.push(Routes.villageDetail(village.id));
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: GwTokens.tapTarget),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? c.goldBg : Colors.transparent,
          border: Border(
            left: BorderSide(
              width: 2.5,
              color: isActive ? c.goldText : Colors.transparent,
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
                style: GwType.ui(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: c.inkLift,
                  borderRadius: BorderRadius.circular(GwTokens.rPill),
                ),
                child: Text(
                  genLabel!,
                  style: GwType.mono(
                    fontSize: 12,
                    letterSpacing: 0.5,
                    color: c.stoneFaint,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Count or lock
            if (isLocked)
              Icon(Symbols.lock, size: 15, color: c.stoneDim)
            else
              Text(
                _formatCount(village.memberCount),
                style: GwType.mono(
                  fontSize: 12,
                  letterSpacing: 0.5,
                  color: c.stoneFaint,
                ),
              ),

            const SizedBox(width: 4),
            if (!isLocked)
              Icon(Symbols.chevron_right, size: 18, color: c.stoneFaint),
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
    final c = GwTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: GestureDetector(
        onTap: () => context.go(Routes.genealogy),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: c.stoneFaint, style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                'Complétez votre arbre\npour débloquer G4+',
                textAlign: TextAlign.center,
                style: GwType.ui(
                  fontSize: 13,
                  color: c.stoneDim,
                  height: 1.65,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Symbols.arrow_forward, size: 14, color: c.goldText),
                  const SizedBox(width: 6),
                  Text(
                    'GÉNÉALOGIE',
                    style: GwType.mono(
                      fontSize: 12,
                      color: c.goldText,
                      letterSpacing: 1,
                    ),
                  ),
                ],
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
    final c = GwTokens.of(context);
    return GestureDetector(
      onTap: () => context.push(Routes.villages),
      child: Container(
        constraints: const BoxConstraints(minHeight: GwTokens.tapTarget),
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
              style: GwType.ui(
                fontSize: 14,
                color: c.stoneFaint,
              ),
            ),
            const Spacer(),
            Icon(Symbols.arrow_forward, size: 16, color: c.stoneFaint),
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
    final c = GwTokens.of(context);
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
              color: c.goldBg,
              border: Border.all(color: c.goldLine),
            ),
            child: Center(
              child: Icon(Symbols.holiday_village, size: 28, color: c.goldText),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Vous n'avez rejoint aucun village",
            style: GwType.display(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: c.stone,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Explorez les villages disponibles et\nrejoignez votre communauté',
            style: GwType.ui(
              fontSize: 13,
              color: c.stoneDim,
              height: 1.7,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => context.push(Routes.villages),
            child: Container(
              constraints: const BoxConstraints(minHeight: GwTokens.tapTarget),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: GwTokens.gold,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: GwTokens.gold.withAlpha(60), blurRadius: 16)],
              ),
              child: Text(
                'Explorer les villages',
                style: GwType.ui(
                  color: const Color(0xFF0C0B0F),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
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
    final c = GwTokens.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 1,
      color: c.line,
    );
  }
}
