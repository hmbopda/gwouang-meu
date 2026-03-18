import 'package:freezed_annotation/freezed_annotation.dart';

part 'country_model.freezed.dart';
part 'country_model.g.dart';

@freezed
class CountryModel with _$CountryModel {
  const factory CountryModel({
    required String id,
    required String isoCode,
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
