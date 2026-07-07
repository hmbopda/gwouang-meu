import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/router/breadcrumb_provider.dart';
import 'package:gwangmeu/core/router/route_names.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/home/home_screen.dart';
import 'package:gwangmeu/features/villages/villages_notifier.dart';
import 'package:gwangmeu/shared/models/village_model.dart';
import 'package:gwangmeu/shared/widgets/loading_overlay.dart';

/// Encre foncée posée sur les surfaces or / teintées (maquette : #0C0B0F).
const _onTint = Color(0xFF0C0B0F);

/// Écran Villages « Tissage » (maquette #1e — Concept Villages vivants).
///
/// - Bande tissée signature + titre Fraunces 22 + action « Fonder » (44 px)
/// - Recherche permanente (50 px, inkLift, rayon 14) + rangée de filtres chips
/// - Carte « Mon village » : bannière motif tissé, badge dialecte mono,
///   ligne d'activité live (point ember pulsant), rayon 20
/// - Rangées découverte : tuile initiale 48 px Fraunces teintée par région,
///   activité mono sage MAJUSCULES, bouton « Rejoindre » outline or 40 px
class VillagesScreen extends ConsumerStatefulWidget {
  const VillagesScreen({super.key});

  @override
  ConsumerState<VillagesScreen> createState() => _VillagesScreenState();
}

class _VillagesScreenState extends ConsumerState<VillagesScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  int _filterIndex = 0;

  static const _filters = ['Tous', 'Cameroun', 'Bassa', 'Diaspora', 'Vérifiés'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final desktop = isDesktopLayout(context);
    final t = GwTokens.of(context);

    final content = Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, desktop ? 16 : 10, 20, 0),
          child: _searchField(t),
        ),
        const SizedBox(height: 10),
        _filterRow(t),
        const SizedBox(height: 2),
        Expanded(child: _discoveryList(t)),
      ],
    );

    // Desktop : rendu dans le shell (IconRail + TopBar) — pas de Scaffold.
    if (desktop) return content;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const GwWeaveBand(),
            _header(t),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  // ── Header mobile — titre Fraunces 22 + pilule « Fonder » 44 px ──

  Widget _header(GwTokens t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Villages',
              style: GwType.display(
                  fontSize: 22, fontWeight: FontWeight.w700, color: t.stone),
            ),
          ),
          Material(
            color: GwTokens.gold,
            borderRadius: BorderRadius.circular(GwTokens.rPill),
            child: InkWell(
              onTap: () => context.push(Routes.createVillage),
              borderRadius: BorderRadius.circular(GwTokens.rPill),
              child: Container(
                height: GwTokens.tapTarget,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Symbols.add, size: 18, color: _onTint),
                    const SizedBox(width: 8),
                    Text(
                      'Fonder',
                      style: GwType.ui(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: _onTint),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Recherche permanente — 50 px, inkLift, rayon 14 ──

  Widget _searchField(GwTokens t) {
    return Container(
      height: 50,
      padding: const EdgeInsets.only(left: 16, right: 4),
      decoration: BoxDecoration(
        color: t.inkLift,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
      ),
      child: Row(
        children: [
          Icon(Symbols.search, size: 20, color: t.stoneDim),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onQueryChanged,
              style: GwType.ui(fontSize: 14.5, color: t.stone),
              cursorColor: t.goldText,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'Village, dialecte, région…',
                hintStyle: GwType.ui(fontSize: 14.5, color: t.stoneDim),
              ),
            ),
          ),
          if (_query.isNotEmpty)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _clearSearch,
                borderRadius: BorderRadius.circular(GwTokens.rBtn),
                child: SizedBox(
                  width: GwTokens.tapTarget,
                  height: GwTokens.tapTarget,
                  child: Icon(Symbols.close, size: 18, color: t.stoneMid),
                ),
              ),
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }

  void _onQueryChanged(String q) {
    setState(() => _query = q);
    if (q.length >= 2 || q.isEmpty) {
      ref.read(villagesNotifierProvider.notifier).search(q);
    }
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() => _query = '');
    ref.read(villagesNotifierProvider.notifier).refresh();
  }

  // ── Filtres chips — pilules rayon 99, cible tactile 44 px ──

  Widget _filterRow(GwTokens t) {
    return SizedBox(
      height: GwTokens.tapTarget,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => _filterChip(t, i),
      ),
    );
  }

  Widget _filterChip(GwTokens t, int i) {
    final active = i == _filterIndex;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _filterIndex = i),
      child: Center(
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? t.goldBg : t.inkLift,
            borderRadius: BorderRadius.circular(GwTokens.rPill),
            border: active
                ? Border.all(color: GwTokens.gold.withValues(alpha: 0.30))
                : null,
          ),
          child: Text(
            _filters[i],
            style: GwType.ui(
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color: active ? t.goldText : t.stoneMid,
            ),
          ),
        ),
      ),
    );
  }

  List<VillageModel> _applyFilter(List<VillageModel> villages) {
    switch (_filterIndex) {
      case 1: // Cameroun
        return villages
            .where((v) => v.country.toLowerCase().contains('cameroun'))
            .toList();
      case 2: // Bassa
        return villages
            .where((v) =>
                (v.primaryDialect ?? '').toLowerCase().contains('bassa'))
            .toList();
      case 3: // Diaspora
        return villages
            .where((v) => !v.country.toLowerCase().contains('cameroun'))
            .toList();
      case 4: // Vérifiés
        return villages.where((v) => v.verified).toList();
      default:
        return villages;
    }
  }

  // ── Liste — Mon village + rangées découverte ──

  Widget _discoveryList(GwTokens t) {
    final villagesState = ref.watch(villagesNotifierProvider);
    final searching = _query.isNotEmpty;

    return villagesState.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: 6,
        itemBuilder: (_, __) => const ShimmerCard(height: 88),
      ),
      error: (e, _) => _ErrorState(
        onRetry: () => ref.read(villagesNotifierProvider.notifier).refresh(),
      ),
      data: (villages) {
        final filtered = _applyFilter(villages);
        return RefreshIndicator(
          color: t.goldText,
          onRefresh: _refreshAll,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 4, bottom: 24),
            children: [
              if (!searching) const _MyVillageSection(),
              _SectionLabel(searching ? 'RÉSULTATS' : 'DÉCOUVRIR'),
              if (filtered.isEmpty)
                _EmptyState(
                  icon:
                      searching ? Symbols.search_off : Symbols.holiday_village,
                  message: searching
                      ? 'Aucun résultat'
                      : _filterIndex != 0
                          ? 'Aucun village pour ce filtre'
                          : 'Aucun village pour le moment',
                )
              else
                ...filtered.map(
                  (v) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _VillageRow(village: v),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _refreshAll() async {
    ref.invalidate(myVillagesNotifierProvider);
    await ref.read(villagesNotifierProvider.notifier).refresh();
  }
}

// ─────────────────────────────────────────────────────────────────
//  Section « Mon village » — carte pleine avec bannière tissée
// ─────────────────────────────────────────────────────────────────

class _MyVillageSection extends ConsumerWidget {
  const _MyVillageSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myVillages = ref.watch(myVillagesNotifierProvider);
    return myVillages.when(
      loading: () => const ShimmerCard(height: 210),
      error: (_, __) => const SizedBox.shrink(),
      data: (mine) => mine.isEmpty
          ? const SizedBox.shrink()
          : _MyVillageCard(village: mine.first),
    );
  }
}

class _MyVillageCard extends ConsumerWidget {
  const _MyVillageCard({required this.village});

  final VillageModel village;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
      child: Material(
        color: t.inkCard,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GwTokens.rCardLg),
          side: BorderSide(color: GwTokens.gold.withValues(alpha: 0.25)),
        ),
        child: InkWell(
          onTap: () => _openVillage(context, ref, village),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bannière motif tissé (bandes gold/sage/ember ~5-16 %)
                  const SizedBox(
                    height: 110,
                    width: double.infinity,
                    child: CustomPaint(painter: _WeaveBannerPainter()),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 30, 18, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                village.name,
                                style: GwType.display(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w600,
                                    color: t.stone),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (village.verified) ...[
                              const SizedBox(width: 8),
                              Icon(Symbols.verified,
                                  size: 17, fill: 1, color: t.goldText),
                            ],
                            const Spacer(),
                            Text(
                              '${_formatCount(village.memberCount)} '
                              'membre${village.memberCount > 1 ? 's' : ''}',
                              style:
                                  GwType.ui(fontSize: 13, color: t.stoneFaint),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (village.primaryDialect != null &&
                                village.primaryDialect!.isNotEmpty)
                              _dialectChip(t),
                            _liveChip(t),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Symbols.location_on,
                                size: 15, color: t.stoneDim),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                [
                                  village.country,
                                  if (village.region != null &&
                                      village.region!.isNotEmpty)
                                    village.region!,
                                ].join(' · '),
                                style:
                                    GwType.ui(fontSize: 13, color: t.stoneMid),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Badge mono « MON VILLAGE »
              Positioned(
                top: 12,
                left: 14,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: t.ink,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'MON VILLAGE',
                    style: GwType.mono(
                        fontSize: 10, color: t.goldText, letterSpacing: 2),
                  ),
                ),
              ),
              // Tuile initiale 56 px chevauchant la bannière
              Positioned(
                top: 78,
                left: 18,
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: GwTokens.gold,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: t.inkCard, width: 4),
                  ),
                  child: Text(
                    _initial(village.name),
                    style: GwType.display(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _onTint),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialectChip(GwTokens t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: t.goldBg,
        borderRadius: BorderRadius.circular(GwTokens.rPill),
      ),
      child: Text(
        'DIALECTE ${village.primaryDialect!.toUpperCase()}',
        style: GwType.mono(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: t.goldText,
            letterSpacing: 1),
      ),
    );
  }

  Widget _liveChip(GwTokens t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: GwTokens.emberBg,
        borderRadius: BorderRadius.circular(GwTokens.rPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PulsingDot(),
          const SizedBox(width: 6),
          Text(
            'Live en cours',
            style: GwType.ui(
                fontSize: 12, fontWeight: FontWeight.w600, color: t.emberText),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Rangée découverte — tuile teintée, activité mono sage, Rejoindre
// ─────────────────────────────────────────────────────────────────

class _VillageRow extends ConsumerWidget {
  const _VillageRow({required this.village});

  final VillageModel village;

  /// Teintes par région : or, sage, azure, rose (GwTokens.rose).
  static const _tints = [
    GwTokens.gold,
    Color(0xFF70C090),
    Color(0xFF7AA8E0),
    GwTokens.rose,
  ];

  /// Ligne d'activité — placeholder déterministe en attendant l'API
  /// d'activité village (lives, récits, conversations).
  static const _activities = [
    'ACTIF CETTE SEMAINE',
    'NOUVEAUX MEMBRES RÉCENTS',
    'RÉCITS PARTAGÉS',
    'CONVERSATIONS EN COURS',
  ];

  Color get _tint => _tints[
      (village.region ?? village.country).toLowerCase().hashCode.abs() %
          _tints.length];

  String get _activity =>
      _activities[village.id.hashCode.abs() % _activities.length];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final mine = ref.watch(myVillagesNotifierProvider).valueOrNull ??
        const <VillageModel>[];
    final joined = mine.any((v) => v.id == village.id);

    final meta = [
      village.country,
      if (village.primaryDialect != null && village.primaryDialect!.isNotEmpty)
        village.primaryDialect!,
      '${_formatCount(village.memberCount)} '
          'membre${village.memberCount > 1 ? 's' : ''}',
    ].join(' · ');

    return Material(
      color: t.inkCard,
      borderRadius: BorderRadius.circular(GwTokens.rCard),
      child: InkWell(
        onTap: () => _openVillage(context, ref, village),
        borderRadius: BorderRadius.circular(GwTokens.rCard),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Tuile initiale 48 px, rayon 14, Fraunces 19 w700
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _tint,
                  borderRadius: BorderRadius.circular(GwTokens.rBtn),
                ),
                child: Text(
                  _initial(village.name),
                  style: GwType.display(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: _onTint),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            village.name,
                            style: GwType.ui(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: t.stone),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (village.verified) ...[
                          const SizedBox(width: 6),
                          Icon(Symbols.verified,
                              size: 15, fill: 1, color: t.goldText),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meta,
                      style: GwType.ui(fontSize: 12.5, color: t.stoneDim),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _activity,
                      style: GwType.mono(
                          fontSize: 11.5, color: t.sageText, letterSpacing: 1),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (joined)
                _joinedChip(t)
              else
                _JoinButton(onTap: () => _join(context, ref)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _joinedChip(GwTokens t) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: GwTokens.sageBg,
        borderRadius: BorderRadius.circular(GwTokens.rPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Symbols.check, size: 15, color: t.sageText),
          const SizedBox(width: 5),
          Text(
            'Rejoint',
            style: GwType.ui(
                fontSize: 12.5, fontWeight: FontWeight.w600, color: t.sageText),
          ),
        ],
      ),
    );
  }

  Future<void> _join(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(myVillagesNotifierProvider.notifier)
          .joinVillage(village.id);
      messenger.showSnackBar(
          _gwSnack('Vous avez rejoint ${village.name}', GwTokens.sage));
    } catch (_) {
      messenger.showSnackBar(
          _gwSnack('Impossible de rejoindre le village', GwTokens.ember));
    }
  }
}

/// Bouton « Rejoindre » — outline or 40 px, cible tactile 44 px.
class _JoinButton extends StatelessWidget {
  const _JoinButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GwTokens.rPill),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(GwTokens.rPill),
              border: Border.all(color: t.goldLine, width: 1.5),
            ),
            child: Text(
              'Rejoindre',
              style: GwType.ui(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: t.goldText),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  États vides / erreur, label de section
// ─────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      child: Text(
        label,
        style: GwType.mono(fontSize: 10, color: t.stoneFaint, letterSpacing: 2),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: t.stoneDim),
            const SizedBox(height: 12),
            Text(message, style: GwType.ui(fontSize: 14, color: t.stoneMid)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Symbols.wifi_off, size: 44, color: t.stoneDim),
          const SizedBox(height: 12),
          Text('Impossible de charger',
              style: GwType.ui(fontSize: 14, color: t.stoneMid)),
          const SizedBox(height: 14),
          Material(
            color: t.inkLift,
            borderRadius: BorderRadius.circular(GwTokens.rPill),
            child: InkWell(
              onTap: onRetry,
              borderRadius: BorderRadius.circular(GwTokens.rPill),
              child: Container(
                height: GwTokens.tapTarget,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Symbols.refresh, size: 18, color: t.goldText),
                    const SizedBox(width: 8),
                    Text(
                      'Réessayer',
                      style: GwType.ui(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: t.goldText),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Éléments partagés
// ─────────────────────────────────────────────────────────────────

/// Navigation vers le détail avec fil d'Ariane (logique conservée).
void _openVillage(BuildContext context, WidgetRef ref, VillageModel village) {
  ref
      .read(breadcrumbProvider.notifier)
      .reset(const BreadcrumbEntry(label: 'Villages', route: Routes.villages));
  ref.read(breadcrumbProvider.notifier).push(BreadcrumbEntry(
      label: village.name, route: Routes.villageDetail(village.id)));
  context.push(Routes.villageDetail(village.id));
}

String _initial(String name) {
  final trimmed = name.trim();
  return trimmed.isEmpty ? 'V' : trimmed.substring(0, 1).toUpperCase();
}

/// « 1 247 » — séparateur de milliers (espace fine insécable).
String _formatCount(int n) {
  if (n < 1000) return '$n';
  return '${n ~/ 1000} ${(n % 1000).toString().padLeft(3, '0')}';
}

SnackBar _gwSnack(String message, Color background) {
  return SnackBar(
    content: Text(
      message,
      style: GwType.ui(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFF0EBE1)),
    ),
    backgroundColor: background,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GwTokens.rBtn)),
  );
}

/// Point ember pulsant (ligne d'activité live).
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(_ctrl),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: t.emberText, shape: BoxShape.circle),
      ),
    );
  }
}

/// Bannière « Mon village » — bandes diagonales tissées gold/sage/ember
/// translucides (équivalent du repeating-linear-gradient -45° de la maquette).
class _WeaveBannerPainter extends CustomPainter {
  const _WeaveBannerPainter();

  static const _bands = [
    Color(0x29C9A84C), // gold 16 %
    Color(0x0DC9A84C), // gold 5 %
    Color(0x242A7A5C), // sage 14 %
    Color(0x0DC9A84C), // gold 5 %
    Color(0x1FC4583A), // ember 12 %
    Color(0x0DC9A84C), // gold 5 %
  ];

  static const double _bandWidth = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final ext = size.width + size.height;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.rotate(-math.pi / 4);
    var i = 0;
    for (double x = -ext; x < ext; x += _bandWidth) {
      paint.color = _bands[i % _bands.length];
      canvas.drawRect(Rect.fromLTWH(x, -ext, _bandWidth, ext * 3), paint);
      i++;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WeaveBannerPainter oldDelegate) => false;
}
