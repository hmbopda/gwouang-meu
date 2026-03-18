import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wrapper autour de Supabase Auth.
/// Centralise toutes les opérations d'authentification.
class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  GoTrueClient get auth => _client.auth;

  // ── Connexion email/password ───────────────────────────────────────────────

  Future<AuthResponse> signInWithPassword(String email, String password) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  // ── Connexion sociale OAuth (Google, Facebook, Apple, GitHub...) ──────────

  /// Ouvre le navigateur pour l'auth OAuth.
  /// Sur mobile, redirige vers io.supabase.gwangmeu://login-callback/
  /// Sur web, Supabase gère la redirection directement.
  Future<void> signInWithOAuth(OAuthProvider provider) async {
    await _client.auth.signInWithOAuth(
      provider,
      redirectTo: kIsWeb
          ? null
          : 'io.supabase.gwangmeu://login-callback/',
    );
  }

  // ── Inscription ───────────────────────────────────────────────────────────

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String displayName,
    String? country,
    String? nativeLanguage,
    String? bio,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'display_name': displayName,
        'role': 'MEMBRE',
        if (country != null) 'country': country,
        if (nativeLanguage != null) 'native_language': nativeLanguage,
        if (bio != null) 'bio': bio,
      },
    );
  }

  // ── Mot de passe oublié ───────────────────────────────────────────────────

  Future<void> resetPassword(String email) {
    return _client.auth.resetPasswordForEmail(email);
  }

  // ── Déconnexion ───────────────────────────────────────────────────────────

  Future<void> signOut() => _client.auth.signOut();

  // ── Session courante ──────────────────────────────────────────────────────

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;
  bool get isAuthenticated => currentSession != null;

  /// Stream des changements d'état d'auth
  /// Utilisé par AuthNotifier et GoRouter pour réagir aux events OAuth
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}

// ── Provider ─────────────────────────────────────────────────────────────────

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});
