import 'package:hive/hive.dart';

part 'feed_post_cache.g.dart';

@HiveType(typeId: 0)
class FeedPostCache extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String? authorId;

  @HiveField(2)
  String? authorName;

  @HiveField(3)
  String? authorAvatarUrl;

  @HiveField(4)
  String? content;

  @HiveField(5)
  String? mediaUrl;

  @HiveField(6)
  String? villageId;

  @HiveField(7)
  int likesCount;

  @HiveField(8)
  int commentsCount;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime cachedAt;

  FeedPostCache({
    required this.id,
    this.authorId,
    this.authorName,
    this.authorAvatarUrl,
    this.content,
    this.mediaUrl,
    this.villageId,
    this.likesCount = 0,
    this.commentsCount = 0,
    required this.createdAt,
    required this.cachedAt,
  });
}
