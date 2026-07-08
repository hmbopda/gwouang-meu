import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:gwangmeu/core/network/api_client.dart';

part 'notification_service.g.dart';

// Handler pour les messages reçus en background (top-level, pas dans une classe)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase est déjà initialisé dans main.dart
  debugPrint('[FCM] Background message: ${message.messageId}');
}

@riverpod
NotificationService notificationService(Ref ref) {
  return NotificationService(ref);
}

class NotificationService {
  final Ref _ref;

  final _fcm = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'gwangmeu_channel',
    'Gwang Meu',
    description: 'Notifications Gwang Meu',
    importance: Importance.high,
  );

  NotificationService(this._ref);

  Future<void> init() async {
    // 1) Demander la permission
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2) Configurer les local notifications Android
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
    }

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // 3) Gérer les messages en foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 4) Gérer le clic sur notification quand app était en background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 5) Envoyer le token FCM au backend
    await _registerToken();

    // 6) Écouter les refresh de token
    _fcm.onTokenRefresh.listen(_sendTokenToBackend);
  }

  Future<void> _registerToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      debugPrint('[FCM] Impossible de récupérer le token: $e');
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      final client = _ref.read(apiClientProvider);
      await client.patch('/api/v1/users/me/fcm-token', data: {'fcmToken': token});
      debugPrint('[FCM] Token enregistré sur le backend');
    } catch (e) {
      debugPrint('[FCM] Erreur envoi token backend: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          icon: '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('[FCM] App ouverte depuis notification: ${message.data}');
    // Navigation future possible ici via GoRouter
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('[FCM] Tap notification payload: ${response.payload}');
    // Navigation future possible ici via GoRouter
  }
}
