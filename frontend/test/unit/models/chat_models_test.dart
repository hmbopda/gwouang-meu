import 'package:flutter_test/flutter_test.dart';
import 'package:gwangmeu/shared/models/chat_group_model.dart';
import 'package:gwangmeu/shared/models/chat_message_model.dart';

import '../../helpers/test_data.dart';

void main() {
  group('ChatGroupModel', () {
    test('fromJson avec tous les champs', () {
      final group = ChatGroupModel.fromJson(chatGroupJson);

      expect(group.id, 'cg-001');
      expect(group.villageId, 'v-001');
      expect(group.name, 'General Edea');
      expect(group.description, 'Discussion generale');
      expect(group.type, 'GENERAL');
      expect(group.memberCount, 15);
      expect(group.createdBy, 'u-001');
    });

    test('fromJson avec champs minimaux', () {
      final group = ChatGroupModel.fromJson({
        'id': 'cg-min',
        'villageId': 'v-001',
        'name': 'Test',
        'type': 'GENERAL',
        'createdBy': 'u-001',
      });

      expect(group.memberCount, 0);
      expect(group.description, isNull);
      expect(group.createdAt, isNull);
    });

    test('toJson puis fromJson preservent les donnees', () {
      final original = ChatGroupModel.fromJson(chatGroupJson);
      final roundTrip = ChatGroupModel.fromJson(original.toJson());

      expect(roundTrip, original);
    });

    test('egalite', () {
      final a = ChatGroupModel.fromJson(chatGroupJson);
      final b = ChatGroupModel.fromJson(chatGroupJson);

      expect(a, b);
    });
  });

  group('ChatMessageModel', () {
    test('fromJson avec tous les champs', () {
      final message = ChatMessageModel.fromJson(chatMessageJson);

      expect(message.id, 'cm-001');
      expect(message.groupId, 'cg-001');
      expect(message.senderId, 'u-001');
      expect(message.senderName, 'Jean Kouassi');
      expect(message.content, 'Bonjour la communaute!');
      expect(message.type, 'TEXT');
    });

    test('fromJson avec champs minimaux', () {
      final message = ChatMessageModel.fromJson({
        'id': 'cm-min',
        'groupId': 'cg-001',
        'senderId': 'u-001',
        'content': 'Hello',
      });

      expect(message.type, 'TEXT');
      expect(message.senderName, isNull);
      expect(message.senderAvatarUrl, isNull);
      expect(message.createdAt, isNull);
    });

    test('toJson puis fromJson preservent les donnees', () {
      final original = ChatMessageModel.fromJson(chatMessageJson);
      final roundTrip = ChatMessageModel.fromJson(original.toJson());

      expect(roundTrip, original);
    });

    test('egalite', () {
      final a = ChatMessageModel.fromJson(chatMessageJson);
      final b = ChatMessageModel.fromJson(chatMessageJson);

      expect(a, b);
    });
  });
}
