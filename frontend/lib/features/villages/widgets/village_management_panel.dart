import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/villages/services/village_governance_service.dart';
import 'package:gwangmeu/features/villages/villages_notifier.dart';
import 'package:gwangmeu/shared/models/village_member_model.dart';

// ═══════════════════════════════════════════════════════════════════
//  GÉRER LE VILLAGE — panneau de gouvernance déléguée (chef/admin/délégué)
//  Charte « Tissage » : GwTokens / GwType exclusivement.
// ═══════════════════════════════════════════════════════════════════

/// Permissions déléguables, avec libellé FR lisible.
const _kPermissionLabels = <String, String>{
  'VALIDATE_MEMBERS': 'Valider les membres',
  'MODERATE_POSTS': 'Modérer les publications',
  'VALIDATE_CULTURE': 'Valider le patrimoine',
  'VALIDATE_SUCCESSION': 'Valider la succession',
  'MANAGE_ROLES': 'Gérer les rôles',
  'EDIT_VILLAGE': 'Modifier le village',
};

/// Libellé FR court des types de validation culturelle.
const _kCultureKindLabels = <String, String>{
  'CLAN': 'Clan',
  'CHEFFERIE': 'Chefferie',
  'CHIEF_LINE': 'Lignée du chef',
};

String _permLabel(String p) => _kPermissionLabels[p] ?? p;

/// Ouvre le panneau « GÉRER LE VILLAGE ».
///
/// Bottom sheet plein écran sur mobile, dialog large sur grand écran.
/// Le contenu ne montre que les sections autorisées par [MyVillagePermissions].
Future<void> showVillageManagement(
  BuildContext context,
  String villageId,
) async {
  final wide = MediaQuery.of(context).size.width >= 720;
  if (wide) {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        backgroundColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
          child: _VillageManagementPanel(villageId: villageId),
        ),
      ),
    );
  } else {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: _VillageManagementPanel(villageId: villageId),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  Panneau racine — résout les permissions puis compose les sections.
// ───────────────────────────────────────────────────────────────────

class _VillageManagementPanel extends ConsumerWidget {
  const _VillageManagementPanel({required this.villageId});

  final String villageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final permsAsync = ref.watch(villageMyPermissionsProvider(villageId));

    return Container(
      decoration: BoxDecoration(
        color: t.ink,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GwWeaveBand(),
          const _Header(),
          Flexible(
            child: permsAsync.when(
              loading: () => _CenteredBox(
                child: CircularProgressIndicator(color: t.goldText),
              ),
              error: (e, _) => _CenteredBox(
                child: Text(
                  'Impossible de charger vos droits.',
                  style: GwType.ui(fontSize: 14, color: t.stoneMid),
                  textAlign: TextAlign.center,
                ),
              ),
              data: (perms) => _PanelBody(
                villageId: villageId,
                perms: perms,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GOUVERNANCE',
                  style: GwType.mono(
                    fontSize: 10,
                    color: t.goldText,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gérer le village',
                  style: GwType.display(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: t.stone,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.close_rounded, color: t.stoneMid, size: 22),
            tooltip: 'Fermer',
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  Corps — onglets dynamiques selon les permissions.
// ───────────────────────────────────────────────────────────────────

class _PanelBody extends StatefulWidget {
  const _PanelBody({required this.villageId, required this.perms});

  final String villageId;
  final MyVillagePermissions perms;

  @override
  State<_PanelBody> createState() => _PanelBodyState();
}

class _PanelBodyState extends State<_PanelBody>
    with SingleTickerProviderStateMixin {
  late final List<_Tab> _tabs;
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    final p = widget.perms;
    _tabs = [
      if (p.chief || p.has('MANAGE_ROLES'))
        const _Tab('RÔLES & DROITS', _SectionKind.roles),
      if (p.has('VALIDATE_MEMBERS'))
        const _Tab('ADHÉSIONS', _SectionKind.joins),
      if (p.has('VALIDATE_CULTURE'))
        const _Tab('PATRIMOINE', _SectionKind.culture),
      if (p.has('VALIDATE_SUCCESSION'))
        const _Tab('SUCCESSION', _SectionKind.succession),
    ];
    _controller = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);

    if (_tabs.isEmpty) {
      return _CenteredBox(
        child: Text(
          "Vous n'avez pas de droits de gestion sur ce village.",
          style: GwType.ui(fontSize: 14, color: t.stoneMid),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: t.line)),
          ),
          child: TabBar(
            controller: _controller,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: t.goldText,
            indicatorWeight: 2,
            dividerColor: Colors.transparent,
            labelColor: t.goldText,
            unselectedLabelColor: t.stoneDim,
            labelPadding: const EdgeInsets.symmetric(horizontal: 14),
            labelStyle: GwType.mono(
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: GwType.mono(
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w500,
            ),
            tabs: [for (final tab in _tabs) Tab(height: 42, text: tab.label)],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _controller,
            children: [
              for (final tab in _tabs)
                switch (tab.kind) {
                  _SectionKind.roles =>
                    _RolesSection(villageId: widget.villageId),
                  _SectionKind.joins =>
                    _JoinsSection(villageId: widget.villageId),
                  _SectionKind.culture =>
                    _CultureSection(villageId: widget.villageId),
                  _SectionKind.succession =>
                    _SuccessionSection(villageId: widget.villageId),
                },
            ],
          ),
        ),
      ],
    );
  }
}

enum _SectionKind { roles, joins, culture, succession }

class _Tab {
  const _Tab(this.label, this.kind);
  final String label;
  final _SectionKind kind;
}

// ═══════════════════════════════════════════════════════════════════
//  1) RÔLES & DROITS
// ═══════════════════════════════════════════════════════════════════

class _RolesSection extends ConsumerWidget {
  const _RolesSection({required this.villageId});

  final String villageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final rolesAsync = ref.watch(villageRolesProvider(villageId));

    return _SectionScaffold(
      caption: "L'admin n'agit que sur CE village.",
      action: _GoldButton(
        icon: Icons.add_rounded,
        label: 'Attribuer un rôle',
        onPressed: () => _openGrantDialog(context),
      ),
      child: rolesAsync.when(
        loading: () => _CenteredBox(
          child: CircularProgressIndicator(color: t.goldText),
        ),
        error: (e, _) => _ErrorLine(t: t),
        data: (roles) {
          if (roles.isEmpty) {
            return _EmptyState(
              t: t,
              icon: Icons.workspace_premium_outlined,
              message: 'Aucun rôle délégué pour le moment.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            itemCount: roles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _RoleCard(
              role: roles[i],
              villageId: villageId,
            ),
          );
        },
      ),
    );
  }

  Future<void> _openGrantDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _GrantRoleDialog(villageId: villageId),
    );
  }
}

class _RoleCard extends ConsumerWidget {
  const _RoleCard({required this.role, required this.villageId});

  final VillageRole role;
  final String villageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    return _WhiteCard(
      t: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.title.isEmpty ? 'Rôle délégué' : role.title,
                      style: GwType.ui(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: t.stone,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _shortId(role.userId),
                      style: GwType.mono(
                        fontSize: 10,
                        color: t.stoneDim,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              _RevokeButton(
                t: t,
                onPressed: () => _confirmRevoke(context, ref),
              ),
            ],
          ),
          if (role.permissions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final p in role.permissions) _PermPill(t: t, perm: p),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmRevoke(BuildContext context, WidgetRef ref) async {
    final ok = await _confirm(
      context,
      title: 'Retirer ce rôle ?',
      message: 'Le membre perdra les droits associés sur ce village.',
      confirmLabel: 'Retirer',
      danger: true,
    );
    if (ok != true) return;
    final service = ref.read(villageGovernanceServiceProvider);
    try {
      await service.revokeRole(villageId, role.userId);
      ref.invalidate(villageRolesProvider(villageId));
      if (context.mounted) _snack(context, 'Rôle retiré.');
    } catch (_) {
      if (context.mounted) _snack(context, 'Échec du retrait.', error: true);
    }
  }
}

class _RevokeButton extends StatelessWidget {
  const _RevokeButton({required this.t, required this.onPressed});

  final GwTokens t;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: t.emberText,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          side: const BorderSide(color: GwTokens.emberLine),
        ),
      ),
      icon: const Icon(Icons.person_remove_outlined, size: 16),
      label: Text(
        'Retirer',
        style: GwType.ui(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: t.emberText,
        ),
      ),
    );
  }
}

class _PermPill extends StatelessWidget {
  const _PermPill({required this.t, required this.perm});

  final GwTokens t;
  final String perm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: t.goldBg,
        borderRadius: BorderRadius.circular(GwTokens.rPill),
        border: Border.all(color: t.goldLine),
      ),
      child: Text(
        _permLabel(perm),
        style: GwType.ui(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: t.goldText,
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  Dialog : attribuer un rôle
// ───────────────────────────────────────────────────────────────────

class _RolePreset {
  const _RolePreset(this.title, this.permissions);
  final String title;
  final List<String> permissions;
}

const _kRolePresets = <_RolePreset>[
  _RolePreset('Administrateur du village', [
    'VALIDATE_MEMBERS',
    'MODERATE_POSTS',
    'VALIDATE_CULTURE',
    'VALIDATE_SUCCESSION',
    'MANAGE_ROLES',
    'EDIT_VILLAGE',
  ]),
  _RolePreset('Notable', ['VALIDATE_CULTURE', 'VALIDATE_SUCCESSION']),
  _RolePreset('Modérateur', ['MODERATE_POSTS', 'VALIDATE_MEMBERS']),
];

class _GrantRoleDialog extends ConsumerStatefulWidget {
  const _GrantRoleDialog({required this.villageId});

  final String villageId;

  @override
  ConsumerState<_GrantRoleDialog> createState() => _GrantRoleDialogState();
}

class _GrantRoleDialogState extends ConsumerState<_GrantRoleDialog> {
  final _titleController = TextEditingController();
  String? _selectedUserId;
  final Set<String> _permissions = {};
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _applyPreset(_RolePreset preset) {
    setState(() {
      _titleController.text = preset.title;
      _permissions
        ..clear()
        ..addAll(preset.permissions);
    });
  }

  bool get _canSubmit =>
      _selectedUserId != null &&
      _titleController.text.trim().isNotEmpty &&
      _permissions.isNotEmpty &&
      !_submitting;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final membersAsync = ref.watch(villageMembersProvider(widget.villageId));

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
        child: Container(
          decoration: BoxDecoration(
            color: t.inkCard,
            borderRadius: BorderRadius.circular(GwTokens.rCard),
            border: Border.all(color: t.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GwWeaveBand(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Attribuer un rôle',
                        style: GwType.display(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: t.stone,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded,
                          color: t.stoneMid, size: 20),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(t, 'MEMBRE'),
                      const SizedBox(height: 8),
                      membersAsync.when(
                        loading: () => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: t.goldText),
                          ),
                        ),
                        error: (e, _) => Text(
                          'Membres indisponibles.',
                          style: GwType.ui(fontSize: 13, color: t.emberText),
                        ),
                        data: (members) => _memberPicker(t, members),
                      ),
                      const SizedBox(height: 18),
                      _label(t, 'TITRE'),
                      const SizedBox(height: 8),
                      _titleField(t),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final preset in _kRolePresets)
                            _PresetChip(
                              t: t,
                              label: preset.title,
                              onTap: () => _applyPreset(preset),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _label(t, 'PERMISSIONS'),
                      const SizedBox(height: 8),
                      for (final entry in _kPermissionLabels.entries)
                        _permCheck(t, entry.key, entry.value),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                child: SizedBox(
                  width: double.infinity,
                  child: _GoldButton(
                    icon: Icons.check_rounded,
                    label: _submitting ? 'Attribution…' : 'Attribuer le rôle',
                    onPressed: _canSubmit ? _submit : null,
                    filled: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _memberPicker(GwTokens t, List<VillageMemberModel> members) {
    if (members.isEmpty) {
      return Text(
        'Aucun membre à afficher.',
        style: GwType.ui(fontSize: 13, color: t.stoneMid),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: t.inkLift,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        border: Border.all(color: t.line),
      ),
      constraints: const BoxConstraints(maxHeight: 160),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.all(4),
        itemCount: members.length,
        itemBuilder: (_, i) {
          final m = members[i];
          final selected = _selectedUserId == m.userId;
          return InkWell(
            borderRadius: BorderRadius.circular(GwTokens.rBtn - 4),
            onTap: () => setState(() => _selectedUserId = m.userId),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: selected ? t.goldBg : Colors.transparent,
                borderRadius: BorderRadius.circular(GwTokens.rBtn - 4),
              ),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 18,
                    color: selected ? t.goldText : t.stoneDim,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      m.displayName?.trim().isNotEmpty == true
                          ? m.displayName!
                          : _shortId(m.userId),
                      style: GwType.ui(
                        fontSize: 14,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w400,
                        color: t.stone,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _titleField(GwTokens t) {
    return TextField(
      controller: _titleController,
      onChanged: (_) => setState(() {}),
      style: GwType.ui(fontSize: 14, color: t.stone),
      cursorColor: t.goldText,
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Ex. Notable, Gardien du patrimoine…',
        hintStyle: GwType.ui(fontSize: 14, color: t.stoneDim),
        filled: true,
        fillColor: t.inkLift,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          borderSide: BorderSide(color: t.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          borderSide: BorderSide(color: t.goldLine),
        ),
      ),
    );
  }

  Widget _permCheck(GwTokens t, String perm, String label) {
    final checked = _permissions.contains(perm);
    return InkWell(
      borderRadius: BorderRadius.circular(GwTokens.rBtn),
      onTap: () => setState(() {
        if (checked) {
          _permissions.remove(perm);
        } else {
          _permissions.add(perm);
        }
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: checked ? t.goldText : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: checked ? t.goldText : t.lineMid,
                  width: 1.5,
                ),
              ),
              child: checked
                  ? const Icon(Icons.check_rounded,
                      size: 15, color: GwTokens.inkOnGold)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GwType.ui(fontSize: 14, color: t.stone),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final service = ref.read(villageGovernanceServiceProvider);
    final navigator = Navigator.of(context);
    try {
      await service.grantRole(
        widget.villageId,
        _selectedUserId!,
        _titleController.text.trim(),
        _permissions.toList(),
      );
      ref.invalidate(villageRolesProvider(widget.villageId));
      if (mounted) {
        navigator.pop();
        _snack(context, 'Rôle attribué.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
        _snack(context, "Échec de l'attribution.", error: true);
      }
    }
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.t,
    required this.label,
    required this.onTap,
  });

  final GwTokens t;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(GwTokens.rPill),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: t.inkLift,
          borderRadius: BorderRadius.circular(GwTokens.rPill),
          border: Border.all(color: t.lineMid),
        ),
        child: Text(
          label,
          style: GwType.ui(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: t.stoneMid,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  2) DEMANDES D'ADHÉSION
// ═══════════════════════════════════════════════════════════════════

class _JoinsSection extends ConsumerWidget {
  const _JoinsSection({required this.villageId});

  final String villageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final joinsAsync = ref.watch(villagePendingJoinsProvider(villageId));

    return _SectionScaffold(
      caption: 'Validez ou refusez les demandes de rattachement.',
      child: joinsAsync.when(
        loading: () => _CenteredBox(
          child: CircularProgressIndicator(color: t.goldText),
        ),
        error: (e, _) => _ErrorLine(t: t),
        data: (joins) {
          if (joins.isEmpty) {
            return _EmptyState(
              t: t,
              icon: Icons.how_to_reg_outlined,
              message: 'Aucune demande en attente.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            itemCount: joins.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) =>
                _JoinCard(request: joins[i], villageId: villageId),
          );
        },
      ),
    );
  }
}

class _JoinCard extends ConsumerStatefulWidget {
  const _JoinCard({required this.request, required this.villageId});

  final VillageJoinRequest request;
  final String villageId;

  @override
  ConsumerState<_JoinCard> createState() => _JoinCardState();
}

class _JoinCardState extends ConsumerState<_JoinCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final r = widget.request;
    return _WhiteCard(
      t: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _shortId(r.userId),
            style: GwType.ui(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: t.stone,
            ),
          ),
          if (r.reason?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              r.reason!,
              style: GwType.ui(fontSize: 13, color: t.stoneMid, height: 1.35),
            ),
          ],
          if (r.autoReason?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 8),
            _InfoBadge(
              t: t,
              icon: Icons.auto_awesome_outlined,
              text: r.autoReason!,
              tone: _Tone.sage,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SmallAction(
                  t: t,
                  label: 'Approuver',
                  icon: Icons.check_rounded,
                  tone: _Tone.sage,
                  busy: _busy,
                  onPressed: () => _decide(approve: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SmallAction(
                  t: t,
                  label: 'Refuser',
                  icon: Icons.close_rounded,
                  tone: _Tone.ember,
                  busy: _busy,
                  onPressed: () => _decide(approve: false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _decide({required bool approve}) async {
    setState(() => _busy = true);
    final service = ref.read(villageGovernanceServiceProvider);
    try {
      if (approve) {
        await service.approveJoin(widget.villageId, widget.request.id);
      } else {
        await service.rejectJoin(widget.villageId, widget.request.id);
      }
      ref.invalidate(villagePendingJoinsProvider(widget.villageId));
      if (mounted) {
        _snack(context, approve ? 'Adhésion approuvée.' : 'Demande refusée.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        _snack(context, "Échec de l'action.", error: true);
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  3) VALIDATIONS CULTURELLES (patrimoine)
// ═══════════════════════════════════════════════════════════════════

class _CultureSection extends ConsumerWidget {
  const _CultureSection({required this.villageId});

  final String villageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    // Sans filtre kind → on écarte manuellement les SUCCESSION.
    final arg = VillageValidationsArg(villageId);
    final async = ref.watch(villageValidationsProvider(arg));

    return _SectionScaffold(
      caption: 'Clan, chefferie et lignée du chef.',
      action: _GoldButton(
        icon: Icons.add_rounded,
        label: 'Soumettre',
        onPressed: () => _openSubmitDialog(context),
      ),
      child: async.when(
        loading: () => _CenteredBox(
          child: CircularProgressIndicator(color: t.goldText),
        ),
        error: (e, _) => _ErrorLine(t: t),
        data: (all) {
          final items = all.where((v) => v.kind != 'SUCCESSION').toList();
          if (items.isEmpty) {
            return _EmptyState(
              t: t,
              icon: Icons.verified_outlined,
              message: 'Aucun élément à valider.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _ValidationCard(
              validation: items[i],
              villageId: villageId,
              arg: arg,
            ),
          );
        },
      ),
    );
  }

  Future<void> _openSubmitDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _SubmitValidationDialog(villageId: villageId),
    );
  }
}

class _ValidationCard extends ConsumerStatefulWidget {
  const _ValidationCard({
    required this.validation,
    required this.villageId,
    required this.arg,
    this.witnessNote,
  });

  final VillageValidation validation;
  final String villageId;
  final VillageValidationsArg arg;
  final String? witnessNote;

  @override
  ConsumerState<_ValidationCard> createState() => _ValidationCardState();
}

class _ValidationCardState extends ConsumerState<_ValidationCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final v = widget.validation;
    final kindLabel = _kCultureKindLabels[v.kind] ?? v.kind;
    return _WhiteCard(
      t: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: GwTokens.azureBg,
                borderRadius: BorderRadius.circular(GwTokens.rPill),
                border: Border.all(color: GwTokens.azureLine),
              ),
              child: Text(
                kindLabel.toUpperCase(),
                style: GwType.mono(
                  fontSize: 9,
                  letterSpacing: 1.5,
                  color: t.azureText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            v.title.isEmpty ? 'Élément à valider' : v.title,
            style: GwType.ui(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: t.stone,
            ),
          ),
          if (v.detail?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              v.detail!,
              style: GwType.ui(fontSize: 13, color: t.stoneMid, height: 1.35),
            ),
          ],
          if (widget.witnessNote != null) ...[
            const SizedBox(height: 8),
            _InfoBadge(
              t: t,
              icon: Icons.groups_2_outlined,
              text: widget.witnessNote!,
              tone: _Tone.ember,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SmallAction(
                  t: t,
                  label: 'Approuver',
                  icon: Icons.check_rounded,
                  tone: _Tone.sage,
                  busy: _busy,
                  onPressed: () => _decide(approve: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SmallAction(
                  t: t,
                  label: 'Rejeter',
                  icon: Icons.close_rounded,
                  tone: _Tone.ember,
                  busy: _busy,
                  onPressed: () => _decide(approve: false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _decide({required bool approve}) async {
    setState(() => _busy = true);
    final service = ref.read(villageGovernanceServiceProvider);
    try {
      await service.decideValidation(
          widget.villageId, widget.validation.id, approve);
      ref.invalidate(villageValidationsProvider(widget.arg));
      if (mounted) {
        _snack(context, approve ? 'Validé.' : 'Rejeté.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        _snack(context, 'Échec de la décision.', error: true);
      }
    }
  }
}

// ───────────────────────────────────────────────────────────────────
//  Dialog : soumettre une validation culturelle
// ───────────────────────────────────────────────────────────────────

const _kSubmitKinds = <String>['CLAN', 'CHEFFERIE', 'CHIEF_LINE'];

class _SubmitValidationDialog extends ConsumerStatefulWidget {
  const _SubmitValidationDialog({required this.villageId});

  final String villageId;

  @override
  ConsumerState<_SubmitValidationDialog> createState() =>
      _SubmitValidationDialogState();
}

class _SubmitValidationDialogState
    extends ConsumerState<_SubmitValidationDialog> {
  final _titleController = TextEditingController();
  final _detailController = TextEditingController();
  String _kind = _kSubmitKinds.first;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _titleController.text.trim().isNotEmpty && !_submitting;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          decoration: BoxDecoration(
            color: t.inkCard,
            borderRadius: BorderRadius.circular(GwTokens.rCard),
            border: Border.all(color: t.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GwWeaveBand(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Soumettre à validation',
                        style: GwType.display(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: t.stone,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded,
                          color: t.stoneMid, size: 20),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(t, 'TYPE'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final k in _kSubmitKinds)
                          _KindChip(
                            t: t,
                            label: _kCultureKindLabels[k] ?? k,
                            selected: _kind == k,
                            onTap: () => setState(() => _kind = k),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _label(t, 'TITRE'),
                    const SizedBox(height: 8),
                    _field(t, _titleController, "Intitulé de l'élément"),
                    const SizedBox(height: 16),
                    _label(t, 'DÉTAIL (optionnel)'),
                    const SizedBox(height: 8),
                    _field(t, _detailController, 'Contexte, sources…',
                        maxLines: 3),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: _GoldButton(
                        icon: Icons.send_rounded,
                        label: _submitting ? 'Envoi…' : 'Soumettre',
                        filled: true,
                        onPressed: _canSubmit ? _submit : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    GwTokens t,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      onChanged: (_) => setState(() {}),
      maxLines: maxLines,
      style: GwType.ui(fontSize: 14, color: t.stone),
      cursorColor: t.goldText,
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: GwType.ui(fontSize: 14, color: t.stoneDim),
        filled: true,
        fillColor: t.inkLift,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          borderSide: BorderSide(color: t.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          borderSide: BorderSide(color: t.goldLine),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final service = ref.read(villageGovernanceServiceProvider);
    final navigator = Navigator.of(context);
    final detail = _detailController.text.trim();
    try {
      await service.submitValidation(
        widget.villageId,
        _kind,
        _titleController.text.trim(),
        detail.isEmpty ? null : detail,
      );
      ref.invalidate(
          villageValidationsProvider(VillageValidationsArg(widget.villageId)));
      if (mounted) {
        navigator.pop();
        _snack(context, 'Élément soumis à validation.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
        _snack(context, "Échec de l'envoi.", error: true);
      }
    }
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({
    required this.t,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final GwTokens t;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(GwTokens.rPill),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? t.goldBg : t.inkLift,
          borderRadius: BorderRadius.circular(GwTokens.rPill),
          border: Border.all(color: selected ? t.goldLine : t.lineMid),
        ),
        child: Text(
          label,
          style: GwType.ui(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? t.goldText : t.stoneMid,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  4) SUCCESSION DU CHEF
// ═══════════════════════════════════════════════════════════════════

class _SuccessionSection extends ConsumerWidget {
  const _SuccessionSection({required this.villageId});

  final String villageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final arg = VillageValidationsArg(villageId, kind: 'SUCCESSION');
    final async = ref.watch(villageValidationsProvider(arg));

    return _SectionScaffold(
      caption: 'Demande la validation des témoins du clan.',
      child: async.when(
        loading: () => _CenteredBox(
          child: CircularProgressIndicator(color: t.goldText),
        ),
        error: (e, _) => _ErrorLine(t: t),
        data: (items) {
          if (items.isEmpty) {
            return _EmptyState(
              t: t,
              icon: Icons.account_balance_outlined,
              message: 'Aucune succession en cours.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _ValidationCard(
              validation: items[i],
              villageId: villageId,
              arg: arg,
              witnessNote: 'Demande la validation des témoins du clan.',
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Composants partagés — charte Tissage
// ═══════════════════════════════════════════════════════════════════

/// Enveloppe d'une section : caption mono + action optionnelle + contenu.
class _SectionScaffold extends StatelessWidget {
  const _SectionScaffold({
    required this.caption,
    required this.child,
    this.action,
  });

  final String caption;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  caption,
                  style: GwType.ui(
                    fontSize: 12,
                    color: t.stoneMid,
                    height: 1.3,
                  ),
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: 10),
                action!,
              ],
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

/// Carte blanche, liseré fin, coins arrondis (charte cartes).
class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.t, required this.child});

  final GwTokens t;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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

/// Bouton or — plein (accent) ou contour discret.
class _GoldButton extends StatelessWidget {
  const _GoldButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final enabled = onPressed != null;
    if (filled) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          color: enabled ? GwTokens.gold : t.inkLift,
        ),
        child: TextButton.icon(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: GwTokens.inkOnGold,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(GwTokens.rBtn),
            ),
          ),
          icon: Icon(icon,
              size: 18, color: enabled ? GwTokens.inkOnGold : t.stoneDim),
          label: Text(
            label,
            style: GwType.ui(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: enabled ? GwTokens.inkOnGold : t.stoneDim,
            ),
          ),
        ),
      );
    }
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: t.goldText,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          side: BorderSide(color: t.goldLine),
        ),
      ),
      icon: Icon(icon, size: 16, color: t.goldText),
      label: Text(
        label,
        style: GwType.ui(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: t.goldText,
        ),
      ),
    );
  }
}

enum _Tone { sage, ember }

/// Petit bouton d'action bicolore (Approuver / Rejeter…).
class _SmallAction extends StatelessWidget {
  const _SmallAction({
    required this.t,
    required this.label,
    required this.icon,
    required this.tone,
    required this.onPressed,
    this.busy = false,
  });

  final GwTokens t;
  final String label;
  final IconData icon;
  final _Tone tone;
  final VoidCallback onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final fg = tone == _Tone.sage ? t.sageText : t.emberText;
    final bg = tone == _Tone.sage ? GwTokens.sageBg : GwTokens.emberBg;
    final line = tone == _Tone.sage ? GwTokens.sageLine : GwTokens.emberLine;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        border: Border.all(color: line),
      ),
      child: TextButton.icon(
        onPressed: busy ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: fg,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          minimumSize: const Size(0, GwTokens.tapTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GwTokens.rBtn),
          ),
        ),
        icon: busy
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              )
            : Icon(icon, size: 16, color: fg),
        label: Text(
          label,
          style:
              GwType.ui(fontSize: 13, fontWeight: FontWeight.w700, color: fg),
        ),
      ),
    );
  }
}

/// Encart d'info teinté (auto-admission, note témoins…).
class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.t,
    required this.icon,
    required this.text,
    required this.tone,
  });

  final GwTokens t;
  final IconData icon;
  final String text;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    final fg = tone == _Tone.sage ? t.sageText : t.emberText;
    final bg = tone == _Tone.sage ? GwTokens.sageBg : GwTokens.emberBg;
    final line = tone == _Tone.sage ? GwTokens.sageLine : GwTokens.emberLine;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        border: Border.all(color: line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: GwType.ui(fontSize: 12, color: fg, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

/// État vide, centré, icône discrète + message.
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.t,
    required this.icon,
    required this.message,
  });

  final GwTokens t;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: t.stoneDim),
            const SizedBox(height: 12),
            Text(
              message,
              style: GwType.ui(fontSize: 14, color: t.stoneMid),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine({required this.t});

  final GwTokens t;

  @override
  Widget build(BuildContext context) {
    return _CenteredBox(
      child: Text(
        'Chargement impossible.',
        style: GwType.ui(fontSize: 14, color: t.emberText),
      ),
    );
  }
}

class _CenteredBox extends StatelessWidget {
  const _CenteredBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    );
  }
}

/// Label mono MAJUSCULES d'un intitulé de champ.
Widget _label(GwTokens t, String text) => Text(
      text,
      style: GwType.mono(
        fontSize: 10,
        letterSpacing: 1.5,
        color: t.stoneMid,
        fontWeight: FontWeight.w600,
      ),
    );

// ── Utilitaires ────────────────────────────────────────────────────

String _shortId(String id) {
  if (id.length <= 12) return id;
  return '${id.substring(0, 6)}…${id.substring(id.length - 4)}';
}

void _snack(BuildContext context, String message, {bool error = false}) {
  final t = GwTokens.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? GwTokens.ember : t.inkHigh,
        content: Text(
          message,
          style: GwType.ui(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: error ? Colors.white : t.stone,
          ),
        ),
      ),
    );
}

Future<bool?> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool danger = false,
}) {
  final t = GwTokens.of(context);
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: t.inkCard,
          borderRadius: BorderRadius.circular(GwTokens.rCard),
          border: Border.all(color: t.line),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GwType.display(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: t.stone,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GwType.ui(fontSize: 14, color: t.stoneMid, height: 1.4),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(
                    'Annuler',
                    style: GwType.ui(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: t.stoneMid,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: danger ? GwTokens.emberBg : GwTokens.gold,
                    borderRadius: BorderRadius.circular(GwTokens.rBtn),
                    border: danger
                        ? Border.all(color: GwTokens.emberLine)
                        : null,
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                    ),
                    child: Text(
                      confirmLabel,
                      style: GwType.ui(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: danger ? t.emberText : GwTokens.inkOnGold,
                      ),
                    ),
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
