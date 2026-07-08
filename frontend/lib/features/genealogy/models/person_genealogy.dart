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
    // Pays de résidence, ISO-3166 alpha-2 (ex : CM, FR).
    String? residenceCountry,
    // Régime matrimonial déclaré : MONOGAMY, POLYGAMY, CUSTOMARY, DE_FACTO, UNKNOWN.
    String? maritalRegime,
    required String privacy,
    required String status,
    DateTime? createdAt,
    // ── Rattachement généalogique (rempli quand la personne est exposée comme enfant) ──
    // Id de la mère (parent_role MOTHER) — null si inconnu.
    String? motherId,
    // Id du père (parent_role FATHER) — null si inconnu.
    String? fatherId,
    // Id de l'union rattachant l'enfant à la bonne co-épouse — null si non dérivable.
    String? unionId,
  }) = _PersonGenealogy;

  factory PersonGenealogy.fromJson(Map<String, dynamic> json) =>
      _$PersonGenealogyFromJson(json);
}
