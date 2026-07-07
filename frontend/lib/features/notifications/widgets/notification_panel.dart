import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/notifications/models/notification_model.dart';
import 'package:gwangmeu/features/notifications/notifications_notifier.dart';
import 'package:gwangmeu/features/notifications/widgets/confirmation_dialogs.dart';

// ─────────────────────────────────────────────────────────────────
//  Groupes de notifications — Tissage #3e
// ─────────────────────────────────────────────────────────────────

enum _NotifGroup {
  memory('MÉMOIRE FAMILIALE'),
  village('VILLAGES'),
  social('SOCIAL');

  const _NotifGroup(this.label);
  final String label;
}

_NotifGroup _groupOf(String type) {
  const memoryPrefixes = [
    'UNION',
    'PARENT',
    'CHILD',
    'DIVORCE',
    'DEATH',
    'PERSON',
    'LINEAGE',
    'GENEALOGY',
    'AI_',
    'MEMORY',
    'SUGGESTION',
  ];
  const villagePrefixes = ['VILLAGE', 'LIVE', 'EVENT'];

  for (final p in memoryPrefixes) {
    if (type.startsWith(p)) return _NotifGroup.memory;
  }
  for (final p in villagePrefixes) {
    if (type.startsWith(p)) return _NotifGroup.village;
  }
  return _NotifGroup.social;
}

// ─────────────────────────────────────────────────────────────────
//  Panneau notifications groupées — affiché sous la cloche
//  (desktop) ou en bottom sheet (mobile)
// ─────────────────────────────────────────────────────────────────

class NotificationPanel extends ConsumerWidget {
  const NotificationPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final notifsAsync = ref.watch(notificationsNotifierProvider);

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(GwTokens.rCardLg),
      color: t.ink,
      child: Container(
        width: 380,
        constraints: const BoxConstraints(maxHeight: 520),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(GwTokens.rCardLg),
          border: Border.all(color: t.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications',
                          style: GwType.display(fontSize: 18, color: t.stone),
                        ),
                        Text(
                          'GROUPÉES PAR TYPE',
                          style: GwType.mono(
                            fontSize: 10,
                            color: t.stoneFaint,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref
                          .read(notificationsNotifierProvider.notifier)
                          .markAllAsRead();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(GwTokens.tapTarget, GwTokens.tapTarget),
                    ),
                    child: Text(
                      'Tout lire',
                      style: GwType.ui(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: t.goldText,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: t.line),

            // ── Liste groupée ──
            Flexible(
              child: notifsAsync.when(
                loading: () => Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: t.goldText,
                      ),
                    ),
                  ),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Symbols.cloud_off, size: 20, color: t.emberText),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Notifications indisponibles',
                          style: GwType.ui(fontSize: 13, color: t.emberText),
                        ),
                      ),
                    ],
                  ),
                ),
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Symbols.notifications,
                                size: 40, color: t.stoneDim),
                            const SizedBox(height: 8),
                            Text(
                              'Aucune notification',
                              style:
                                  GwType.ui(fontSize: 13, color: t.stoneMid),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final groups =
                      <_NotifGroup, List<NotificationModel>>{};
                  for (final n in notifications) {
                    groups.putIfAbsent(_groupOf(n.type), () => []).add(n);
                  }

                  return ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                    children: [
                      for (final group in _NotifGroup.values)
                        if (groups.containsKey(group)) ...[
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(6, 10, 6, 6),
                            child: Text(
                              group.label,
                              style: GwType.mono(
                                fontSize: 10,
                                letterSpacing: 2,
                                color: t.stoneFaint,
                              ),
                            ),
                          ),
                          for (final n in groups[group]!)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _NotificationCard(
                                notification: n,
                                group: group,
                              ),
                            ),
                        ],
                    ],
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

// ─────────────────────────────────────────────────────────────────
//  Carte notification — Mémoire = sage, Villages / Social = neutres
// ─────────────────────────────────────────────────────────────────

class _NotificationCard extends ConsumerWidget {
  const _NotificationCard({required this.notification, required this.group});

  final NotificationModel notification;
  final _NotifGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final isUnread = !notification.read;
    final (iconFg, iconBg) = _tint(t);

    return Material(
      color: Colors.transparent,
      child: InkWell(
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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: group == _NotifGroup.memory ? GwTokens.sageBg : t.inkCard,
            borderRadius: BorderRadius.circular(16),
            border: group == _NotifGroup.memory
                ? Border.all(color: GwTokens.sageLine)
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône dans tuile teintée
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_glyph(), size: 20, color: iconFg),
              ),
              const SizedBox(width: 12),

              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: GwType.ui(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: t.stone,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.body,
                      style: GwType.ui(
                        fontSize: 13,
                        color: t.stoneMid,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (notification.createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _timeAgo(notification.createdAt!),
                        style: GwType.mono(
                          fontSize: 10,
                          color: t.stoneFaint,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Point non-lu ember
              if (isUnread)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4, left: 8),
                  decoration: const BoxDecoration(
                    color: GwTokens.ember,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Teinte de la tuile d'icône selon le groupe :
  /// mémoire = sage, villages = or, social = ember.
  (Color, Color) _tint(GwTokens t) => switch (group) {
        _NotifGroup.memory => (t.sageText, GwTokens.sageBg),
        _NotifGroup.village => (t.goldText, t.goldBg),
        _NotifGroup.social => (t.emberText, GwTokens.emberBg),
      };

  IconData _glyph() {
    switch (notification.type) {
      case 'DIVORCE_REQUEST':
        return Symbols.heart_broken;
      case 'DEATH_DECLARATION':
      case 'DEATH_FAMILY_NOTICE':
        return Symbols.sentiment_very_dissatisfied;
      case 'UNION_REQUEST':
      case 'UNION_CREATED':
      case 'UNION_PENDING':
        return Symbols.favorite;
      case 'PARENT_ADDED':
      case 'PARENT_REQUEST':
        return Symbols.family_history;
      case 'CHILD_REQUEST':
        return Symbols.family_restroom;
      case 'CHILD_ASSOCIATION_REQUEST':
        return Symbols.child_care;
      case 'CHILD_ASSOCIATION_RESPONSE':
        return Symbols.how_to_reg;
    }
    return switch (group) {
      _NotifGroup.memory => Symbols.auto_awesome,
      _NotifGroup.village => Symbols.holiday_village,
      _NotifGroup.social => Symbols.favorite,
    };
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "à l'instant";
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
