import 'package:freezed_annotation/freezed_annotation.dart';

part 'person_genealogy.freezed.dart';
part 'person_genealogy.g.dart';

@freezed
class PersonGenealogy with _$PersonGenealogy {
  const factory PersonGenealogy({
    required String id,
    String? userId,
    @Default([]) List<String> villageIds,
    required String firstName,
    required String lastName,
    String? maidenName,
    required String gender,
    DateTime? birthDate,
    String? birthPlace,
    @Default(true) bool isAlive,
    String? clan,
    String? totem,
    String? nativeLanguage,
    String? photoUrl,
    String? profession,
    String? email,
    String? phone,
    String? religion,
    String? maritalStatus,
    required String privacy,
    required String status,
    DateTime? createdAt,
  }) = _PersonGenealogy;

  factory PersonGenealogy.fromJson(Map<String, dynamic> json) =>
      _$PersonGenealogyFromJson(json);
}
