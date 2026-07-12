import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// URL de redirection des liens d'authentification par email
/// (confirmation d'inscription + réinitialisation de mot de passe).
///
/// - Sur mobile / desktop natif : deep link custom scheme capté par un
///   intent-filter Android / un CFBundleURLScheme iOS → ré-ouvre l'app sur
///   la route `/auth-callback`.
/// - Sur web : l'origine de l'app + `/auth-callback` (le SDK supabase-flutter
///   consomme automatiquement le fragment/paramètres au démarrage).
String get authRedirectUrl => kIsWeb
    ? '${Uri.base.origin}/auth-callback'
    : 'io.supabase.gwangmeu://auth-callback/';

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
      // Le lien de confirmation d'email ré-ouvre l'app sur /auth-callback
      // (deep link mobile / URL app web) au lieu d'une page Supabase morte.
      emailRedirectTo: authRedirectUrl,
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

  /// Envoie un email de réinitialisation. Le lien ramène dans l'app sur
  /// /auth-callback avec `type=recovery` → écran « Nouveau mot de passe ».
  Future<void> resetPassword(String email) {
    return _client.auth.resetPasswordForEmail(email, redirectTo: authRedirectUrl);
  }

  // ── Mise à jour du mot de passe (après lien recovery) ─────────────────────

  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
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
