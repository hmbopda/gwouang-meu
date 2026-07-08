import 'package:hive/hive.dart';

part 'user_profile_cache.g.dart';

@HiveType(typeId: 1)
class UserProfileCache extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String email;

  @HiveField(2)
  String? displayName;

  @HiveField(3)
  String? avatarUrl;

  @HiveField(4)
  String? coverUrl;

  @HiveField(5)
  String? bio;

  @HiveField(6)
  String? role;

  @HiveField(7)
  DateTime cachedAt;

  UserProfileCache({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.coverUrl,
    this.bio,
    this.role,
    required this.cachedAt,
  });
}
