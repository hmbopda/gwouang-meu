import 'package:freezed_annotation/freezed_annotation.dart';

part 'village_model.freezed.dart';
part 'village_model.g.dart';

@freezed
class VillageModel with _$VillageModel {
  const factory VillageModel({
    required String id,
    required String name,
    String? description,
    required String country,
    String? region,
    String? continentCode,
    String? coverImageUrl,
    double? latitude,
    double? longitude,
    String? primaryDialect,
    @Default(0) int memberCount,
    @Default(false) bool verified,
    int? foundedYear,
    int? populationEstimate,
    String? historicalSummary,
    DateTime? createdAt,
  }) = _VillageModel;

  factory VillageModel.fromJson(Map<String, dynamic> json) =>
      _$VillageModelFromJson(json);
}

extension VillageModelX on VillageModel {
  /// Slug SEO — ex: "Bafia" → "bafia"
  String get slug => name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
}
