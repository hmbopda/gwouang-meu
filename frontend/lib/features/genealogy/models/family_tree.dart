import 'package:freezed_annotation/freezed_annotation.dart';
import 'ai_suggestion.dart';
import 'genealogy_union.dart';
import 'person_genealogy.dart';
import 'sibling_genealogy.dart';

part 'family_tree.freezed.dart';
part 'family_tree.g.dart';

@freezed
class FamilyTree with _$FamilyTree {
  const factory FamilyTree({
    required PersonGenealogy subject,
    @Default([]) List<PersonGenealogy> father,
    @Default([]) List<PersonGenealogy> mother,
    @Default([]) List<PersonGenealogy> paternalGP,
    @Default([]) List<PersonGenealogy> maternalGP,
    @Default([]) List<SiblingGenealogy> siblings,
    @Default([]) List<PersonGenealogy> children,
    @Default([]) List<GenealogyUnion> unions,
    @Default([]) List<PersonGenealogy> cousins,
    @Default([]) List<PersonGenealogy> uncles,
    @Default([]) List<AiSuggestion> pendingSuggestions,
  }) = _FamilyTree;

  factory FamilyTree.fromJson(Map<String, dynamic> json) =>
      _$FamilyTreeFromJson(json);
}
