import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gwangmeu/features/genealogy/models/person_genealogy.dart';

part 'genealogy_union.freezed.dart';
part 'genealogy_union.g.dart';

@freezed
class GenealogyUnion with _$GenealogyUnion {
  const factory GenealogyUnion({
    required String id,
    required String husbandId,
    required String wifeId,
    PersonGenealogy? husband,
    PersonGenealogy? wife,
    @Default([]) List<String> unionTypes,
    required int unionOrder,
    DateTime? startDate,
    DateTime? endDate,
    required bool isActive,
    required bool isDotPaid,
    DateTime? dotDate,
    String? dotPaidBy,
    String? dotDescription,
    @Default([]) List<String> dotWitnesses,
    String? endReason,
    // ── Régime matrimonial / conformité au droit civil ──
    String? legalRegime,
    @Default(false) bool isPolygamous,
    // Pays de rattachement légal, ISO-3166 alpha-2.
    String? legalCountry,
    // COMPLIANT | WARNING | NON_COMPLIANT | UNKNOWN.
    @Default('UNKNOWN') String complianceStatus,
    String? complianceNote,
  }) = _GenealogyUnion;

  factory GenealogyUnion.fromJson(Map<String, dynamic> json) =>
      _$GenealogyUnionFromJson(json);
}
