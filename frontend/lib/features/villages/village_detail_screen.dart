import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/network/api_client.dart';
import 'package:gwangmeu/core/router/breadcrumb_provider.dart';
import 'package:gwangmeu/core/router/route_names.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/shared/models/post_model.dart';
import 'package:gwangmeu/shared/models/village_member_model.dart';
import 'package:gwangmeu/shared/models/village_model.dart';
import 'package:gwangmeu/shared/models/chat_group_model.dart';
import 'package:gwangmeu/shared/models/chat_message_model.dart';
import 'package:gwangmeu/shared/widgets/error_widget.dart';
import 'package:gwangmeu/features/chat/chat_notifier.dart';
import 'package:gwangmeu/features/profile/profile_notifier.dart';
import 'package:gwangmeu/features/villages/villages_notifier.dart';
import 'package:gwangmeu/features/villages/services/village_governance_service.dart';
import 'package:gwangmeu/features/villages/widgets/village_management_panel.dart';

// ═══════════════════════════════════════════════════════════════
// ÉCRAN DÉTAIL VILLAGE — charte « Tissage » (ivoire/crème, cartes
// blanches liseré, or accent, Fraunces / Syne / JetBrains Mono).
// Desktop : 3 colonnes · Mobile : colonne unique empilée.
// ═══════════════════════════════════════════════════════════════

class VillageDetailScreen extends ConsumerWidget {
  const VillageDetailScreen({super.key, required this.villageId});
  final String villageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final villageAsync = ref.watch(villageDetailProvider(villageId));

    return villageAsync.when(
      loading: () => Scaffold(
        backgroundColor: t.ink,
        body: Center(child: CircularProgressIndicator(color: GwTokens.gold)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: t.ink,
        appBar: AppBar(backgroundColor: t.ink, elevation: 0),
        body: const GwangErrorWidget(message: 'Village introuvable'),
      ),
      data: (village) => _ResponsiveShell(village: village),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// RESPONSIVE SHELL
// ═══════════════════════════════════════════════════════════════

class _ResponsiveShell extends StatelessWidget {
  const _ResponsiveShell({required this.village});
  final VillageModel village;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Scaffold(
      backgroundColor: t.ink,
      body: Column(
        children: [
          const GwWeaveBand(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 1100;
                final isTablet = constraints.maxWidth >= 800 &&
                    constraints.maxWidth < 1100;

                if (isDesktop) {
                  return Row(
                    children: [
                      SizedBox(
                        width: 240,
                        child: _LeftPanel(selectedVillageId: village.id),
                      ),
                      Container(width: 1, color: t.line),
                      Expanded(child: _CenterPanel(village: village)),
                      Container(width: 1, color: t.line),
                      SizedBox(width: 340, child: _RightPanel(village: village)),
                    ],
                  );
                }

                if (isTablet) {
                  return Row(
                    children: [
                      Expanded(child: _CenterPanel(village: village)),
                      Container(width: 1, color: t.line),
                      SizedBox(width: 320, child: _RightPanel(village: village)),
                    ],
                  );
                }

                return _CenterPanel(village: village, includeRightPanel: true);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PANNEAU GAUCHE — « MES VILLAGES »
// ═══════════════════════════════════════════════════════════════

class _LeftPanel extends ConsumerWidget {
  const _LeftPanel({required this.selectedVillageId});
  final String selectedVillageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final gemColors = [
      GwTokens.gold,
      GwTokens.sage,
      GwTokens.azure,
      GwTokens.ember,
      GwTokens.rose,
    ];
    final myVillagesAsync = ref.watch(myVillagesNotifierProvider);
    final allVillagesAsync = ref.watch(villagesNotifierProvider);

    return Container(
      color: t.ink,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 14, 14),
            decoration:
                BoxDecoration(border: Border(bottom: BorderSide(color: t.line))),
            child: Row(
              children: [
                Expanded(
                  child: Text('MES VILLAGES',
                      style: GwType.mono(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.8,
                          color: t.stoneDim)),
                ),
                GestureDetector(
                  onTap: () => context.push(Routes.villages),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: t.goldBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: t.goldLine),
                    ),
                    child: Icon(Icons.add, color: t.goldText, size: 16),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: myVillagesAsync.when(
              loading: () => Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: GwTokens.gold)),
              error: (_, __) => Center(
                  child: Text('Erreur',
                      style: GwType.ui(fontSize: 12, color: t.stoneDim))),
              data: (myVillages) {
                final allVillages = allVillagesAsync.valueOrNull ?? [];
                final myIds = myVillages.map((v) => v.id).toSet();
                final otherVillages =
                    allVillages.where((v) => !myIds.contains(v.id)).toList();

                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _sectionLabel(context, 'Accès confirmé'),
                    ...myVillages.asMap().entries.map((e) => _LeftVillageItem(
                          village: e.value,
                          gemColor: gemColors[e.key % gemColors.length],
                          genLabel: 'G${e.key + 1}',
                          isSelected: e.value.id == selectedVillageId,
                          onTap: () {
                            final crumbs = ref.read(breadcrumbProvider);
                            if (crumbs.isNotEmpty) {
                              ref.read(breadcrumbProvider.notifier).popTo(
                                  crumbs[crumbs.length > 1
                                          ? crumbs.length - 2
                                          : 0]
                                      .route);
                            }
                            ref.read(breadcrumbProvider.notifier).push(
                                BreadcrumbEntry(
                                    label: e.value.name,
                                    route: Routes.villageDetail(e.value.id)));
                            context.go(Routes.villageDetail(e.value.id));
                          },
                        )),
                    if (otherVillages.length >= 2) ...[
                      const _PanelRule(),
                      _sectionLabel(context, 'Autres villages'),
                      ...otherVillages.take(2).map((v) => _LeftVillageItem(
                            village: v,
                            gemColor: t.stoneFaint,
                            isLocked: true,
                          )),
                    ],
                    const _PanelRule(),
                    _sectionLabel(context, 'À débloquer'),
                    _buildUnlockCard(context),
                    const _PanelRule(),
                    _sectionLabel(context, 'Autres'),
                    _buildExploreItem(context),
                    const SizedBox(height: 24),
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
    final t = GwTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(text.toUpperCase(),
          style: GwType.mono(
              fontSize: 10, letterSpacing: 1.6, color: t.stoneFaint)),
    );
  }

  Widget _buildUnlockCard(BuildContext context) {
    final t = GwTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GestureDetector(
        onTap: () => context.go(Routes.genealogy),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: t.inkCard,
            borderRadius: BorderRadius.circular(GwTokens.rBtn),
            border: Border.all(color: t.line),
          ),
          child: Column(
            children: [
              Text('Complétez votre arbre\npour débloquer G4+',
                  textAlign: TextAlign.center,
                  style: GwType.ui(fontSize: 12, color: t.stoneMid, height: 1.6)),
              const SizedBox(height: 8),
              Text('→ GÉNÉALOGIE',
                  style: GwType.mono(
                      fontSize: 10, color: t.goldText, letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExploreItem(BuildContext context) {
    final t = GwTokens.of(context);
    return GestureDetector(
      onTap: () => context.push(Routes.villages),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Icon(Symbols.explore, size: 16, color: t.stoneFaint),
            const SizedBox(width: 10),
            Text('Explorer + de villages',
                style: GwType.ui(fontSize: 13, color: t.stoneMid)),
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
    final t = GwTokens.of(context);
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? t.goldBg : Colors.transparent,
          border: Border(
              left: BorderSide(
                  width: 2.5,
                  color: isSelected ? GwTokens.gold : Colors.transparent)),
        ),
        child: Row(
          children: [
            Transform.rotate(
              angle: 0.785,
              child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: gemColor, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(village.name,
                  style: GwType.ui(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isLocked
                          ? t.stoneDim
                          : isSelected
                              ? t.stone
                              : t.stoneMid),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            if (genLabel != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                    color: t.inkLift, borderRadius: BorderRadius.circular(3)),
                child: Text(genLabel!,
                    style: GwType.mono(
                        fontSize: 9, letterSpacing: 0.5, color: t.stoneFaint)),
              ),
              const SizedBox(width: 6),
            ],
            if (isLocked)
              Icon(Symbols.lock, size: 13, color: t.stoneFaint)
            else
              Text(_fmtCount(village.memberCount),
                  style: GwType.mono(
                      fontSize: 10, letterSpacing: 0.5, color: t.stoneFaint)),
          ],
        ),
      ),
    );
  }

  String _fmtCount(int n) {
    if (n >= 1000) {
      return '${n ~/ 1000} ${(n % 1000).toString().padLeft(3, '0')}';
    }
    return '$n';
  }
}

class _PanelRule extends StatelessWidget {
  const _PanelRule();
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      height: 1,
      color: GwTokens.of(context).line);
}

// ═══════════════════════════════════════════════════════════════
// PANNEAU CENTRE — Hero + onglets
// ═══════════════════════════════════════════════════════════════

class _CenterPanel extends ConsumerStatefulWidget {
  const _CenterPanel({required this.village, this.includeRightPanel = false});
  final VillageModel village;
  final bool includeRightPanel;

  @override
  ConsumerState<_CenterPanel> createState() => _CenterPanelState();
}

class _CenterPanelState extends ConsumerState<_CenterPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  static const _tabs = [
    'Aperçu',
    'Plan',
    'Ligne des chefs',
    'Membres',
    'Publications',
    'Chat'
  ];

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
    final t = GwTokens.of(context);
    return Column(
      children: [
        _buildHero(context),
        Container(
          color: t.ink,
          child: TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: GwTokens.gold,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 2,
            labelColor: t.stone,
            unselectedLabelColor: t.stoneDim,
            labelStyle: GwType.ui(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle:
                GwType.ui(fontSize: 13, fontWeight: FontWeight.w400),
            dividerColor: t.line,
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
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _ApercuTab(
                  village: v, includeRightPanel: widget.includeRightPanel),
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
    final t = GwTokens.of(context);
    return Tab(
      height: 46,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                  color: t.inkLift, borderRadius: BorderRadius.circular(3)),
              child: Text(count,
                  style: GwType.mono(
                      fontSize: 9, letterSpacing: 0.5, color: t.stoneFaint)),
            ),
          ],
        ],
      ),
    );
  }

  // ── HERO ──────────────────────────────────────────────────────

  Widget _buildHero(BuildContext context) {
    final t = GwTokens.of(context);
    final permsAsync = ref.watch(villageMyPermissionsProvider(v.id));
    final canManage = permsAsync.valueOrNull?.let((p) =>
            p.chief || p.superAdmin || p.permissions.isNotEmpty) ??
        false;

    return Container(
      color: t.inkDeep,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (MediaQuery.sizeOf(context).width < 800)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Row(
                  children: [
                    Icon(Symbols.arrow_back, color: t.stoneMid, size: 20),
                    const SizedBox(width: 6),
                    Text('Retour',
                        style: GwType.ui(fontSize: 13, color: t.stoneMid)),
                  ],
                ),
              ),
            ),
          // Méta mono : région · ● LIVE EN COURS
          Row(
            children: [
              Flexible(
                child: Text(
                  [
                    if (v.region != null)
                      'RÉGION ${v.region!.toUpperCase()}'
                    else
                      v.country.toUpperCase(),
                  ].join(' · '),
                  style: GwType.mono(
                      fontSize: 10, letterSpacing: 1.8, color: t.stoneDim),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              _livePill(context),
            ],
          ),
          const SizedBox(height: 12),
          // Nom du village — Fraunces, seconde moitié italique or
          RichText(
            text: TextSpan(
              children: _buildTitleSpans(context, v.name),
              style: GwType.display(
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                  letterSpacing: -0.5,
                  color: t.stone),
            ),
          ),
          const SizedBox(height: 10),
          // Sous-ligne or
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Clan ${v.primaryDialect ?? v.name}',
                  style: GwType.ui(fontSize: 13, color: t.stoneMid)),
              const _SubSep(),
              Text('${v.memberCount} membre${v.memberCount > 1 ? 's' : ''}',
                  style: GwType.ui(fontSize: 13, color: t.stoneMid)),
              const _SubSep(),
              Text('Groupe privé',
                  style: GwType.ui(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: t.goldText)),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _heroButton(context, 'Rejoindre le Live',
                  isPrimary: true, onTap: () {}),
              const SizedBox(width: 10),
              _FollowButton(villageId: v.id),
              if (canManage) ...[
                const SizedBox(width: 10),
                _manageButton(context),
              ],
            ],
          ),
        ],
      ),
    );
  }

  List<TextSpan> _buildTitleSpans(BuildContext context, String name) {
    final t = GwTokens.of(context);
    if (name.length > 4) {
      final mid = (name.length * 0.45).round();
      return [
        TextSpan(text: name.substring(0, mid)),
        TextSpan(
            text: name.substring(mid),
            style: TextStyle(
                fontStyle: FontStyle.italic, color: t.goldText)),
      ];
    }
    return [TextSpan(text: name)];
  }

  Widget _heroButton(BuildContext context, String label,
      {required bool isPrimary, required VoidCallback onTap}) {
    final t = GwTokens.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
        decoration: BoxDecoration(
          color: isPrimary ? GwTokens.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          border: Border.all(color: isPrimary ? GwTokens.gold : t.lineMid),
        ),
        child: Text(label,
            style: GwType.ui(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isPrimary ? GwTokens.inkOnGold : t.stoneMid)),
      ),
    );
  }

  Widget _manageButton(BuildContext context) {
    final t = GwTokens.of(context);
    return GestureDetector(
      onTap: () => showVillageManagement(context, v.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          border: Border.all(color: t.goldLine),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.settings, size: 15, color: t.goldText),
            const SizedBox(width: 6),
            Text('Gérer',
                style: GwType.ui(fontSize: 13, color: t.goldText)),
          ],
        ),
      ),
    );
  }

  Widget _livePill(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
          color: GwTokens.emberBg,
          borderRadius: BorderRadius.circular(GwTokens.rPill),
          border: Border.all(color: GwTokens.emberLine)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                  color: GwTokens.ember, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text('LIVE EN COURS',
              style: GwType.mono(
                  fontSize: 9,
                  letterSpacing: 0.8,
                  color: GwTokens.of(context).emberText)),
        ],
      ),
    );
  }
}

/// Bouton « Suivre le village » — POST /join?type=FOLLOW (best-effort).
class _FollowButton extends ConsumerStatefulWidget {
  const _FollowButton({required this.villageId});
  final String villageId;

  @override
  ConsumerState<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<_FollowButton> {
  bool _following = false;
  bool _busy = false;

  Future<void> _toggle() async {
    if (_busy || _following) return;
    setState(() => _busy = true);
    try {
      // POST /join?type=FOLLOW — abonnement sans adhésion MEMBRE.
      await ref
          .read(apiClientProvider)
          .post('/api/v1/villages/${widget.villageId}/join?type=FOLLOW');
      // Rafraîchir la liste « mes villages » côté panneau gauche.
      ref.invalidate(myVillagesNotifierProvider);
      if (mounted) setState(() => _following = true);
    } catch (_) {
      // best-effort : on ne bloque pas l'UI
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          border: Border.all(color: _following ? GwTokens.sageLine : t.lineMid),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_busy)
              SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: t.stoneMid))
            else
              Icon(_following ? Symbols.check : Symbols.add,
                  size: 15,
                  color: _following ? GwTokens.sage : t.stoneMid),
            const SizedBox(width: 6),
            Text(_following ? 'Village suivi' : 'Suivre le village',
                style: GwType.ui(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _following ? GwTokens.sage : t.stoneMid)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PANNEAU DROIT — Chef + Filiation + En ligne
// ═══════════════════════════════════════════════════════════════

class _RightPanel extends StatelessWidget {
  const _RightPanel({required this.village});
  final VillageModel village;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Container(
      color: t.ink,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            decoration:
                BoxDecoration(border: Border(bottom: BorderSide(color: t.line))),
            child: Row(
              children: [
                Expanded(
                  child: Text(village.name.toUpperCase(),
                      style: GwType.mono(
                          fontSize: 11,
                          letterSpacing: 1.4,
                          color: t.stoneMid),
                      overflow: TextOverflow.ellipsis),
                ),
                Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: GwTokens.sage, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('ACTIF',
                    style: GwType.mono(
                        fontSize: 10,
                        letterSpacing: 1,
                        color: GwTokens.sage)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _rightSectionLabel(context, 'Chef actuel · Administrateur'),
                _ChefCard(village: village),
                _rightSectionLabel(context, 'Votre ligne de filiation'),
                const _FiliationTree(),
                _rightSectionLabel(context, 'En ligne maintenant'),
                _OnlineMembers(village: village),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rightSectionLabel(BuildContext context, String text) {
    final t = GwTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Text(text.toUpperCase(),
          style: GwType.mono(
              fontSize: 10, letterSpacing: 1.4, color: t.stoneFaint)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ONGLET 1 — APERÇU
// ═══════════════════════════════════════════════════════════════

class _ApercuTab extends ConsumerWidget {
  const _ApercuTab({required this.village, this.includeRightPanel = false});
  final VillageModel village;
  final bool includeRightPanel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final membersAsync = ref.watch(villageMembersProvider(village.id));

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _StatsRow(village: village),
        _Section(
          title: 'Plan du village',
          badge: 'Temps réel',
          trailing: GestureDetector(
            onTap: () {},
            child: Text('PLEIN ÉCRAN →',
                style: GwType.mono(
                    fontSize: 10, color: t.goldText, letterSpacing: 0.6)),
          ),
          child: const _MapPlaceholder(),
        ),
        _Section(
          title: 'Ligne dynastique',
          badge: village.foundedYear != null
              ? '${village.foundedYear} – auj.'
              : null,
          trailing: Text('Voir tout →',
              style: GwType.mono(
                  fontSize: 10, color: t.goldText, letterSpacing: 0.6)),
          child: const _DynastyTimeline(),
        ),
        _Section(
          title: 'Votre lignée dans ce village',
          trailing: Text('Tous les membres →',
              style: GwType.mono(
                  fontSize: 10, color: t.goldText, letterSpacing: 0.6)),
          child: membersAsync.when(
            loading: () => SizedBox(
                height: 80,
                child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: GwTokens.gold))),
            error: (_, __) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text('Impossible de charger',
                  style: GwType.ui(color: t.stoneDim, fontSize: 12)),
            ),
            data: (members) => _MembersGrid(members: members.take(4).toList()),
          ),
        ),
        if (village.description != null)
          _Section(
            title: 'À propos',
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(village.description!,
                  style: GwType.ui(
                      fontSize: 13, color: t.stoneMid, height: 1.8)),
            ),
          ),
        if (includeRightPanel) ...[
          Container(height: 1, color: t.line),
          _Section(
              title: 'Chef actuel · Administrateur',
              isMonoTitle: true,
              child: _ChefCard(village: village)),
          const _Section(
              title: 'Votre ligne de filiation',
              isMonoTitle: true,
              child: _FiliationTree()),
          _Section(
              title: 'En ligne maintenant',
              isMonoTitle: true,
              child: _OnlineMembers(village: village)),
          _Section(
              title: 'Activité récente',
              isMonoTitle: true,
              child: _ActivityLog(villageName: village.name)),
        ],
        const SizedBox(height: 40),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ONGLET 2 — PLAN
// ═══════════════════════════════════════════════════════════════

class _PlanTab extends StatelessWidget {
  const _PlanTab({required this.village});
  final VillageModel village;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
              color: t.ink, border: Border(bottom: BorderSide(color: t.line))),
          child: Row(
            children: [
              Text('PLAN INTERACTIF',
                  style: GwType.mono(
                      fontSize: 10, letterSpacing: 1.4, color: t.stoneDim)),
              const SizedBox(width: 10),
              Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: GwTokens.sage, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text('Synchronisé',
                  style: GwType.mono(fontSize: 10, color: GwTokens.sage)),
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
    final t = GwTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: isPrimary ? t.goldBg : t.inkLift,
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          border: Border.all(color: isPrimary ? t.goldLine : t.line)),
      child: Text(label,
          style: GwType.ui(
              fontSize: 12, color: isPrimary ? t.goldText : t.stoneMid)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ONGLET 3 — LIGNE DES CHEFS
// ═══════════════════════════════════════════════════════════════

class _ChefsTab extends StatelessWidget {
  const _ChefsTab({required this.village});
  final VillageModel village;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Ligne dynastique complète',
            style: GwType.display(fontSize: 28, color: t.stone)),
        const SizedBox(height: 8),
        Text(
          village.foundedYear != null
              ? 'Archives depuis ${village.foundedYear}. Récits de chaque règne disponibles.'
              : 'Archives historiques du village.',
          style: GwType.ui(fontSize: 13, color: t.stoneDim, height: 1.9),
        ),
        const SizedBox(height: 28),
        const _DynastyTimeline(extended: true),
        const SizedBox(height: 40),
        if (village.historicalSummary != null)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: t.inkCard,
                borderRadius: BorderRadius.circular(GwTokens.rCard),
                border: Border.all(color: t.line)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RÉSUMÉ HISTORIQUE',
                    style: GwType.mono(
                        fontSize: 10, letterSpacing: 1.4, color: t.stoneFaint)),
                const SizedBox(height: 12),
                Text(village.historicalSummary!,
                    style: GwType.ui(
                        fontSize: 13, color: t.stoneMid, height: 1.9)),
              ],
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ONGLET 4 — MEMBRES
// ═══════════════════════════════════════════════════════════════

class _MembresTab extends ConsumerWidget {
  const _MembresTab({required this.village});
  final VillageModel village;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final membersAsync = ref.watch(villageMembersProvider(village.id));

    return membersAsync.when(
      loading: () => Center(
          child: CircularProgressIndicator(
              strokeWidth: 1.5, color: GwTokens.gold)),
      error: (e, _) => Center(
          child: Text('Impossible de charger',
              style: GwType.ui(color: t.stoneDim, fontSize: 13))),
      data: (members) {
        if (members.isEmpty) {
          return Center(
              child: Text('Aucun membre',
                  style: GwType.ui(color: t.stoneDim, fontSize: 13)));
        }
        return Container(
          color: t.line,
          child: GridView.builder(
            padding: const EdgeInsets.all(1),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.78,
                mainAxisSpacing: 1,
                crossAxisSpacing: 1),
            itemCount: members.length,
            itemBuilder: (_, i) => _MemberCell(member: members[i], index: i),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ONGLET 5 — PUBLICATIONS
// ═══════════════════════════════════════════════════════════════

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
      await ref
          .read(villageFeedNotifierProvider(widget.village.id).notifier)
          .createPost(text);
      _composeCtrl.clear();
      if (mounted) {
        _toast('Publication envoyée', GwTokens.sage);
      }
    } catch (_) {
      if (mounted) {
        _toast('Erreur', GwTokens.ember);
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  void _toast(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GwType.ui(
                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GwTokens.rPill)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final feedAsync = ref.watch(villageFeedNotifierProvider(widget.village.id));

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
              color: t.ink, border: Border(bottom: BorderSide(color: t.line))),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterBtn(
                          label: 'Tout',
                          active: _filter == 'all',
                          onTap: () => setState(() => _filter = 'all')),
                      _FilterBtn(
                          label: 'Publications',
                          active: _filter == 'post',
                          onTap: () => setState(() => _filter = 'post')),
                      _FilterBtn(
                          label: 'Lives',
                          active: _filter == 'live',
                          onTap: () => setState(() => _filter = 'live'),
                          hasLiveDot: true),
                      _FilterBtn(
                          label: 'Conférences',
                          active: _filter == 'conf',
                          onTap: () => setState(() => _filter = 'conf')),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showComposeSheet(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                      color: GwTokens.gold,
                      borderRadius: BorderRadius.circular(GwTokens.rBtn)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add,
                          size: 14, color: GwTokens.inkOnGold),
                      const SizedBox(width: 5),
                      Text('Publier',
                          style: GwType.ui(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: GwTokens.inkOnGold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: feedAsync.when(
            loading: () => Center(
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: GwTokens.gold)),
            error: (_, __) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Symbols.wifi_off, size: 36, color: t.stoneFaint),
                  const SizedBox(height: 8),
                  Text('Erreur de chargement',
                      style: GwType.ui(color: t.stoneDim, fontSize: 12)),
                  TextButton(
                      onPressed: () => ref
                          .read(villageFeedNotifierProvider(widget.village.id)
                              .notifier)
                          .refresh(),
                      child: Text('Réessayer',
                          style: GwType.ui(color: t.goldText))),
                ],
              ),
            ),
            data: (posts) => RefreshIndicator(
              color: GwTokens.gold,
              backgroundColor: t.inkCard,
              onRefresh: () => ref
                  .read(villageFeedNotifierProvider(widget.village.id).notifier)
                  .refresh(),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const _LiveBanner(),
                  if (posts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Symbols.article, size: 36, color: t.stoneFaint),
                            const SizedBox(height: 8),
                            Text('Aucune publication\nSoyez le premier à publier !',
                                textAlign: TextAlign.center,
                                style: GwType.ui(
                                    color: t.stoneDim,
                                    fontSize: 12,
                                    height: 1.6)),
                          ],
                        ),
                      ),
                    ),
                  ...posts.map((post) =>
                      _PostCard(post: post, villageId: widget.village.id)),
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
    final t = GwTokens.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: t.inkCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) {
        final st = GwTokens.of(sheetContext);
        return Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _composeCtrl,
                autofocus: true,
                maxLines: 4,
                minLines: 2,
                style: GwType.ui(color: st.stone, fontSize: 14),
                decoration: InputDecoration(
                    hintText: 'Écrire une publication...',
                    hintStyle: GwType.ui(color: st.stoneDim, fontSize: 14),
                    filled: true,
                    fillColor: st.inkLift,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(GwTokens.rBtn),
                        borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _posting
                      ? null
                      : () {
                          _submitPost();
                          Navigator.pop(context);
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                        color: GwTokens.gold,
                        borderRadius: BorderRadius.circular(GwTokens.rBtn)),
                    child: Center(
                      child: _posting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: GwTokens.inkOnGold))
                          : Text('Publier',
                              style: GwType.ui(
                                  color: GwTokens.inkOnGold,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ONGLET CHAT — groupes + messages inline
// ═══════════════════════════════════════════════════════════════

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
    final t = GwTokens.of(context);
    final groupsAsync = ref.watch(chatGroupsProvider(widget.village.id));
    return groupsAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: GwTokens.gold)),
      error: (e, _) => Center(
        child: Text('Erreur de chargement du chat',
            style: GwType.ui(color: t.stoneDim)),
      ),
      data: (groups) {
        if (_selectedGroup != null) {
          return Column(
            children: [
              Container(
                color: t.ink,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Symbols.arrow_back, color: t.stone, size: 20),
                      onPressed: () => setState(() => _selectedGroup = null),
                    ),
                    Expanded(
                      child: Text(_selectedGroup!.name,
                          style: GwType.ui(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: t.stone),
                          overflow: TextOverflow.ellipsis),
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
}

// ── Liste des groupes ────────────────────────────────────────────

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
    final t = GwTokens.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
          decoration:
              BoxDecoration(border: Border(bottom: BorderSide(color: t.line))),
          child: Row(
            children: [
              Icon(Symbols.forum, color: t.goldText, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text('GROUPES',
                    style: GwType.mono(
                        fontSize: 11,
                        letterSpacing: 1.4,
                        color: t.stoneDim)),
              ),
              IconButton(
                icon: Icon(Icons.add, size: 18, color: t.goldText),
                tooltip: 'Créer un groupe',
                onPressed: () => _showCreateDialog(context, ref),
              ),
            ],
          ),
        ),
        Expanded(
          child: groups.isEmpty
              ? _emptyGroups(context, ref, t)
              : ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, i) {
                    final g = groups[i];
                    final isSelected = g.id == selectedId;
                    final isCommission = g.type == 'COMMISSION';
                    return GestureDetector(
                      onTap: () => onSelect(g),
                      child: Container(
                        color: isSelected ? t.goldBg : Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: (isCommission
                                        ? GwTokens.azure
                                        : GwTokens.gold)
                                    .withAlpha(28),
                                borderRadius: BorderRadius.circular(10),
                                border: isSelected
                                    ? Border.all(color: t.goldLine)
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                isCommission
                                    ? Symbols.groups
                                    : Symbols.chat_bubble,
                                size: 18,
                                color: isSelected
                                    ? t.goldText
                                    : (isCommission
                                        ? t.azureText
                                        : t.stoneDim),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(g.name,
                                      style: GwType.ui(
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: isSelected
                                              ? t.goldText
                                              : t.stone),
                                      overflow: TextOverflow.ellipsis),
                                  Text(
                                      '${g.memberCount} membre${g.memberCount > 1 ? 's' : ''}',
                                      style: GwType.ui(
                                          fontSize: 11, color: t.stoneFaint)),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(Symbols.chevron_right,
                                  size: 16, color: t.goldText),
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

  Widget _emptyGroups(BuildContext context, WidgetRef ref, GwTokens t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.forum, size: 36, color: t.stoneFaint),
            const SizedBox(height: 10),
            Text('Aucun groupe',
                style: GwType.ui(color: t.stoneDim, fontSize: 13)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showCreateDialog(context, ref),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: t.goldBg,
                  borderRadius: BorderRadius.circular(GwTokens.rBtn),
                  border: Border.all(color: t.goldLine),
                ),
                child: Text('+ Créer un groupe',
                    style: GwType.ui(fontSize: 12, color: t.goldText)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String type = 'GENERAL';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: t.inkCard,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(GwTokens.rCard)),
          title: Text('Nouveau groupe',
              style: GwType.display(fontSize: 20, color: t.stone)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: GwType.ui(fontSize: 14, color: t.stone),
                decoration: InputDecoration(
                    labelText: 'Nom du groupe *',
                    labelStyle: GwType.ui(fontSize: 13, color: t.stoneDim),
                    isDense: true),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                style: GwType.ui(fontSize: 14, color: t.stone),
                decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: GwType.ui(fontSize: 13, color: t.stoneDim),
                    isDense: true),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Type :',
                        style: GwType.ui(fontSize: 13, color: t.stoneMid)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Général'),
                          selected: type == 'GENERAL',
                          onSelected: (_) => setD(() => type = 'GENERAL'),
                          selectedColor: t.goldBg,
                        ),
                        ChoiceChip(
                          label: const Text('Commission'),
                          selected: type == 'COMMISSION',
                          onSelected: (_) => setD(() => type = 'COMMISSION'),
                          selectedColor: t.goldBg,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Annuler',
                  style: GwType.ui(color: t.stoneDim)),
            ),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().length < 2) return;
                Navigator.pop(ctx);
                try {
                  await ref.read(createChatGroupProvider.notifier).create(
                        villageId: village.id,
                        name: nameCtrl.text.trim(),
                        description: descCtrl.text.trim().isNotEmpty
                            ? descCtrl.text.trim()
                            : null,
                        type: type,
                      );
                } catch (_) {}
              },
              style: FilledButton.styleFrom(
                backgroundColor: GwTokens.gold,
                foregroundColor: GwTokens.inkOnGold,
              ),
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Messages inline ──────────────────────────────────────────────

class _InlineMessages extends ConsumerStatefulWidget {
  const _InlineMessages({required this.group, this.onClose});
  final ChatGroupModel group;
  final VoidCallback? onClose;

  @override
  ConsumerState<_InlineMessages> createState() => _InlineMessagesState();
}

class _InlineMessagesState extends ConsumerState<_InlineMessages> {
  final _msgCtrl = TextEditingController();
  final _focusNode = FocusNode();
  bool _sending = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _focusNode.dispose();
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
    final t = GwTokens.of(context);
    final messagesAsync =
        ref.watch(chatMessagesNotifierProvider(widget.group.id));
    final currentUserId = ref.watch(profileNotifierProvider).valueOrNull?.id;

    return Container(
      color: t.ink,
      child: Column(
        children: [
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: t.inkCard,
              border: Border(bottom: BorderSide(color: t.line, width: 0.5)),
            ),
            child: Row(
              children: [
                if (widget.group.type == 'DIRECT')
                  Container(
                    width: 28,
                    height: 28,
                    decoration:
                        BoxDecoration(color: t.goldBg, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(
                      widget.group.name.isNotEmpty
                          ? widget.group.name[0].toUpperCase()
                          : '?',
                      style: GwType.display(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: t.goldText),
                    ),
                  )
                else
                  Icon(Symbols.groups, size: 18, color: t.goldText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(widget.group.name,
                      style: GwType.ui(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: t.stone),
                      overflow: TextOverflow.ellipsis),
                ),
                IconButton(
                  icon: Icon(Symbols.refresh, size: 16, color: t.stoneDim),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => ref
                      .read(chatMessagesNotifierProvider(widget.group.id)
                          .notifier)
                      .refresh(),
                ),
                if (widget.onClose != null)
                  IconButton(
                    icon: Icon(Icons.close, size: 16, color: t.stoneDim),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: widget.onClose,
                  ),
              ],
            ),
          ),
          Expanded(
            child: messagesAsync.when(
              loading: () => Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: GwTokens.gold, strokeWidth: 2))),
              error: (e, _) => Center(
                  child: Text('Erreur',
                      style: GwType.ui(color: t.stoneDim, fontSize: 12))),
              data: (messages) => messages.isEmpty
                  ? Center(
                      child: Text('Aucun message',
                          style: GwType.ui(color: t.stoneFaint, fontSize: 12)))
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      itemCount: messages.length,
                      itemBuilder: (_, i) => _InlineBubble(
                        message: messages[i],
                        isMe: currentUserId != null &&
                            messages[i].senderId == currentUserId,
                      ),
                    ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
                8, 6, 8, MediaQuery.of(context).viewInsets.bottom + 6),
            decoration: BoxDecoration(
              color: t.inkCard,
              border: Border(top: BorderSide(color: t.line, width: 0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    maxLines: 4,
                    minLines: 1,
                    style: GwType.ui(fontSize: 13, color: t.stone),
                    decoration: InputDecoration(
                      hintText: 'Aa',
                      hintStyle: GwType.ui(color: t.stoneDim),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: t.inkLift,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _sending ? null : _send,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _sending ? t.goldLine : GwTokens.gold,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: _sending
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: GwTokens.inkOnGold))
                        : const Icon(Symbols.send,
                            color: GwTokens.inkOnGold, size: 16),
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

// ── Bulle de message inline ──────────────────────────────────────

class _InlineBubble extends StatelessWidget {
  const _InlineBubble({required this.message, required this.isMe});
  final ChatMessageModel message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);

    if (message.type == 'SYSTEM') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Text(message.content,
              style: GwType.quote(fontSize: 11, color: t.stoneFaint)),
        ),
      );
    }

    final time = message.createdAt != null
        ? '${message.createdAt!.hour.toString().padLeft(2, '0')}:${message.createdAt!.minute.toString().padLeft(2, '0')}'
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 24,
              height: 24,
              decoration:
                  BoxDecoration(color: t.goldBg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                (message.senderName?.isNotEmpty == true)
                    ? message.senderName![0].toUpperCase()
                    : '?',
                style: GwType.display(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: t.goldText),
              ),
            ),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe && message.type != 'DIRECT')
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 1),
                    child: Text(message.senderName ?? '',
                        style: GwType.ui(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: t.stoneDim)),
                  ),
                Container(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.65),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isMe ? GwTokens.gold : t.inkCard,
                    border: isMe ? null : Border.all(color: t.line),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                  ),
                  child: Text(message.content,
                      style: GwType.ui(
                          fontSize: 13,
                          color: isMe ? GwTokens.inkOnGold : t.stone,
                          height: 1.3)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 1, left: 4, right: 4),
                  child: Text(time,
                      style: GwType.mono(fontSize: 9, color: t.stoneFaint)),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// WIDGETS RÉUTILISABLES
// ═══════════════════════════════════════════════════════════════

// ── Stats Row ──

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.village});
  final VillageModel village;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Container(
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: t.line))),
      child: Row(
        children: [
          _stat(context, '${village.memberCount}', 'MEMBRES', isGold: true),
          _stat(context, '124', 'CONCESSIONS'),
          _stat(context, '58', 'FAMILLES'),
          _stat(context, '2', 'PAYS'),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label,
      {bool isGold = false}) {
    final t = GwTokens.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration:
            BoxDecoration(border: Border(right: BorderSide(color: t.line))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, val, child) => Opacity(opacity: val, child: child),
              child: Text(value,
                  style: GwType.display(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      height: 1,
                      color: isGold ? t.goldText : t.stone)),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: GwType.mono(
                    fontSize: 9, letterSpacing: 1.0, color: t.stoneFaint)),
          ],
        ),
      ),
    );
  }
}

// ── Section wrapper ──

class _Section extends StatelessWidget {
  const _Section(
      {required this.title,
      required this.child,
      this.badge,
      this.trailing,
      this.isMonoTitle = false});
  final String title;
  final Widget child;
  final String? badge;
  final Widget? trailing;
  final bool isMonoTitle;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Container(
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: t.line))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                Expanded(
                  child: isMonoTitle
                      ? Text(title.toUpperCase(),
                          style: GwType.mono(
                              fontSize: 10,
                              letterSpacing: 1.4,
                              color: t.stoneFaint))
                      : Row(
                          children: [
                            Flexible(
                              child: Text(title,
                                  style: GwType.display(
                                      fontSize: 20, color: t.stone),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            if (badge != null) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                    border: Border.all(color: t.line),
                                    borderRadius: BorderRadius.circular(3)),
                                child: Text(badge!.toUpperCase(),
                                    style: GwType.mono(
                                        fontSize: 8,
                                        letterSpacing: 0.8,
                                        color: t.stoneFaint)),
                              ),
                            ],
                          ],
                        ),
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
    final t = GwTokens.of(context);
    return Container(
      height: fullScreen ? double.infinity : 300,
      constraints: fullScreen ? null : const BoxConstraints(maxHeight: 300),
      color: t.inkDeep,
      child: Stack(
        children: [
          Positioned.fill(
              child: CustomPaint(
                  painter: _MapPatternPainter(brightness: t.brightness))),
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: t.inkCard.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(GwTokens.rBtn),
                  border: Border.all(color: t.lineMid)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LegendRow(
                      color: t.goldText,
                      label: 'Concession familiale',
                      isGem: true),
                  const SizedBox(height: 6),
                  _LegendRow(
                      color: GwTokens.gold,
                      label: 'Votre ligne',
                      isGem: true),
                  const SizedBox(height: 6),
                  _LegendRow(color: GwTokens.ember, label: 'Point du chef'),
                  const SizedBox(height: 6),
                  _LegendRow(color: GwTokens.sage, label: 'Zone sacrée'),
                  const SizedBox(height: 6),
                  _LegendRow(color: GwTokens.azure, label: 'Place publique'),
                ],
              ),
            ),
          ),
          const Positioned(
            bottom: 14,
            right: 14,
            child: Column(children: [
              _MapCtrlBtn('+'),
              SizedBox(height: 4),
              _MapCtrlBtn('−'),
              SizedBox(height: 4),
              _MapCtrlBtn('⊙')
            ]),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow(
      {required this.color, required this.label, this.isGem = false});
  final Color color;
  final String label;
  final bool isGem;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isGem)
          Transform.rotate(
              angle: 0.785,
              child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(2))))
        else
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 9),
        Text(label, style: GwType.ui(fontSize: 11, color: t.stoneMid)),
      ],
    );
  }
}

class _MapCtrlBtn extends StatelessWidget {
  const _MapCtrlBtn(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
          color: t.inkCard.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          border: Border.all(color: t.lineMid)),
      child: Center(
          child: Text(label,
              style: TextStyle(fontSize: 16, color: t.stoneMid))),
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
    final t = GwTokens.of(context);
    return SizedBox(
      height: extended ? 140 : 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: _chiefs.length,
        separatorBuilder: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Center(
                child: Text('›',
                    style: TextStyle(fontSize: 14, color: t.stoneFaint)))),
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
    final t = GwTokens.of(context);
    final isCurrent = chief.type == _ChiefType.current;
    final isAncestor = chief.type == _ChiefType.ancestor;
    final size = isCurrent ? 54.0 : 44.0;

    Color bgColor, borderColor, textColor;
    if (isCurrent) {
      bgColor = t.goldBg;
      borderColor = GwTokens.gold;
      textColor = t.goldText;
    } else if (isAncestor) {
      bgColor = t.goldBg;
      borderColor = t.goldLine;
      textColor = t.goldText;
    } else {
      bgColor = t.inkLift;
      borderColor = t.lineMid;
      textColor = t.stoneDim;
    }

    return SizedBox(
      width: 80,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bgColor,
                  border:
                      Border.all(color: borderColor, width: isCurrent ? 1.5 : 1),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                              color: t.goldGlow, blurRadius: 16)
                        ]
                      : null,
                ),
                child: Center(
                    child: Text(chief.initials,
                        style: GwType.display(
                            fontSize: isCurrent ? 17 : 14,
                            fontWeight: FontWeight.w500,
                            color: textColor))),
              ),
              if (isCurrent)
                const Positioned(
                    top: -14,
                    left: 0,
                    right: 0,
                    child: Center(
                        child: Text('👑', style: TextStyle(fontSize: 14)))),
            ],
          ),
          const SizedBox(height: 6),
          Text(chief.name,
              style: GwType.ui(
                  fontSize: 11,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                  color: isCurrent ? t.goldText : t.stoneMid),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(chief.years,
              style: GwType.mono(fontSize: 9, color: t.stoneFaint),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Members Grid (aperçu lignée) ──

class _MembersGrid extends StatelessWidget {
  const _MembersGrid({required this.members});
  final List<VillageMemberModel> members;

  static const _roles = [
    'Père · G3',
    'Grand-père · G2',
    'Grand-mère · G2',
    'Frère · G4'
  ];
  static const _badges = ['Résident', 'Fondateur', 'Résidente', 'Diaspora'];

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final cellColors = [
      GwTokens.azureBg,
      GwTokens.sageBg,
      GwTokens.emberBg,
      t.goldBg
    ];
    final cellBorders = [
      GwTokens.azureLine,
      GwTokens.sageLine,
      GwTokens.emberLine,
      t.goldLine
    ];
    final cellTexts = [t.azureText, t.sageText, t.emberText, t.goldText];

    if (members.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Text('Aucun membre',
            style: GwType.ui(fontSize: 12, color: t.stoneFaint)),
      );
    }

    return Container(
      color: t.line,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(1),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            mainAxisSpacing: 1,
            crossAxisSpacing: 1),
        itemCount: members.length.clamp(0, 4),
        itemBuilder: (_, i) {
          final m = members[i];
          final ci = i % cellColors.length;
          return Container(
            color: t.inkCard,
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: cellColors[ci],
                  backgroundImage:
                      m.avatarUrl != null ? NetworkImage(m.avatarUrl!) : null,
                  child: m.avatarUrl == null
                      ? Text((m.displayName ?? '?')[0].toUpperCase(),
                          style: GwType.display(
                              color: cellTexts[ci],
                              fontWeight: FontWeight.w600,
                              fontSize: 14))
                      : null,
                ),
                const SizedBox(height: 8),
                Text(m.displayName ?? 'Membre',
                    style: GwType.ui(fontSize: 12, color: t.stoneMid),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(i < _roles.length ? _roles[i] : m.type,
                    style: GwType.mono(fontSize: 9, color: t.stoneFaint)),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                      color: cellColors[ci],
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: cellBorders[ci])),
                  child: Text(i < _badges.length ? _badges[i] : 'Membre',
                      style: GwType.mono(
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                          color: cellTexts[ci])),
                ),
              ],
            ),
          );
        },
      ),
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
    final t = GwTokens.of(context);
    final colors = [
      GwTokens.azureBg,
      GwTokens.sageBg,
      t.goldBg,
      GwTokens.emberBg
    ];
    final textColors = [t.azureText, t.sageText, t.goldText, t.emberText];
    final ci = index % colors.length;
    final roleLabel = switch (member.type) {
      'AMBASSADOR' => 'Ambassadeur',
      'MEMBER' => 'Membre',
      _ => 'Abonné'
    };

    return Container(
      color: t.inkCard,
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colors[ci],
            backgroundImage:
                member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
            child: member.avatarUrl == null
                ? Text((member.displayName ?? '?')[0].toUpperCase(),
                    style: GwType.display(color: textColors[ci], fontSize: 13))
                : null,
          ),
          const SizedBox(height: 6),
          Text(member.displayName ?? 'Membre',
              style: GwType.ui(fontSize: 11, color: t.stoneMid),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(roleLabel,
              style: GwType.mono(fontSize: 9, color: t.stoneFaint)),
        ],
      ),
    );
  }
}

// ── Chef Card ──

class _ChefCard extends ConsumerStatefulWidget {
  const _ChefCard({required this.village});
  final VillageModel village;

  @override
  ConsumerState<_ChefCard> createState() => _ChefCardState();
}

class _ChefCardState extends ConsumerState<_ChefCard> {
  bool _requesting = false;

  Future<void> _requestAccess() async {
    if (_requesting) return;
    setState(() => _requesting = true);
    try {
      final result = await ref
          .read(villageGovernanceServiceProvider)
          .requestMembership(widget.village.id);
      if (!mounted) return;
      if (result.member) {
        _toast(
            'Accès validé${result.autoReason != null ? ' — ${result.autoReason}' : ''}',
            GwTokens.sage,
            icon: Symbols.check_circle);
        // Rafraîchir le détail, les membres et les permissions.
        ref.invalidate(villageDetailProvider(widget.village.id));
        ref.invalidate(villageMembersProvider(widget.village.id));
        ref.invalidate(villageMyPermissionsProvider(widget.village.id));
      } else {
        _toast('Demande envoyée, en attente de validation', GwTokens.gold,
            icon: Symbols.hourglass_top, fg: GwTokens.inkOnGold);
      }
    } catch (_) {
      if (mounted) {
        _toast('Impossible d\'envoyer la demande', GwTokens.ember,
            icon: Symbols.error);
      }
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  void _toast(String msg, Color bg,
      {required IconData icon, Color fg = Colors.white}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 10),
            Flexible(
              child: Text(msg,
                  style: GwType.ui(
                      fontSize: 14, fontWeight: FontWeight.w600, color: fg)),
            ),
          ],
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GwTokens.rPill)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final permsAsync = ref.watch(villageMyPermissionsProvider(widget.village.id));
    // L'utilisateur est déjà membre si chef, super-admin, ou permissions non
    // vides (heuristique en attente d'un flag membre explicite).
    final isMember = permsAsync.valueOrNull?.let(
            (p) => p.chief || p.superAdmin || p.permissions.isNotEmpty) ??
        false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.inkCard,
          borderRadius: BorderRadius.circular(GwTokens.rCard),
          border: Border.all(color: t.goldLine),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                            colors: [GwTokens.goldLight, GwTokens.gold]),
                        border: Border.all(color: t.goldLine, width: 1.5),
                      ),
                      child: Center(
                          child: Text('ND',
                              style: GwType.display(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: GwTokens.inkOnGold))),
                    ),
                    const Positioned(
                        top: -12,
                        left: 0,
                        right: 0,
                        child: Center(
                            child: Text('👑', style: TextStyle(fontSize: 14)))),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ndoumbe Bassa II',
                          style: GwType.display(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: t.stone)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text('Chef du village',
                              style: GwType.ui(
                                  fontSize: 12, color: t.goldText)),
                          const SizedBox(width: 6),
                          Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                  color: GwTokens.gold,
                                  shape: BoxShape.circle)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('En fonction depuis 2008',
                          style: GwType.mono(fontSize: 9, color: t.stoneFaint)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: GwTokens.sage, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('En ligne maintenant',
                  style: GwType.mono(fontSize: 9, color: GwTokens.sage)),
            ]),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                        color: t.inkLift,
                        borderRadius: BorderRadius.circular(GwTokens.rBtn),
                        border: Border.all(color: t.lineMid)),
                    child: Center(
                        child: Text('Message',
                            style: GwType.ui(fontSize: 12, color: t.stoneMid))),
                  ),
                ),
                if (!isMember) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: _requestAccess,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                            color: GwTokens.gold,
                            borderRadius:
                                BorderRadius.circular(GwTokens.rBtn)),
                        child: Center(
                          child: _requesting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: GwTokens.inkOnGold))
                              : Text('Demander accès',
                                  textAlign: TextAlign.center,
                                  style: GwType.ui(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: GwTokens.inkOnGold)),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filiation Tree ──

class _FiliationTree extends ConsumerWidget {
  const _FiliationTree();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        children: [
          _filNode(context, 'SM', 'Stéphane Mbopda', 'Vous', 'Fondateur',
              t.goldBg, t.goldLine, t.goldText,
              isMine: true),
          _indentWrap(context, [
            _filNode(context, 'EM', 'Emmanuel Mbopda', 'Père', 'Résident',
                GwTokens.azureBg, GwTokens.azureLine, t.azureText,
                isMine: true),
            const SizedBox(height: 6),
            Opacity(
              opacity: 0.6,
              child: _filNode(context, 'MN', 'Marie Njock', 'Mère', '🔒',
                  GwTokens.emberBg, GwTokens.emberLine, t.emberText),
            ),
            const SizedBox(height: 6),
            _indentWrap(context, [
              _filNode(context, 'DM', 'Daniel Mbopda', 'Gd-père', 'Fondateur',
                  GwTokens.sageBg, GwTokens.sageLine, t.sageText,
                  isMine: true),
            ]),
          ]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: GwTokens.sageBg,
                borderRadius: BorderRadius.circular(GwTokens.rBtn),
                border: Border.all(color: GwTokens.sageLine)),
            child: Row(children: [
              Icon(Symbols.check_circle, size: 14, color: t.sageText),
              const SizedBox(width: 8),
              Text('3 liens confirmés · accès validé',
                  style: GwType.ui(fontSize: 12, color: t.sageText)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _filNode(BuildContext context, String initials, String name,
      String rel, String tag, Color bg, Color border, Color text,
      {bool isMine = false}) {
    final t = GwTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: isMine ? t.goldGlow : t.inkCard,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        border: Border.all(color: isMine ? t.goldLine : t.line),
      ),
      child: Row(
        children: [
          CircleAvatar(
              radius: 14,
              backgroundColor: bg,
              child: Text(initials,
                  style: GwType.display(fontSize: 11, color: text))),
          const SizedBox(width: 9),
          Expanded(
              child: Text(name,
                  style: GwType.ui(
                      fontSize: 12,
                      color: isMine ? t.stone : t.stoneMid))),
          Text(rel, style: GwType.mono(fontSize: 9, color: t.stoneFaint)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: border)),
            child: Text(tag,
                style: GwType.mono(
                    fontSize: 8, fontWeight: FontWeight.w500, color: text)),
          ),
        ],
      ),
    );
  }

  Widget _indentWrap(BuildContext context, List<Widget> children) {
    final t = GwTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 18, top: 6),
      child: Container(
        decoration:
            BoxDecoration(border: Border(left: BorderSide(color: t.line))),
        padding: const EdgeInsets.only(left: 12),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ),
    );
  }
}

// ── Online Members ──

class _OnlineMembers extends ConsumerWidget {
  const _OnlineMembers({required this.village});
  final VillageModel village;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final membersAsync = ref.watch(villageMembersProvider(village.id));

    return membersAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Center(
            child: CircularProgressIndicator(
                strokeWidth: 1.5, color: GwTokens.gold)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (members) {
        if (members.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text('Aucun membre en ligne',
                style: GwType.ui(fontSize: 12, color: t.stoneFaint)),
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            children: members.take(5).map((member) {
              final name = member.displayName ?? 'Membre';
              final initials = name
                  .trim()
                  .split(' ')
                  .take(2)
                  .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
                  .join();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => _openDirectChat(context, ref, member),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(GwTokens.rBtn),
                    ),
                    child: Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: GwTokens.sageBg,
                              backgroundImage: member.avatarUrl != null &&
                                      member.avatarUrl!.isNotEmpty
                                  ? NetworkImage(member.avatarUrl!)
                                  : null,
                              child: member.avatarUrl == null ||
                                      member.avatarUrl!.isEmpty
                                  ? Text(initials,
                                      style: GwType.display(
                                          fontSize: 11, color: t.sageText))
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: GwTokens.sage,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: t.ink, width: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: GwType.ui(
                                      fontSize: 12.5, color: t.stoneMid)),
                              Text(
                                member.type == 'CHEF'
                                    ? 'Chef · Administrateur'
                                    : 'Résident',
                                style: GwType.mono(
                                    fontSize: 9, color: t.stoneFaint),
                              ),
                            ],
                          ),
                        ),
                        Icon(Symbols.chat_bubble, size: 14, color: t.goldText),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _openDirectChat(
      BuildContext context, WidgetRef ref, VillageMemberModel member) async {
    final t = GwTokens.of(context);
    final name = member.displayName ?? 'Membre';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: GwTokens.gold)),
          const SizedBox(width: 10),
          Text('Ouverture de la discussion avec $name…',
              style: GwType.ui(fontSize: 14, color: t.stone)),
        ]),
        duration: const Duration(seconds: 3),
        backgroundColor: t.inkCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GwTokens.rBtn)),
      ),
    );

    try {
      final group = await ref.read(createDirectChatProvider.notifier).openWith(
            villageId: village.id,
            targetUserId: member.userId,
            targetName: name,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => DraggableScrollableSheet(
          initialChildSize: 0.52,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          snap: true,
          snapSizes: const [0.52, 0.75, 0.92],
          builder: (_, __) => ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Column(
              children: [
                Container(
                  color: t.inkCard,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: t.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _InlineMessages(
                    group: group,
                    onClose: () => Navigator.of(ctx).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible d\'ouvrir la discussion',
              style: GwType.ui(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          backgroundColor: GwTokens.ember,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(GwTokens.rPill)),
        ),
      );
    }
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
        _logRow(context, 'Kofi A.', 'a ajouté 6 photos à la concession', '2h',
            isGold: true),
        _logRow(context, 'Chef Ndoumbe', 'Plan mis à jour', '4h'),
        _logRow(context, 'Ama D.', 'a complété l\'arbre de la famille', '6h'),
        _logRow(context, 'Chef Ndoumbe', 'a anobli Ama Diallo', '3j',
            isGold: true),
      ]),
    );
  }

  Widget _logRow(BuildContext context, String actor, String action, String time,
      {bool isGold = false}) {
    final t = GwTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: t.line))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                  color: isGold ? t.goldText : t.stoneFaint,
                  shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
                text: TextSpan(
                    style: GwType.ui(
                        fontSize: 12, height: 1.6, color: t.stoneMid),
                    children: [
                  TextSpan(
                      text: actor,
                      style: GwType.ui(
                          fontSize: 12,
                          color: t.stone,
                          fontWeight: FontWeight.w600)),
                  TextSpan(text: ' $action'),
                ])),
          ),
          const SizedBox(width: 8),
          Text(time, style: GwType.mono(fontSize: 9, color: t.stoneFaint)),
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
    final t = GwTokens.of(context);
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GwTokens.emberBg,
        borderRadius: BorderRadius.circular(GwTokens.rCard),
        border: Border.all(color: GwTokens.emberLine),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: t.inkCard,
                        borderRadius: BorderRadius.circular(GwTokens.rPill),
                        border: Border.all(color: GwTokens.emberLine)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                              color: GwTokens.ember, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text('EN DIRECT',
                          style: GwType.mono(
                              fontSize: 9, color: t.emberText)),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Text('Cérémonie des premiers fruits',
                      style: GwType.display(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: t.stone)),
                  const SizedBox(height: 2),
                  Text('Retransmission officielle',
                      style: GwType.quote(fontSize: 12, color: t.stoneDim)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Symbols.person, size: 12, color: t.stoneFaint),
                    const SizedBox(width: 4),
                    Text('247',
                        style: GwType.mono(fontSize: 10, color: t.stoneFaint)),
                  ]),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                    color: GwTokens.ember,
                    borderRadius: BorderRadius.circular(GwTokens.rBtn)),
                child: Text('Rejoindre',
                    style: GwType.ui(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
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
    final t = GwTokens.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
          color: t.inkCard,
          borderRadius: BorderRadius.circular(GwTokens.rCard),
          border: Border.all(color: t.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: t.goldBg,
                  backgroundImage: post.authorAvatarUrl != null
                      ? NetworkImage(post.authorAvatarUrl!)
                      : null,
                  child: post.authorAvatarUrl == null
                      ? Text(
                          (post.authorDisplayName ?? '?')[0].toUpperCase(),
                          style: GwType.display(
                              color: t.goldText, fontSize: 12))
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                            child: Text(post.authorDisplayName ?? 'Utilisateur',
                                style: GwType.ui(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: t.stone),
                                overflow: TextOverflow.ellipsis)),
                        if (post.authorRole != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                                color: t.goldBg,
                                borderRadius: BorderRadius.circular(3)),
                            child: Text(post.authorRole!.toUpperCase(),
                                style: GwType.mono(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w500,
                                    color: t.goldText)),
                          ),
                        ],
                      ]),
                      if (post.createdAt != null)
                        Text(_formatDate(post.createdAt!),
                            style: GwType.mono(
                                fontSize: 9, color: t.stoneFaint)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(post.content,
                  style: GwType.ui(
                      fontSize: 13, color: t.stoneMid, height: 1.7))),
          if (post.mediaUrl != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(GwTokens.rBtn),
                  child: Image.network(post.mediaUrl!,
                      fit: BoxFit.cover,
                      height: 160,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink())),
            ),
          Container(
            decoration: BoxDecoration(
                border: Border(top: BorderSide(color: t.line))),
            child: Row(children: [
              _actBtn(
                  context,
                  Symbols.thumb_up,
                  post.reactionCount > 0 ? '${post.reactionCount}' : 'J\'aime',
                  () => ref
                      .read(villageFeedNotifierProvider(villageId).notifier)
                      .react(post.id, 'LIKE')),
              _actBtn(
                  context,
                  Symbols.comment,
                  post.commentCount > 0
                      ? '${post.commentCount}'
                      : 'Commenter',
                  () {}),
              _actBtn(
                  context,
                  Symbols.favorite,
                  'Respect',
                  () => ref
                      .read(villageFeedNotifierProvider(villageId).notifier)
                      .react(post.id, 'RESPECT')),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _actBtn(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final t = GwTokens.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 14, color: t.stoneDim),
            const SizedBox(width: 5),
            Text(label,
                style: GwType.ui(color: t.stoneDim, fontSize: 11)),
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
  const _FilterBtn(
      {required this.label,
      required this.active,
      required this.onTap,
      this.hasLiveDot = false});
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool hasLiveDot;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
              color: active ? t.inkLift : Colors.transparent,
              borderRadius: BorderRadius.circular(GwTokens.rPill),
              border:
                  Border.all(color: active ? t.lineMid : Colors.transparent)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (hasLiveDot) ...[
              Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: GwTokens.ember, shape: BoxShape.circle)),
              const SizedBox(width: 6)
            ],
            Text(label,
                style: GwType.ui(
                    fontSize: 12, color: active ? t.stone : t.stoneDim)),
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
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text('·',
          style: TextStyle(color: GwTokens.of(context).stoneFaint)));
}

// ═══════════════════════════════════════════════════════════════
// PAINTERS
// ═══════════════════════════════════════════════════════════════

class _MapPatternPainter extends CustomPainter {
  _MapPatternPainter({required this.brightness});
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final t = brightness == Brightness.dark ? GwTokens.dark : GwTokens.light;

    final gridPaint = Paint()
      ..color = t.stoneFaint.withAlpha(24)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final dotPaint = Paint()..style = PaintingStyle.fill;
    final concessions = [
      [0.25, 0.3, GwTokens.gold],
      [0.45, 0.45, GwTokens.goldLight],
      [0.65, 0.35, GwTokens.gold],
      [0.3, 0.65, GwTokens.sage],
      [0.5, 0.55, GwTokens.azure],
      [0.75, 0.6, GwTokens.gold],
      [0.4, 0.75, GwTokens.ember],
    ];
    for (final cc in concessions) {
      dotPaint.color = (cc[2] as Color).withAlpha(210);
      canvas.drawCircle(
          Offset(size.width * (cc[0] as double), size.height * (cc[1] as double)),
          10,
          dotPaint);
    }

    final roadPaint = Paint()
      ..color = t.stoneFaint.withAlpha(80)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.4,
          size.width * 0.6, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.6,
          size.width * 0.95, size.height * 0.55);
    canvas.drawPath(path, roadPaint);

    final labels = [
      [0.32, 0.28, 'Bassa'],
      [0.52, 0.43, 'Likoko'],
      [0.42, 0.58, 'Place publique'],
      [0.78, 0.58, 'Nkoulou'],
    ];
    for (final l in labels) {
      final tp = TextPainter(
        text: TextSpan(
            text: l[2] as String,
            style: GwType.mono(
                fontSize: 10,
                color: t.stoneDim.withAlpha(200))),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset(size.width * (l[0] as double), size.height * (l[1] as double)));
    }
  }

  @override
  bool shouldRepaint(covariant _MapPatternPainter oldDelegate) =>
      oldDelegate.brightness != brightness;
}

// ═══════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════

/// Petit helper `let` façon Kotlin pour chaîner sur un nullable.
extension _LetExtension<T> on T {
  R let<R>(R Function(T) op) => op(this);
}
