import 'package:freezed_annotation/freezed_annotation.dart';
import 'person_genealogy.dart';

part 'sibling_genealogy.freezed.dart';
part 'sibling_genealogy.g.dart';

@freezed
class SiblingGenealogy with _$SiblingGenealogy {
  const factory SiblingGenealogy({
    required PersonGenealogy person,
    required String type, // FULL, HALF_PATERNAL, HALF_MATERNAL, STEP
    String? sharedParentId,
  }) = _SiblingGenealogy;

  factory SiblingGenealogy.fromJson(Map<String, dynamic> json) =>
      _$SiblingGenealogyFromJson(json);
}
