import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/notification_model.dart';
import '../../genealogy/models/person_genealogy.dart';

class NotificationApiService {
  final ApiClient _api;

  NotificationApiService(this._api);

  // ── Notifications ─────────────────────────────────────────

  Future<List<NotificationModel>> getNotifications() async {
    final response = await _api.get('/api/v1/notifications');
    final list = response['data'] as List;
    return list
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final response = await _api.get('/api/v1/notifications/unread-count');
    final data = response['data'] as Map<String, dynamic>;
    return (data['count'] as num).toInt();
  }

  Future<void> markAsRead(String notifId) async {
    await _api.patch('/api/v1/notifications/$notifId/read');
  }

  Future<void> markAllAsRead() async {
    await _api.patch('/api/v1/notifications/read-all');
  }

  // ── Lookup persons (deduplication) ────────────────────────

  Future<List<PersonGenealogy>> lookupPersons({
    String? email,
    String? phone,
  }) async {
    final params = <String, dynamic>{};
    if (email != null && email.isNotEmpty) params['email'] = email;
    if (phone != null && phone.isNotEmpty) params['phone'] = phone;

    final response = await _api.get(
      '/api/v1/persons/lookup',
      queryParameters: params,
    );
    final list = response['data'] as List;
    return list
        .map((e) => PersonGenealogy.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Union confirmation ───────────────────────────────────

  Future<Map<String, dynamic>> confirmUnion(String unionId) async {
    final response = await _api.post('/api/v1/unions/$unionId/confirm');
    return response['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> contestUnion(
      String unionId, String reason) async {
    final response = await _api.post(
      '/api/v1/unions/$unionId/contest',
      data: {'reason': reason},
    );
    return response['data'] as Map<String, dynamic>;
  }

  // ── Dissolution ───────────────────────────────────────────

  Future<Map<String, dynamic>> requestDivorce(
      String unionId, String docUrl) async {
    final response = await _api.post(
      '/api/v1/dissolutions/unions/$unionId/divorce',
      data: {'docUrl': docUrl},
    );
    return response['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> confirmDivorce(String unionId) async {
    final response = await _api.post(
      '/api/v1/dissolutions/unions/$unionId/divorce/confirm',
    );
    return response['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> contestDivorce(
      String unionId, String reason) async {
    final response = await _api.post(
      '/api/v1/dissolutions/unions/$unionId/divorce/contest',
      data: {'reason': reason},
    );
    return response['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> declareDeath(
      String unionId, String deathCertificateUrl) async {
    final response = await _api.post(
      '/api/v1/dissolutions/unions/$unionId/death',
      data: {'docUrl': deathCertificateUrl},
    );
    return response['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> contestDeath(
      String unionId, String reason) async {
    final response = await _api.post(
      '/api/v1/dissolutions/unions/$unionId/death/contest',
      data: {'reason': reason},
    );
    return response['data'] as Map<String, dynamic>;
  }

  // ── Child Association ─────────────────────────────────────

  Future<void> acceptChildAssociation(String requestId) async {
    await _api.post('/api/v1/genealogy/child-associations/$requestId/accept');
  }

  Future<void> rejectChildAssociation(String requestId) async {
    await _api.post('/api/v1/genealogy/child-associations/$requestId/reject');
  }
}

// ── Providers ──────────────────────────────────────────────

final notificationApiServiceProvider = Provider<NotificationApiService>((ref) {
  return NotificationApiService(ref.read(apiClientProvider));
});
