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
import 'package:gwangmeu/features/genealogy/genealogy_notifier.dart';
import 'package:gwangmeu/features/genealogy/models/family_tree.dart';
import 'package:gwangmeu/features/genealogy/models/person_genealogy.dart';
import 'package:gwangmeu/features/genealogy/services/genealogy_api_service.dart';
import 'package:gwangmeu/features/profile/profile_notifier.dart';
import 'package:gwangmeu/features/villages/villages_notifier.dart';
import 'package:gwangmeu/features/villages/services/village_governance_service.dart';
import 'package:gwangmeu/features/villages/services/village_heritage_service.dart';
import 'package:gwangmeu/features/villages/widgets/village_management_panel.dart';
import 'package:gwangmeu/shared/widgets/gw_dialog.dart';

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
                  onTap: () => context.push(Routes.addVillage),
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
      onTap: () => context.push(Routes.addVillage),
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
    'Ligne des chefs',
    'Temps forts',
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
              _tabItem(context, 'Ligne des chefs', null),
              _tabItem(context, 'Temps forts', null),
              _tabItem(context, 'Membres', '${v.memberCount}'),
              _tabItem(context, 'Publications', null),
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
              _ChefsTab(village: v),
              _TempsFortsTab(village: v),
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
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Symbols.arrow_back, color: t.stoneMid, size: 20),
                      const SizedBox(width: 6),
                      Text('Retour',
                          style: GwType.ui(fontSize: 13, color: t.stoneMid)),
                    ]),
                  ),
                  const Spacer(),
                  // Sélecteur de village (mobile) : bascule entre tous les
                  // villages de l'utilisateur, comme le panneau gauche desktop.
                  _MobileVillageSwitcher(currentId: v.id),
                ],
              ),
            ),
          // Méta mono : région / pays
          Text(
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
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FollowButton(villageId: v.id),
              if (canManage) _manageButton(context),
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

/// Sélecteur de village (mobile) : liste les villages de l'utilisateur et
/// permet de basculer vers la fiche d'un autre village. Masqué si < 2 villages.
class _MobileVillageSwitcher extends ConsumerWidget {
  const _MobileVillageSwitcher({required this.currentId});
  final String currentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final mine = ref.watch(myVillagesNotifierProvider).valueOrNull ?? const [];
    if (mine.length < 2) return const SizedBox.shrink();
    return Material(
      color: t.inkLift,
      borderRadius: BorderRadius.circular(GwTokens.rPill),
      child: InkWell(
        onTap: () => _open(context, ref, mine),
        borderRadius: BorderRadius.circular(GwTokens.rPill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GwTokens.rPill),
            border: Border.all(color: t.line),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Symbols.swap_horiz, size: 15, color: t.goldText),
            const SizedBox(width: 6),
            Text('Changer',
                style: GwType.ui(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: t.stoneMid)),
          ]),
        ),
      ),
    );
  }

  void _open(BuildContext context, WidgetRef ref, List<VillageModel> mine) {
    showGwDialog(context, builder: (dctx) {
      final t = GwTokens.of(dctx);
      return GwDialog(
        title: 'Tes villages',
        subtitle: 'Basculer d\'un village à l\'autre',
        icon: Symbols.holiday_village,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final village in mine)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Material(
                  color: village.id == currentId ? t.goldBg : t.inkLift,
                  borderRadius: BorderRadius.circular(GwTokens.rBtn),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(GwTokens.rBtn),
                    onTap: () {
                      Navigator.of(dctx).maybePop();
                      if (village.id != currentId) {
                        context.go(Routes.villageDetail(village.id));
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(GwTokens.rBtn),
                        border: Border.all(
                            color: village.id == currentId
                                ? t.goldLine
                                : t.line),
                      ),
                      child: Row(children: [
                        Icon(
                            village.id == currentId
                                ? Symbols.check_circle
                                : Symbols.location_city,
                            size: 18,
                            color: village.id == currentId
                                ? t.goldText
                                : t.stoneDim),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(village.name,
                              style: GwType.ui(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: t.stone),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
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
                _rightSectionLabel(context, 'Chef du village'),
                _ChefCard(village: village),
                _rightSectionLabel(context, 'Votre ligne de filiation'),
                const _FiliationTree(),
                _rightSectionLabel(context, 'Membres'),
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
    final canEdit = ref
            .watch(villageMyPermissionsProvider(village.id))
            .valueOrNull
            ?.has('EDIT_VILLAGE') ??
        false;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _StatsRow(village: village),
        _Section(
          title: 'Genèse',
          trailing: canEdit
              ? _sectionEditBtn(
                  context, () => _showGenesisDialog(context, ref, village))
              : null,
          child: _GenesisContent(
            village: village,
            canEdit: canEdit,
            onEdit: () => _showGenesisDialog(context, ref, village),
          ),
        ),
        _Section(
          title: 'Votre lignée dans ce village',
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
        if (village.description != null && village.description!.trim().isNotEmpty)
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
              title: 'Chef du village',
              isMonoTitle: true,
              child: _ChefCard(village: village)),
          const _Section(
              title: 'Votre ligne de filiation',
              isMonoTitle: true,
              child: _FiliationTree()),
          _Section(
              title: 'Membres',
              isMonoTitle: true,
              child: _OnlineMembers(village: village)),
        ],
        const SizedBox(height: 40),
      ],
    );
  }
}

/// Contenu de la section Genèse : année de fondation + récit fondateur réels,
/// ou état vide honnête (avec action de saisie si l'utilisateur peut éditer).
class _GenesisContent extends StatelessWidget {
  const _GenesisContent({
    required this.village,
    required this.canEdit,
    required this.onEdit,
  });
  final VillageModel village;
  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final hasFounded = village.foundedYear != null;
    final summary = village.historicalSummary?.trim() ?? '';
    final hasSummary = summary.isNotEmpty;

    if (!hasFounded && !hasSummary) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: _EmptyHeritage(
          icon: Symbols.auto_stories,
          title: 'Genèse non renseignée',
          message: canEdit
              ? 'Racontez l\'origine du village : année de fondation, fondateurs, migration, sens du nom.'
              : 'L\'origine de ce village n\'a pas encore été documentée.',
          actionLabel: canEdit ? 'Renseigner la genèse' : null,
          onAction: onEdit,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasFounded) ...[
            Row(children: [
              Icon(Symbols.event, size: 15, color: t.goldText),
              const SizedBox(width: 6),
              Text('Fondé en ${village.foundedYear}',
                  style: GwType.ui(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: t.stone)),
            ]),
            if (hasSummary) const SizedBox(height: 10),
          ],
          if (hasSummary)
            Text(summary,
                style: GwType.quote(fontSize: 14, color: t.stoneMid, height: 1.8)),
        ],
      ),
    );
  }
}

/// Petit bouton « MODIFIER » or pour l'en-tête d'une section éditable.
Widget _sectionEditBtn(BuildContext context, VoidCallback onTap) {
  final t = GwTokens.of(context);
  return GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Symbols.edit, size: 13, color: t.goldText),
      const SizedBox(width: 4),
      Text('MODIFIER',
          style: GwType.mono(
              fontSize: 10, color: t.goldText, letterSpacing: 0.6)),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════
// ONGLET 3 — LIGNE DES CHEFS
// ═══════════════════════════════════════════════════════════════

class _ChefsTab extends ConsumerWidget {
  const _ChefsTab({required this.village});
  final VillageModel village;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final dynastyAsync = ref.watch(villageDynastyProvider(village.id));
    final canEdit = ref
            .watch(villageMyPermissionsProvider(village.id))
            .valueOrNull
            ?.has('EDIT_VILLAGE') ??
        false;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 44),
      children: [
        Text('Ligne des chefs',
            style: GwType.display(fontSize: 26, color: t.stone)),
        const SizedBox(height: 6),
        Text('La dynastie du village : chef actuel et anciens chefs.',
            style: GwType.ui(fontSize: 13, color: t.stoneDim, height: 1.6)),
        const SizedBox(height: 20),
        dynastyAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: Center(child: CircularProgressIndicator(color: GwTokens.gold)),
          ),
          error: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text('Impossible de charger la dynastie',
                style: GwType.ui(fontSize: 13, color: t.stoneDim)),
          ),
          data: (chiefs) {
            if (chiefs.isEmpty) {
              return _EmptyHeritage(
                icon: Symbols.history_edu,
                title: 'Dynastie non renseignée',
                message: canEdit
                    ? 'Aucun chef n\'a encore été documenté. Ajoutez le chef actuel et les anciens chefs pour bâtir la dynastie du village.'
                    : 'La succession des chefs de ce village n\'a pas encore été documentée.',
                actionLabel: canEdit ? 'Ajouter un chef' : null,
                onAction: () => _showChiefDialog(context, ref, village.id),
              );
            }
            final current = chiefs.where((c) => c.current).toList();
            final formers = chiefs.where((c) => !c.current).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final c in current)
                  _ChiefEntryCard(
                      villageId: village.id, chief: c, canEdit: canEdit),
                if (formers.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('ANCIENS CHEFS',
                      style: GwType.mono(
                          fontSize: 10,
                          letterSpacing: 1.6,
                          color: t.stoneFaint)),
                  const SizedBox(height: 10),
                  for (final c in formers)
                    _ChiefEntryCard(
                        villageId: village.id, chief: c, canEdit: canEdit),
                ],
                if (canEdit) ...[
                  const SizedBox(height: 14),
                  _HeritageAddButton(
                    label: 'Ajouter un chef',
                    onTap: () => _showChiefDialog(context, ref, village.id),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ONGLET TEMPS FORTS — jalons historiques réels (éditables)
// ═══════════════════════════════════════════════════════════════

class _TempsFortsTab extends ConsumerWidget {
  const _TempsFortsTab({required this.village});
  final VillageModel village;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final milestonesAsync = ref.watch(villageMilestonesProvider(village.id));
    final canEdit = ref
            .watch(villageMyPermissionsProvider(village.id))
            .valueOrNull
            ?.has('EDIT_VILLAGE') ??
        false;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 44),
      children: [
        Text('Temps forts',
            style: GwType.display(fontSize: 26, color: t.stone)),
        const SizedBox(height: 6),
        Text('Les jalons marquants de l\'histoire du village.',
            style: GwType.ui(fontSize: 13, color: t.stoneDim, height: 1.6)),
        const SizedBox(height: 20),
        milestonesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: Center(child: CircularProgressIndicator(color: GwTokens.gold)),
          ),
          error: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text('Impossible de charger les temps forts',
                style: GwType.ui(fontSize: 13, color: t.stoneDim)),
          ),
          data: (items) {
            if (items.isEmpty) {
              return _EmptyHeritage(
                icon: Symbols.timeline,
                title: 'Aucun temps fort',
                message: canEdit
                    ? 'Documentez les grands moments du village : fondation, migrations, intronisations, événements marquants.'
                    : 'Les temps forts de ce village n\'ont pas encore été documentés.',
                actionLabel: canEdit ? 'Ajouter un temps fort' : null,
                onAction: () => _showMilestoneDialog(context, ref, village.id),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < items.length; i++)
                  _MilestoneCard(
                    villageId: village.id,
                    milestone: items[i],
                    canEdit: canEdit,
                    isLast: i == items.length - 1,
                  ),
                if (canEdit) ...[
                  const SizedBox(height: 8),
                  _HeritageAddButton(
                    label: 'Ajouter un temps fort',
                    onTap: () => _showMilestoneDialog(context, ref, village.id),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

// ── Carte d'un temps fort (frise verticale) ──────────────────────

class _MilestoneCard extends ConsumerWidget {
  const _MilestoneCard({
    required this.villageId,
    required this.milestone,
    required this.canEdit,
    required this.isLast,
  });
  final String villageId;
  final VillageMilestone milestone;
  final bool canEdit;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final date = milestone.dateText;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: GwTokens.gold,
                    border: Border.all(color: t.goldLine, width: 3)),
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: t.line)),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: t.inkCard,
                  borderRadius: BorderRadius.circular(GwTokens.rCard),
                  border: Border.all(color: t.line)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (date.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: t.goldBg,
                              borderRadius: BorderRadius.circular(GwTokens.rPill),
                              border: Border.all(color: t.goldLine)),
                          child: Text(date,
                              style: GwType.mono(
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                  color: t.goldText)),
                        ),
                      const Spacer(),
                      if (canEdit) ...[
                        _heritageIconBtn(context, Symbols.edit, 'Modifier',
                            () => _showMilestoneDialog(context, ref, villageId,
                                existing: milestone)),
                        _heritageIconBtn(context, Symbols.delete, 'Supprimer',
                            () => _confirmDeleteMilestone(
                                context, ref, villageId, milestone),
                            danger: true),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(milestone.title,
                      style: GwType.display(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: t.stone)),
                  if (milestone.description != null &&
                      milestone.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(milestone.description!.trim(),
                        style: GwType.ui(
                            fontSize: 12.5, color: t.stoneMid, height: 1.6)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PATRIMOINE — widgets partagés + carte chef + édition (Tissage)
// ═══════════════════════════════════════════════════════════════

/// État vide honnête d'une section patrimoine, avec action facultative.
class _EmptyHeritage extends StatelessWidget {
  const _EmptyHeritage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.inkCard,
        borderRadius: BorderRadius.circular(GwTokens.rCard),
        border: Border.all(color: t.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 20, color: t.stoneDim),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  style: GwType.ui(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: t.stone)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(message,
              style: GwType.ui(fontSize: 12.5, color: t.stoneDim, height: 1.5)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            _HeritageAddButton(label: actionLabel!, onTap: onAction!),
          ],
        ],
      ),
    );
  }
}

/// Bouton « + Ajouter … » or discret, réutilisé par les sections patrimoine.
class _HeritageAddButton extends StatelessWidget {
  const _HeritageAddButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Material(
      color: t.goldBg,
      borderRadius: BorderRadius.circular(GwTokens.rBtn),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GwTokens.rBtn),
            border: Border.all(color: t.goldLine),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Symbols.add, size: 17, color: t.goldText),
              const SizedBox(width: 7),
              Text(label,
                  style: GwType.ui(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: t.goldText)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte d'un chef de la dynastie (actuel mis en avant en or).
class _ChiefEntryCard extends ConsumerWidget {
  const _ChiefEntryCard({
    required this.villageId,
    required this.chief,
    required this.canEdit,
  });
  final String villageId;
  final DynastyChief chief;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final reign = chief.reignLabel;
    final hasAvatar = chief.avatarUrl != null && chief.avatarUrl!.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: chief.current ? t.goldGlow : t.inkCard,
        borderRadius: BorderRadius.circular(GwTokens.rCard),
        border: Border.all(color: chief.current ? t.goldLine : t.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: chief.current
                      ? const LinearGradient(
                          colors: [GwTokens.goldLight, GwTokens.gold])
                      : null,
                  color: chief.current ? null : t.inkLift,
                  border: Border.all(
                      color: chief.current ? t.goldLine : t.lineMid,
                      width: 1.5),
                  image: hasAvatar
                      ? DecorationImage(
                          image: NetworkImage(chief.avatarUrl!),
                          fit: BoxFit.cover)
                      : null,
                ),
                alignment: Alignment.center,
                child: hasAvatar
                    ? null
                    : Text(_initialsOf(chief.displayName),
                        style: GwType.display(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: chief.current
                                ? GwTokens.inkOnGold
                                : t.stoneMid)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(chief.displayName,
                              style: GwType.display(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: t.stone),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (chief.current) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                                color: t.goldBg,
                                borderRadius:
                                    BorderRadius.circular(GwTokens.rPill),
                                border: Border.all(color: t.goldLine)),
                            child: Text('CHEF ACTUEL',
                                style: GwType.mono(
                                    fontSize: 8,
                                    letterSpacing: 0.8,
                                    color: t.goldText)),
                          ),
                        ],
                      ],
                    ),
                    if (reign.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(reign,
                          style: GwType.mono(
                              fontSize: 10,
                              letterSpacing: 0.5,
                              color: t.stoneFaint)),
                    ],
                  ],
                ),
              ),
              if (canEdit) ...[
                _heritageIconBtn(context, Symbols.edit, 'Modifier',
                    () => _showChiefDialog(context, ref, villageId, existing: chief)),
                _heritageIconBtn(context, Symbols.delete, 'Supprimer',
                    () => _confirmDeleteChief(context, ref, villageId, chief),
                    danger: true),
              ],
            ],
          ),
          if (chief.note != null && chief.note!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(chief.note!.trim(),
                style: GwType.ui(fontSize: 12.5, color: t.stoneMid, height: 1.6)),
          ],
        ],
      ),
    );
  }
}

/// Initiales (1–2 lettres MAJ) d'un nom complet.
String _initialsOf(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final w = parts.first;
    return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
  }
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

/// Petit bouton icône (32 px) pour éditer/supprimer une entrée patrimoine.
Widget _heritageIconBtn(BuildContext context, IconData icon, String tooltip,
    VoidCallback onTap,
    {bool danger = false}) {
  final t = GwTokens.of(context);
  return IconButton(
    icon: Icon(icon, size: 17, color: danger ? t.emberText : t.stoneDim),
    tooltip: tooltip,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
    onPressed: onTap,
  );
}

void _heritageToast(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg,
          style: GwType.ui(
              fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
      backgroundColor: error ? GwTokens.ember : GwTokens.sage,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GwTokens.rPill)),
    ),
  );
}

// ── Édition : chef ───────────────────────────────────────────────

void _showChiefDialog(BuildContext context, WidgetRef ref, String villageId,
    {DynastyChief? existing}) {
  showGwDialog(context,
      builder: (_) => _ChiefFormSheet(villageId: villageId, existing: existing));
}

class _ChiefFormSheet extends ConsumerStatefulWidget {
  const _ChiefFormSheet({required this.villageId, this.existing});
  final String villageId;
  final DynastyChief? existing;

  @override
  ConsumerState<_ChiefFormSheet> createState() => _ChiefFormSheetState();
}

class _ChiefFormSheetState extends ConsumerState<_ChiefFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _start;
  late final TextEditingController _end;
  late final TextEditingController _note;
  late bool _current;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.displayName ?? '');
    _start = TextEditingController(text: e?.reignStart?.toString() ?? '');
    _end = TextEditingController(text: e?.reignEnd?.toString() ?? '');
    _note = TextEditingController(text: e?.note ?? '');
    _current = e?.current ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _start.dispose();
    _end.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      _heritageToast(context, 'Le nom du chef est requis', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(villageHeritageServiceProvider).saveChief(
            widget.villageId,
            chiefId: widget.existing?.id,
            displayName: name,
            reignStart: int.tryParse(_start.text.trim()),
            reignEnd: int.tryParse(_end.text.trim()),
            current: _current,
            ordinal: widget.existing?.ordinal,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
            avatarUrl: widget.existing?.avatarUrl,
          );
      ref.invalidate(villageDynastyProvider(widget.villageId));
      ref.invalidate(villageChiefProvider(widget.villageId));
      if (!mounted) return;
      Navigator.of(context).pop();
      _heritageToast(context, 'Chef enregistré');
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        _heritageToast(context, 'Impossible d\'enregistrer', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final isEdit = widget.existing != null;
    return GwDialog(
      title: isEdit ? 'Modifier le chef' : 'Ajouter un chef',
      subtitle: 'Chef actuel ou ancien chef de la dynastie',
      icon: Symbols.workspace_premium,
      actions: [
        GwDialogAction(
            label: 'Annuler', onPressed: () => Navigator.of(context).maybePop()),
        GwDialogAction(
            label: 'Enregistrer',
            primary: true,
            loading: _saving,
            onPressed: _save),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            style: GwType.ui(fontSize: 14, color: t.stone),
            decoration: gwInputDecoration(context,
                label: 'Nom du chef', prefixIcon: Symbols.person),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _start,
                  keyboardType: TextInputType.number,
                  style: GwType.ui(fontSize: 14, color: t.stone),
                  decoration: gwInputDecoration(context, label: 'Début de règne'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _end,
                  keyboardType: TextInputType.number,
                  style: GwType.ui(fontSize: 14, color: t.stone),
                  decoration: gwInputDecoration(context, label: 'Fin de règne'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Années facultatives. Laissez la fin vide s\'il est en fonction.',
              style: GwType.ui(fontSize: 11.5, color: t.stoneFaint)),
          const SizedBox(height: 14),
          GwChoicePill(
            label: 'Chef actuellement en fonction',
            selected: _current,
            icon: Symbols.verified,
            expand: true,
            onTap: () => setState(() => _current = !_current),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _note,
            maxLines: 4,
            minLines: 2,
            style: GwType.ui(fontSize: 14, color: t.stone, height: 1.5),
            decoration: gwInputDecoration(context,
                label: 'Récit de règne (facultatif)',
                hint: 'Faits marquants, intronisation, réalisations…'),
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmDeleteChief(
    BuildContext context, WidgetRef ref, String villageId, DynastyChief chief) {
  return _confirmHeritageDelete(
    context,
    title: 'Supprimer ce chef ?',
    message: '« ${chief.displayName} » sera retiré de la dynastie du village.',
    onConfirm: () async {
      await ref
          .read(villageHeritageServiceProvider)
          .deleteChief(villageId, chief.id);
      ref.invalidate(villageDynastyProvider(villageId));
      ref.invalidate(villageChiefProvider(villageId));
    },
  );
}

// ── Édition : temps fort ─────────────────────────────────────────

void _showMilestoneDialog(BuildContext context, WidgetRef ref, String villageId,
    {VillageMilestone? existing}) {
  showGwDialog(context,
      builder: (_) =>
          _MilestoneFormSheet(villageId: villageId, existing: existing));
}

class _MilestoneFormSheet extends ConsumerStatefulWidget {
  const _MilestoneFormSheet({required this.villageId, this.existing});
  final String villageId;
  final VillageMilestone? existing;

  @override
  ConsumerState<_MilestoneFormSheet> createState() =>
      _MilestoneFormSheetState();
}

class _MilestoneFormSheetState extends ConsumerState<_MilestoneFormSheet> {
  late final TextEditingController _title;
  late final TextEditingController _year;
  late final TextEditingController _dateLabel;
  late final TextEditingController _desc;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _year = TextEditingController(text: e?.year?.toString() ?? '');
    _dateLabel = TextEditingController(text: e?.dateLabel ?? '');
    _desc = TextEditingController(text: e?.description ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _year.dispose();
    _dateLabel.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      _heritageToast(context, 'Le titre est requis', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(villageHeritageServiceProvider).saveMilestone(
            widget.villageId,
            milestoneId: widget.existing?.id,
            title: title,
            year: int.tryParse(_year.text.trim()),
            dateLabel:
                _dateLabel.text.trim().isEmpty ? null : _dateLabel.text.trim(),
            description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
            ordinal: widget.existing?.ordinal,
          );
      ref.invalidate(villageMilestonesProvider(widget.villageId));
      if (!mounted) return;
      Navigator.of(context).pop();
      _heritageToast(context, 'Temps fort enregistré');
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        _heritageToast(context, 'Impossible d\'enregistrer', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final isEdit = widget.existing != null;
    return GwDialog(
      title: isEdit ? 'Modifier le temps fort' : 'Ajouter un temps fort',
      subtitle: 'Un jalon marquant de l\'histoire du village',
      icon: Symbols.timeline,
      actions: [
        GwDialogAction(
            label: 'Annuler', onPressed: () => Navigator.of(context).maybePop()),
        GwDialogAction(
            label: 'Enregistrer',
            primary: true,
            loading: _saving,
            onPressed: _save),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            style: GwType.ui(fontSize: 14, color: t.stone),
            decoration: gwInputDecoration(context,
                label: 'Titre', prefixIcon: Symbols.flag),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _year,
                  keyboardType: TextInputType.number,
                  style: GwType.ui(fontSize: 14, color: t.stone),
                  decoration: gwInputDecoration(context, label: 'Année'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _dateLabel,
                  style: GwType.ui(fontSize: 14, color: t.stone),
                  decoration: gwInputDecoration(context,
                      label: 'Ou date libre', hint: 'ex. XVIIIe siècle'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _desc,
            maxLines: 5,
            minLines: 3,
            style: GwType.ui(fontSize: 14, color: t.stone, height: 1.5),
            decoration: gwInputDecoration(context,
                label: 'Récit (facultatif)',
                hint: 'Décrivez l\'événement et son importance…'),
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmDeleteMilestone(BuildContext context, WidgetRef ref,
    String villageId, VillageMilestone milestone) {
  return _confirmHeritageDelete(
    context,
    title: 'Supprimer ce temps fort ?',
    message: '« ${milestone.title} » sera retiré de l\'histoire du village.',
    onConfirm: () async {
      await ref
          .read(villageHeritageServiceProvider)
          .deleteMilestone(villageId, milestone.id);
      ref.invalidate(villageMilestonesProvider(villageId));
    },
  );
}

// ── Édition : genèse (founded_year + historical_summary) ──────────

void _showGenesisDialog(
    BuildContext context, WidgetRef ref, VillageModel village) {
  showGwDialog(context, builder: (_) => _GenesisFormSheet(village: village));
}

class _GenesisFormSheet extends ConsumerStatefulWidget {
  const _GenesisFormSheet({required this.village});
  final VillageModel village;

  @override
  ConsumerState<_GenesisFormSheet> createState() => _GenesisFormSheetState();
}

class _GenesisFormSheetState extends ConsumerState<_GenesisFormSheet> {
  late final TextEditingController _founded;
  late final TextEditingController _summary;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _founded =
        TextEditingController(text: widget.village.foundedYear?.toString() ?? '');
    _summary =
        TextEditingController(text: widget.village.historicalSummary ?? '');
  }

  @override
  void dispose() {
    _founded.dispose();
    _summary.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(villageHeritageServiceProvider).updateGenesis(
            widget.village.id,
            foundedYear: int.tryParse(_founded.text.trim()),
            historicalSummary:
                _summary.text.trim().isEmpty ? null : _summary.text.trim(),
          );
      ref.invalidate(villageDetailProvider(widget.village.id));
      if (!mounted) return;
      Navigator.of(context).pop();
      _heritageToast(context, 'Genèse enregistrée');
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        _heritageToast(context, 'Impossible d\'enregistrer', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return GwDialog(
      title: 'Genèse du village',
      subtitle: 'Origine et récit fondateur',
      icon: Symbols.auto_stories,
      actions: [
        GwDialogAction(
            label: 'Annuler', onPressed: () => Navigator.of(context).maybePop()),
        GwDialogAction(
            label: 'Enregistrer',
            primary: true,
            loading: _saving,
            onPressed: _save),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: TextField(
              controller: _founded,
              keyboardType: TextInputType.number,
              style: GwType.ui(fontSize: 14, color: t.stone),
              decoration: gwInputDecoration(context,
                  label: 'Année de fondation', prefixIcon: Symbols.event),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _summary,
            maxLines: 8,
            minLines: 5,
            style: GwType.ui(fontSize: 14, color: t.stone, height: 1.6),
            decoration: gwInputDecoration(context,
                label: 'Récit fondateur',
                hint:
                    'Origine du village, migration, fondateurs, sens du nom…'),
          ),
        ],
      ),
    );
  }
}

// ── Confirmation de suppression (Tissage) ────────────────────────

Future<void> _confirmHeritageDelete(
  BuildContext context, {
  required String title,
  required String message,
  required Future<void> Function() onConfirm,
}) async {
  final ok = await showGwDialog<bool>(
    context,
    builder: (dctx) {
      final t = GwTokens.of(dctx);
      return GwDialog(
        title: title,
        icon: Symbols.delete,
        showWeave: false,
        actions: [
          GwDialogAction(
              label: 'Annuler',
              onPressed: () => Navigator.of(dctx).pop(false)),
          GwDialogAction(
              label: 'Supprimer',
              primary: true,
              icon: Symbols.delete,
              onPressed: () => Navigator.of(dctx).pop(true)),
        ],
        child: Text(message,
            style: GwType.ui(fontSize: 13.5, color: t.stoneMid, height: 1.6)),
      );
    },
  );
  if (ok != true) return;
  if (!context.mounted) return;
  try {
    await onConfirm();
    if (context.mounted) _heritageToast(context, 'Supprimé');
  } catch (_) {
    if (context.mounted) {
      _heritageToast(context, 'Impossible de supprimer', error: true);
    }
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
                child: Text('PUBLICATIONS',
                    style: GwType.mono(
                        fontSize: 11, letterSpacing: 1.4, color: t.stoneDim)),
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
    showGwDialog(context,
        builder: (_) => _CreateGroupSheet(villageId: village.id));
  }
}

/// Création d'un groupe de discussion de village (dialog Tissage).
class _CreateGroupSheet extends ConsumerStatefulWidget {
  const _CreateGroupSheet({required this.villageId});
  final String villageId;

  @override
  ConsumerState<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends ConsumerState<_CreateGroupSheet> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  String _type = 'GENERAL';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_name.text.trim().length < 2) {
      _heritageToast(context, 'Le nom du groupe est requis', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(createChatGroupProvider.notifier).create(
            villageId: widget.villageId,
            name: _name.text.trim(),
            description:
                _desc.text.trim().isEmpty ? null : _desc.text.trim(),
            type: _type,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        _heritageToast(context, 'Impossible de créer le groupe', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return GwDialog(
      title: 'Nouveau groupe',
      subtitle: 'Une discussion pour ce village',
      icon: Symbols.forum,
      actions: [
        GwDialogAction(
            label: 'Annuler', onPressed: () => Navigator.of(context).maybePop()),
        GwDialogAction(
            label: 'Créer',
            primary: true,
            loading: _saving,
            onPressed: _create),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            style: GwType.ui(fontSize: 14, color: t.stone),
            decoration: gwInputDecoration(context,
                label: 'Nom du groupe', prefixIcon: Symbols.tag),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _desc,
            maxLines: 2,
            style: GwType.ui(fontSize: 14, color: t.stone),
            decoration:
                gwInputDecoration(context, label: 'Description (facultatif)'),
          ),
          const SizedBox(height: 14),
          const GwSectionLabel('Type'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: GwChoicePill(
                label: 'Général',
                icon: Symbols.chat_bubble,
                selected: _type == 'GENERAL',
                onTap: () => setState(() => _type = 'GENERAL'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GwChoicePill(
                label: 'Commission',
                icon: Symbols.groups,
                selected: _type == 'COMMISSION',
                onTap: () => setState(() => _type = 'COMMISSION'),
              ),
            ),
          ]),
        ],
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
                      hintText: 'Écrire au groupe…',
                      hintStyle: GwType.ui(color: t.stoneDim, fontSize: 13),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(GwTokens.rPill),
                        borderSide: BorderSide(color: t.lineMid),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(GwTokens.rPill),
                        borderSide:
                            const BorderSide(color: GwTokens.gold, width: 1.5),
                      ),
                      filled: true,
                      fillColor: t.inkCard,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
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
                      maxWidth: MediaQuery.of(context).size.width * 0.72),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? t.goldBg : t.inkLift,
                    border: isMe
                        ? Border.all(
                            color: GwTokens.gold.withValues(alpha: 0.3))
                        : null,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 6),
                      bottomRight: Radius.circular(isMe ? 6 : 18),
                    ),
                  ),
                  child: Text(message.content,
                      style: GwType.ui(
                          fontSize: 14.5, color: t.stone, height: 1.55)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                  child: Text(time,
                      style: GwType.mono(
                          fontSize: 10,
                          letterSpacing: 0.5,
                          color: t.stoneFaint)),
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

class _StatsRow extends ConsumerWidget {
  const _StatsRow({required this.village});
  final VillageModel village;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final dynasty = ref.watch(villageDynastyProvider(village.id)).valueOrNull;
    final milestones =
        ref.watch(villageMilestonesProvider(village.id)).valueOrNull;
    return Container(
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: t.line))),
      child: Row(
        children: [
          _stat(context, '${village.memberCount}', 'MEMBRES', isGold: true),
          _stat(context, village.foundedYear?.toString() ?? '—', 'FONDATION'),
          _stat(context, dynasty != null ? '${dynasty.length}' : '—', 'CHEFS'),
          _stat(context, milestones != null ? '${milestones.length}' : '—',
              'TEMPS FORTS'),
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
      this.trailing,
      this.isMonoTitle = false});
  final String title;
  final Widget child;
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
                      : Text(title,
                          style:
                              GwType.display(fontSize: 20, color: t.stone),
                          overflow: TextOverflow.ellipsis),
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

// ── Members Grid (aperçu lignée) ──

/// Libellé de rôle réel dérivé du type d'adhésion au village.
String _memberRoleLabel(String type) {
  switch (type.toUpperCase()) {
    case 'AMBASSADOR':
      return 'Ambassadeur';
    case 'MEMBER':
      return 'Membre';
    case 'FOLLOW':
      return 'Abonné';
    default:
      return 'Membre';
  }
}

class _MembersGrid extends StatelessWidget {
  const _MembersGrid({required this.members});
  final List<VillageMemberModel> members;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final cellColors = [
      GwTokens.azureBg,
      GwTokens.sageBg,
      GwTokens.emberBg,
      t.goldBg
    ];
    final cellTexts = [t.azureText, t.sageText, t.emberText, t.goldText];

    if (members.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Text('Aucun membre pour l\'instant',
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
            childAspectRatio: 1.3,
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
                const SizedBox(height: 3),
                Text(_memberRoleLabel(m.type),
                    style: GwType.mono(
                        fontSize: 9, letterSpacing: 0.5, color: t.stoneFaint)),
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

  /// Initiales calculées d'un nom complet (1 à 2 lettres, MAJ).
  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final w = parts.first;
      return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  /// En-tête chef : avatar (image ou initiales) + nom serif + rôle + ancienneté.
  /// [chief] null → « Chef non désigné » discret.
  Widget _header(BuildContext context, VillageChief? chief) {
    final t = GwTokens.of(context);
    final hasChief = chief != null && chief.displayName.trim().isNotEmpty;
    final name = hasChief ? chief.displayName.trim() : 'Chef non désigné';
    final avatarUrl = chief?.avatarUrl;

    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasChief
                    ? const LinearGradient(
                        colors: [GwTokens.goldLight, GwTokens.gold])
                    : null,
                color: hasChief ? null : t.inkLift,
                border: Border.all(
                    color: hasChief ? t.goldLine : t.lineMid, width: 1.5),
                image: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? DecorationImage(
                        image: NetworkImage(avatarUrl), fit: BoxFit.cover)
                    : null,
              ),
              child: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? null
                  : Center(
                      child: Text(hasChief ? _initials(name) : '—',
                          style: GwType.display(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: hasChief
                                  ? GwTokens.inkOnGold
                                  : t.stoneFaint))),
            ),
            if (hasChief)
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
              Text(name,
                  style: GwType.display(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: hasChief ? t.stone : t.stoneDim),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(hasChief ? 'Chef du village' : 'Aucun chef désigné',
                      style: GwType.ui(
                          fontSize: 12,
                          color: hasChief ? t.goldText : t.stoneFaint)),
                  if (hasChief) ...[
                    const SizedBox(width: 6),
                    Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            color: GwTokens.gold, shape: BoxShape.circle)),
                  ],
                ],
              ),
              if (hasChief && chief.since != null) ...[
                const SizedBox(height: 2),
                Text('En fonction depuis ${chief.since}',
                    style: GwType.mono(fontSize: 9, color: t.stoneFaint)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Squelette discret pendant le chargement du chef.
  Widget _headerSkeleton(BuildContext context) {
    final t = GwTokens.of(context);
    Widget bar(double w) => Container(
          width: w,
          height: 10,
          decoration: BoxDecoration(
              color: t.inkLift, borderRadius: BorderRadius.circular(3)),
        );
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: t.inkLift,
              border: Border.all(color: t.lineMid, width: 1.5)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bar(120),
              const SizedBox(height: 8),
              bar(80),
            ],
          ),
        ),
      ],
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
    final chiefAsync = ref.watch(villageChiefProvider(widget.village.id));

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
            chiefAsync.when(
              // Erreur : on ne plante pas, on retombe sur un chef générique.
              error: (_, __) => _header(context, null),
              // Chargement : squelette discret (avatar + lignes grisées).
              loading: () => _headerSkeleton(context),
              data: (chief) => _header(context, chief),
            ),
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
    // Ligne de filiation construite depuis la LIGNÉE RÉELLE de l'utilisateur
    // (getMyPerson → familyTree) : vous → parents → aïeuls. Rien d'inventé.
    final meAsync = ref.watch(genealogyNotifierProvider);
    return meAsync.when(
      loading: () => _loader(context),
      error: (_, __) => _empty(context),
      data: (me) {
        final treeAsync = ref.watch(familyTreeProvider(me.id));
        return treeAsync.when(
          loading: () => _loader(context),
          error: (_, __) => _empty(context),
          data: (tree) => _content(context, tree),
        );
      },
    );
  }

  Widget _content(BuildContext context, FamilyTree tree) {
    final t = GwTokens.of(context);
    final me = tree.subject;
    final father = tree.father.isNotEmpty ? tree.father.first : null;
    final mother = tree.mother.isNotEmpty ? tree.mother.first : null;
    final patGP = tree.paternalGP;
    final matGP = tree.maternalGP;
    final ascendants = <PersonGenealogy>[
      if (father != null) father,
      if (mother != null) mother,
      ...patGP,
      ...matGP,
    ];

    if (ascendants.isEmpty) return _empty(context);

    Widget gpNode(PersonGenealogy gp) => _filNode(
        context, _ini(gp), _full(gp), 'Aïeul·e',
        gp.isAlive ? 'Vivant·e' : 'In memoriam',
        GwTokens.sageBg, GwTokens.sageLine, t.sageText);

    final parentBlock = <Widget>[];
    if (father != null) {
      parentBlock.add(_filNode(
          context, _ini(father), _full(father), 'Père',
          father.isAlive ? 'Vivant' : 'In memoriam',
          GwTokens.azureBg, GwTokens.azureLine, t.azureText,
          isMine: true));
      if (patGP.isNotEmpty) {
        parentBlock.add(const SizedBox(height: 6));
        parentBlock.add(_indentWrap(context, patGP.map(gpNode).toList()));
      }
    }
    if (mother != null) {
      if (parentBlock.isNotEmpty) parentBlock.add(const SizedBox(height: 6));
      parentBlock.add(_filNode(
          context, _ini(mother), _full(mother), 'Mère',
          mother.isAlive ? 'Vivante' : 'In memoriam',
          GwTokens.emberBg, GwTokens.emberLine, t.emberText));
      if (matGP.isNotEmpty) {
        parentBlock.add(const SizedBox(height: 6));
        parentBlock.add(_indentWrap(context, matGP.map(gpNode).toList()));
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        children: [
          _filNode(context, _ini(me), _full(me), 'Vous', 'Moi',
              t.goldBg, t.goldLine, t.goldText, isMine: true),
          if (parentBlock.isNotEmpty) _indentWrap(context, parentBlock),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: GwTokens.sageBg,
                borderRadius: BorderRadius.circular(GwTokens.rBtn),
                border: Border.all(color: GwTokens.sageLine)),
            child: Row(children: [
              Icon(Symbols.account_tree, size: 14, color: t.sageText),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    '${ascendants.length} ascendant${ascendants.length > 1 ? 's' : ''} dans votre lignée',
                    style: GwType.ui(fontSize: 12, color: t.sageText)),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _loader(BuildContext context) {
    final t = GwTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Row(children: [
        SizedBox(
            width: 16,
            height: 16,
            child:
                CircularProgressIndicator(strokeWidth: 2, color: t.goldText)),
        const SizedBox(width: 10),
        Text('Chargement de votre lignée…',
            style: GwType.ui(fontSize: 12, color: t.stoneDim)),
      ]),
    );
  }

  Widget _empty(BuildContext context) {
    final t = GwTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: t.inkCard,
            borderRadius: BorderRadius.circular(GwTokens.rCard),
            border: Border.all(color: t.line)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Symbols.account_tree, size: 16, color: t.stoneDim),
              const SizedBox(width: 8),
              Text('Lignée à compléter',
                  style: GwType.ui(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: t.stone)),
            ]),
            const SizedBox(height: 6),
            Text(
                'Ajoutez vos parents et aïeuls dans votre arbre pour voir votre ligne de filiation ici.',
                style: GwType.ui(fontSize: 12, color: t.stoneDim, height: 1.5)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => context.go(Routes.genealogy),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Symbols.arrow_forward, size: 15, color: t.goldText),
                const SizedBox(width: 6),
                Text('Ouvrir mon arbre',
                    style: GwType.ui(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: t.goldText)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  String _ini(PersonGenealogy p) {
    final f = p.firstName.trim();
    final l = p.lastName.trim();
    final s = ((f.isNotEmpty ? f[0] : '') + (l.isNotEmpty ? l[0] : ''))
        .toUpperCase();
    return s.isEmpty ? '?' : s;
  }

  String _full(PersonGenealogy p) => '${p.firstName} ${p.lastName}'.trim();

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
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: GwType.ui(
                                      fontSize: 12.5, color: t.stoneMid)),
                              Text(_memberRoleLabel(member.type),
                                  style: GwType.mono(
                                      fontSize: 9, color: t.stoneFaint)),
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
// HELPERS
// ═══════════════════════════════════════════════════════════════

/// Petit helper `let` façon Kotlin pour chaîner sur un nullable.
extension _LetExtension<T> on T {
  R let<R>(R Function(T) op) => op(this);
}
