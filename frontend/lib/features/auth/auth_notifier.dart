import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gwangmeu/core/network/api_client.dart';
import 'package:gwangmeu/core/network/supabase_service.dart';

part 'auth_notifier.g.dart';

enum AuthMode { login, register, forgotPassword }

@riverpod
class AuthNotifier extends _$AuthNotifier {
  /// Bloque onAuthStateChange pendant les operations manuelles (signIn/signUp)
  /// pour eviter une navigation prematuree avant que les appels API ne terminent.
  bool _manualOperation = false;

  @override
  AsyncValue<User?> build() {
    final sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      // Ne pas overrider le state pendant signIn/signUp — sinon l'app navigue
      // vers le feed AVANT que l'appel API backend (/auth/sync ou /auth/register)
      // ne termine, et les donnees ne sont jamais enregistrees en BDD.
      if (!_manualOperation) {
        state = AsyncValue.data(data.session?.user);
      }
    });
    ref.onDispose(sub.cancel);
    return AsyncValue.data(Supabase.instance.client.auth.currentUser);
  }

  SupabaseService get _service => ref.read(supabaseServiceProvider);

  // ── Connexion email / password ─────────────────────────────────────────────

  Future<void> signIn(String email, String password) async {
    _manualOperation = true;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final response = await _service.signInWithPassword(email, password);
      // Sync vers le backend pour creer/mettre a jour l'utilisateur en BDD
      try {
        await ref.read(apiClientProvider).post('/api/v1/users/auth/sync');
      } catch (e) {
        debugPrint('Backend sync failed (non-bloquant): $e');
      }
      return response.user;
    });
    _manualOperation = false;
  }

  // ── Connexion sociale (Google, Facebook, Apple, GitHub...) ─────────────────
  // Ouvre le navigateur — la session arrive via onAuthStateChange (dans build)

  Future<void> signInWithSocial(OAuthProvider provider) async {
    await AsyncValue.guard(() => _service.signInWithOAuth(provider));
  }

  // ── Inscription ───────────────────────────────────────────────────────────

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    required String gender,
    String? country,
    String? nativeLanguage,
    String? bio,
    List<String>? villageIds,
    String? clan,
  }) async {
    _manualOperation = true;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      AuthResponse response;
      try {
        response = await _service.signUp(
          email: email,
          password: password,
          displayName: displayName,
          country: country,
          nativeLanguage: nativeLanguage,
          bio: bio,
        );
      } on AuthException catch (e) {
        // L'email existe deja dans Supabase Auth (tentative precedente echouee
        // cote backend, ou compte deja cree). On tente un signIn + sync.
        if (e.message.toLowerCase().contains('already') ||
            e.message.toLowerCase().contains('exists') ||
            e.message.toLowerCase().contains('registered')) {
          debugPrint('Email deja dans Supabase Auth, fallback signIn + sync');
          response = await _service.signInWithPassword(email, password);
          try {
            await ref.read(apiClientProvider).post('/api/v1/users/auth/sync');
            debugPrint('Sync backend reussie apres fallback signIn');
          } catch (syncErr) {
            debugPrint('Sync backend echouee (non-bloquant): $syncErr');
          }
          return response.user;
        }
        rethrow;
      }

      final userId = response.user?.id;
      if (userId == null || userId.isEmpty) {
        debugPrint('Supabase signUp: user ID null (email confirmation pending?)');
        return response.user;
      }

      // Persister l'utilisateur en BDD via le backend Spring Boot
      // Endpoint PUBLIC /auth/register — pas besoin de JWT
      final api = ref.read(apiClientProvider);
      debugPrint('Appel API /auth/register pour userId=$userId ...');
      await api.post('/api/v1/users/auth/register', data: {
        'supabaseId': userId,
        'email': email,
        'displayName': displayName,
        'gender': gender,
        if (country != null) 'country': country,
        if (nativeLanguage != null) 'nativeLanguage': nativeLanguage,
        if (bio != null) 'bio': bio,
        if (villageIds != null && villageIds.isNotEmpty) 'villageIds': villageIds,
        if (clan != null) 'clan': clan,
      });
      debugPrint('Utilisateur enregistre en BDD avec succes');

      return response.user;
    });
    _manualOperation = false;
  }

  // ── Mot de passe oublie ────────────────────────────────────────────────────

  Future<void> resetPassword(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _service.resetPassword(email);
      return null;
    });
  }

  // ── Deconnexion ────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _service.signOut();
    state = const AsyncValue.data(null);
  }
}
