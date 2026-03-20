import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gwangmeu/core/theme/app_theme.dart';
import 'package:gwangmeu/features/notifications/models/notification_model.dart';
import 'package:gwangmeu/features/notifications/notifications_notifier.dart';
import 'package:gwangmeu/features/notifications/widgets/confirmation_dialogs.dart';

/// Panel dropdown style Facebook/Instagram — affiché sous la cloche.
class NotificationPanel extends ConsumerWidget {
  const NotificationPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsNotifierProvider);

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: Theme.of(context).colorScheme.surface,
      child: Container(
        width: 380,
        constraints: const BoxConstraints(maxHeight: 480),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withAlpha(30),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Row(
                children: [
                  Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      ref
                          .read(notificationsNotifierProvider.notifier)
                          .markAllAsRead();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: Text(
                      'Tout marquer lu',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outline.withAlpha(20),
            ),

            // ── Liste ──
            Flexible(
              child: notifsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Erreur: $e',
                    style: TextStyle(color: Colors.red[400], fontSize: 13),
                  ),
                ),
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notifications_none,
                                size: 40, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'Aucune notification',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color:
                          Theme.of(context).colorScheme.outline.withAlpha(15),
                    ),
                    itemBuilder: (context, index) =>
                        _NotificationTile(notification: notifications[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});
  final NotificationModel notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUnread = !notification.read;

    return InkWell(
      onTap: () {
        // Marquer comme lu
        if (isUnread) {
          ref
              .read(notificationsNotifierProvider.notifier)
              .markAsRead(notification.id);
        }
        // Fermer le panel
        Navigator.of(context).pop();
        // Navigation selon le type
        _handleNotificationTap(context, notification);
      },
      child: Container(
        color: isUnread
            ? Theme.of(context).colorScheme.primary.withAlpha(8)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icone selon type
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _iconColor(notification.type).withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _icon(notification.type),
                size: 18,
                color: _iconColor(notification.type),
              ),
            ),
            const SizedBox(width: 12),

            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (notification.createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _timeAgo(notification.createdAt!),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Point bleu non lu
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4, left: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _icon(String type) {
    switch (type) {
      case 'DIVORCE_REQUEST':
        return Icons.heart_broken;
      case 'DEATH_DECLARATION':
      case 'DEATH_FAMILY_NOTICE':
        return Icons.sentiment_very_dissatisfied;
      case 'UNION_REQUEST':
      case 'UNION_CREATED':
      case 'UNION_PENDING':
        return Icons.favorite;
      case 'PARENT_ADDED':
      case 'PARENT_REQUEST':
      case 'CHILD_REQUEST':
        return Icons.family_restroom;
      case 'CHILD_ASSOCIATION_REQUEST':
        return Icons.child_care;
      case 'CHILD_ASSOCIATION_RESPONSE':
        return Icons.how_to_reg;
      default:
        return Icons.notifications;
    }
  }

  Color _iconColor(String type) {
    switch (type) {
      case 'DIVORCE_REQUEST':
        return Colors.orange;
      case 'DEATH_DECLARATION':
      case 'DEATH_FAMILY_NOTICE':
        return Colors.red;
      case 'UNION_REQUEST':
      case 'UNION_CREATED':
      case 'UNION_PENDING':
        return Colors.pink;
      case 'PARENT_ADDED':
      case 'PARENT_REQUEST':
      case 'CHILD_REQUEST':
        return Colors.blue;
      case 'CHILD_ASSOCIATION_REQUEST':
        return Colors.teal;
      case 'CHILD_ASSOCIATION_RESPONSE':
        return Colors.green;
      default:
        return const Color(0xFFC8A020); // fallback accent
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "a l'instant";
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'il y a ${diff.inDays}j';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleNotificationTap(
      BuildContext context, NotificationModel notification) {
    openConfirmationDialog(context, notification);
  }
}
