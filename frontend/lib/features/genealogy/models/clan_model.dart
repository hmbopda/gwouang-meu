import 'package:freezed_annotation/freezed_annotation.dart';

part 'clan_model.freezed.dart';
part 'clan_model.g.dart';

@freezed
class ClanModel with _$ClanModel {
  const factory ClanModel({
    required String id,
    required String name,
    required String villageId,
    String? description,
    @Default(0) int personCount,
  }) = _ClanModel;

  factory ClanModel.fromJson(Map<String, dynamic> json) =>
      _$ClanModelFromJson(json);
}
