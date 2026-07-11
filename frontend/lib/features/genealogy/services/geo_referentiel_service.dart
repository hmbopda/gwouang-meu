import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gwangmeu/core/network/api_client.dart';

/// Référentiel territorial camerounais (endpoints PUBLICS sous
/// `/api/v1/geo/cm`). Chaîne région → département → arrondissement →
/// chefferie. Modèles légers en lecture seule.

// ── Modèles ─────────────────────────────────────────────────

class GeoRegion {
  const GeoRegion({required this.code, required this.name, this.chiefTown});

  final String code;
  final String name;
  final String? chiefTown;

  factory GeoRegion.fromJson(Map<String, dynamic> json) => GeoRegion(
        code: json['code'] as String,
        name: json['name'] as String,
        chiefTown: json['chiefTown'] as String?,
      );
}

class GeoDepartment {
  const GeoDepartment({
    required this.code,
    required this.regionCode,
    required this.name,
    this.chiefTown,
  });

  final String code;
  final String regionCode;
  final String name;
  final String? chiefTown;

  factory GeoDepartment.fromJson(Map<String, dynamic> json) => GeoDepartment(
        code: json['code'] as String,
        regionCode: json['regionCode'] as String,
        name: json['name'] as String,
        chiefTown: json['chiefTown'] as String?,
      );
}

class GeoArrondissement {
  const GeoArrondissement({
    required this.code,
    required this.departmentCode,
    required this.name,
  });

  final String code;
  final String departmentCode;
  final String name;

  factory GeoArrondissement.fromJson(Map<String, dynamic> json) =>
      GeoArrondissement(
        code: json['code'] as String,
        departmentCode: json['departmentCode'] as String,
        name: json['name'] as String,
      );
}

class GeoChefferie {
  const GeoChefferie({
    required this.degre,
    required this.denomination,
    this.regionName,
    this.departmentName,
    this.departmentCode,
    this.numero,
  });

  final int degre;
  final String denomination;
  final String? regionName;
  final String? departmentName;
  final String? departmentCode;
  final int? numero;

  factory GeoChefferie.fromJson(Map<String, dynamic> json) => GeoChefferie(
        degre: (json['degre'] as num?)?.toInt() ?? 0,
        denomination: json['denomination'] as String? ?? '',
        regionName: json['regionName'] as String?,
        departmentName: json['departmentName'] as String?,
        departmentCode: json['departmentCode'] as String?,
        numero: (json['numero'] as num?)?.toInt(),
      );
}

// ── Service ─────────────────────────────────────────────────

class GeoReferentielService {
  final ApiClient _api;

  GeoReferentielService(this._api);

  static const _base = '/api/v1/geo/cm';

  Future<List<GeoRegion>> fetchRegions() async {
    final response = await _api.get('$_base/regions');
    final list = response['data'] as List;
    return list
        .map((e) => GeoRegion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<GeoDepartment>> fetchDepartments(String regionCode) async {
    final response = await _api.get(
      '$_base/departments',
      queryParameters: {'region': regionCode},
    );
    final list = response['data'] as List;
    return list
        .map((e) => GeoDepartment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<GeoArrondissement>> fetchArrondissements(
      String departmentCode) async {
    final response = await _api.get(
      '$_base/arrondissements',
      queryParameters: {'department': departmentCode},
    );
    final list = response['data'] as List;
    return list
        .map((e) => GeoArrondissement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<GeoChefferie>> fetchChefferies(
    String departmentCode, {
    String? query,
    int limit = 50,
  }) async {
    final response = await _api.get(
      '$_base/chefferies',
      queryParameters: {
        'department': departmentCode,
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        'limit': limit,
      },
    );
    final list = response['data'] as List;
    return list
        .map((e) => GeoChefferie.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// ── Provider ────────────────────────────────────────────────

final geoReferentielServiceProvider = Provider<GeoReferentielService>((ref) {
  return GeoReferentielService(ref.read(apiClientProvider));
});
