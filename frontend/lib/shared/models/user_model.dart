import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String email,
    String? displayName,
    String? avatarUrl,
    String? coverUrl,
    @Default('MEMBRE') String role,
    String? country,
    String? nativeLanguage,
    String? bio,
    String? supabaseId,
    @Default(false) bool verified,
    DateTime? createdAt,
    // Parents
    String? fatherName,
    String? fatherOrigin,
    String? motherName,
    String? motherOrigin,
    // Famille
    String? maritalStatus,
    String? matrimonialRegime,
    int? childrenCount,
    String? diet,
    // Origines culturelles (village gere via village_subscriptions)
    String? tribe,
    String? clan,
    // Origine référentielle (ancre de la lignée, noms du référentiel)
    String? originCountry,
    String? originRegion,
    String? originDepartment,
    String? originArrondissement,
    String? originVillage,
    // Residence & Profession
    String? profession,
    String? employer,
    String? residenceCity,
    String? residenceCountry,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
