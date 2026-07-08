import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/genealogy/genealogy_notifier.dart';
import 'package:gwangmeu/features/genealogy/services/genealogy_api_service.dart';
import 'package:gwangmeu/features/notifications/models/notification_model.dart';
import 'package:gwangmeu/features/notifications/services/notification_api_service.dart';
import 'package:gwangmeu/features/notifications/notifications_notifier.dart';

/// Ouvre le bon dialog de confirmation selon le type de notification.
void openConfirmationDialog(BuildContext context, NotificationModel notification) {
  final type = notification.type;
  final data = notification.data;

  switch (type) {
    case 'UNION_PENDING':
    case 'UNION_CREATED':
      showDialog(
        context: context,
        builder: (_) => _UnionConfirmationDialog(
          unionId: data['unionId'] as String? ?? '',
          notification: notification,
        ),
      );
    case 'PARENT_ADDED':
      showDialog(
        context: context,
        builder: (_) => _ParentAddedDialog(notification: notification),
      );
    case 'DIVORCE_REQUEST':
      showDialog(
        context: context,
        builder: (_) => _DivorceConfirmationDialog(
          unionId: data['unionId'] as String? ?? '',
          notification: notification,
        ),
      );
    case 'DEATH_DECLARATION':
      showDialog(
        context: context,
        builder: (_) => _DeathContestationDialog(
          unionId: data['unionId'] as String? ?? '',
          notification: notification,
        ),
      );
    case 'CHILD_ASSOCIATION_REQUEST':
      showDialog(
        context: context,
        builder: (_) => _ChildAssociationDialog(
          requestId: data['requestId'] as String? ?? '',
          notification: notification,
        ),
      );
    case 'CHILD_ASSOCIATION_RESPONSE':
      showDialog(
        context: context,
        builder: (_) => _ChildAssociationResponseDialog(notification: notification),
      );
    case 'PERSON_MODIFICATION_REQUEST':
      showDialog(
        context: context,
        builder: (_) => _PersonModificationRequestDialog(
          requestId: data['requestId'] as String? ?? '',
          notification: notification,
        ),
      );
    case 'PERSON_MODIFICATION_RESPONSE':
      showDialog(
        context: context,
        builder: (_) => _PersonModificationResponseDialog(notification: notification),
      );
    default:
      // Notifications informatives — pas de dialog
      break;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SOCLE VISUEL « TISSAGE » — specs GwDialog appliquées inline :
// fond inkCard rayon 20, titre Fraunces, actions or/ember 50 px.
// Tuile d'icône teintée : or = demande, sage = confirmation,
// ember = contestation / décès, azure = information.
// ════════════════════════════════════════════════════════════════════════════

/// Teinte de la tuile d'icône du dialog.
class _TileTint {
  const _TileTint(this.fg, this.bg, this.line);

  final Color fg;
  final Color bg;
  final Color line;

  static _TileTint gold(GwTokens t) => _TileTint(t.goldText, t.goldBg, t.goldLine);
  static _TileTint sage(GwTokens t) =>
      _TileTint(t.sageText, GwTokens.sageBg, GwTokens.sageLine);
  static _TileTint ember(GwTokens t) =>
      _TileTint(t.emberText, GwTokens.emberBg, GwTokens.emberLine);
  static _TileTint azure(GwTokens t) =>
      _TileTint(t.azureText, GwTokens.azureBg, GwTokens.azureLine);
}

/// Coquille commune des dialogs de confirmation.
class _DialogShell extends StatelessWidget {
  const _DialogShell({
    required this.icon,
    required this.tint,
    required this.title,
    required this.children,
    required this.actions,
  });

  final IconData icon;
  final _TileTint tint;
  final String title;
  final List<Widget> children;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Dialog(
      backgroundColor: t.inkCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GwTokens.rCardLg),
        side: BorderSide(color: t.line),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: tint.bg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: tint.line),
                    ),
                    child: Icon(icon, size: 26, color: tint.fg, fill: 1),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: GwType.display(fontSize: 19, color: t.stone),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...children,
              const SizedBox(height: 20),
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                actions[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Corps de texte du dialog — 14 px stoneMid.
Widget _dialogBody(BuildContext context, String text) {
  final t = GwTokens.of(context);
  return Text(text, style: GwType.ui(fontSize: 14, color: t.stoneMid, height: 1.5));
}

/// Encart d'information teinté.
Widget _infoPanel(BuildContext context, String text, _TileTint tint) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: tint.bg,
      borderRadius: BorderRadius.circular(GwTokens.rBtn),
      border: Border.all(color: tint.line),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Symbols.info, size: 16, color: tint.fg),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GwType.ui(fontSize: 13, color: tint.fg, height: 1.4),
          ),
        ),
      ],
    ),
  );
}

/// Action primaire — or plein, 50 px, rayon 14.
Widget _primaryAction(
  BuildContext context, {
  required String label,
  required VoidCallback? onPressed,
  bool loading = false,
  IconData? icon,
}) {
  return SizedBox(
    width: double.infinity,
    height: 50,
    child: FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: GwTokens.gold,
        foregroundColor: Colors.black,
        disabledBackgroundColor: GwTokens.gold.withAlpha(110),
        disabledForegroundColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
        ),
        textStyle: GwType.ui(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      child: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, fill: 1),
                  const SizedBox(width: 8),
                ],
                Text(label),
              ],
            ),
    ),
  );
}

/// Action destructive / contestation — ember plein, 50 px, rayon 14.
Widget _destructiveAction(
  BuildContext context, {
  required String label,
  required VoidCallback? onPressed,
  bool loading = false,
  IconData? icon,
}) {
  return SizedBox(
    width: double.infinity,
    height: 50,
    child: FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: GwTokens.ember,
        foregroundColor: Colors.white,
        disabledBackgroundColor: GwTokens.ember.withAlpha(110),
        disabledForegroundColor: Colors.white70,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
        ),
        textStyle: GwType.ui(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      child: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, fill: 1),
                  const SizedBox(width: 8),
                ],
                Text(label),
              ],
            ),
    ),
  );
}

/// Action discrète (annuler / fermer).
Widget _cancelAction(
  BuildContext context, {
  String label = 'Fermer',
  required VoidCallback? onPressed,
}) {
  final t = GwTokens.of(context);
  return SizedBox(
    width: double.infinity,
    height: 46,
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: t.stoneMid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
        ),
        textStyle: GwType.ui(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    ),
  );
}

/// Champ de saisie stylé Tissage — fond inkLift, rayon 14, focus or.
InputDecoration _fieldDecoration(
  BuildContext context, {
  required String label,
  IconData? icon,
}) {
  final t = GwTokens.of(context);
  return InputDecoration(
    labelText: label,
    labelStyle: GwType.ui(fontSize: 13, color: t.stoneDim),
    prefixIcon: icon != null ? Icon(icon, size: 18, color: t.stoneDim) : null,
    filled: true,
    fillColor: t.inkLift,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(GwTokens.rBtn),
      borderSide: BorderSide(color: t.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(GwTokens.rBtn),
      borderSide: BorderSide(color: t.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(GwTokens.rBtn),
      borderSide: const BorderSide(color: GwTokens.gold, width: 1.5),
    ),
  );
}

/// Snackbar stylée.
void _showSnack(BuildContext context, String message, Color bg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: GwType.ui(fontSize: 14, color: Colors.white)),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GwTokens.rBtn)),
    ),
  );
}

// ── Union Confirmation (Confirmer / Contester) ─────────────

class _UnionConfirmationDialog extends ConsumerStatefulWidget {
  const _UnionConfirmationDialog({
    required this.unionId,
    required this.notification,
  });

  final String unionId;
  final NotificationModel notification;

  @override
  ConsumerState<_UnionConfirmationDialog> createState() =>
      _UnionConfirmationDialogState();
}

class _UnionConfirmationDialogState
    extends ConsumerState<_UnionConfirmationDialog> {
  bool _loading = false;
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return _DialogShell(
      icon: Symbols.favorite,
      tint: _TileTint.gold(t),
      title: 'Demande d\'union',
      children: [
        _dialogBody(context, widget.notification.body),
        const SizedBox(height: 16),
        _infoPanel(
          context,
          'Quelqu\'un souhaite enregistrer une union avec vous. '
          'Confirmez si cette union est reelle, ou contestez-la.',
          _TileTint.gold(t),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _reasonCtrl,
          style: GwType.ui(fontSize: 14, color: t.stone),
          decoration: _fieldDecoration(
            context,
            label: 'Raison de contestation (si refus)',
            icon: Symbols.comment,
          ),
          maxLines: 2,
        ),
      ],
      actions: [
        _primaryAction(
          context,
          label: 'Confirmer l\'union',
          icon: Symbols.check,
          onPressed: _loading ? null : _confirm,
        ),
        _destructiveAction(
          context,
          label: 'Contester',
          loading: _loading,
          onPressed: _contest,
        ),
        _cancelAction(
          context,
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Future<void> _confirm() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(notificationApiServiceProvider)
          .confirmUnion(widget.unionId);
      if (mounted) {
        Navigator.of(context).pop();
        ref.invalidate(notificationsNotifierProvider);
        ref.invalidate(unreadCountProvider);
        _showSnack(context, 'Union confirmee avec succes', GwTokens.sage);
      }
    } catch (e) {
      if (mounted) {
        _showSnack(context, 'Erreur: $e', GwTokens.ember);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _contest() async {
    setState(() => _loading = true);
    try {
      await ref.read(notificationApiServiceProvider).contestUnion(
            widget.unionId,
            _reasonCtrl.text.trim().isNotEmpty
                ? _reasonCtrl.text.trim()
                : 'Union contestee sans motif precis',
          );
      if (mounted) {
        Navigator.of(context).pop();
        ref.invalidate(notificationsNotifierProvider);
        ref.invalidate(unreadCountProvider);
        _showSnack(context, 'Union contestee — demande rejetee', GwTokens.ember);
      }
    } catch (e) {
      if (mounted) {
        _showSnack(context, 'Erreur: $e', GwTokens.ember);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ── Parent Added ────────────────────────────────────────────

class _ParentAddedDialog extends StatelessWidget {
  const _ParentAddedDialog({required this.notification});
  final NotificationModel notification;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return _DialogShell(
      icon: Symbols.family_restroom,
      tint: _TileTint.azure(t),
      title: 'Lien de parente',
      children: [
        _dialogBody(context, notification.body),
        const SizedBox(height: 16),
        _infoPanel(
          context,
          'Un lien de parente a ete ajoute dans votre arbre genealogique. '
          'Consultez l\'onglet Genealogie pour verifier.',
          _TileTint.azure(t),
        ),
      ],
      actions: [
        _primaryAction(
          context,
          label: 'Voir dans l\'arbre',
          icon: Symbols.account_tree,
          onPressed: () {
            Navigator.of(context).pop();
            context.go('/home/genealogy');
          },
        ),
        _cancelAction(
          context,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

// ── Divorce Confirmation ────────────────────────────────────

class _DivorceConfirmationDialog extends ConsumerStatefulWidget {
  const _DivorceConfirmationDialog({
    required this.unionId,
    required this.notification,
  });

  final String unionId;
  final NotificationModel notification;

  @override
  ConsumerState<_DivorceConfirmationDialog> createState() =>
      _DivorceConfirmationDialogState();
}

class _DivorceConfirmationDialogState
    extends ConsumerState<_DivorceConfirmationDialog> {
  bool _loading = false;
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return _DialogShell(
      icon: Symbols.heart_broken,
      tint: _TileTint.ember(t),
      title: 'Demande de divorce',
      children: [
        _dialogBody(context, widget.notification.body),
        const SizedBox(height: 16),
        Text(
          'Que souhaitez-vous faire ?',
          style: GwType.ui(fontSize: 14, fontWeight: FontWeight.w700, color: t.stone),
        ),
        const SizedBox(height: 8),
        Text(
          'Si vous acceptez, le divorce sera finalise.\n'
          'Si vous contestez, un litige sera ouvert et un administrateur tranchera.',
          style: GwType.ui(fontSize: 13, color: t.stoneDim, height: 1.4),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _reasonCtrl,
          style: GwType.ui(fontSize: 14, color: t.stone),
          decoration: _fieldDecoration(
            context,
            label: 'Raison de contestation (optionnel)',
            icon: Symbols.comment,
          ),
          maxLines: 2,
        ),
      ],
      actions: [
        _primaryAction(
          context,
          label: 'Accepter le divorce',
          icon: Symbols.check,
          onPressed: _loading ? null : _confirm,
        ),
        _destructiveAction(
          context,
          label: 'Contester',
          loading: _loading,
          onPressed: _contest,
        ),
        _cancelAction(
          context,
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Future<void> _confirm() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(notificationApiServiceProvider)
          .confirmDivorce(widget.unionId);
      if (mounted) {
        Navigator.of(context).pop();
        ref.invalidate(notificationsNotifierProvider);
        ref.invalidate(unreadCountProvider);
        _showSnack(context, 'Divorce confirme', GwTokens.sage);
      }
    } catch (e) {
      if (mounted) {
        _showSnack(context, 'Erreur: $e', GwTokens.ember);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _contest() async {
    setState(() => _loading = true);
    try {
      await ref.read(notificationApiServiceProvider).contestDivorce(
            widget.unionId,
            _reasonCtrl.text.trim().isNotEmpty
                ? _reasonCtrl.text.trim()
                : 'Contestation sans motif precis',
          );
      if (mounted) {
        Navigator.of(context).pop();
        ref.invalidate(notificationsNotifierProvider);
        ref.invalidate(unreadCountProvider);
        _showSnack(context, 'Divorce conteste — litige ouvert', GwTokens.ember);
      }
    } catch (e) {
      if (mounted) {
        _showSnack(context, 'Erreur: $e', GwTokens.ember);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ── Death Contestation ──────────────────────────────────────

class _DeathContestationDialog extends ConsumerStatefulWidget {
  const _DeathContestationDialog({
    required this.unionId,
    required this.notification,
  });

  final String unionId;
  final NotificationModel notification;

  @override
  ConsumerState<_DeathContestationDialog> createState() =>
      _DeathContestationDialogState();
}

class _DeathContestationDialogState
    extends ConsumerState<_DeathContestationDialog> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return _DialogShell(
      icon: Symbols.warning,
      tint: _TileTint.ember(t),
      title: 'Declaration de deces',
      children: [
        _dialogBody(context, widget.notification.body),
        const SizedBox(height: 16),
        _infoPanel(
          context,
          'Si vous etes vivant(e), cliquez "Je suis vivant(e)" pour contester '
          'cette declaration. Un litige sera ouvert et un administrateur verifiera.',
          _TileTint.ember(t),
        ),
      ],
      actions: [
        _primaryAction(
          context,
          label: 'Je suis vivant(e)',
          icon: Symbols.person,
          loading: _loading,
          onPressed: _contestDeath,
        ),
        _cancelAction(
          context,
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Future<void> _contestDeath() async {
    setState(() => _loading = true);
    try {
      await ref.read(notificationApiServiceProvider).contestDeath(
            widget.unionId,
            'La personne declaree decedee conteste: elle est vivante.',
          );
      if (mounted) {
        Navigator.of(context).pop();
        ref.invalidate(notificationsNotifierProvider);
        ref.invalidate(unreadCountProvider);
        _showSnack(context, 'Contestation enregistree — litige ouvert', GwTokens.sage);
      }
    } catch (e) {
      if (mounted) {
        _showSnack(context, 'Erreur: $e', GwTokens.ember);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ── Child Association Request (Accepter / Refuser) ──────────

class _ChildAssociationDialog extends ConsumerStatefulWidget {
  const _ChildAssociationDialog({
    required this.requestId,
    required this.notification,
  });

  final String requestId;
  final NotificationModel notification;

  @override
  ConsumerState<_ChildAssociationDialog> createState() =>
      _ChildAssociationDialogState();
}

class _ChildAssociationDialogState
    extends ConsumerState<_ChildAssociationDialog> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return _DialogShell(
      icon: Symbols.child_care,
      tint: _TileTint.gold(t),
      title: 'Demande d\'association d\'enfant',
      children: [
        _dialogBody(context, widget.notification.body),
        const SizedBox(height: 16),
        _infoPanel(
          context,
          'Quelqu\'un souhaite vous associer comme co-parent d\'un enfant. '
          'Acceptez pour confirmer cette filiation dans votre arbre.',
          _TileTint.gold(t),
        ),
      ],
      actions: [
        _primaryAction(
          context,
          label: 'Accepter',
          icon: Symbols.check,
          onPressed: _loading ? null : _accept,
        ),
        _destructiveAction(
          context,
          label: 'Refuser',
          loading: _loading,
          onPressed: _reject,
        ),
        _cancelAction(
          context,
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Future<void> _accept() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(notificationApiServiceProvider)
          .acceptChildAssociation(widget.requestId);
      if (mounted) {
        Navigator.of(context).pop();
        ref.invalidate(notificationsNotifierProvider);
        ref.invalidate(unreadCountProvider);

        // Rafraichir l'arbre genealogique pour que l'enfant apparaisse lie aux 2 parents
        final myPerson = ref.read(genealogyNotifierProvider).valueOrNull;
        if (myPerson != null) {
          ref.invalidate(familyTreeProvider(myPerson.id));
        }
        final childId = widget.notification.data['childId'] as String?;
        if (childId != null) {
          ref.invalidate(familyTreeProvider(childId));
        }

        _showSnack(
          context,
          'Association acceptee — l\'enfant a ete lie a votre arbre',
          GwTokens.sage,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnack(context, 'Erreur: $e', GwTokens.ember);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reject() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(notificationApiServiceProvider)
          .rejectChildAssociation(widget.requestId);
      if (mounted) {
        Navigator.of(context).pop();
        ref.invalidate(notificationsNotifierProvider);
        ref.invalidate(unreadCountProvider);
        _showSnack(context, 'Demande d\'association refusee', GwTokens.ember);
      }
    } catch (e) {
      if (mounted) {
        _showSnack(context, 'Erreur: $e', GwTokens.ember);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ── Child Association Response (informative) ─────────────────

class _ChildAssociationResponseDialog extends ConsumerWidget {
  const _ChildAssociationResponseDialog({required this.notification});
  final NotificationModel notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final accepted = notification.data['accepted'] == true ||
        notification.data['accepted'] == 'true';
    final tint = accepted ? _TileTint.sage(t) : _TileTint.ember(t);

    return _DialogShell(
      icon: accepted ? Symbols.check_circle : Symbols.cancel,
      tint: tint,
      title: accepted ? 'Association acceptee' : 'Association refusee',
      children: [
        _dialogBody(context, notification.body),
        const SizedBox(height: 16),
        _infoPanel(
          context,
          accepted
              ? 'Le co-parent a confirme la filiation. L\'enfant est maintenant lie a son arbre.'
              : 'Le co-parent a refuse l\'association. L\'enfant reste lie uniquement a votre arbre.',
          tint,
        ),
      ],
      actions: [
        if (accepted)
          _primaryAction(
            context,
            label: 'Voir dans l\'arbre',
            icon: Symbols.account_tree,
            onPressed: () {
              // Rafraichir l'arbre avant de naviguer
              final myPerson = ref.read(genealogyNotifierProvider).valueOrNull;
              if (myPerson != null) {
                ref.invalidate(familyTreeProvider(myPerson.id));
              }
              final childId = notification.data['childId'] as String?;
              if (childId != null) {
                ref.invalidate(familyTreeProvider(childId));
              }
              Navigator.of(context).pop();
              context.go('/home/genealogy');
            },
          ),
        _cancelAction(
          context,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

// ── Person Modification Request (Accepter / Refuser) ─────────

class _PersonModificationRequestDialog extends ConsumerStatefulWidget {
  const _PersonModificationRequestDialog({
    required this.requestId,
    required this.notification,
  });

  final String requestId;
  final NotificationModel notification;

  @override
  ConsumerState<_PersonModificationRequestDialog> createState() =>
      _PersonModificationRequestDialogState();
}

class _PersonModificationRequestDialogState
    extends ConsumerState<_PersonModificationRequestDialog> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return _DialogShell(
      icon: Symbols.edit_note,
      tint: _TileTint.gold(t),
      title: 'Demande de modification',
      children: [
        _dialogBody(context, widget.notification.body),
        const SizedBox(height: 16),
        _infoPanel(
          context,
          'Le co-parent souhaite modifier les informations de votre enfant. '
          'Acceptez pour appliquer les modifications, ou refusez pour les annuler.',
          _TileTint.gold(t),
        ),
      ],
      actions: [
        _primaryAction(
          context,
          label: 'Accepter',
          icon: Symbols.check,
          onPressed: _loading ? null : _accept,
        ),
        _destructiveAction(
          context,
          label: 'Refuser',
          loading: _loading,
          onPressed: _reject,
        ),
        _cancelAction(
          context,
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Future<void> _accept() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(genealogyApiServiceProvider)
          .acceptModificationRequest(widget.requestId);
      if (mounted) {
        Navigator.of(context).pop();
        ref.invalidate(notificationsNotifierProvider);
        ref.invalidate(unreadCountProvider);

        final myPerson = ref.read(genealogyNotifierProvider).valueOrNull;
        if (myPerson != null) {
          ref.invalidate(familyTreeProvider(myPerson.id));
        }
        final personId = widget.notification.data['personId'] as String?;
        if (personId != null) {
          ref.invalidate(familyTreeProvider(personId));
        }

        _showSnack(context, 'Modification acceptee et appliquee', GwTokens.sage);
      }
    } catch (e) {
      if (mounted) {
        _showSnack(context, 'Erreur: $e', GwTokens.ember);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reject() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(genealogyApiServiceProvider)
          .rejectModificationRequest(widget.requestId);
      if (mounted) {
        Navigator.of(context).pop();
        ref.invalidate(notificationsNotifierProvider);
        ref.invalidate(unreadCountProvider);
        _showSnack(context, 'Modification refusee', GwTokens.ember);
      }
    } catch (e) {
      if (mounted) {
        _showSnack(context, 'Erreur: $e', GwTokens.ember);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ── Person Modification Response (informative) ─────────────────

class _PersonModificationResponseDialog extends StatelessWidget {
  const _PersonModificationResponseDialog({required this.notification});
  final NotificationModel notification;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final accepted = notification.data['accepted'] == true ||
        notification.data['accepted'] == 'true';
    final tint = accepted ? _TileTint.sage(t) : _TileTint.ember(t);

    return _DialogShell(
      icon: accepted ? Symbols.check_circle : Symbols.cancel,
      tint: tint,
      title: accepted ? 'Modification acceptee' : 'Modification refusee',
      children: [
        _dialogBody(context, notification.body),
        const SizedBox(height: 16),
        _infoPanel(
          context,
          accepted
              ? 'Le co-parent a valide les modifications. Les informations de l\'enfant ont ete mises a jour.'
              : 'Le co-parent a refuse les modifications. Les informations restent inchangees.',
          tint,
        ),
      ],
      actions: [
        _cancelAction(
          context,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
