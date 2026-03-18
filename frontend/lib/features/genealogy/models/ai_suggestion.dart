import 'package:freezed_annotation/freezed_annotation.dart';
import 'person_genealogy.dart';

part 'ai_suggestion.freezed.dart';
part 'ai_suggestion.g.dart';

@freezed
class AiSuggestion with _$AiSuggestion {
  const factory AiSuggestion({
    required String id,
    required String personAId,
    required String personBId,
    PersonGenealogy? personA,
    PersonGenealogy? personB,
    required String suggestedRelation,
    required double confidence,
    @Default([]) List<String> reasons,
    required String status,
    DateTime? createdAt,
  }) = _AiSuggestion;

  factory AiSuggestion.fromJson(Map<String, dynamic> json) =>
      _$AiSuggestionFromJson(json);
}
