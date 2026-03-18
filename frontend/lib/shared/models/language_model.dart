import 'package:freezed_annotation/freezed_annotation.dart';

part 'language_model.freezed.dart';
part 'language_model.g.dart';

@freezed
class LanguageModel with _$LanguageModel {
  const factory LanguageModel({
    required String id,
    required String name,
    String? nameLocal,
    @Default(false) bool official,
  }) = _LanguageModel;

  factory LanguageModel.fromJson(Map<String, dynamic> json) =>
      _$LanguageModelFromJson(json);
}
