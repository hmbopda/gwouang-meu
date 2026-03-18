import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gwangmeu/features/notifications/services/notification_api_service.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_data.dart';

void main() {
  late MockApiClient mockApi;
  late NotificationApiService service;

  setUp(() {
    mockApi = MockApiClient();
    service = NotificationApiService(mockApi);
  });

  group('NotificationApiService', () {
    // ── getNotifications ────────────────────────────────────

    test('getNotifications retourne une liste', () async {
      when(() => mockApi.get('/api/v1/notifications')).thenAnswer((_) async => {
            'data': [notificationJson, notificationReadJson]
          });

      final notifs = await service.getNotifications();

      expect(notifs, hasLength(2));
      expect(notifs[0].type, 'CHILD_ASSOCIATION_REQUEST');
      expect(notifs[1].type, 'PARENT_ADDED');
      verify(() => mockApi.get('/api/v1/notifications')).called(1);
    });

    test('getNotifications retourne liste vide', () async {
      when(() => mockApi.get('/api/v1/notifications'))
          .thenAnswer((_) async => {'data': <Map<String, dynamic>>[]});

      final notifs = await service.getNotifications();

      expect(notifs, isEmpty);
    });

    // ── getUnreadCount ──────────────────────────────────────

    test('getUnreadCount retourne le nombre de notifications non lues',
        () async {
      when(() => mockApi.get('/api/v1/notifications/unread-count'))
          .thenAnswer((_) async => {
                'data': {'count': 5}
              });

      final count = await service.getUnreadCount();

      expect(count, 5);
    });

    test('getUnreadCount retourne 0 si aucune notification', () async {
      when(() => mockApi.get('/api/v1/notifications/unread-count'))
          .thenAnswer((_) async => {
                'data': {'count': 0}
              });

      final count = await service.getUnreadCount();

      expect(count, 0);
    });

    // ── markAsRead ──────────────────────────────────────────

    test('markAsRead appelle PATCH avec le bon id', () async {
      when(() => mockApi.patch('/api/v1/notifications/n-001/read'))
          .thenAnswer((_) async => <String, dynamic>{});

      await service.markAsRead('n-001');

      verify(() => mockApi.patch('/api/v1/notifications/n-001/read')).called(1);
    });

    // ── markAllAsRead ───────────────────────────────────────

    test('markAllAsRead appelle PATCH', () async {
      when(() => mockApi.patch('/api/v1/notifications/read-all'))
          .thenAnswer((_) async => <String, dynamic>{});

      await service.markAllAsRead();

      verify(() => mockApi.patch('/api/v1/notifications/read-all')).called(1);
    });

    // ── lookupPersons ───────────────────────────────────────

    test('lookupPersons par email', () async {
      when(() => mockApi.get(
            '/api/v1/persons/lookup',
            queryParameters: {'email': 'jean@test.com'},
          )).thenAnswer((_) async => {
            'data': [personJson]
          });

      final persons =
          await service.lookupPersons(email: 'jean@test.com');

      expect(persons, hasLength(1));
      expect(persons.first.email, 'jean@test.com');
    });

    test('lookupPersons par telephone', () async {
      when(() => mockApi.get(
            '/api/v1/persons/lookup',
            queryParameters: {'phone': '+237600000000'},
          )).thenAnswer((_) async => {
            'data': [personJson]
          });

      final persons =
          await service.lookupPersons(phone: '+237600000000');

      expect(persons, hasLength(1));
    });

    test('lookupPersons ignore les chaines vides', () async {
      when(() => mockApi.get(
            '/api/v1/persons/lookup',
            queryParameters: <String, dynamic>{},
          )).thenAnswer((_) async => {
            'data': <Map<String, dynamic>>[]
          });

      final persons = await service.lookupPersons(email: '', phone: '');

      expect(persons, isEmpty);
    });

    // ── Union confirmation ──────────────────────────────────

    test('confirmUnion appelle POST et retourne la reponse', () async {
      when(() => mockApi.post('/api/v1/unions/un-001/confirm'))
          .thenAnswer((_) async => {
                'data': {'status': 'CONFIRMED'}
              });

      final result = await service.confirmUnion('un-001');

      expect(result['status'], 'CONFIRMED');
    });

    test('contestUnion envoie la raison', () async {
      when(() => mockApi.post(
            '/api/v1/unions/un-001/contest',
            data: {'reason': 'Pas d\'accord'},
          )).thenAnswer((_) async => {
            'data': {'status': 'CONTESTED'}
          });

      final result =
          await service.contestUnion('un-001', 'Pas d\'accord');

      expect(result['status'], 'CONTESTED');
    });

    // ── Dissolution ─────────────────────────────────────────

    test('requestDivorce envoie le document', () async {
      when(() => mockApi.post(
            '/api/v1/dissolutions/unions/un-001/divorce',
            data: {'docUrl': 'https://cdn.example.com/doc.pdf'},
          )).thenAnswer((_) async => {
            'data': {'status': 'PENDING'}
          });

      final result = await service.requestDivorce(
          'un-001', 'https://cdn.example.com/doc.pdf');

      expect(result['status'], 'PENDING');
    });

    test('confirmDivorce appelle POST', () async {
      when(() =>
              mockApi.post('/api/v1/dissolutions/unions/un-001/divorce/confirm'))
          .thenAnswer((_) async => {
                'data': {'status': 'CONFIRMED'}
              });

      final result = await service.confirmDivorce('un-001');

      expect(result['status'], 'CONFIRMED');
    });

    test('contestDivorce envoie la raison', () async {
      when(() => mockApi.post(
            '/api/v1/dissolutions/unions/un-001/divorce/contest',
            data: {'reason': 'Pas d\'accord'},
          )).thenAnswer((_) async => {
            'data': {'status': 'CONTESTED'}
          });

      final result =
          await service.contestDivorce('un-001', 'Pas d\'accord');

      expect(result['status'], 'CONTESTED');
    });

    test('declareDeath envoie le certificat', () async {
      when(() => mockApi.post(
            '/api/v1/dissolutions/unions/un-001/death',
            data: {'docUrl': 'https://cdn.example.com/cert.pdf'},
          )).thenAnswer((_) async => {
            'data': {'status': 'PENDING'}
          });

      final result = await service.declareDeath(
          'un-001', 'https://cdn.example.com/cert.pdf');

      expect(result['status'], 'PENDING');
    });

    test('contestDeath envoie la raison', () async {
      when(() => mockApi.post(
            '/api/v1/dissolutions/unions/un-001/death/contest',
            data: {'reason': 'Erreur'},
          )).thenAnswer((_) async => {
            'data': {'status': 'CONTESTED'}
          });

      final result = await service.contestDeath('un-001', 'Erreur');

      expect(result['status'], 'CONTESTED');
    });

    // ── Child Association ───────────────────────────────────

    test('acceptChildAssociation appelle POST', () async {
      when(() => mockApi
              .post('/api/v1/genealogy/child-associations/req-001/accept'))
          .thenAnswer((_) async => <String, dynamic>{});

      await service.acceptChildAssociation('req-001');

      verify(() => mockApi
              .post('/api/v1/genealogy/child-associations/req-001/accept'))
          .called(1);
    });

    test('rejectChildAssociation appelle POST', () async {
      when(() => mockApi
              .post('/api/v1/genealogy/child-associations/req-001/reject'))
          .thenAnswer((_) async => <String, dynamic>{});

      await service.rejectChildAssociation('req-001');

      verify(() => mockApi
              .post('/api/v1/genealogy/child-associations/req-001/reject'))
          .called(1);
    });

    // ── Erreurs ─────────────────────────────────────────────

    test('getNotifications propage les erreurs', () async {
      when(() => mockApi.get('/api/v1/notifications'))
          .thenThrow(Exception('Network error'));

      expect(
        () => service.getNotifications(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
