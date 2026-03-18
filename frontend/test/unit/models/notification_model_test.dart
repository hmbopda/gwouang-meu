import 'package:flutter_test/flutter_test.dart';
import 'package:gwangmeu/features/notifications/models/notification_model.dart';

import '../../helpers/test_data.dart';

void main() {
  group('NotificationModel', () {
    test('fromJson notification non lue', () {
      final notif = NotificationModel.fromJson(notificationJson);

      expect(notif.id, 'n-001');
      expect(notif.type, 'CHILD_ASSOCIATION_REQUEST');
      expect(notif.title, contains('association'));
      expect(notif.body, contains('Amara'));
      expect(notif.data['requestId'], 'req-001');
      expect(notif.data['childName'], 'Amara');
      expect(notif.read, false);
    });

    test('fromJson notification lue', () {
      final notif = NotificationModel.fromJson(notificationReadJson);

      expect(notif.id, 'n-002');
      expect(notif.type, 'PARENT_ADDED');
      expect(notif.read, true);
      expect(notif.data, isEmpty);
    });

    test('toJson puis fromJson preservent les donnees', () {
      final original = NotificationModel.fromJson(notificationJson);
      final roundTrip = NotificationModel.fromJson(original.toJson());

      expect(roundTrip, original);
    });

    test('egalite entre deux instances identiques', () {
      final a = NotificationModel.fromJson(notificationJson);
      final b = NotificationModel.fromJson(notificationJson);

      expect(a, b);
    });

    test('defaults appliques', () {
      final notif = NotificationModel.fromJson({
        'id': 'n-min',
        'type': 'TEST',
        'title': 'Test',
        'body': 'Body',
      });

      expect(notif.data, isEmpty);
      expect(notif.read, false);
      expect(notif.createdAt, isNull);
    });

    test('copyWith marquer comme lu', () {
      final notif = NotificationModel.fromJson(notificationJson);
      final read = notif.copyWith(read: true);

      expect(read.read, true);
      expect(read.id, notif.id);
      expect(read.type, notif.type);
    });
  });
}
