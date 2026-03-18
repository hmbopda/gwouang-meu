import 'package:flutter_test/flutter_test.dart';
import 'package:gwangmeu/features/genealogy/models/ai_suggestion.dart';
import 'package:gwangmeu/features/genealogy/models/clan_model.dart';
import 'package:gwangmeu/features/genealogy/models/genealogy_union.dart';
import 'package:gwangmeu/features/genealogy/models/person_comment_model.dart';
import 'package:gwangmeu/features/genealogy/models/sibling_genealogy.dart';

import '../../helpers/test_data.dart';

void main() {
  group('GenealogyUnion', () {
    test('fromJson avec tous les champs', () {
      final union = GenealogyUnion.fromJson(unionJson);

      expect(union.id, 'un-001');
      expect(union.husbandId, 'pe-001');
      expect(union.wifeId, 'pe-003');
      expect(union.unionTypes, ['MARRIAGE_CIVIL', 'MARRIAGE_TRADITIONAL']);
      expect(union.unionOrder, 1);
      expect(union.startDate, isNotNull);
      expect(union.isActive, true);
      expect(union.isDotPaid, true);
      expect(union.dotPaidBy, 'pe-001');
      expect(union.dotDescription, contains('Bassa'));
      expect(union.dotWitnesses, hasLength(2));
      expect(union.endReason, isNull);
    });

    test('fromJson avec champs minimaux', () {
      final union = GenealogyUnion.fromJson({
        'id': 'un-min',
        'husbandId': 'pe-a',
        'wifeId': 'pe-b',
        'unionOrder': 1,
        'isActive': false,
        'isDotPaid': false,
      });

      expect(union.unionTypes, isEmpty);
      expect(union.dotWitnesses, isEmpty);
      expect(union.husband, isNull);
      expect(union.wife, isNull);
      expect(union.startDate, isNull);
    });

    test('toJson puis fromJson preservent les donnees', () {
      final original = GenealogyUnion.fromJson(unionJson);
      final roundTrip = GenealogyUnion.fromJson(original.toJson());

      expect(roundTrip, original);
    });

    test('egalite', () {
      final a = GenealogyUnion.fromJson(unionJson);
      final b = GenealogyUnion.fromJson(unionJson);

      expect(a, b);
    });
  });

  group('ClanModel', () {
    test('fromJson avec tous les champs', () {
      final clan = ClanModel.fromJson(clanJson);

      expect(clan.id, 'cl-001');
      expect(clan.name, 'Bakoko');
      expect(clan.villageId, 'v-001');
      expect(clan.description, contains('Bassa'));
      expect(clan.personCount, 12);
    });

    test('fromJson avec champs minimaux', () {
      final clan = ClanModel.fromJson({
        'id': 'cl-min',
        'name': 'Beti',
        'villageId': 'v-002',
      });

      expect(clan.description, isNull);
      expect(clan.personCount, 0);
    });

    test('toJson puis fromJson preservent les donnees', () {
      final original = ClanModel.fromJson(clanJson);
      final roundTrip = ClanModel.fromJson(original.toJson());

      expect(roundTrip, original);
    });
  });

  group('SiblingGenealogy', () {
    test('fromJson avec tous les champs', () {
      final sibling = SiblingGenealogy.fromJson(siblingJson);

      expect(sibling.person.firstName, 'Marie');
      expect(sibling.type, 'FULL');
      expect(sibling.sharedParentId, 'pe-010');
    });

    test('fromJson sans sharedParentId', () {
      final sibling = SiblingGenealogy.fromJson({
        'person': personMinimalJson,
        'type': 'HALF_PATERNAL',
      });

      expect(sibling.type, 'HALF_PATERNAL');
      expect(sibling.sharedParentId, isNull);
    });

    test('toJson produit un Map serialisable', () {
      final original = SiblingGenealogy.fromJson(siblingJson);
      final json = original.toJson();

      expect(json.containsKey('person'), true);
      expect(json.containsKey('type'), true);
      expect(json['type'], 'FULL');
    });
  });

  group('PersonCommentModel', () {
    test('fromJson avec tous les champs', () {
      final comment = PersonCommentModel.fromJson(commentJson);

      expect(comment.id, 'co-001');
      expect(comment.personId, 'pe-001');
      expect(comment.authorId, 'u-001');
      expect(comment.authorName, 'Jean Kouassi');
      expect(comment.content, contains('chasseur'));
      expect(comment.parentCommentId, isNull);
      expect(comment.createdAt, isNotNull);
    });

    test('fromJson reponse a un commentaire', () {
      final reply = PersonCommentModel.fromJson({
        ...commentJson,
        'id': 'co-002',
        'parentCommentId': 'co-001',
        'content': 'Merci pour le partage!',
      });

      expect(reply.parentCommentId, 'co-001');
    });

    test('toJson puis fromJson preservent les donnees', () {
      final original = PersonCommentModel.fromJson(commentJson);
      final roundTrip = PersonCommentModel.fromJson(original.toJson());

      expect(roundTrip, original);
    });
  });

  group('AiSuggestion', () {
    test('fromJson avec tous les champs', () {
      final suggestion = AiSuggestion.fromJson(aiSuggestionJson);

      expect(suggestion.id, 'ai-001');
      expect(suggestion.personAId, 'pe-001');
      expect(suggestion.personBId, 'pe-010');
      expect(suggestion.suggestedRelation, 'FATHER');
      expect(suggestion.confidence, 0.92);
      expect(suggestion.reasons, hasLength(2));
      expect(suggestion.status, 'PENDING');
      expect(suggestion.personA, isNull);
      expect(suggestion.personB, isNull);
    });

    test('fromJson avec champs minimaux', () {
      final suggestion = AiSuggestion.fromJson({
        'id': 'ai-min',
        'personAId': 'pe-a',
        'personBId': 'pe-b',
        'suggestedRelation': 'SIBLING',
        'confidence': 0.5,
        'status': 'PENDING',
      });

      expect(suggestion.reasons, isEmpty);
      expect(suggestion.createdAt, isNull);
    });

    test('toJson puis fromJson preservent les donnees', () {
      final original = AiSuggestion.fromJson(aiSuggestionJson);
      final roundTrip = AiSuggestion.fromJson(original.toJson());

      expect(roundTrip, original);
    });
  });
}
