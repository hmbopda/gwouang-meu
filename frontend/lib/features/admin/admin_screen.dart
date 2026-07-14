import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/responsive/responsive.dart';
import 'package:gwangmeu/core/router/route_names.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/admin/admin_service.dart';

/// Panneau d'administration « Tissage » — tableau des utilisateurs avec
/// changement de rôle et activation/désactivation.
///
/// L'écran se **protège lui-même** : si [adminAccessProvider] n'est pas `true`
/// (non super-admin OU pas web), il affiche « Accès réservé aux administrateurs
/// (web) » au lieu du contenu — il ne plante jamais.
class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  /// Id de l'utilisateur en cours de modification (contrôles désactivés).
  String? _busyId;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final access = ref.watch(adminAccessProvider);

    return Scaffold(
      backgroundColor: t.ink,
      body: SafeArea(
        child: Column(
          children: [
            const GwWeaveBand(),
            _TopBar(
              onBack: _goBack,
              onRefresh: () => ref.invalidate(adminUsersProvider),
              showRefresh: access.valueOrNull == true,
            ),
            Expanded(
              child: access.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: t.goldText),
                ),
                // hasAccess() ne lève jamais — mais par prudence, une erreur
                // est traitée comme un refus (ne pas planter).
                error: (_, __) => _AccessDenied(onBack: _goBack),
                data: (ok) =>
                    ok ? _content(t) : _AccessDenied(onBack: _goBack),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.profile);
    }
  }

  Widget _content(GwTokens t) {
    final usersAsync = ref.watch(adminUsersProvider);
    return usersAsync.when(
      // Garde la liste affichée pendant un rafraîchissement (pas de flash).
      skipLoadingOnReload: true,
      loading: () => Center(
        child: CircularProgressIndicator(color: t.goldText),
      ),
      error: (e, _) => _ErrorState(
        message: _serverMessage(e, 'Impossible de charger les utilisateurs.'),
        onRetry: () => ref.invalidate(adminUsersProvider),
      ),
      data: (users) => _UsersList(
        users: users,
        busyId: _busyId,
        onRole: _changeRole,
        onActive: _changeActive,
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────

  Future<void> _changeRole(AdminUser u, String role) async {
    if (role == u.role || _busyId != null) return;
    setState(() => _busyId = u.id);
    try {
      final updated = await ref.read(adminServiceProvider).setRole(u.id, role);
      ref.invalidate(adminUsersProvider);
      _toast('Rôle mis à jour : ${AdminRoles.label(updated.role)}', ok: true);
    } catch (e) {
      _toast(_serverMessage(e, 'Impossible de changer le rôle.'), ok: false);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _changeActive(AdminUser u, bool active) async {
    if (_busyId != null) return;
    setState(() => _busyId = u.id);
    try {
      final updated =
          await ref.read(adminServiceProvider).setActive(u.id, active);
      ref.invalidate(adminUsersProvider);
      _toast(
        updated.active ? 'Compte activé.' : 'Compte désactivé.',
        ok: true,
      );
    } catch (e) {
      _toast(_serverMessage(e, 'Impossible de changer le statut.'), ok: false);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  void _toast(String message, {required bool ok}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GwType.ui(fontSize: 14, color: Colors.white),
        ),
        backgroundColor: ok ? GwTokens.sage : GwTokens.ember,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
        ),
      ),
    );
  }
}

/// Extrait le message d'erreur du serveur (`message` de l'ApiResponse, ou
/// `data['message']`) d'une [DioException] ; sinon renvoie [fallback].
String _serverMessage(Object e, String fallback) {
  if (e is DioException) {
    final body = e.response?.data;
    if (body is Map) {
      final direct = body['message'];
      if (direct is String && direct.trim().isNotEmpty) return direct.trim();
      final nested = body['data'];
      if (nested is Map && nested['message'] is String) {
        final m = (nested['message'] as String).trim();
        if (m.isNotEmpty) return m;
      }
    }
  }
  return fallback;
}

// ─────────────────────────────────────────────────────────────────
//  Barre supérieure — retour + titre « Administration » + rafraîchir
// ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onBack,
    required this.onRefresh,
    required this.showRefresh,
  });
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final bool showRefresh;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: t.ink,
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Symbols.arrow_back, color: t.stone),
            tooltip: 'Retour',
          ),
          const SizedBox(width: 4),
          Icon(Symbols.admin_panel_settings, size: 22, color: t.goldText),
          const SizedBox(width: 10),
          Text(
            'Administration',
            style: GwType.display(fontSize: 20, color: t.stone),
          ),
          const Spacer(),
          if (showRefresh)
            IconButton(
              onPressed: onRefresh,
              icon: Icon(Symbols.refresh, color: t.stoneMid),
              tooltip: 'Rafraîchir',
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Accès refusé (non super-admin ou pas web)
// ─────────────────────────────────────────────────────────────────

class _AccessDenied extends StatelessWidget {
  const _AccessDenied({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: t.goldBg,
                shape: BoxShape.circle,
                border: Border.all(color: t.goldLine),
              ),
              alignment: Alignment.center,
              child: Icon(Symbols.lock, size: 34, color: t.goldText),
            ),
            const SizedBox(height: 20),
            Text(
              'Accès réservé aux administrateurs (web)',
              textAlign: TextAlign.center,
              style: GwType.display(fontSize: 20, color: t.stone),
            ),
            const SizedBox(height: 8),
            Text(
              "Ce panneau n'est disponible que pour les super-admins, "
              'depuis la version web de GWANG MEU.',
              textAlign: TextAlign.center,
              style: GwType.ui(fontSize: 14, color: t.stoneMid, height: 1.5),
            ),
            const SizedBox(height: 24),
            _PillButton(
              icon: Symbols.arrow_back,
              label: 'Retour',
              onTap: onBack,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  État d'erreur (chargement de la liste)
// ─────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.error, size: 48, color: t.stoneDim),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GwType.ui(fontSize: 15, color: t.stoneMid),
            ),
            const SizedBox(height: 20),
            _PillButton(
              icon: Symbols.refresh,
              label: 'Réessayer',
              onTap: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Liste des utilisateurs (colonne centrée, bornée pour la lisibilité)
// ─────────────────────────────────────────────────────────────────

class _UsersList extends StatelessWidget {
  const _UsersList({
    required this.users,
    required this.busyId,
    required this.onRole,
    required this.onActive,
  });
  final List<AdminUser> users;
  final String? busyId;
  final void Function(AdminUser user, String role) onRole;
  final void Function(AdminUser user, bool active) onActive;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final activeCount = users.where((u) => u.active).length;

    return AdaptiveContent(
      maxWidth: Breakpoints.contentMax,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          // En-tête : compteur + libellé de section.
          Row(
            children: [
              Text(
                'UTILISATEURS · ${users.length}',
                style: GwType.mono(
                  fontSize: 11,
                  letterSpacing: 2,
                  color: t.stoneFaint,
                ),
              ),
              const Spacer(),
              Text(
                '$activeCount actif${activeCount > 1 ? 's' : ''}',
                style: GwType.mono(fontSize: 11, color: t.sageText),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (users.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'Aucun utilisateur.',
                  style: GwType.ui(fontSize: 15, color: t.stoneMid),
                ),
              ),
            )
          else
            for (final u in users) ...[
              _UserRow(
                user: u,
                busy: busyId == u.id,
                // Toute la grille est verrouillée si UNE action est en cours.
                locked: busyId != null && busyId != u.id,
                onRole: (role) => onRole(u, role),
                onActive: (v) => onActive(u, v),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Carte-ligne utilisateur — initiales, nom + email, badge super-admin,
//  sélecteur de rôle (dropdown), interrupteur actif/désactivé.
// ─────────────────────────────────────────────────────────────────

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.busy,
    required this.locked,
    required this.onRole,
    required this.onActive,
  });
  final AdminUser user;
  final bool busy;
  final bool locked;
  final ValueChanged<String> onRole;
  final ValueChanged<bool> onActive;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final isSuper = user.role == AdminRoles.superAdmin;
    final disabled = busy || locked;

    // Identité : initiales + nom + email + badge super-admin.
    final identity = Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: t.goldBg,
            border: Border.all(color: t.goldLine),
          ),
          alignment: Alignment.center,
          child: Text(
            _initial(user),
            style: GwType.display(fontSize: 18, color: t.goldText),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      user.displayName ?? 'Sans nom',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GwType.display(
                        fontSize: 16,
                        color: user.displayName != null
                            ? t.stone
                            : t.stoneDim,
                      ),
                    ),
                  ),
                  if (isSuper) ...[
                    const SizedBox(width: 8),
                    const _SuperAdminBadge(),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GwType.ui(fontSize: 13, color: t.stoneDim),
              ),
            ],
          ),
        ),
      ],
    );

    // Contrôles : sélecteur de rôle + interrupteur actif.
    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoleSelector(
          role: user.role,
          enabled: !disabled,
          onChanged: onRole,
        ),
        const SizedBox(width: 12),
        _ActiveToggle(
          active: user.active,
          enabled: !disabled,
          onChanged: onActive,
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 20,
          height: 20,
          child: busy
              ? CircularProgressIndicator(strokeWidth: 2, color: t.goldText)
              : null,
        ),
      ],
    );

    return Opacity(
      opacity: locked ? 0.5 : 1,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.inkCard,
          borderRadius: BorderRadius.circular(GwTokens.rCard),
          border: Border.all(color: isSuper ? t.goldLine : t.line),
        ),
        // Grand écran : identité + contrôles sur une ligne. Étroit : empilés.
        child: LayoutBuilder(
          builder: (ctx, c) {
            if (c.maxWidth >= 620) {
              return Row(
                children: [
                  Expanded(child: identity),
                  const SizedBox(width: 16),
                  controls,
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                identity,
                const SizedBox(height: 14),
                Align(alignment: Alignment.centerLeft, child: controls),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Badge « SUPER-ADMIN » — pilule or (mono, petites capitales).
class _SuperAdminBadge extends StatelessWidget {
  const _SuperAdminBadge();

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: t.goldBg,
        borderRadius: BorderRadius.circular(GwTokens.rPill),
        border: Border.all(color: t.goldLine),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Symbols.shield_person, size: 12, color: t.goldText, fill: 1),
          const SizedBox(width: 4),
          Text(
            'SUPER-ADMIN',
            style: GwType.mono(
              fontSize: 9,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
              color: t.goldText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sélecteur de rôle — dropdown stylé « Tissage » parmi les 6 rôles.
class _RoleSelector extends StatelessWidget {
  const _RoleSelector({
    required this.role,
    required this.enabled,
    required this.onChanged,
  });
  final String role;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    // S'assure que la valeur courante figure toujours dans les items (évite
    // l'assertion de DropdownButton si le backend renvoie un rôle inconnu).
    final roles = <String>[
      ...AdminRoles.all,
      if (!AdminRoles.all.contains(role)) role,
    ];

    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: t.inkLift,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        border: Border.all(color: t.line),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: role,
          isDense: true,
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          dropdownColor: t.inkCard,
          focusColor: Colors.transparent,
          icon: Icon(Symbols.expand_more, size: 18, color: t.stoneMid),
          style: GwType.ui(fontSize: 13.5, color: t.stone),
          onChanged: enabled
              ? (v) {
                  if (v != null) onChanged(v);
                }
              : null,
          items: [
            for (final r in roles)
              DropdownMenuItem<String>(
                value: r,
                child: Text(
                  AdminRoles.label(r),
                  style: GwType.ui(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: r == AdminRoles.superAdmin
                        ? t.goldText
                        : t.stone,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Interrupteur actif / désactivé — libellé + Switch or.
class _ActiveToggle extends StatelessWidget {
  const _ActiveToggle({
    required this.active,
    required this.enabled,
    required this.onChanged,
  });
  final bool active;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          active ? 'Actif' : 'Inactif',
          style: GwType.mono(
            fontSize: 10,
            letterSpacing: 1,
            color: active ? t.sageText : t.stoneDim,
          ),
        ),
        const SizedBox(width: 6),
        Switch(
          value: active,
          onChanged: enabled ? onChanged : null,
          activeThumbColor: GwTokens.inkOnGold,
          activeTrackColor: t.goldText,
          inactiveThumbColor: t.stoneDim,
          inactiveTrackColor: t.inkLift,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Bouton pilule contour or (partagé : accès refusé, erreur)
// ─────────────────────────────────────────────────────────────────

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GwTokens.rPill),
        child: Container(
          constraints: const BoxConstraints(minHeight: GwTokens.tapTarget),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GwTokens.rPill),
            border: Border.all(color: t.goldLine),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: t.goldText),
              const SizedBox(width: 8),
              Text(
                label,
                style: GwType.ui(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: t.goldText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _initial(AdminUser u) {
  final base = (u.displayName ?? u.email).trim();
  return base.isEmpty ? '?' : base.substring(0, 1).toUpperCase();
}
