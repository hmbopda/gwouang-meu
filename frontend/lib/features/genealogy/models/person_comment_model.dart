import 'package:freezed_annotation/freezed_annotation.dart';

part 'person_comment_model.freezed.dart';
part 'person_comment_model.g.dart';

@freezed
class PersonCommentModel with _$PersonCommentModel {
  const factory PersonCommentModel({
    required String id,
    required String personId,
    required String authorId,
    required String authorName,
    String? authorAvatarUrl,
    required String content,
    String? parentCommentId,
    required DateTime createdAt,
  }) = _PersonCommentModel;

  factory PersonCommentModel.fromJson(Map<String, dynamic> json) =>
      _$PersonCommentModelFromJson(json);
}
