import 'package:flutter_test/flutter_test.dart';
import 'package:gwangmeu/features/genealogy/models/person_genealogy.dart';

import '../../helpers/test_data.dart';

void main() {
  group('PersonGenealogy', () {
    test('fromJson avec tous les champs', () {
      final person = PersonGenealogy.fromJson(personJson);

      expect(person.id, 'pe-001');
      expect(person.userId, 'u-001');
      expect(person.firstName, 'Jean');
      expect(person.lastName, 'Kouassi');
      expect(person.gender, 'MALE');
      expect(person.birthDate, isNotNull);
      expect(person.birthPlace, 'Edea');
      expect(person.isAlive, true);
      expect(person.clan, 'Bakoko');
      expect(person.totem, 'Tortue');
      expect(person.email, 'jean@test.com');
      expect(person.phone, '+237600000000');
      expect(person.privacy, 'PUBLIC');
      expect(person.status, 'ALIVE');
    });

    test('fromJson enfant < 4 ans', () {
      final child = PersonGenealogy.fromJson(personChildJson);

      expect(child.id, 'pe-002');
      expect(child.firstName, 'Amara');
      expect(child.lastName, 'Kouassi');
      expect(child.gender, 'MALE');
      expect(child.isAlive, true);
      expect(child.clan, 'Bakoko');
      expect(child.privacy, 'FAMILY_ONLY');
      expect(child.email, isNull);
      expect(child.phone, isNull);
    });

    test('fromJson avec champs minimaux', () {
      final person = PersonGenealogy.fromJson(personMinimalJson);

      expect(person.id, 'pe-003');
      expect(person.firstName, 'Marie');
      expect(person.lastName, 'Njoh');
      expect(person.gender, 'FEMALE');
      expect(person.privacy, 'PUBLIC');
      expect(person.status, 'ALIVE');
      expect(person.birthDate, isNull);
      expect(person.clan, isNull);
      expect(person.userId, isNull);
      expect(person.villageIds, isEmpty);
    });

    test('toJson puis fromJson preservent les donnees', () {
      final original = PersonGenealogy.fromJson(personJson);
      final roundTrip = PersonGenealogy.fromJson(original.toJson());

      expect(roundTrip, original);
    });

    test('egalite entre deux instances identiques', () {
      final a = PersonGenealogy.fromJson(personJson);
      final b = PersonGenealogy.fromJson(personJson);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('copyWith modifie un champ', () {
      final person = PersonGenealogy.fromJson(personJson);
      final updated = person.copyWith(firstName: 'Paul');

      expect(updated.firstName, 'Paul');
      expect(updated.lastName, person.lastName);
      expect(updated.id, person.id);
    });

    test('defaults villageIds vide', () {
      final person = PersonGenealogy.fromJson(personMinimalJson);
      expect(person.villageIds, isEmpty);
    });

    test('default isAlive vrai', () {
      final person = PersonGenealogy.fromJson(personMinimalJson);
      expect(person.isAlive, true);
    });
  });
}
