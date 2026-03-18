import 'package:freezed_annotation/freezed_annotation.dart';

part 'village_member_model.freezed.dart';
part 'village_member_model.g.dart';

@freezed
class VillageMemberModel with _$VillageMemberModel {
  const factory VillageMemberModel({
    required String userId,
    String? displayName,
    String? avatarUrl,
    required String type,
    DateTime? joinedAt,
  }) = _VillageMemberModel;

  factory VillageMemberModel.fromJson(Map<String, dynamic> json) =>
      _$VillageMemberModelFromJson(json);
}
