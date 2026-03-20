import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:gwangmeu/features/notifications/models/notification_model.dart';
import 'package:gwangmeu/features/notifications/services/notification_api_service.dart';

part 'notifications_notifier.g.dart';

@riverpod
class NotificationsNotifier extends _$NotificationsNotifier {
  @override
  Future<List<NotificationModel>> build() async {
    return ref.read(notificationApiServiceProvider).getNotifications();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(notificationApiServiceProvider).getNotifications(),
    );
  }

  Future<void> markAsRead(String notifId) async {
    await ref.read(notificationApiServiceProvider).markAsRead(notifId);
    // Mise à jour locale
    state.whenData((notifications) {
      state = AsyncData(
        notifications.map((n) {
          if (n.id == notifId) return n.copyWith(read: true);
          return n;
        }).toList(),
      );
    });
    ref.invalidate(unreadCountProvider);
  }

  Future<void> markAllAsRead() async {
    await ref.read(notificationApiServiceProvider).markAllAsRead();
    state.whenData((notifications) {
      state = AsyncData(
        notifications.map((n) => n.copyWith(read: true)).toList(),
      );
    });
    ref.invalidate(unreadCountProvider);
  }
}

@riverpod
Future<int> unreadCount(UnreadCountRef ref) async {
  return ref.read(notificationApiServiceProvider).getUnreadCount();
}
