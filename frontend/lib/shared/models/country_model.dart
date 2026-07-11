import 'package:freezed_annotation/freezed_annotation.dart';

part 'country_model.freezed.dart';
part 'country_model.g.dart';

@freezed
class CountryModel with _$CountryModel {
  const factory CountryModel({
    required String id,
    required String isoCode,
    // Code ISO-3166 alpha-2 (ex 'CM'). Distinct de isoCode (alpha-3, ex 'CMR').
    // Les fiches persons.origin_country / residence_country sont en ISO-2.
    String? iso2,
    required String name,
    String? continentCode,
    String? flagEmoji,
    String? flagUrl,
    String? phoneCode,
    @Default(0) int villageCount,
  }) = _CountryModel;

  factory CountryModel.fromJson(Map<String, dynamic> json) =>
      _$CountryModelFromJson(json);
}
