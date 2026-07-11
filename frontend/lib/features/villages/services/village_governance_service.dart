import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gwangmeu/core/network/api_client.dart';
import 'package:gwangmeu/shared/models/village_model.dart';

/// Gouvernance de village — permissions, adhésion MEMBRE, rôles délégués,
/// demandes d'adhésion et validations (clan / chefferie / lignée / succession).
///
/// Base : `/api/v1/villages/{villageId}`. Réponses enveloppées `ApiResponse`
/// → lecture systématique via `response['data']`. JWT injecté par [ApiClient].

// ── Modèles ─────────────────────────────────────────────────

/// Permissions de l'utilisateur courant sur un village.
/// [permissions] ∈ VALIDATE_MEMBERS, MODERATE_POSTS, VALIDATE_CULTURE,
/// VALIDATE_SUCCESSION, MANAGE_ROLES, EDIT_VILLAGE.
class MyVillagePermissions {
  const MyVillagePermissions({
    required this.villageId,
    required this.userId,
    required this.chief,
    required this.superAdmin,
    required this.permissions,
  });

  final String villageId;
  final String userId;
  final bool chief;
  final bool superAdmin;
  final List<String> permissions;

  /// Le chef et le super-admin disposent implicitement de toute permission.
  bool has(String perm) =>
      chief || superAdmin || permissions.contains(perm);

  factory MyVillagePermissions.fromJson(Map<String, dynamic> json) =>
      MyVillagePermissions(
        villageId: json['villageId']?.toString() ?? '',
        userId: json['userId']?.toString() ?? '',
        chief: json['chief'] as bool? ?? false,
        superAdmin: json['superAdmin'] as bool? ?? false,
        permissions: (json['permissions'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
}

/// Résultat d'une demande d'adhésion MEMBRE.
/// Admission AUTO si un parent est déjà membre → [member] = true,
/// [status] = AUTO_APPROVED, [autoReason] renseigné.
class MembershipResult {
  const MembershipResult({
    required this.status,
    required this.member,
    this.autoReason,
  });

  /// PENDING | AUTO_APPROVED | APPROVED | REJECTED
  final String status;
  final bool member;
  final String? autoReason;

  factory MembershipResult.fromJson(Map<String, dynamic> json) =>
      MembershipResult(
        status: json['status']?.toString() ?? '',
        member: json['member'] as bool? ?? false,
        autoReason: json['autoReason'] as String?,
      );
}

/// Rôle délégué attribué à un utilisateur au sein du village.
class VillageRole {
  const VillageRole({
    required this.userId,
    required this.title,
    required this.permissions,
    this.id,
    this.villageId,
    this.grantedBy,
  });

  final String userId;
  final String title;
  final List<String> permissions;
  final String? id;
  final String? villageId;
  final String? grantedBy;

  factory VillageRole.fromJson(Map<String, dynamic> json) => VillageRole(
        id: json['id']?.toString(),
        villageId: json['villageId']?.toString(),
        userId: json['userId']?.toString() ?? '',
        title: json['title'] as String? ?? '',
        permissions: (json['permissions'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        grantedBy: json['grantedBy']?.toString(),
      );
}

/// Demande d'adhésion en attente.
class VillageJoinRequest {
  const VillageJoinRequest({
    required this.id,
    required this.userId,
    required this.status,
    this.villageId,
    this.reason,
    this.autoReason,
  });

  final String id;
  final String userId;
  final String status;
  final String? villageId;
  final String? reason;
  final String? autoReason;

  factory VillageJoinRequest.fromJson(Map<String, dynamic> json) =>
      VillageJoinRequest(
        id: json['id']?.toString() ?? '',
        villageId: json['villageId']?.toString(),
        userId: json['userId']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        reason: json['reason'] as String?,
        autoReason: json['autoReason'] as String?,
      );
}

/// Élément de validation communautaire.
/// [kind] ∈ CLAN | CHEFFERIE | CHIEF_LINE | SUCCESSION.
class VillageValidation {
  const VillageValidation({
    required this.id,
    required this.kind,
    required this.title,
    required this.status,
    this.detail,
    this.villageId,
  });

  final String id;
  final String kind;
  final String title;
  final String status;
  final String? detail;
  final String? villageId;

  factory VillageValidation.fromJson(Map<String, dynamic> json) =>
      VillageValidation(
        id: json['id']?.toString() ?? '',
        villageId: json['villageId']?.toString(),
        kind: json['kind']?.toString() ?? '',
        title: json['title'] as String? ?? '',
        detail: json['detail'] as String?,
        status: json['status']?.toString() ?? '',
      );
}

/// Chef d'un village — porteur de la chefferie (créateur ou successeur validé).
/// [since] = année d'accession ; [isCreator] = a fondé le village.
class VillageChief {
  const VillageChief({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.since,
    this.isCreator = false,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int? since;
  final bool isCreator;

  factory VillageChief.fromJson(Map<String, dynamic> json) => VillageChief(
        userId: json['userId']?.toString() ?? '',
        displayName: json['displayName'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String?,
        since: (json['since'] as num?)?.toInt(),
        isCreator: json['isCreator'] as bool? ?? false,
      );
}

/// Invitation reçue à rejoindre un village.
/// [status] ∈ PENDING | ACCEPTED | DECLINED.
class VillageInvitation {
  const VillageInvitation({
    required this.id,
    required this.villageId,
    required this.villageName,
    required this.invitedByName,
    required this.status,
    this.message,
  });

  final String id;
  final String villageId;
  final String villageName;
  final String invitedByName;
  final String status;
  final String? message;

  factory VillageInvitation.fromJson(Map<String, dynamic> json) =>
      VillageInvitation(
        id: json['id']?.toString() ?? '',
        villageId: json['villageId']?.toString() ?? '',
        villageName: json['villageName'] as String? ?? '',
        invitedByName: json['invitedByName'] as String? ?? '',
        status: json['status']?.toString() ?? '',
        message: json['message'] as String?,
      );
}

// ── Service ─────────────────────────────────────────────────

class VillageGovernanceService {
  VillageGovernanceService(this._api);

  final ApiClient _api;

  static const _base = '/api/v1/villages';

  String _v(String villageId) => '$_base/$villageId';

  /// GET /my-permissions
  Future<MyVillagePermissions> myPermissions(String villageId) async {
    final response = await _api.get('${_v(villageId)}/my-permissions');
    return MyVillagePermissions.fromJson(
        response['data'] as Map<String, dynamic>);
  }

  /// POST /membership — demande d'adhésion MEMBRE (peut être auto-approuvée).
  Future<MembershipResult> requestMembership(String villageId) async {
    final response = await _api.post('${_v(villageId)}/membership');
    return MembershipResult.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// GET /roles
  Future<List<VillageRole>> roles(String villageId) async {
    final response = await _api.get('${_v(villageId)}/roles');
    final list = response['data'] as List? ?? const [];
    return list
        .map((e) => VillageRole.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /roles — attribuer un rôle délégué.
  Future<VillageRole> grantRole(
    String villageId,
    String userId,
    String title,
    List<String> permissions,
  ) async {
    final response = await _api.post('${_v(villageId)}/roles', data: {
      'userId': userId,
      'title': title,
      'permissions': permissions,
    });
    return VillageRole.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// DELETE /roles/{userId}
  Future<void> revokeRole(String villageId, String userId) async {
    await _api.delete('${_v(villageId)}/roles/$userId');
  }

  /// GET /join-requests?status=PENDING
  Future<List<VillageJoinRequest>> pendingJoins(String villageId) async {
    final response = await _api.get(
      '${_v(villageId)}/join-requests',
      queryParameters: {'status': 'PENDING'},
    );
    final list = response['data'] as List? ?? const [];
    return list
        .map((e) => VillageJoinRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /join-requests/{id}/approve
  Future<void> approveJoin(String villageId, String id) async {
    await _api.post('${_v(villageId)}/join-requests/$id/approve');
  }

  /// POST /join-requests/{id}/reject
  Future<void> rejectJoin(String villageId, String id) async {
    await _api.post('${_v(villageId)}/join-requests/$id/reject');
  }

  /// GET /validations?kind=&status=PENDING
  Future<List<VillageValidation>> validations(
    String villageId, {
    String? kind,
  }) async {
    final response = await _api.get(
      '${_v(villageId)}/validations',
      queryParameters: {
        'status': 'PENDING',
        if (kind != null && kind.isNotEmpty) 'kind': kind,
      },
    );
    final list = response['data'] as List? ?? const [];
    return list
        .map((e) => VillageValidation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /validations — soumettre un élément à valider.
  Future<VillageValidation> submitValidation(
    String villageId,
    String kind,
    String title,
    String? detail,
  ) async {
    final response = await _api.post('${_v(villageId)}/validations', data: {
      'kind': kind,
      'title': title,
      if (detail != null) 'detail': detail,
    });
    return VillageValidation.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// POST /validations/{id}/decide {approve}
  Future<void> decideValidation(
    String villageId,
    String id,
    bool approve,
  ) async {
    await _api.post(
      '${_v(villageId)}/validations/$id/decide',
      data: {'approve': approve},
    );
  }

  // ── Chefferie / adhésion héritée / invitations ─────────────

  /// GET /{villageId}/chief — chef du village.
  /// Renvoie `null` si le village n'a pas (encore) de chef (404).
  Future<VillageChief?> chief(String villageId) async {
    try {
      final response = await _api.get('${_v(villageId)}/chief');
      final data = response['data'];
      if (data == null) return null;
      return VillageChief.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// GET /eligible — villages où un parent est déjà membre (« hérités »),
  /// que l'utilisateur peut rejoindre en admission automatique.
  Future<List<VillageModel>> eligibleVillages() async {
    final response = await _api.get('$_base/eligible');
    final list = response['data'] as List? ?? const [];
    return list
        .map((e) => VillageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /invitations — invitations reçues par l'utilisateur courant.
  Future<List<VillageInvitation>> myInvitations() async {
    final response = await _api.get('$_base/invitations');
    final list = response['data'] as List? ?? const [];
    return list
        .map((e) => VillageInvitation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /invitations/{id}/accept
  Future<void> acceptInvitation(String id) async {
    await _api.post('$_base/invitations/$id/accept');
  }

  /// POST /invitations/{id}/decline
  Future<void> declineInvitation(String id) async {
    await _api.post('$_base/invitations/$id/decline');
  }

  /// POST /from-chefferie — matérialise une chefferie du référentiel en
  /// communauté (find-or-create par chefferie_id) et inscrit l'utilisateur
  /// comme membre. Idempotent. Renvoie le village fondé/rejoint.
  Future<VillageModel> foundVillageFromChefferie(String chefferieId) async {
    final response = await _api.post(
      '$_base/from-chefferie',
      data: {'chefferieId': chefferieId},
    );
    return VillageModel.fromJson(response['data'] as Map<String, dynamic>);
  }
}

// ── Providers ───────────────────────────────────────────────

final villageGovernanceServiceProvider =
    Provider<VillageGovernanceService>((ref) {
  return VillageGovernanceService(ref.read(apiClientProvider));
});

/// Permissions de l'utilisateur courant sur un village (invalidable).
final villageMyPermissionsProvider =
    FutureProvider.family<MyVillagePermissions, String>((ref, villageId) {
  return ref.read(villageGovernanceServiceProvider).myPermissions(villageId);
});

/// Rôles délégués d'un village (invalidable après grant/revoke).
final villageRolesProvider =
    FutureProvider.family<List<VillageRole>, String>((ref, villageId) {
  return ref.read(villageGovernanceServiceProvider).roles(villageId);
});

/// Demandes d'adhésion en attente (invalidable après approve/reject).
final villagePendingJoinsProvider =
    FutureProvider.family<List<VillageJoinRequest>, String>((ref, villageId) {
  return ref.read(villageGovernanceServiceProvider).pendingJoins(villageId);
});

/// Argument composite pour filtrer les validations par [kind].
class VillageValidationsArg {
  const VillageValidationsArg(this.villageId, {this.kind});

  final String villageId;
  final String? kind;

  @override
  bool operator ==(Object other) =>
      other is VillageValidationsArg &&
      other.villageId == villageId &&
      other.kind == kind;

  @override
  int get hashCode => Object.hash(villageId, kind);
}

/// Validations en attente d'un village, optionnellement filtrées par [kind]
/// (invalidable après submit/decide).
final villageValidationsProvider = FutureProvider.family<List<VillageValidation>,
    VillageValidationsArg>((ref, arg) {
  return ref
      .read(villageGovernanceServiceProvider)
      .validations(arg.villageId, kind: arg.kind);
});

/// Chef d'un village (null si aucun chef). Invalidable après succession.
final villageChiefProvider =
    FutureProvider.family<VillageChief?, String>((ref, villageId) {
  return ref.read(villageGovernanceServiceProvider).chief(villageId);
});

/// Villages hérités — un parent y est déjà membre (admission automatique).
/// Invalidable après avoir rejoint un village.
final eligibleVillagesProvider =
    FutureProvider<List<VillageModel>>((ref) {
  return ref.read(villageGovernanceServiceProvider).eligibleVillages();
});

/// Invitations reçues par l'utilisateur courant.
/// Invalidable après accept/decline.
final villageInvitationsProvider =
    FutureProvider<List<VillageInvitation>>((ref) {
  return ref.read(villageGovernanceServiceProvider).myInvitations();
});
