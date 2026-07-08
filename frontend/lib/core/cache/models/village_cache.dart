import 'package:hive/hive.dart';

part 'village_cache.g.dart';

@HiveType(typeId: 2)
class VillageCache extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  String? country;

  @HiveField(4)
  String? region;

  @HiveField(5)
  String? coverUrl;

  @HiveField(6)
  int membersCount;

  @HiveField(7)
  bool isMember;

  @HiveField(8)
  DateTime cachedAt;

  VillageCache({
    required this.id,
    required this.name,
    this.description,
    this.country,
    this.region,
    this.coverUrl,
    this.membersCount = 0,
    this.isMember = false,
    required this.cachedAt,
  });
}
