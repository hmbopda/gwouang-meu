import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:gwangmeu/core/network/api_client.dart';
import 'package:gwangmeu/shared/models/country_model.dart';
import 'package:gwangmeu/shared/models/language_model.dart';
import 'package:gwangmeu/shared/models/village_model.dart';

part 'geo_notifier.g.dart';

/// Charge la liste de tous les pays depuis l'API.
@riverpod
class CountriesNotifier extends _$CountriesNotifier {
  @override
  Future<List<CountryModel>> build() async {
    final api = ref.read(apiClientProvider);
    final json = await api.get('/api/v1/geo/countries');
    final list = json['data'] as List<dynamic>;
    return list
        .map((e) => CountryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Charge les villages d'un pays donne (par code ISO alpha-3).
/// Retourne une liste vide si countryCode est null.
@riverpod
class VillagesByCountryNotifier extends _$VillagesByCountryNotifier {
  @override
  Future<List<VillageModel>> build(String? countryCode) async {
    if (countryCode == null || countryCode.isEmpty) return [];
    final api = ref.read(apiClientProvider);
    final json = await api.get('/api/v1/villages/country/$countryCode');
    final list = json['data'] as List<dynamic>;
    return list
        .map((e) => VillageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Charge les langues d'un pays donne (par code ISO alpha-3).
/// Retourne une liste vide si countryCode est null.
@riverpod
class LanguagesByCountryNotifier extends _$LanguagesByCountryNotifier {
  @override
  Future<List<LanguageModel>> build(String? countryCode) async {
    if (countryCode == null || countryCode.isEmpty) return [];
    final api = ref.read(apiClientProvider);
    final json = await api.get('/api/v1/geo/countries/$countryCode/languages');
    final list = json['data'] as List<dynamic>;
    return list
        .map((e) => LanguageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Charge les clans distincts existants pour un village donne.
/// Retourne une liste vide si villageId est null.
@riverpod
class ClansByVillageNotifier extends _$ClansByVillageNotifier {
  @override
  Future<List<String>> build(String? villageId) async {
    if (villageId == null || villageId.isEmpty) return [];
    final api = ref.read(apiClientProvider);
    final json = await api.get('/api/v1/persons/village/$villageId/clans');
    final list = json['data'] as List<dynamic>;
    return list.map((e) => e as String).toList();
  }
}
