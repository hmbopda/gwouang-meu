import 'package:mocktail/mocktail.dart';
import 'package:gwangmeu/core/network/api_client.dart';
import 'package:gwangmeu/features/genealogy/services/genealogy_api_service.dart';
import 'package:gwangmeu/features/notifications/services/notification_api_service.dart';

/// Mock du client HTTP central.
class MockApiClient extends Mock implements ApiClient {}

/// Mock du service API genealogie.
class MockGenealogyApiService extends Mock implements GenealogyApiService {}

/// Mock du service API notifications.
class MockNotificationApiService extends Mock
    implements NotificationApiService {}
