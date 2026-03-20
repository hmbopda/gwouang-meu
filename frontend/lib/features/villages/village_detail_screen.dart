import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gwangmeu/core/router/breadcrumb_provider.dart';
import 'package:gwangmeu/core/router/route_names.dart';
import 'package:gwangmeu/shared/models/post_model.dart';
import 'package:gwangmeu/shared/models/village_member_model.dart';
import 'package:gwangmeu/shared/models/village_model.dart';
import 'package:gwangmeu/shared/widgets/error_widget.dart';
import 'package:gwangmeu/core/theme/gw_colors.dart';
import 'package:gwangmeu/shared/models/chat_group_model.dart';
import 'package:gwangmeu/shared/models/chat_message_model.dart';
import 'package:gwangmeu/features/chat/chat_notifier.dart';
import 'package:gwangmeu/features/villages/villages_notifier.dart';

// ═══════════════════════════════════════════════════════
// ÉCRAN DÉTAIL VILLAGE — responsive 3 colonnes
// ═══════════════════════════════════════════════════════

class VillageDetailScreen extends ConsumerWidget {
  const VillageDetailScreen({super.key, required this.villageId});
  final String villageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = GwColors.of(context);
    final villageAsync = ref.watch(villageDetailProvider(villageId));

    return villageAsync.when(
      loading: () => Scaffold(
        backgroundColor: c.inkDeep,
        body: Center(child: CircularProgressIndicator(color: c.gold)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: c.inkDeep,
        appBar: AppBar(backgroundColor: c.inkDeep),
        body: const GwangErrorWidget(message: 'Village introuvable'),
      ),
      data: (village) => _ResponsiveShell(village: village),
    );
  }
}

// ═══════════════════════════════════════════════════════
// RESPONSIVE SHELL — desktop 3 colonnes / mobile single
// ═══════════════════════════════════════════════════════

class _ResponsiveShell extends ConsumerWidget {
  const _ResponsiveShell({required this.village});
  final VillageModel village;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = GwColors.of(context);
    return Scaffold(
      backgroundColor: c.inkDeep,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final cc = GwColors.of(context);
          final isDesktop = constraints.maxWidth >= 1100;
          final isTablet = constraints.maxWidth >= 800 && constraints.maxWidth < 1100;

          if (isDesktop) {
            return Row(
              children: [
                // ── Left Panel (240px) ──
                SizedBox(
                  width: 240,
                  child: _LeftPanel(selectedVillageId: village.id),
                ),
                Container(width: 1, color: cc.line),
                // ── Center Panel (flex) ──
                Expanded(child: _CenterPanel(village: village)),
                Container(width: 1, color: cc.line),
                // ── Right Panel (340px) ──
                SizedBox(
                  width: 340,
                  child: _RightPanel(village: village),
                ),
              ],
            );
          }

          if (isTablet) {
            return Row(
              children: [
                // ── Center Panel (flex) ──
                Expanded(child: _CenterPanel(village: village)),
                Container(width: 1, color: cc.line),
                // ── Right Panel (320px) ──
                SizedBox(
                  width: 320,
                  child: _RightPanel(village: village),
                ),
              ],
            );
          }

          // ── Mobile : single column ──
          return _CenterPanel(village: village, includeRightPanel: true);
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// LEFT PANEL — Liste des villages
// ═══════════════════════════════════════════════════════

class _LeftPanel extends ConsumerWidget {
  const _LeftPanel({required this.selectedVillageId});
  final String selectedVillageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = GwColors.of(context);
    final gemColors = [c.gold, c.sage, c.azure, c.ember, c.goldLight];
    final myVillagesAsync = ref.watch(myVillagesNotifierProvider);
    final allVillagesAsync = ref.watch(villagesNotifierProvider);

    return Container(
      color: c.inkDeep,
      child: Column(
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'MES VILLAGES',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 1.8, color: c.stoneDim),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push(Routes.villages),
                  child: Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(color: c.sageBg, borderRadius: BorderRadius.circular(13), border: Border.all(color: c.sageLine)),
                    child: Center(child: Text('+', style: TextStyle(color: c.sage, fontSize: 16, fontWeight: FontWeight.w300))),
                  ),
                ),
              ],
            ),
          ),

          // ── Content ──
          Expanded(
            child: myVillagesAsync.when(
              loading: () => Center(child: CircularProgressIndicator(strokeWidth: 1.5, color: c.gold)),
              error: (_, __) => Center(child: Text('Erreur', style: TextStyle(color: c.stoneDim, fontSize: 12))),
              data: (myVillages) {
                final allVillages = allVillagesAsync.valueOrNull ?? [];
                final myIds = myVillages.map((v) => v.id).toSet();
                final otherVillages = allVillages.where((v) => !myIds.contains(v.id)).toList();

                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // ── ACCÈS CONFIRMÉ ──
                    _sectionLabel(context, 'Accès confirmé'),
                    ...myVillages.asMap().entries.map((e) => _LeftVillageItem(
                      village: e.value,
                      gemColor: gemColors[e.key % gemColors.length],
                      genLabel: 'G${e.key + 1}',
                      isSelected: e.value.id == selectedVillageId,
                      onTap: () {
                        // Update breadcrumb to reflect new village
                        final crumbs = ref.read(breadcrumbProvider);
                        if (crumbs.isNotEmpty) {
                          ref.read(breadcrumbProvider.notifier).popTo(crumbs[crumbs.length > 1 ? crumbs.length - 2 : 0].route);
                        }
                        ref.read(breadcrumbProvider.notifier).push(BreadcrumbEntry(label: e.value.name, route: Routes.villageDetail(e.value.id)));
                        context.go(Routes.villageDetail(e.value.id));
                      },
                    )),

                    // ── ACCÈS EN ATTENTE ──
                    if (otherVillages.length >= 2) ...[
                      const _PanelRule(),
                      _sectionLabel(context, 'Accès en attente'),
                      ...otherVillages.take(2).map((v) => _LeftVillageItem(
                        village: v, gemColor: c.stoneFaint, isLocked: true,
                      )),
                    ],

                    // ── À DÉBLOQUER ──
                    const _PanelRule(),
                    _sectionLabel(context, 'À débloquer'),
                    _buildUnlockCard(context),

                    // ── AUTRES ──
                    const _PanelRule(),
                    _sectionLabel(context, 'Autres'),
                    _buildExploreItem(context),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    final c = GwColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(text.toUpperCase(), style: TextStyle(fontFamily: 'monospace', fontSize: 9, fontWeight: FontWeight.w500, letterSpacing: 1.5, color: c.stoneFaint)),
    );
  }

  Widget _buildUnlockCard(BuildContext context) {
    final c = GwColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GestureDetector(
        onTap: () => context.go(Routes.genealogy),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: c.stoneFaint, style: BorderStyle.solid),
          ),
          child: Column(
            children: [
              Text('Complétez votre arbre\npour débloquer G4+', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300, color: c.stoneDim, height: 1.6)),
              const SizedBox(height: 8),
              Text('→ GÉNÉALOGIE', style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: c.goldDim, letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExploreItem(BuildContext context) {
    final c = GwColors.of(context);
    return GestureDetector(
      onTap: () => context.push(Routes.villages),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.explore_outlined, size: 14, color: c.stoneFaint),
            const SizedBox(width: 10),
            Text('Explorer + de villages', style: TextStyle(fontSize: 12.5, color: c.stoneFaint)),
          ],
        ),
      ),
    );
  }
}

class _LeftVillageItem extends StatelessWidget {
  const _LeftVillageItem({
    required this.village,
    required this.gemColor,
    this.genLabel,
    this.isSelected = false,
    this.isLocked = false,
    this.onTap,
  });
  final VillageModel village;
  final Color gemColor;
  final String? genLabel;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? c.goldFaint : Colors.transparent,
          border: Border(left: BorderSide(width: 2.5, color: isSelected ? c.gold : Colors.transparent)),
        ),
        child: Row(
          children: [
            Transform.rotate(
              angle: 0.785,
              child: Container(width: 8, height: 8, decoration: BoxDecoration(color: gemColor, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(village.name,
                style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  color: isLocked ? c.stoneDim : isSelected ? c.stone : c.stoneMid),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            if (genLabel != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: c.inkLift, borderRadius: BorderRadius.circular(3)),
                child: Text(genLabel!, style: TextStyle(fontFamily: 'monospace', fontSize: 8.5, color: c.stoneFaint)),
              ),
              const SizedBox(width: 6),
            ],
            if (isLocked)
              const Text('🔒', style: TextStyle(fontSize: 11))
            else
              Text(_fmtCount(village.memberCount), style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: c.stoneFaint)),
          ],
        ),
      ),
    );
  }

  String _fmtCount(int n) {
    if (n >= 1000) return '${n ~/ 1000} ${(n % 1000).toString().padLeft(3, '0')}';
    return '$n';
  }
}

class _PanelRule extends StatelessWidget {
  const _PanelRule();
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.symmetric(vertical: 6), height: 1, color: GwColors.of(context).line);
}

// ═══════════════════════════════════════════════════════
// CENTER PANEL — Hero + Tabs
// ═══════════════════════════════════════════════════════

class _CenterPanel extends ConsumerStatefulWidget {
  const _CenterPanel({required this.village, this.includeRightPanel = false});
  final VillageModel village;
  final bool includeRightPanel;

  @override
  ConsumerState<_CenterPanel> createState() => _CenterPanelState();
}

class _CenterPanelState extends ConsumerState<_CenterPanel> with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  static const _tabs = ['Aperçu', 'Plan', 'Ligne des chefs', 'Membres', 'Publications', 'Chat'];

  VillageModel get v => widget.village;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return Column(
      children: [
        // ── Hero ──
        _buildHero(context),

        // ── Tab bar ──
        Container(
          color: c.ink,
          child: TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: c.gold,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 1.5,
            labelColor: c.stone,
            unselectedLabelColor: c.stoneDim,
            labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
            unselectedLabelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400),
            dividerColor: c.line,
            labelPadding: const EdgeInsets.symmetric(horizontal: 16),
            tabs: [
              _tabItem(context, 'Aperçu', null),
              _tabItem(context, 'Plan', '267'),
              _tabItem(context, 'Ligne des chefs', '12'),
              _tabItem(context, 'Membres', '${v.memberCount}'),
              _tabItem(context, 'Publications', '89'),
              _tabItem(context, 'Chat', null),
            ],
          ),
        ),

        // ── Tab content ──
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _ApercuTab(village: v, includeRightPanel: widget.includeRightPanel),
              _PlanTab(village: v),
              _ChefsTab(village: v),
              _MembresTab(village: v),
              _PublicationsTab(village: v),
              _ChatTab(village: v),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tabItem(BuildContext context, String label, String? count) {
    final c = GwColors.of(context);
    return Tab(
      height: 44,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: c.inkLift, borderRadius: BorderRadius.circular(3)),
              child: Text(count, style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: c.stoneFaint)),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // HERO
  // ─────────────────────────────────────────

  Widget _buildHero(BuildContext context) {
    final c = GwColors.of(context);
    return Container(
      color: c.inkDeep,
      child: Stack(
        children: [
          // Pattern background
          SizedBox(
            height: 280,
            width: double.infinity,
            child: v.coverImageUrl != null && v.coverImageUrl!.isNotEmpty
                ? Image.network(v.coverImageUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => CustomPaint(painter: _HeroPatternPainter()))
                : CustomPaint(painter: _HeroPatternPainter()),
          ),

          // Gradient overlay
          Container(
            height: 280,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00080709), Color(0x33080709), Color(0xCC080709), Color(0xFF080709)],
                stops: [0.0, 0.3, 0.65, 1.0],
              ),
            ),
          ),

          // Content
          Positioned(
            left: 24, right: 24, bottom: 0, top: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Back button (mobile only — on desktop, shell handles navigation)
                if (MediaQuery.sizeOf(context).width < 800)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: Colors.black.withAlpha(120), borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.arrow_back, color: c.stoneMid, size: 18),
                      ),
                    ),
                  ),

                const Spacer(),

                // Meta row : region + live pill
                Row(
                  children: [
                    Text(
                      [if (v.region != null) 'RÉGION ${v.region!.toUpperCase()}', v.country.toUpperCase()].join(' · '),
                      style: TextStyle(fontFamily: 'monospace', fontSize: 9, letterSpacing: 1.8, color: c.stoneDim),
                    ),
                    const SizedBox(width: 12),
                    _livePill(context),
                  ],
                ),
                const SizedBox(height: 10),

                // Title (large serif italic style)
                RichText(
                  text: TextSpan(
                    children: _buildTitleSpans(context, v.name),
                    style: TextStyle(fontSize: 42, fontWeight: FontWeight.w300, letterSpacing: -1.5, height: 0.95, color: c.stone),
                  ),
                ),
                const SizedBox(height: 10),

                // Subtitle : Clan · members · access
                Row(
                  children: [
                    Text('Clan ${v.primaryDialect ?? v.name}', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400, color: c.stoneMid)),
                    const _SubSep(),
                    Text('${v.memberCount} membres', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w300, color: c.stoneMid)),
                    const _SubSep(),
                    Text('Groupe privé', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400, color: c.gold)),
                  ],
                ),
                const SizedBox(height: 18),

                // Buttons : Rejoindre le Live + Suivre le village
                Row(
                  children: [
                    _heroButton(context, 'Rejoindre le Live', isPrimary: true, onTap: () {}),
                    const SizedBox(width: 10),
                    _heroButton(context, 'Suivre le village', isPrimary: false, onTap: () {}),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _buildTitleSpans(BuildContext context, String name) {
    final c = GwColors.of(context);
    // Simulate italic second half like mockup "Ndog*bassi*"
    if (name.length > 4) {
      final mid = (name.length * 0.45).round();
      return [
        TextSpan(text: name.substring(0, mid)),
        TextSpan(text: name.substring(mid), style: TextStyle(fontStyle: FontStyle.italic, color: c.goldLight)),
      ];
    }
    return [TextSpan(text: name)];
  }

  Widget _heroButton(BuildContext context, String label, {required bool isPrimary, required VoidCallback onTap}) {
    final c = GwColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isPrimary ? c.gold : c.lineMid),
        ),
        child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400, color: isPrimary ? c.gold : c.stoneMid)),
      ),
    );
  }

  Widget _livePill(BuildContext context) {
    final c = GwColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: c.emberBg, borderRadius: BorderRadius.circular(99), border: Border.all(color: c.emberLine)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 5, height: 5, decoration: const BoxDecoration(color: Color(0xFFE87858), shape: BoxShape.circle)),
          const SizedBox(width: 5),
          const Text('Live en cours', style: TextStyle(fontFamily: 'monospace', fontSize: 8.5, color: Color(0xFFE87858), letterSpacing: 0.8)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// RIGHT PANEL — Chef + Filiation + En ligne
// ═══════════════════════════════════════════════════════

class _RightPanel extends StatelessWidget {
  const _RightPanel({required this.village});
  final VillageModel village;

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return Container(
      color: c.inkDeep,
      child: Column(
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
            child: Row(
              children: [
                Text(village.name.toUpperCase(), style: TextStyle(fontFamily: 'monospace', fontSize: 10, letterSpacing: 1.2, color: c.stoneMid)),
                const Spacer(),
                Container(width: 6, height: 6, decoration: BoxDecoration(color: c.sage, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('ACTIF', style: TextStyle(fontFamily: 'monospace', fontSize: 9, letterSpacing: 1, color: c.sage)),
              ],
            ),
          ),

          // ── Scrollable content ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(0),
              children: [
                // CHEF ACTUEL
                _rightSectionLabel(context, 'Chef actuel · Administrateur'),
                _ChefCard(village: village),

                // FILIATION
                _rightSectionLabel(context, 'Votre lien de filiation'),
                const _FiliationTree(),

                // EN LIGNE MAINTENANT
                _rightSectionLabel(context, 'En ligne maintenant'),
                const _OnlineMembers(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rightSectionLabel(BuildContext context, String text) {
    final c = GwColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Text(text.toUpperCase(), style: TextStyle(fontFamily: 'monospace', fontSize: 8.5, letterSpacing: 1.2, color: c.stoneFaint)),
    );
  }
}

// ═══════════════════════════════════════════════════════
// ONGLET 1 — APERÇU
// ═══════════════════════════════════════════════════════

class _ApercuTab extends ConsumerWidget {
  const _ApercuTab({required this.village, this.includeRightPanel = false});
  final VillageModel village;
  final bool includeRightPanel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = GwColors.of(context);
    final membersAsync = ref.watch(villageMembersProvider(village.id));

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Stats row
        _StatsRow(village: village),

        // Plan du village
        _Section(
          title: 'Plan du village',
          badge: 'Temps réel',
          trailing: GestureDetector(
            onTap: () {},
            child: Text('PLEIN ÉCRAN →', style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: c.goldDim, letterSpacing: 0.6)),
          ),
          child: const _MapPlaceholder(),
        ),

        // Ligne dynastique
        _Section(
          title: 'Ligne dynastique',
          badge: village.foundedYear != null ? '${village.foundedYear} – aujourd\'hui' : null,
          trailing: Text('Voir tout →', style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: c.goldDim, letterSpacing: 0.6)),
          child: const _DynastyTimeline(),
        ),

        // Votre lignée
        _Section(
          title: 'Votre lignée dans ce village',
          trailing: Text('Tous les membres →', style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: c.goldDim, letterSpacing: 0.6)),
          child: membersAsync.when(
            loading: () => SizedBox(height: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 1.5, color: c.gold))),
            error: (_, __) => Text('Impossible de charger', style: TextStyle(color: c.stoneDim, fontSize: 12)),
            data: (members) => _MembersGrid(members: members.take(4).toList()),
          ),
        ),

        // Description
        if (village.description != null)
          _Section(
            title: 'À propos',
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(village.description!, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w300, color: c.stoneMid, height: 1.8)),
            ),
          ),

        // ── Right panel content (mobile only) ──
        if (includeRightPanel) ...[
          Container(height: 1, color: c.line),
          _Section(title: 'Chef actuel · Administrateur', isMonoTitle: true, child: _ChefCard(village: village)),
          const _Section(title: 'Votre lien de filiation', isMonoTitle: true, child: _FiliationTree()),
          const _Section(title: 'En ligne maintenant', isMonoTitle: true, child: _OnlineMembers()),
          _Section(title: 'Activité récente', isMonoTitle: true, child: _ActivityLog(villageName: village.name)),
        ],

        const SizedBox(height: 40),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// ONGLET 2 — PLAN
// ═══════════════════════════════════════════════════════

class _PlanTab extends StatelessWidget {
  const _PlanTab({required this.village});
  final VillageModel village;

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(color: c.ink, border: Border(bottom: BorderSide(color: c.line))),
          child: Row(
            children: [
              Text('PLAN INTERACTIF', style: TextStyle(fontFamily: 'monospace', fontSize: 9, letterSpacing: 1.2, color: c.stoneDim)),
              const SizedBox(width: 10),
              Text('● Synchronisé', style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: c.sage)),
              const Spacer(),
              const _PlanBtn(label: '+ Concession', isPrimary: false),
              const SizedBox(width: 8),
              const _PlanBtn(label: 'Satellite', isPrimary: true),
            ],
          ),
        ),
        const SizedBox(height: 480, child: _MapPlaceholder(fullScreen: true)),
      ],
    );
  }
}

class _PlanBtn extends StatelessWidget {
  const _PlanBtn({required this.label, required this.isPrimary});
  final String label;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: isPrimary ? c.goldFaint : c.inkLift, borderRadius: BorderRadius.circular(6), border: Border.all(color: isPrimary ? c.goldLine : c.line)),
      child: Text(label, style: TextStyle(fontSize: 11, color: isPrimary ? c.gold : c.stoneMid)),
    );
  }
}

// ═══════════════════════════════════════════════════════
// ONGLET 3 — LIGNE DES CHEFS
// ═══════════════════════════════════════════════════════

class _ChefsTab extends StatelessWidget {
  const _ChefsTab({required this.village});
  final VillageModel village;

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Ligne dynastique complète', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, letterSpacing: -0.8, color: c.stone)),
        const SizedBox(height: 8),
        Text(
          village.foundedYear != null
              ? 'Archives depuis ${village.foundedYear}. Récits de chaque règne disponibles.'
              : 'Archives historiques du village.',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w300, color: c.stoneDim, height: 1.9),
        ),
        const SizedBox(height: 28),
        const _DynastyTimeline(extended: true),
        const SizedBox(height: 40),
        if (village.historicalSummary != null)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: c.inkLift, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.line)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RÉSUMÉ HISTORIQUE', style: TextStyle(fontFamily: 'monospace', fontSize: 8.5, letterSpacing: 1.2, color: c.stoneFaint)),
                const SizedBox(height: 12),
                Text(village.historicalSummary!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w300, color: c.stoneMid, height: 1.9)),
              ],
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// ONGLET 4 — MEMBRES
// ═══════════════════════════════════════════════════════

class _MembresTab extends ConsumerWidget {
  const _MembresTab({required this.village});
  final VillageModel village;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = GwColors.of(context);
    final membersAsync = ref.watch(villageMembersProvider(village.id));

    return membersAsync.when(
      loading: () => Center(child: CircularProgressIndicator(strokeWidth: 1.5, color: c.gold)),
      error: (e, _) => Center(child: Text('Impossible de charger', style: TextStyle(color: c.stoneDim, fontSize: 13))),
      data: (members) {
        if (members.isEmpty) return Center(child: Text('Aucun membre', style: TextStyle(color: c.stoneDim, fontSize: 13)));
        return GridView.builder(
          padding: const EdgeInsets.all(1),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.78, mainAxisSpacing: 1, crossAxisSpacing: 1),
          itemCount: members.length,
          itemBuilder: (_, i) => _MemberCell(member: members[i], index: i),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════
// ONGLET 5 — PUBLICATIONS
// ═══════════════════════════════════════════════════════

class _PublicationsTab extends ConsumerStatefulWidget {
  const _PublicationsTab({required this.village});
  final VillageModel village;

  @override
  ConsumerState<_PublicationsTab> createState() => _PublicationsTabState();
}

class _PublicationsTabState extends ConsumerState<_PublicationsTab> {
  final _composeCtrl = TextEditingController();
  bool _posting = false;
  String _filter = 'all';

  @override
  void dispose() {
    _composeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    final text = _composeCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _posting = true);
    try {
      await ref.read(villageFeedNotifierProvider(widget.village.id).notifier).createPost(text);
      _composeCtrl.clear();
      if (mounted) {
        final c = GwColors.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Publication envoyée'), backgroundColor: c.sage,
              behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        );
      }
    } catch (_) {
      if (mounted) {
        final c = GwColors.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Erreur'), backgroundColor: c.ember,
              behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        );
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    final feedAsync = ref.watch(villageFeedNotifierProvider(widget.village.id));

    return Column(
      children: [
        // Filter bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: c.ink, border: Border(bottom: BorderSide(color: c.line))),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterBtn(label: 'Tout', active: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                      _FilterBtn(label: 'Publications', active: _filter == 'post', onTap: () => setState(() => _filter = 'post')),
                      _FilterBtn(label: 'Lives', active: _filter == 'live', onTap: () => setState(() => _filter = 'live'), hasLiveDot: true),
                      _FilterBtn(label: 'Conférences', active: _filter == 'conf', onTap: () => setState(() => _filter = 'conf')),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showComposeSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(color: c.goldFaint, borderRadius: BorderRadius.circular(6), border: Border.all(color: c.goldLine)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [Icon(Icons.add, size: 13, color: c.gold), const SizedBox(width: 5), Text('Publier', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: c.gold))],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Feed
        Expanded(
          child: feedAsync.when(
            loading: () => Center(child: CircularProgressIndicator(strokeWidth: 1.5, color: c.gold)),
            error: (_, __) => Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.wifi_off, size: 36, color: c.stoneFaint),
                const SizedBox(height: 8),
                Text('Erreur de chargement', style: TextStyle(color: c.stoneDim, fontSize: 12)),
                TextButton(onPressed: () => ref.read(villageFeedNotifierProvider(widget.village.id).notifier).refresh(), child: Text('Réessayer', style: TextStyle(color: c.gold))),
              ]),
            ),
            data: (posts) => RefreshIndicator(
              color: c.gold, backgroundColor: c.inkRaise,
              onRefresh: () => ref.read(villageFeedNotifierProvider(widget.village.id).notifier).refresh(),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const _LiveBanner(),
                  if (posts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Column(children: [
                        Icon(Icons.article_outlined, size: 36, color: c.stoneFaint),
                        const SizedBox(height: 8),
                        Text('Aucune publication\nSoyez le premier à publier !', textAlign: TextAlign.center, style: TextStyle(color: c.stoneDim, fontSize: 12, height: 1.6)),
                      ])),
                    ),
                  ...posts.map((post) => _PostCard(post: post, villageId: widget.village.id)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showComposeSheet(BuildContext context) {
    final c = GwColors.of(context);
    showModalBottomSheet(
      context: context, backgroundColor: c.ink,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) {
        final sc = GwColors.of(sheetContext);
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: _composeCtrl, autofocus: true, maxLines: 4, minLines: 2,
              style: TextStyle(color: sc.stone, fontSize: 14),
              decoration: InputDecoration(hintText: 'Écrire une publication...', hintStyle: TextStyle(color: sc.stoneFaint),
                filled: true, fillColor: sc.inkLift, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _posting ? null : () { _submitPost(); Navigator.pop(context); },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: sc.gold, borderRadius: BorderRadius.circular(6)),
                  child: Center(
                    child: _posting
                      ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: sc.inkDeep))
                      : Text('Publier', style: TextStyle(color: sc.inkDeep, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }

}

// ═══════════════════════════════════════════════════════
// ONGLET CHAT — groupes + messages inline
// ═══════════════════════════════════════════════════════

class _ChatTab extends ConsumerStatefulWidget {
  const _ChatTab({required this.village});
  final VillageModel village;

  @override
  ConsumerState<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends ConsumerState<_ChatTab> {
  ChatGroupModel? _selectedGroup;

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    final groupsAsync = ref.watch(chatGroupsProvider(widget.village.id));
    final width = MediaQuery.of(context).size.width;
    final isSplit = width >= 700; // desktop/tablet : 2 colonnes

    return groupsAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: c.gold)),
      error: (e, _) => Center(
        child: Text('Erreur de chargement du chat', style: TextStyle(color: c.stoneDim)),
      ),
      data: (groups) {
        if (isSplit) {
          return Row(
            children: [
              // Colonne gauche — liste des groupes
              SizedBox(
                width: 260,
                child: _GroupList(
                  village: widget.village,
                  groups: groups,
                  selectedId: _selectedGroup?.id,
                  onSelect: (g) => setState(() => _selectedGroup = g),
                ),
              ),
              VerticalDivider(width: 1, color: c.line),
              // Colonne droite — messages
              Expanded(
                child: _selectedGroup == null
                    ? _noGroupSelected(context, c, groups)
                    : _InlineMessages(group: _selectedGroup!),
              ),
            ],
          );
        }

        // Mobile — vue unique : si groupe sélectionné → messages, sinon liste
        if (_selectedGroup != null) {
          return Column(
            children: [
              // Barre retour
              Container(
                color: c.ink,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: c.stone, size: 20),
                      onPressed: () => setState(() => _selectedGroup = null),
                    ),
                    Text(
                      _selectedGroup!.name,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.stone),
                    ),
                  ],
                ),
              ),
              Expanded(child: _InlineMessages(group: _selectedGroup!)),
            ],
          );
        }
        return _GroupList(
          village: widget.village,
          groups: groups,
          selectedId: null,
          onSelect: (g) => setState(() => _selectedGroup = g),
        );
      },
    );
  }

  Widget _noGroupSelected(BuildContext context, GwColors c, List<ChatGroupModel> groups) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.forum_outlined, size: 48, color: c.stoneFaint),
          const SizedBox(height: 12),
          Text(
            groups.isEmpty ? 'Aucun groupe de discussion' : 'Sélectionnez un groupe',
            style: TextStyle(color: c.stoneDim, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ── Liste des groupes ────────────────────────────────────

class _GroupList extends ConsumerWidget {
  const _GroupList({
    required this.village,
    required this.groups,
    required this.selectedId,
    required this.onSelect,
  });
  final VillageModel village;
  final List<ChatGroupModel> groups;
  final String? selectedId;
  final ValueChanged<ChatGroupModel> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = GwColors.of(context);
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Header groupe
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
          child: Row(
            children: [
              Icon(Icons.forum_outlined, color: c.gold, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Groupes',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: c.stoneDim, letterSpacing: 0.5),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add, size: 18, color: c.goldDim),
                tooltip: 'Créer un groupe',
                onPressed: () => _showCreateDialog(context, ref),
              ),
            ],
          ),
        ),
        // Liste
        Expanded(
          child: groups.isEmpty
              ? _emptyGroups(context, ref, c)
              : ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, i) {
                    final g = groups[i];
                    final isSelected = g.id == selectedId;
                    final isCommission = g.type == 'COMMISSION';
                    return GestureDetector(
                      onTap: () => onSelect(g),
                      child: Container(
                        color: isSelected ? c.goldFaint : Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: (isCommission ? cs.tertiary : c.gold).withAlpha(20),
                                borderRadius: BorderRadius.circular(10),
                                border: isSelected ? Border.all(color: c.goldLine) : null,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                isCommission ? Icons.groups_outlined : Icons.chat_bubble_outline,
                                size: 18,
                                color: isSelected ? c.gold : (isCommission ? cs.tertiary : c.stoneDim),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    g.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      color: isSelected ? c.gold : c.stone,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${g.memberCount} membre${g.memberCount > 1 ? 's' : ''}',
                                    style: TextStyle(fontSize: 11, color: c.stoneFaint),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.chevron_right, size: 16, color: c.goldDim),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _emptyGroups(BuildContext context, WidgetRef ref, GwColors c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 36, color: c.stoneFaint),
            const SizedBox(height: 10),
            Text('Aucun groupe', style: TextStyle(color: c.stoneDim, fontSize: 13)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showCreateDialog(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: c.goldFaint,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.goldLine),
                ),
                child: Text('+ Créer un groupe', style: TextStyle(fontSize: 12, color: c.gold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String type = 'GENERAL';
    final accent = Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Nouveau groupe'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nom du groupe *', isDense: true),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description', isDense: true),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Type : ', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Général'),
                    selected: type == 'GENERAL',
                    onSelected: (_) => setD(() => type = 'GENERAL'),
                    selectedColor: accent.withAlpha(40),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Commission'),
                    selected: type == 'COMMISSION',
                    onSelected: (_) => setD(() => type = 'COMMISSION'),
                    selectedColor: accent.withAlpha(40),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().length < 2) return;
                Navigator.pop(ctx);
                try {
                  await ref.read(createChatGroupProvider.notifier).create(
                    villageId: village.id,
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                    type: type,
                  );
                } catch (_) {}
              },
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.black,
              ),
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Messages inline ──────────────────────────────────────

class _InlineMessages extends ConsumerStatefulWidget {
  const _InlineMessages({required this.group});
  final ChatGroupModel group;

  @override
  ConsumerState<_InlineMessages> createState() => _InlineMessagesState();
}

class _InlineMessagesState extends ConsumerState<_InlineMessages> {
  final _msgCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    _msgCtrl.clear();
    try {
      await ref
          .read(chatMessagesNotifierProvider(widget.group.id).notifier)
          .sendMessage(text);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur d\'envoi')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    final cs = Theme.of(context).colorScheme;
    final messagesAsync = ref.watch(chatMessagesNotifierProvider(widget.group.id));

    return Column(
      children: [
        // Header groupe actif
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
          child: Row(
            children: [
              Icon(
                widget.group.type == 'COMMISSION' ? Icons.groups_outlined : Icons.chat_bubble_outline,
                size: 16,
                color: c.gold,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.group.name,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.stone),
                    ),
                    Text(
                      '${widget.group.memberCount} membre${widget.group.memberCount > 1 ? 's' : ''}',
                      style: TextStyle(fontSize: 10, color: c.stoneFaint),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh, size: 16, color: c.stoneDim),
                onPressed: () => ref
                    .read(chatMessagesNotifierProvider(widget.group.id).notifier)
                    .refresh(),
              ),
            ],
          ),
        ),

        // Messages
        Expanded(
          child: messagesAsync.when(
            loading: () => Center(child: CircularProgressIndicator(color: c.gold)),
            error: (e, _) => Center(
              child: Text('Erreur', style: TextStyle(color: c.stoneDim)),
            ),
            data: (messages) => messages.isEmpty
                ? Center(
                    child: Text(
                      'Aucun message\nSoyez le premier à écrire !',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.stoneFaint, fontSize: 13, height: 1.6),
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (_, i) => _InlineBubble(message: messages[i]),
                  ),
          ),
        ),

        // Champ de saisie
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(top: BorderSide(color: c.line)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  maxLines: 3,
                  minLines: 1,
                  style: TextStyle(fontSize: 13, color: c.stone),
                  decoration: InputDecoration(
                    hintText: 'Écrire un message...',
                    hintStyle: TextStyle(color: c.stoneFaint),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: c.inkRaise,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sending ? null : _send,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _sending ? c.goldDim : c.gold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _sending
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: c.ink),
                        )
                      : Icon(Icons.send, color: c.ink, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Bulle de message inline ──────────────────────────────

class _InlineBubble extends StatelessWidget {
  const _InlineBubble({required this.message});
  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    final cs = Theme.of(context).colorScheme;

    if (message.type == 'SYSTEM') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Text(
            message.content,
            style: TextStyle(fontSize: 11, color: c.stoneFaint, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    final time = message.createdAt != null
        ? '${message.createdAt!.hour.toString().padLeft(2, '0')}:${message.createdAt!.minute.toString().padLeft(2, '0')}'
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: c.goldFaint,
              shape: BoxShape.circle,
              border: Border.all(color: c.goldLine),
            ),
            alignment: Alignment.center,
            child: Text(
              (message.senderName?.isNotEmpty == true)
                  ? message.senderName![0].toUpperCase()
                  : '?',
              style: TextStyle(color: c.gold, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      message.senderName ?? 'Inconnu',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.stone),
                    ),
                    const SizedBox(width: 6),
                    Text(time, style: TextStyle(fontSize: 10, color: c.stoneFaint)),
                  ],
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(fontSize: 13, color: c.stone, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// WIDGETS RÉUTILISABLES
// ═══════════════════════════════════════════════════════

// ── Stats Row ──

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.village});
  final VillageModel village;

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
      child: Row(
        children: [
          _stat(context, '${village.memberCount}', 'MEMBRES', isGold: true),
          _stat(context, '124', 'CONCESSIONS'),
          _stat(context, '58', 'FAMILLES'),
          _stat(context, '2', 'PAYS REPRÉSENTÉS'),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label, {bool isGold = false}) {
    final c = GwColors.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(border: Border(right: BorderSide(color: c.line))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, val, child) => Opacity(opacity: val, child: child),
              child: Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, letterSpacing: -0.8, height: 1, color: isGold ? c.goldLight : c.stone)),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontFamily: 'monospace', fontSize: 8, letterSpacing: 1.0, color: c.stoneFaint)),
          ],
        ),
      ),
    );
  }
}

// ── Section wrapper ──

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.badge, this.trailing, this.isMonoTitle = false});
  final String title;
  final Widget child;
  final String? badge;
  final Widget? trailing;
  final bool isMonoTitle;

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                Expanded(
                  child: isMonoTitle
                    ? Text(title.toUpperCase(), style: TextStyle(fontFamily: 'monospace', fontSize: 8.5, letterSpacing: 1.2, color: c.stoneFaint))
                    : Row(children: [
                        Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400, letterSpacing: -0.5, color: c.stone)),
                        if (badge != null) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(border: Border.all(color: c.line), borderRadius: BorderRadius.circular(3)),
                            child: Text(badge!.toUpperCase(), style: TextStyle(fontFamily: 'monospace', fontSize: 8, letterSpacing: 0.8, color: c.stoneFaint)),
                          ),
                        ],
                      ]),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

// ── Map placeholder ──

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({this.fullScreen = false});
  final bool fullScreen;

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return Container(
      height: fullScreen ? double.infinity : 300,
      constraints: fullScreen ? null : const BoxConstraints(maxHeight: 300),
      color: c.inkDeep,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _MapPatternPainter())),
          // Legend
          Positioned(
            top: 14, left: 14,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: c.inkDeep.withValues(alpha: 0.87), borderRadius: BorderRadius.circular(10), border: Border.all(color: c.lineMid)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LegendRow(color: c.gold, label: 'Concession familiale', isGem: true),
                  const SizedBox(height: 6),
                  _LegendRow(color: c.goldLight, label: 'Votre lignée', isGem: true),
                  const SizedBox(height: 6),
                  _LegendRow(color: c.ember, label: 'Palais du chef'),
                  const SizedBox(height: 6),
                  _LegendRow(color: c.sage, label: 'Zone sacrée'),
                  const SizedBox(height: 6),
                  _LegendRow(color: c.azure, label: 'Place publique'),
                ],
              ),
            ),
          ),
          // Controls
          const Positioned(
            bottom: 14, right: 14,
            child: Column(children: [_MapCtrlBtn('+'), SizedBox(height: 4), _MapCtrlBtn('−'), SizedBox(height: 4), _MapCtrlBtn('⊙')]),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label, this.isGem = false});
  final Color color;
  final String label;
  final bool isGem;

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isGem)
          Transform.rotate(angle: 0.785, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))))
        else
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 9),
        Text(label, style: TextStyle(fontSize: 11, color: c.stoneDim)),
      ],
    );
  }
}

class _MapCtrlBtn extends StatelessWidget {
  const _MapCtrlBtn(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(color: c.inkDeep.withValues(alpha: 0.87), borderRadius: BorderRadius.circular(6), border: Border.all(color: c.lineMid)),
      child: Center(child: Text(label, style: TextStyle(fontSize: 16, color: c.stoneMid))),
    );
  }
}

// ── Dynasty Timeline ──

class _DynastyTimeline extends StatelessWidget {
  const _DynastyTimeline({this.extended = false});
  final bool extended;

  static const _chiefs = [
    _ChiefData('BA', 'Bassa I', '1847–1882', _ChiefType.past),
    _ChiefData('NJ', 'Njoh II', '1882–1911', _ChiefType.past),
    _ChiefData('LK', 'Likoko III', '1911–1946', _ChiefType.past),
    _ChiefData('MB', 'Mbopda IV', '1946–1970', _ChiefType.ancestor),
    _ChiefData('NK', 'Njock V', '1970–1993', _ChiefType.past),
    _ChiefData('NK', 'Nkoulou VI', '1993–2008', _ChiefType.ancestor),
    _ChiefData('ND', 'Ndoumbe II', '2008 — auj.', _ChiefType.current),
  ];

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return SizedBox(
      height: extended ? 140 : 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: _chiefs.length,
        separatorBuilder: (_, __) => Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: Center(child: Text('›', style: TextStyle(fontSize: 14, color: c.stoneFaint)))),
        itemBuilder: (_, i) => _ChiefNode(chief: _chiefs[i]),
      ),
    );
  }
}

enum _ChiefType { past, ancestor, current }

class _ChiefData {
  const _ChiefData(this.initials, this.name, this.years, this.type);
  final String initials, name, years;
  final _ChiefType type;
}

class _ChiefNode extends StatelessWidget {
  const _ChiefNode({required this.chief});
  final _ChiefData chief;

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    final isCurrent = chief.type == _ChiefType.current;
    final isAncestor = chief.type == _ChiefType.ancestor;
    final size = isCurrent ? 54.0 : 44.0;

    Color bgColor, borderColor, textColor;
    if (isCurrent) { bgColor = c.gold.withValues(alpha: 0.15); borderColor = c.gold; textColor = c.goldLight; }
    else if (isAncestor) { bgColor = c.gold.withValues(alpha: 0.08); borderColor = c.goldDim; textColor = c.gold; }
    else { bgColor = c.inkRaise; borderColor = c.stoneFaint; textColor = c.stoneDim; }

    return SizedBox(
      width: 80,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size, height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: bgColor,
                  border: Border.all(color: borderColor, width: isCurrent ? 1.5 : 1),
                  boxShadow: isCurrent ? [BoxShadow(color: c.gold.withAlpha(30), blurRadius: 16)] : null,
                ),
                child: Center(child: Text(chief.initials, style: TextStyle(fontSize: isCurrent ? 17 : 14, fontWeight: FontWeight.w400, color: textColor))),
              ),
              if (isCurrent)
                const Positioned(top: -14, left: 0, right: 0, child: Center(child: Text('👑', style: TextStyle(fontSize: 14)))),
            ],
          ),
          const SizedBox(height: 6),
          Text(chief.name, style: TextStyle(fontSize: 11, fontWeight: isCurrent ? FontWeight.w500 : FontWeight.w400, color: isCurrent ? c.goldLight : c.stoneDim),
            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(chief.years, style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: c.stoneFaint), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Members Grid (apercu lineage) ──

class _MembersGrid extends StatelessWidget {
  const _MembersGrid({required this.members});
  final List<VillageMemberModel> members;

  static const _roles = ['Père · G3', 'Grand-père · G2', 'Grand-mère · G2', 'Frère · G4'];
  static const _badges = ['Résident', 'Fondateur', 'Résidente', 'Diaspora'];

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    final cellColors = [c.azureBg, c.sageBg, c.emberBg, c.goldFaint];
    final cellBorders = [c.azureLine, c.sageLine, c.emberLine, c.goldLine];
    final cellTexts = [c.azureLight, c.sageLight, c.emberLight, c.gold];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.1, mainAxisSpacing: 1, crossAxisSpacing: 1),
      itemCount: members.length.clamp(0, 4),
      itemBuilder: (_, i) {
        final m = members[i];
        final ci = i % cellColors.length;
        return Container(
          color: c.ink,
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22, backgroundColor: cellColors[ci],
                backgroundImage: m.avatarUrl != null ? NetworkImage(m.avatarUrl!) : null,
                child: m.avatarUrl == null ? Text((m.displayName ?? '?')[0].toUpperCase(), style: TextStyle(color: cellTexts[ci], fontWeight: FontWeight.w400, fontSize: 14)) : null,
              ),
              const SizedBox(height: 8),
              Text(m.displayName ?? 'Membre', style: TextStyle(fontSize: 12, color: c.stoneMid), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(i < _roles.length ? _roles[i] : m.type, style: TextStyle(fontFamily: 'monospace', fontSize: 9.5, color: c.stoneFaint)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: cellColors[ci], borderRadius: BorderRadius.circular(3), border: Border.all(color: cellBorders[ci])),
                child: Text(i < _badges.length ? _badges[i] : 'Membre', style: TextStyle(fontFamily: 'monospace', fontSize: 8, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: cellTexts[ci])),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Member Cell (full grid) ──

class _MemberCell extends StatelessWidget {
  const _MemberCell({required this.member, required this.index});
  final VillageMemberModel member;
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    final colors = [c.azureBg, c.sageBg, c.goldFaint, c.emberBg];
    final textColors = [c.azureLight, c.sageLight, c.gold, c.emberLight];
    final ci = index % colors.length;
    final roleLabel = switch (member.type) { 'AMBASSADOR' => 'Ambassadeur', 'MEMBER' => 'Membre', _ => 'Abonné' };

    return Container(
      color: c.ink,
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 20, backgroundColor: colors[ci],
            backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
            child: member.avatarUrl == null ? Text((member.displayName ?? '?')[0].toUpperCase(), style: TextStyle(color: textColors[ci], fontSize: 13)) : null,
          ),
          const SizedBox(height: 6),
          Text(member.displayName ?? 'Membre', style: TextStyle(fontSize: 11, color: c.stoneMid), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(roleLabel, style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: c.stoneFaint)),
        ],
      ),
    );
  }
}

// ── Chef Card ──

class _ChefCard extends StatelessWidget {
  const _ChefCard({required this.village});
  final VillageModel village;

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.inkLift,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.goldLine),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0x0FC9A84C), Colors.transparent], stops: [0.0, 0.6]),
        ),
        child: Column(
          children: [
            // Avatar + Info
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 54, height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [c.goldDim, c.gold]),
                        border: Border.all(color: c.goldLine, width: 1.5),
                      ),
                      child: Center(child: Text('ND', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: c.inkDeep))),
                    ),
                    const Positioned(top: -12, left: 0, right: 0, child: Center(child: Text('👑', style: TextStyle(fontSize: 14)))),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ndoumbe Bassa II', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: c.stone)),
                      const SizedBox(height: 2),
                      Text('Chef de village', style: TextStyle(fontSize: 12, color: c.gold, fontWeight: FontWeight.w300)),
                      const SizedBox(height: 2),
                      Text('En fonction depuis 2008', style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: c.stoneFaint)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Online status
            Row(children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: c.sage, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('En ligne maintenant', style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: c.sage)),
            ]),
            const SizedBox(height: 14),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(color: c.inkRaise, borderRadius: BorderRadius.circular(6), border: Border.all(color: c.lineMid)),
                    child: Center(child: Text('Message', style: TextStyle(fontSize: 12, color: c.stoneMid))),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(color: c.goldFaint, borderRadius: BorderRadius.circular(6), border: Border.all(color: c.goldLine)),
                    child: Center(child: Text('Demander\naccès', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: c.gold, height: 1.3))),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filiation Tree ──

class _FiliationTree extends StatelessWidget {
  const _FiliationTree();

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        children: [
          _filNode(context, 'SM', 'Stéphane Mbopda', 'Vous', 'Fondateur', c.goldFaint, c.goldLine, c.gold, isMine: true),
          _indentWrap(context, [
            _filNode(context, 'EM', 'Emmanuel Mbopda', 'Père', 'Résident', c.azureBg, c.azureLine, c.azureLight, isMine: true),
            const SizedBox(height: 6),
            Opacity(
              opacity: 0.6,
              child: _filNode(context, 'MN', 'Marie Njock', 'Mère', '🔒', c.emberBg, c.emberLine, c.emberLight),
            ),
            const SizedBox(height: 6),
            _indentWrap(context, [
              _filNode(context, 'DM', 'Daniel Mbopda', 'Gd-père', 'Fondateur', c.sageBg, c.sageLine, c.sageLight, isMine: true),
            ]),
          ]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: c.sageBg, borderRadius: BorderRadius.circular(6), border: Border.all(color: c.sageLine)),
            child: Row(children: [
              Icon(Icons.check_circle_outline, size: 14, color: c.sage), const SizedBox(width: 8),
              Text('3 liens confirmés · accès validé', style: TextStyle(fontSize: 11.5, color: c.sage, fontWeight: FontWeight.w300)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _filNode(BuildContext context, String initials, String name, String rel, String tag, Color bg, Color border, Color text, {bool isMine = false}) {
    final c = GwColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: isMine ? c.goldGlow : c.inkLift,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isMine ? c.goldLine : c.line),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 14, backgroundColor: bg, child: Text(initials, style: TextStyle(fontSize: 11, color: text))),
          const SizedBox(width: 9),
          Expanded(child: Text(name, style: TextStyle(fontSize: 12, color: isMine ? c.stone : c.stoneMid))),
          Text(rel, style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: c.stoneFaint)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(3), border: Border.all(color: border)),
            child: Text(tag, style: TextStyle(fontFamily: 'monospace', fontSize: 8, fontWeight: FontWeight.w500, color: text)),
          ),
        ],
      ),
    );
  }

  Widget _indentWrap(BuildContext context, List<Widget> children) {
    final c = GwColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 18, top: 6),
      child: Container(
        decoration: BoxDecoration(border: Border(left: BorderSide(color: c.line))),
        padding: const EdgeInsets.only(left: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ),
    );
  }
}

// ── Online Members ──

class _OnlineMembers extends StatelessWidget {
  const _OnlineMembers();

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        children: [
          _onlineMember(context, 'FK', 'Fanta Koné', 'Foumbot Royal', c.ember, c.emberLight, null),
          const SizedBox(height: 8),
          _onlineMember(context, 'PN', 'Prof. Nkomo', 'Bassa-Likoko', c.sage, c.sageLight, 'LIVE'),
        ],
      ),
    );
  }

  Widget _onlineMember(BuildContext context, String initials, String name, String location, Color dotColor, Color avatarColor, String? badge) {
    final c = GwColors.of(context);
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(radius: 18, backgroundColor: Color.alphaBlend(avatarColor.withAlpha(40), c.inkLift),
              child: Text(initials, style: TextStyle(fontSize: 11, color: avatarColor))),
            Positioned(
              bottom: 0, right: 0,
              child: Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle, border: Border.all(color: c.inkDeep, width: 1.5))),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: TextStyle(fontSize: 12.5, color: c.stoneMid)),
              Text(location, style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: c.stoneFaint)),
            ],
          ),
        ),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: c.emberBg, borderRadius: BorderRadius.circular(3), border: Border.all(color: c.emberLine)),
            child: Text(badge, style: TextStyle(fontFamily: 'monospace', fontSize: 8, fontWeight: FontWeight.w600, color: c.ember)),
          ),
      ],
    );
  }
}

// ── Activity Log ──

class _ActivityLog extends StatelessWidget {
  const _ActivityLog({required this.villageName});
  final String villageName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(children: [
        _logRow(context, 'Kofi A.', 'a ajouté 6 photos à la concession', '2h', isGold: true),
        _logRow(context, 'Chef Ndoumbe', 'Plan mis à jour', '4h'),
        _logRow(context, 'Ama D.', 'a complété l\'arbre de la famille', '6h'),
        _logRow(context, 'Chef Ndoumbe', 'a anobli Ama Diallo', '3j', isGold: true),
      ]),
    );
  }

  Widget _logRow(BuildContext context, String actor, String action, String time, {bool isGold = false}) {
    final c = GwColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 4), decoration: BoxDecoration(color: isGold ? c.goldDim : c.stoneFaint, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(text: TextSpan(style: TextStyle(fontSize: 11.5, height: 1.6, color: c.stoneDim, fontWeight: FontWeight.w300), children: [
              TextSpan(text: actor, style: TextStyle(color: c.stoneMid, fontWeight: FontWeight.w400)),
              TextSpan(text: ' $action'),
            ])),
          ),
          const SizedBox(width: 8),
          Text(time, style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: c.stoneFaint)),
        ],
      ),
    );
  }
}

// ── Live Banner ──

class _LiveBanner extends StatelessWidget {
  const _LiveBanner();

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(colors: [Color(0xFF2A1510), Color(0xFF1A0A08)]),
        border: Border.all(color: c.emberLine),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: c.emberBg, borderRadius: BorderRadius.circular(99), border: Border.all(color: c.emberLine)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 5, height: 5, decoration: const BoxDecoration(color: Color(0xFFE87858), shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      const Text('En direct', style: TextStyle(fontFamily: 'monospace', fontSize: 8.5, color: Color(0xFFE87858))),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Text('Cérémonie des premiers fruits', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: c.stone)),
                  const SizedBox(height: 2),
                  Text('Retransmission officielle', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: c.stoneDim)),
                  const SizedBox(height: 6),
                  Row(children: [Icon(Icons.person_outline, size: 12, color: c.stoneFaint), const SizedBox(width: 4), Text('247', style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: c.stoneFaint))]),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(color: c.ember, borderRadius: BorderRadius.circular(6)),
                child: const Text('Rejoindre', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Post Card ──

class _PostCard extends ConsumerWidget {
  const _PostCard({required this.post, required this.villageId});
  final PostModel post;
  final String villageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = GwColors.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(color: c.ink, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16, backgroundColor: c.goldFaint,
                  backgroundImage: post.authorAvatarUrl != null ? NetworkImage(post.authorAvatarUrl!) : null,
                  child: post.authorAvatarUrl == null ? Text((post.authorDisplayName ?? '?')[0].toUpperCase(), style: TextStyle(color: c.gold, fontSize: 12)) : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(child: Text(post.authorDisplayName ?? 'Utilisateur', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400, color: c.stoneMid), overflow: TextOverflow.ellipsis)),
                        if (post.authorRole != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(color: c.goldFaint, borderRadius: BorderRadius.circular(3)),
                            child: Text(post.authorRole!.toUpperCase(), style: TextStyle(fontFamily: 'monospace', fontSize: 7.5, fontWeight: FontWeight.w500, color: c.goldDim)),
                          ),
                        ],
                      ]),
                      if (post.createdAt != null)
                        Text(_formatDate(post.createdAt!), style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: c.stoneFaint)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 12), child: Text(post.content, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w300, color: c.stoneMid, height: 1.7))),
          // Media
          if (post.mediaUrl != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: ClipRRect(borderRadius: BorderRadius.circular(8),
                child: Image.network(post.mediaUrl!, fit: BoxFit.cover, height: 160, width: double.infinity, errorBuilder: (_, __, ___) => const SizedBox.shrink())),
            ),
          // Actions
          Container(
            decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
            child: Row(children: [
              _actBtn(context, Icons.thumb_up_outlined, post.reactionCount > 0 ? '${post.reactionCount}' : 'J\'aime',
                  () => ref.read(villageFeedNotifierProvider(villageId).notifier).react(post.id, 'LIKE')),
              _actBtn(context, Icons.comment_outlined, post.commentCount > 0 ? '${post.commentCount}' : 'Commenter', () {}),
              _actBtn(context, Icons.favorite_outline, 'Respect',
                  () => ref.read(villageFeedNotifierProvider(villageId).notifier).react(post.id, 'RESPECT')),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _actBtn(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final c = GwColors.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 14, color: c.stoneFaint), const SizedBox(width: 5),
            Text(label, style: TextStyle(color: c.stoneFaint, fontSize: 11, fontWeight: FontWeight.w400)),
          ]),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── Filter Button ──

class _FilterBtn extends StatelessWidget {
  const _FilterBtn({required this.label, required this.active, required this.onTap, this.hasLiveDot = false});
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool hasLiveDot;

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(color: active ? c.inkRaise : Colors.transparent, borderRadius: BorderRadius.circular(99), border: Border.all(color: active ? c.lineMid : Colors.transparent)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (hasLiveDot) ...[Container(width: 6, height: 6, decoration: BoxDecoration(color: c.ember, shape: BoxShape.circle)), const SizedBox(width: 6)],
            Text(label, style: TextStyle(fontSize: 12, color: active ? c.stone : c.stoneDim)),
          ]),
        ),
      ),
    );
  }
}

// ── Subtitle separator ──

class _SubSep extends StatelessWidget {
  const _SubSep();
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('·', style: TextStyle(color: GwColors.of(context).stoneFaint)));
}

// ═══════════════════════════════════════════════════════
// PAINTERS
// ═══════════════════════════════════════════════════════

class _HeroPatternPainter extends CustomPainter {
  static const _d = GwColors.dark;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _d.gold.withAlpha(12)..strokeWidth = 1..style = PaintingStyle.stroke;
    for (double i = -size.height; i < size.width + size.height; i += 32) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
    final circlePaint = Paint()..color = _d.gold.withAlpha(8)..style = PaintingStyle.stroke..strokeWidth = 0.5;
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.4), 120, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.6), 80, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapPatternPainter extends CustomPainter {
  static const _d = GwColors.dark;
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = _d.gold.withAlpha(8)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) { canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint); }
    for (double y = 0; y < size.height; y += 40) { canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint); }

    final dotPaint = Paint()..style = PaintingStyle.fill;
    final concessions = [
      [0.25, 0.3, _d.gold], [0.45, 0.45, _d.goldLight], [0.65, 0.35, _d.gold],
      [0.3, 0.65, _d.sage], [0.5, 0.55, _d.azure], [0.75, 0.6, _d.gold], [0.4, 0.75, _d.ember],
    ];
    for (final c in concessions) {
      dotPaint.color = (c[2] as Color).withAlpha(180);
      canvas.drawCircle(Offset(size.width * (c[0] as double), size.height * (c[1] as double)), 10, dotPaint);
    }

    // Roads
    final roadPaint = Paint()..color = _d.stoneFaint.withAlpha(60)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.4, size.width * 0.6, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.6, size.width * 0.95, size.height * 0.55);
    canvas.drawPath(path, roadPaint);

    // Labels
    final labels = [
      [0.32, 0.28, 'Bassa'], [0.52, 0.43, 'Likoko'], [0.42, 0.58, 'Place publique'], [0.78, 0.58, 'Nkoulou'],
    ];
    for (final l in labels) {
      final tp = TextPainter(
        text: TextSpan(text: l[2] as String, style: TextStyle(fontSize: 10, color: _d.stoneDim.withAlpha(180), fontFamily: 'monospace', fontStyle: FontStyle.italic)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(size.width * (l[0] as double), size.height * (l[1] as double)));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
