import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gwangmeu/core/network/api_client.dart';

/// Vue de gouvernance RÉSOLUE d'un village (API GET /villages/{id}/governance).
/// La topologie (authorityModel) choisit le layout, le registre (themeToken /
/// honorificStyle) choisit le thème — aucune culture codée en dur côté UI.
class GovernanceView {
  const GovernanceView({
    required this.villageId,
    required this.authorityModel,
    required this.themeToken,
    required this.honorificStyle,
    required this.localePrimary,
    required this.state,
    required this.apexVacant,
    required this.seats,
    this.apex,
    this.institution,
  });

  final String villageId;
  final String authorityModel; // MONOCEPHALIC | DYARCHIC | COLLEGIAL | ROTATING | ACEPHALOUS
  final String themeToken; // gov.royal | gov.religious | gov.stool | gov.respect | gov.neutral
  final String honorificStyle; // NONE | RESPECT | ROYAL | RELIGIOUS | IMPERIAL
  final String localePrimary;
  final String state; // ABSENT | DOCUMENTED | VERIFIED
  final bool apexVacant;
  final GovHolder? apex;
  final List<GovSeat> seats;
  final GovInstitution? institution;

  bool get isAcephalous => authorityModel == 'ACEPHALOUS';
  bool get isRoyalTheme => themeToken == 'gov.royal';

  /// Sièges de notables/charges (hors apex) portant au moins un titulaire.
  List<GovSeat> get notableSeats =>
      seats.where((s) => !s.isApex && s.holders.isNotEmpty).toList();

  factory GovernanceView.fromJson(Map<String, dynamic> json) => GovernanceView(
        villageId: json['villageId']?.toString() ?? '',
        authorityModel: json['authorityModel'] as String? ?? 'ACEPHALOUS',
        themeToken: json['themeToken'] as String? ?? 'gov.neutral',
        honorificStyle: json['honorificStyle'] as String? ?? 'RESPECT',
        localePrimary: json['localePrimary'] as String? ?? 'fr',
        state: json['state'] as String? ?? 'ABSENT',
        apexVacant: json['apexVacant'] as bool? ?? true,
        apex: json['apex'] == null
            ? null
            : GovHolder.fromJson(json['apex'] as Map<String, dynamic>),
        seats: (json['seats'] as List? ?? const [])
            .map((e) => GovSeat.fromJson(e as Map<String, dynamic>))
            .toList(),
        institution: json['institution'] == null
            ? null
            : GovInstitution.fromJson(
                json['institution'] as Map<String, dynamic>),
      );
}

class GovSeat {
  const GovSeat({
    required this.officeId,
    required this.officeKey,
    required this.titleLabel,
    required this.tier,
    required this.rank,
    required this.isApex,
    required this.vacant,
    required this.holders,
    this.honorific,
  });

  final String officeId;
  final String officeKey;
  final String titleLabel;
  final String? honorific;
  final int tier;
  final int rank;
  final bool isApex;
  final bool vacant;
  final List<GovHolder> holders;

  factory GovSeat.fromJson(Map<String, dynamic> json) => GovSeat(
        officeId: json['officeId']?.toString() ?? '',
        officeKey: json['officeKey'] as String? ?? '',
        titleLabel: json['titleLabel'] as String? ?? '',
        honorific: json['honorific'] as String?,
        tier: (json['tier'] as num?)?.toInt() ?? 0,
        rank: (json['rank'] as num?)?.toInt() ?? 100,
        isApex: json['isApex'] as bool? ?? false,
        vacant: json['vacant'] as bool? ?? true,
        holders: (json['holders'] as List? ?? const [])
            .map((e) => GovHolder.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class GovHolder {
  const GovHolder({
    required this.displayName,
    required this.current,
    this.titleLabel,
    this.ordinal,
    this.termStart,
    this.termEnd,
    this.avatarUrl,
    this.userId,
  });

  final String displayName;
  final String? titleLabel;
  final int? ordinal;
  final int? termStart;
  final int? termEnd;
  final bool current;
  final String? avatarUrl;
  final String? userId;

  factory GovHolder.fromJson(Map<String, dynamic> json) => GovHolder(
        displayName: json['displayName'] as String? ?? '',
        titleLabel: json['titleLabel'] as String?,
        ordinal: (json['ordinal'] as num?)?.toInt(),
        termStart: (json['termStart'] as num?)?.toInt(),
        termEnd: (json['termEnd'] as num?)?.toInt(),
        current: json['current'] as bool? ?? false,
        avatarUrl: json['avatarUrl'] as String?,
        userId: json['userId'] as String?,
      );
}

class GovInstitution {
  const GovInstitution({
    this.degre,
    this.acte,
    this.apexTitleCode,
    this.modelCode,
    this.properName,
  });

  final int? degre;
  final String? acte;
  final String? apexTitleCode;
  final String? modelCode;
  final String? properName;

  /// Libellé du degré MINAT (Cameroun) — 1er/2e/3e.
  String? get degreLabel => switch (degre) {
        1 => '1er degré',
        2 => '2e degré',
        3 => '3e degré',
        _ => null,
      };

  factory GovInstitution.fromJson(Map<String, dynamic> json) => GovInstitution(
        degre: (json['degre'] as num?)?.toInt(),
        acte: json['acte'] as String?,
        apexTitleCode: json['apexTitleCode'] as String?,
        modelCode: json['modelCode'] as String?,
        properName: json['properName'] as String?,
      );
}

/// Vue de gouvernance d'un village (chef + notables + institution + thème).
final governanceViewProvider =
    FutureProvider.autoDispose.family<GovernanceView, String>((ref, villageId) async {
  final client = ref.read(apiClientProvider);
  final json = await client.get('/api/v1/villages/$villageId/governance');
  return GovernanceView.fromJson(json['data'] as Map<String, dynamic>);
});

/// Écriture de la gouvernance : gestion des NOTABLES (gated EDIT_VILLAGE côté
/// API). Le chef (apex) se gère via la dynastie (/chiefs).
final governanceAdminProvider =
    Provider<GovernanceAdmin>((ref) => GovernanceAdmin(ref.read(apiClientProvider)));

class GovernanceAdmin {
  GovernanceAdmin(this._api);
  final ApiClient _api;

  Map<String, dynamic> _body(
          String displayName, String? title, int? rank, int? termStart) =>
      {
        'displayName': displayName.trim(),
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        if (rank != null) 'rank': rank,
        if (termStart != null) 'termStart': termStart,
      };

  Future<void> addNotable(String villageId,
      {required String displayName, String? title, int? rank, int? termStart}) async {
    await _api.post('/api/v1/villages/$villageId/governance/notables',
        data: _body(displayName, title, rank, termStart));
  }

  Future<void> updateNotable(String villageId, String officeId,
      {required String displayName, String? title, int? rank, int? termStart}) async {
    await _api.put('/api/v1/villages/$villageId/governance/notables/$officeId',
        data: _body(displayName, title, rank, termStart));
  }

  Future<void> deleteNotable(String villageId, String officeId) =>
      _api.delete('/api/v1/villages/$villageId/governance/notables/$officeId');
}
