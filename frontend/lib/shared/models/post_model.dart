import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_model.freezed.dart';
part 'post_model.g.dart';

enum PostType { text, media, live, aiSuggestion }

@freezed
class PostModel with _$PostModel {
  const factory PostModel({
    required String id,
    required String authorId,
    required String villageId,
    required String content,
    String? mediaUrl,
    String? mediaType,
    @Default([]) List<String> mediaUrls,
    @Default('PENDING') String moderationStatus,
    @Default(0) int reactionCount,
    @Default(0) int commentCount,
    @Default(0) int shareCount,
    @Default(0) int flagCount,
    @Default([]) List<String> reactions,
    @Default([]) List<String> tags,
    @Default(false) bool isLive,
    int? liveViewerCount,
    @Default(false) bool isLargeText,
    @Default(false) bool isAiSuggestion,
    String? aiConfidence,
    String? aiDescription,

    /// Id de la suggestion IA associée (post « Mémoire familiale »).
    /// `null` tant que le backend n'en fournit pas : le CTA « Explorer le
    /// lien » reste alors inactif.
    String? aiSuggestionId,
    DateTime? createdAt,
    String? authorDisplayName,
    String? authorAvatarUrl,
    String? authorRole,
    String? villageName,
  }) = _PostModel;

  factory PostModel.fromJson(Map<String, dynamic> json) =>
      _$PostModelFromJson(json);
}

extension PostModelX on PostModel {
  bool get isApproved => moderationStatus == 'APPROVED';
  bool get isPending => moderationStatus == 'PENDING';

  PostType get postType {
    if (isAiSuggestion) return PostType.aiSuggestion;
    if (isLive) return PostType.live;
    if (mediaUrl != null || mediaUrls.isNotEmpty) return PostType.media;
    return PostType.text;
  }

  bool get hasMediaGrid => mediaUrls.length > 1;
}
