import 'package:flutter_test/flutter_test.dart';
import 'package:gwangmeu/shared/models/user_model.dart';

import '../../helpers/test_data.dart';

void main() {
  group('UserModel', () {
    test('fromJson avec tous les champs', () {
      final user = UserModel.fromJson(userJson);

      expect(user.id, 'u-001');
      expect(user.email, 'testeur@gwangmeu.test');
      expect(user.displayName, 'Jean Kouassi');
      expect(user.avatarUrl, 'https://cdn.example.com/avatar.jpg');
      expect(user.role, 'MEMBRE');
      expect(user.country, 'CMR');
      expect(user.nativeLanguage, 'Bassa');
      expect(user.bio, 'Passione de genealogie.');
      expect(user.verified, true);
      expect(user.fatherName, 'Pierre Kouassi');
      expect(user.fatherOrigin, 'Edea');
      expect(user.motherName, 'Marie Njoh');
      expect(user.motherOrigin, 'Douala');
      expect(user.maritalStatus, 'MARRIED');
      expect(user.tribe, 'Bassa');
      expect(user.clan, 'Bakoko');
      expect(user.profession, 'Ingenieur');
      expect(user.residenceCity, 'Paris');
      expect(user.residenceCountry, 'France');
    });

    test('fromJson avec champs minimaux', () {
      final user = UserModel.fromJson(userMinimalJson);

      expect(user.id, 'u-002');
      expect(user.email, 'minimal@gwangmeu.test');
      expect(user.displayName, isNull);
      expect(user.role, 'MEMBRE');
      expect(user.verified, false);
      expect(user.fatherName, isNull);
      expect(user.clan, isNull);
    });

    test('toJson puis fromJson preservent les donnees', () {
      final original = UserModel.fromJson(userJson);
      final roundTrip = UserModel.fromJson(original.toJson());

      expect(roundTrip, original);
    });

    test('egalite entre deux instances identiques', () {
      final a = UserModel.fromJson(userJson);
      final b = UserModel.fromJson(userJson);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('inegalite entre instances differentes', () {
      final a = UserModel.fromJson(userJson);
      final b = UserModel.fromJson(userMinimalJson);

      expect(a, isNot(b));
    });

    test('copyWith modifie un champ', () {
      final user = UserModel.fromJson(userJson);
      final updated = user.copyWith(displayName: 'Paul Njoh');

      expect(updated.displayName, 'Paul Njoh');
      expect(updated.id, user.id);
      expect(updated.email, user.email);
    });

    test('defaults appliques correctement', () {
      final user = UserModel.fromJson(userMinimalJson);

      expect(user.role, 'MEMBRE');
      expect(user.verified, false);
    });
  });
}
