import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/router/route_names.dart';
import 'package:gwangmeu/core/theme/app_theme.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/genealogy/services/geo_referentiel_service.dart';
import 'package:gwangmeu/features/villages/services/village_governance_service.dart';
import 'package:gwangmeu/features/villages/villages_notifier.dart';
import 'package:gwangmeu/shared/models/village_model.dart';

// ═══════════════════════════════════════════════════════
// AJOUTER UN VILLAGE — deux voies d'accès « Tissage » :
//   1. Villages hérités (un parent y est déjà membre → admission auto)
//   2. Invitations reçues (accepter / refuser)
// Fond t.ink, cartes blanches liseré, noms serif Fraunces,
// intitulés de section mono MAJ, bouton or, toasts sage.
// ═══════════════════════════════════════════════════════

class AddVillageScreen extends ConsumerWidget {
  const AddVillageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final eligibleAsync = ref.watch(eligibleVillagesProvider);
    final invitationsAsync = ref.watch(villageInvitationsProvider);

    return Scaffold(
      backgroundColor: t.ink,
      body: SafeArea(
        child: Column(
          children: [
            const GwWeaveBand(),
            const _Header(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                children: [
                  // ── Section : rechercher n'importe quelle chefferie ──
                  const _SectionLabel(
                    label: 'Rechercher un village',
                    subtitle:
                        'Tapez le nom d\'une chefferie (ex : Bandenkop). Vous la fondez et la rejoignez en un geste.',
                  ),
                  const SizedBox(height: 10),
                  const _ChefferieSearchSection(),

                  const SizedBox(height: 22),

                  // ── Section : villages hérités ──
                  const _SectionLabel(
                    label: 'Villages dont vous héritez',
                    subtitle:
                        'Un membre de votre famille y appartient déjà — vous y êtes admis automatiquement.',
                  ),
                  const SizedBox(height: 10),
                  eligibleAsync.when(
                    loading: () => const _SectionLoader(),
                    error: (e, _) => _SectionError(
                      onRetry: () => ref.invalidate(eligibleVillagesProvider),
                    ),
                    data: (villages) {
                      if (villages.isEmpty) {
                        return const _EmptyBlock(
                          icon: Symbols.forest,
                          message: 'Aucun village hérité pour l\'instant',
                        );
                      }
                      return Column(
                        children: [
                          for (final v in villages)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _EligibleCard(village: v),
                            ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 22),

                  // ── Section : invitations reçues ──
                  const _SectionLabel(label: 'Invitations reçues'),
                  const SizedBox(height: 10),
                  invitationsAsync.when(
                    loading: () => const _SectionLoader(),
                    error: (e, _) => _SectionError(
                      onRetry: () =>
                          ref.invalidate(villageInvitationsProvider),
                    ),
                    data: (invitations) {
                      final pending = invitations
                          .where((i) => i.status.toUpperCase() == 'PENDING')
                          .toList();
                      final shown =
                          pending.isNotEmpty ? pending : invitations;
                      if (shown.isEmpty) {
                        return const _EmptyBlock(
                          icon: Symbols.mail,
                          message: 'Aucune invitation',
                        );
                      }
                      return Column(
                        children: [
                          for (final inv in shown)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _InvitationCard(invitation: inv),
                            ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 22),

                  // ── Pied : fonder un nouveau village ──
                  Center(
                    child: TextButton.icon(
                      onPressed: () => context.push(Routes.createVillage),
                      icon: Icon(Symbols.add_home, size: 18, color: t.goldText),
                      label: Text(
                        'Fonder un nouveau village',
                        style: GwType.ui(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: t.goldText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// En-tête
// ─────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 20, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: GwTokens.tapTarget,
            height: GwTokens.tapTarget,
            child: IconButton(
              onPressed: () => context.pop(),
              icon: Icon(Symbols.arrow_back, size: 24, color: t.stone),
              tooltip: 'Retour',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'AJOUTER UN VILLAGE',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GwType.mono(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.8,
                color: t.stone,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Intitulé de section
// ─────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.subtitle});

  final String label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GwType.mono(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
            color: t.stoneDim,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: GwType.ui(fontSize: 13, color: t.stoneMid, height: 1.5),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────
// Recherche de chefferie → fonder / rejoindre (pont référentiel→communauté)
// ─────────────────────────────────────────

class _ChefferieSearchSection extends ConsumerStatefulWidget {
  const _ChefferieSearchSection();

  @override
  ConsumerState<_ChefferieSearchSection> createState() =>
      _ChefferieSearchSectionState();
}

class _ChefferieSearchSectionState
    extends ConsumerState<_ChefferieSearchSection> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<GeoChefferie> _results = [];
  bool _loading = false;
  String? _busyId; // chefferie en cours de fondation

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    final q = v.trim();
    if (q.length < 2) {
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 320), () async {
      try {
        final res = await ref
            .read(geoReferentielServiceProvider)
            .lookupChefferies(q, limit: 25);
        if (!mounted) return;
        setState(() {
          _results = res;
          _loading = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _results = [];
          _loading = false;
        });
      }
    });
  }

  Future<void> _found(GeoChefferie c) async {
    final id = c.id;
    if (id == null) return;
    setState(() => _busyId = id);
    try {
      final village = await ref
          .read(villageGovernanceServiceProvider)
          .foundVillageFromChefferie(id);
      if (!mounted) return;
      ref.invalidate(myVillagesNotifierProvider);
      ref.invalidate(eligibleVillagesProvider);
      showGwToast(context, 'Vous avez rejoint ${village.name}');
      context.go(Routes.villageDetail(village.id));
    } catch (e) {
      if (mounted) _showError(context, e);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _ctrl,
          onChanged: _onChanged,
          style: GwType.ui(fontSize: 14.5, color: t.stone),
          decoration: InputDecoration(
            hintText: 'Tapez un nom (ex : Bandenkop)',
            hintStyle: GwType.ui(fontSize: 14, color: t.stoneDim),
            prefixIcon: Icon(Symbols.search, size: 20, color: t.stoneDim),
            filled: true,
            fillColor: t.inkLift,
            isDense: true,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GwTokens.rBtn),
              borderSide: BorderSide(color: t.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GwTokens.rBtn),
              borderSide: const BorderSide(color: GwTokens.gold),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          ),
        ),
        if (_loading) ...[
          const SizedBox(height: 8),
          const _SectionLoader(),
        ] else if (_results.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final c in _results)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _chefferieRow(t, c),
            ),
        ] else if (_ctrl.text.trim().length >= 2) ...[
          const SizedBox(height: 8),
          const _EmptyBlock(
            icon: Symbols.search_off,
            message: 'Aucune chefferie trouvée',
          ),
        ],
      ],
    );
  }

  Widget _chefferieRow(GwTokens t, GeoChefferie c) {
    final place = [c.departmentName, c.regionName]
        .where((s) => s != null && s.trim().isNotEmpty)
        .join(' · ');
    final busy = _busyId == c.id;
    return _Card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.displayName,
                  style: GwType.display(
                      fontSize: 17, fontWeight: FontWeight.w600, color: t.stone),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (place.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    place,
                    style: GwType.ui(fontSize: 12.5, color: t.stoneDim),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: _GoldButton(
              label: 'Rejoindre',
              loading: busy,
              onPressed: () => _found(c),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Carte village hérité
// ─────────────────────────────────────────

class _EligibleCard extends ConsumerStatefulWidget {
  const _EligibleCard({required this.village});

  final VillageModel village;

  @override
  ConsumerState<_EligibleCard> createState() => _EligibleCardState();
}

class _EligibleCardState extends ConsumerState<_EligibleCard> {
  bool _loading = false;

  Future<void> _join() async {
    setState(() => _loading = true);
    final village = widget.village;
    try {
      final result = await ref
          .read(villageGovernanceServiceProvider)
          .requestMembership(village.id);

      if (!mounted) return;

      if (result.member) {
        showGwToast(context, 'Vous avez rejoint ${village.name}');
        ref.invalidate(eligibleVillagesProvider);
        ref.invalidate(myVillagesNotifierProvider);
        context.go(Routes.villageDetail(village.id));
      } else {
        // Demande enregistrée sans admission automatique.
        showGwToast(context, 'Demande envoyée pour ${village.name}');
        ref.invalidate(eligibleVillagesProvider);
      }
    } catch (e) {
      if (mounted) _showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final v = widget.village;
    final place = [v.region, v.country]
        .where((s) => s != null && s.trim().isNotEmpty)
        .join(' · ');

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            v.name,
            style: GwType.display(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: t.stone,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (place.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              place,
              style: GwType.ui(fontSize: 13, color: t.stoneDim),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Symbols.group, size: 15, color: t.stoneFaint),
              const SizedBox(width: 5),
              Text(
                '${v.memberCount} ${v.memberCount > 1 ? "membres" : "membre"}',
                style: GwType.mono(
                  fontSize: 12,
                  letterSpacing: 0.5,
                  color: t.stoneFaint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _GoldButton(
            label: 'Rejoindre',
            loading: _loading,
            onPressed: _join,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Carte invitation
// ─────────────────────────────────────────

class _InvitationCard extends ConsumerStatefulWidget {
  const _InvitationCard({required this.invitation});

  final VillageInvitation invitation;

  @override
  ConsumerState<_InvitationCard> createState() => _InvitationCardState();
}

class _InvitationCardState extends ConsumerState<_InvitationCard> {
  bool _loading = false;

  Future<void> _accept() async {
    setState(() => _loading = true);
    final inv = widget.invitation;
    try {
      await ref
          .read(villageGovernanceServiceProvider)
          .acceptInvitation(inv.id);

      if (!mounted) return;
      showGwToast(context, 'Vous avez rejoint ${inv.villageName}');
      ref.invalidate(villageInvitationsProvider);
      ref.invalidate(myVillagesNotifierProvider);
      ref.invalidate(eligibleVillagesProvider);
      context.go(Routes.villageDetail(inv.villageId));
    } catch (e) {
      if (mounted) _showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _decline() async {
    setState(() => _loading = true);
    final inv = widget.invitation;
    try {
      await ref
          .read(villageGovernanceServiceProvider)
          .declineInvitation(inv.id);

      if (!mounted) return;
      showGwToast(context, 'Invitation refusée');
      ref.invalidate(villageInvitationsProvider);
    } catch (e) {
      if (mounted) _showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final inv = widget.invitation;
    final message = inv.message?.trim();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            inv.villageName,
            style: GwType.display(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: t.stone,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'invité par ${inv.invitedByName}',
            style: GwType.ui(fontSize: 13, color: t.stoneDim),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (message != null && message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: t.inkLift,
                borderRadius: BorderRadius.circular(GwTokens.rBtn),
              ),
              child: Text(
                message,
                style: GwType.quote(fontSize: 14, color: t.stoneMid),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _GoldButton(
                  label: 'Accepter',
                  loading: _loading,
                  onPressed: _accept,
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: _loading ? null : _decline,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, GwTokens.tapTarget),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: Text(
                  'Refuser',
                  style: GwType.ui(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: t.stoneDim,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Bloc carte blanche liseré
// ─────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.inkCard,
        borderRadius: BorderRadius.circular(GwTokens.rCard),
        border: Border.all(color: t.line),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────
// Bouton or plein
// ─────────────────────────────────────────

class _GoldButton extends StatelessWidget {
  const _GoldButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GwTokens.tapTarget,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: GwTokens.gold,
          foregroundColor: GwTokens.inkOnGold,
          disabledBackgroundColor: GwTokens.gold.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: GwTokens.inkOnGold,
                ),
              )
            : Text(
                label,
                style: GwType.ui(fontSize: 14, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// États vides / chargement / erreur
// ─────────────────────────────────────────

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GwTokens.rCard),
        border: Border.all(color: t.line),
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: t.stoneFaint),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GwType.ui(fontSize: 13, color: t.stoneDim),
          ),
        ],
      ),
    );
  }
}

class _SectionLoader extends StatelessWidget {
  const _SectionLoader();

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: t.goldText),
        ),
      ),
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GwTokens.rCard),
        border: Border.all(color: t.line),
      ),
      child: Column(
        children: [
          Icon(Symbols.wifi_off, size: 28, color: t.stoneDim),
          const SizedBox(height: 10),
          Text(
            'Impossible de charger',
            style: GwType.ui(fontSize: 13, color: t.stoneDim),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Réessayer',
              style: GwType.ui(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: t.goldText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Erreur — snackbar ember
// ─────────────────────────────────────────

void _showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Une erreur est survenue. Réessayez.',
        style: GwType.ui(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      backgroundColor: GwTokens.ember,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GwTokens.rPill),
      ),
    ),
  );
}
