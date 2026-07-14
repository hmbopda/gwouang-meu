import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gwangmeu/core/network/api_client.dart';

/// Panneau d'administration — accès réservé aux **super-admins** ET **au web**.
///
/// Tous les appels sont AUTHENTIFIÉS : le JWT Supabase est injecté par
/// [ApiClient] comme pour tous les `/api/v1/**`. Le backend est lui-même gardé
/// `SUPER_ADMIN` (403 sinon). Réponses enveloppées `ApiResponse` → charge utile
/// dans `data` (et message serveur dans `message`).

/// Les 6 rôles reconnus par le backend (valeurs exactes du contrat).
///
/// Exposés en constantes plutôt qu'en énum pour coller au contrat `String role`
/// tout en évitant les chaînes magiques côté UI.
abstract final class AdminRoles {
  static const superAdmin = 'SUPER_ADMIN';
  static const moderateur = 'MODERATEUR';
  static const ambassadeur = 'AMBASSADEUR';
  static const membre = 'MEMBRE';
  static const visiteur = 'VISITEUR';
  static const api = 'API';

  /// Ordre d'affichage (du plus au moins privilégié).
  static const all = <String>[
    superAdmin,
    moderateur,
    ambassadeur,
    membre,
    visiteur,
    api,
  ];

  /// Libellé lisible (français) pour un code de rôle.
  static String label(String role) {
    switch (role) {
      case superAdmin:
        return 'Super-admin';
      case moderateur:
        return 'Modérateur';
      case ambassadeur:
        return 'Ambassadeur';
      case membre:
        return 'Membre';
      case visiteur:
        return 'Visiteur';
      case api:
        return 'API';
      default:
        return role;
    }
  }
}

/// Utilisateur vu par le panneau d'administration (désenveloppé depuis `data`).
class AdminUser {
  const AdminUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.active,
  });

  final String id;
  final String email;
  final String? displayName;
  final String role;
  final bool active;

  factory AdminUser.fromJson(Map<String, dynamic> j) => AdminUser(
        id: (j['id'] ?? '').toString(),
        email: (j['email'] as String? ?? '').trim(),
        displayName: _blankToNull(j['displayName']),
        role: (j['role'] as String? ?? AdminRoles.membre).trim(),
        active: j['active'] as bool? ?? true,
      );

  /// Ramène les chaînes vides/espaces à `null`.
  static String? _blankToNull(dynamic v) {
    if (v is! String) return null;
    final s = v.trim();
    return s.isEmpty ? null : s;
  }
}

class AdminService {
  AdminService(this._api);
  final ApiClient _api;

  /// TEST D'ACCÈS — `GET /admin/me` : 200 ⇒ super-admin (true). Toute erreur
  /// (403 « accès refusé », réseau, autre) ⇒ false, jamais d'exception.
  Future<bool> hasAccess() async {
    try {
      await _api.get('/api/v1/admin/me');
      return true;
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Liste de tous les utilisateurs (super-admin uniquement côté serveur).
  Future<List<AdminUser>> listUsers() async {
    final r = await _api.get('/api/v1/admin/users');
    final data = r['data'];
    final list = data is List ? data : <dynamic>[];
    return list
        .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Change le rôle d'un utilisateur. Le backend peut renvoyer 400 sur
  /// garde-fou (ex. se retirer soi-même super-admin) — la [DioException]
  /// remonte alors à l'UI qui affiche `message` serveur.
  Future<AdminUser> setRole(String id, String role) async {
    final r = await _api.patch(
      '/api/v1/admin/users/$id/role',
      data: {'role': role},
    );
    return AdminUser.fromJson(r['data'] as Map<String, dynamic>);
  }

  /// Active / désactive un utilisateur. 400 possible (ex. se désactiver
  /// soi-même) — la [DioException] remonte à l'UI.
  Future<AdminUser> setActive(String id, bool active) async {
    final r = await _api.patch(
      '/api/v1/admin/users/$id/status',
      data: {'active': active},
    );
    return AdminUser.fromJson(r['data'] as Map<String, dynamic>);
  }
}

// ── Providers Riverpod ─────────────────────────────────────────────────────

final adminServiceProvider = Provider<AdminService>(
  (ref) => AdminService(ref.read(apiClientProvider)),
);

/// Accès au panneau admin : **web ET super-admin**.
///
/// Sur mobile / desktop natif, renvoie `false` IMMÉDIATEMENT (aucun appel
/// réseau) grâce à [kIsWeb]. Sur le web, délègue à `GET /admin/me`.
final adminAccessProvider = FutureProvider<bool>((ref) async {
  if (!kIsWeb) return false;
  return ref.read(adminServiceProvider).hasAccess();
});

/// Liste des utilisateurs pour le tableau d'administration.
final adminUsersProvider = FutureProvider<List<AdminUser>>(
  (ref) => ref.read(adminServiceProvider).listUsers(),
);
