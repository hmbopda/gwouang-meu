import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stockage chiffré pour données sensibles non gérées par Supabase.
/// Note : le JWT Supabase est géré par supabase_flutter en interne.
/// Ce service est utilisé pour les préférences sécurisées supplémentaires.
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keyFcmToken = 'fcm_token';
  static const _keyUserPrefs = 'user_prefs';

  // ── FCM Token ─────────────────────────────────────────────────────────────

  Future<void> saveFcmToken(String token) async {
    await _storage.write(key: _keyFcmToken, value: token);
  }

  Future<String?> getFcmToken() async {
    return _storage.read(key: _keyFcmToken);
  }

  // ── Préférences utilisateur ───────────────────────────────────────────────

  Future<void> saveUserPrefs(String json) async {
    await _storage.write(key: _keyUserPrefs, value: json);
  }

  Future<String?> getUserPrefs() async {
    return _storage.read(key: _keyUserPrefs);
  }

  // ── Utilitaires ───────────────────────────────────────────────────────────

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
