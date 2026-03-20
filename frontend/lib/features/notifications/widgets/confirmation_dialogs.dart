import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.favorite, color: Colors.pink, size: 24),
          SizedBox(width: 8),
          Expanded(
            child: Text('Demande d\'union',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.notification.body,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.pink.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.pink.withAlpha(40)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.pink),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Quelqu\'un souhaite enregistrer une union avec vous. '
                      'Confirmez si cette union est reelle, ou contestez-la.',
                      style: TextStyle(fontSize: 12, color: Colors.pink),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Raison de contestation (si refus)',
                prefixIcon: Icon(Icons.comment_outlined),
                isDense: true,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _contest,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: _loading
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Contester'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _confirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.black,
          ),
          child: const Text('Confirmer l\'union'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Union confirmee avec succes'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Union contestee — demande rejetee'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
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
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.family_restroom, color: Colors.blue, size: 24),
          SizedBox(width: 8),
          Expanded(
            child: Text('Lien de parente',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.body,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withAlpha(40)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Un lien de parente a ete ajoute dans votre arbre genealogique. '
                      'Consultez l\'onglet Genealogie pour verifier.',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            context.go('/home/genealogy');
          },
          icon: const Icon(Icons.account_tree, size: 18),
          label: const Text('Voir dans l\'arbre'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.black,
          ),
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
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.heart_broken, color: Colors.orange, size: 24),
          SizedBox(width: 8),
          Expanded(
            child: Text('Demande de divorce',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.notification.body,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'Que souhaitez-vous faire ?',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            const Text(
              'Si vous acceptez, le divorce sera finalise.\n'
              'Si vous contestez, un litige sera ouvert et un administrateur tranchera.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Raison de contestation (optionnel)',
                prefixIcon: Icon(Icons.comment_outlined),
                isDense: true,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _contest,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: _loading
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Contester'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _confirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.black,
          ),
          child: const Text('Accepter le divorce'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Divorce confirme'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Divorce conteste — litige ouvert'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
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
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.red, size: 24),
          SizedBox(width: 8),
          Expanded(
            child: Text('Declaration de deces',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.notification.body,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withAlpha(60)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Si vous etes vivant(e), cliquez "Je suis vivant(e)" pour contester '
                      'cette declaration. Un litige sera ouvert et un administrateur verifiera.',
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
        ElevatedButton.icon(
          onPressed: _loading ? null : _contestDeath,
          icon: _loading
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.person, size: 18),
          label: const Text('Je suis vivant(e)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contestation enregistree — litige ouvert'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
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
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.child_care, color: Colors.teal, size: 24),
          SizedBox(width: 8),
          Expanded(
            child: Text('Demande d\'association d\'enfant',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.notification.body,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.withAlpha(40)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.teal),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Quelqu\'un souhaite vous associer comme co-parent d\'un enfant. '
                      'Acceptez pour confirmer cette filiation dans votre arbre.',
                      style: TextStyle(fontSize: 12, color: Colors.teal),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _reject,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Refuser'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _accept,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.black,
          ),
          child: const Text('Accepter'),
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

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Association acceptee — l\'enfant a ete lie a votre arbre'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande d\'association refusee'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
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
    final accepted = notification.data['accepted'] == true ||
        notification.data['accepted'] == 'true';

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            accepted ? Icons.check_circle : Icons.cancel,
            color: accepted ? Colors.green : Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              accepted ? 'Association acceptee' : 'Association refusee',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.body,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (accepted ? Colors.green : Colors.orange).withAlpha(15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: (accepted ? Colors.green : Colors.orange).withAlpha(40)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16,
                      color: accepted ? Colors.green : Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      accepted
                          ? 'Le co-parent a confirme la filiation. L\'enfant est maintenant lie a son arbre.'
                          : 'Le co-parent a refuse l\'association. L\'enfant reste lie uniquement a votre arbre.',
                      style: TextStyle(
                          fontSize: 12,
                          color: accepted ? Colors.green : Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
        if (accepted)
          ElevatedButton.icon(
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
            icon: const Icon(Icons.account_tree, size: 18),
            label: const Text('Voir dans l\'arbre'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.black,
            ),
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
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.edit_note, color: Colors.indigo, size: 24),
          SizedBox(width: 8),
          Expanded(
            child: Text('Demande de modification',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.notification.body,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.indigo.withAlpha(40)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.indigo),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Le co-parent souhaite modifier les informations de votre enfant. '
                      'Acceptez pour appliquer les modifications, ou refusez pour les annuler.',
                      style: TextStyle(fontSize: 12, color: Colors.indigo),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _reject,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Refuser'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _accept,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.black,
          ),
          child: const Text('Accepter'),
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

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Modification acceptee et appliquee'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Modification refusee'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
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
    final accepted = notification.data['accepted'] == true ||
        notification.data['accepted'] == 'true';

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            accepted ? Icons.check_circle : Icons.cancel,
            color: accepted ? Colors.green : Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              accepted ? 'Modification acceptee' : 'Modification refusee',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.body,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (accepted ? Colors.green : Colors.orange).withAlpha(15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: (accepted ? Colors.green : Colors.orange).withAlpha(40)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16,
                      color: accepted ? Colors.green : Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      accepted
                          ? 'Le co-parent a valide les modifications. Les informations de l\'enfant ont ete mises a jour.'
                          : 'Le co-parent a refuse les modifications. Les informations restent inchangees.',
                      style: TextStyle(
                          fontSize: 12,
                          color: accepted ? Colors.green : Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}
