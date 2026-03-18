import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_group_model.freezed.dart';
part 'chat_group_model.g.dart';

@freezed
class ChatGroupModel with _$ChatGroupModel {
  const factory ChatGroupModel({
    required String id,
    required String villageId,
    required String name,
    String? description,
    required String type,
    @Default(0) int memberCount,
    required String createdBy,
    DateTime? createdAt,
  }) = _ChatGroupModel;

  factory ChatGroupModel.fromJson(Map<String, dynamic> json) =>
      _$ChatGroupModelFromJson(json);
}
