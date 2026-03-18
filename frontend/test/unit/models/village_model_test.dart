import 'package:flutter_test/flutter_test.dart';
import 'package:gwangmeu/shared/models/village_model.dart';

import '../../helpers/test_data.dart';

void main() {
  group('VillageModel', () {
    test('fromJson avec tous les champs', () {
      final village = VillageModel.fromJson(villageJson);

      expect(village.id, 'v-001');
      expect(village.name, 'Edea');
      expect(village.description, 'Ville industrielle au bord de la Sanaga.');
      expect(village.country, 'CMR');
      expect(village.region, 'Littoral');
      expect(village.continentCode, 'AF-CENTRAL');
      expect(village.latitude, 3.7986);
      expect(village.longitude, 10.1337);
      expect(village.primaryDialect, 'Bassa');
      expect(village.memberCount, 42);
      expect(village.verified, true);
      expect(village.foundedYear, 1900);
      expect(village.populationEstimate, 85000);
    });

    test('fromJson avec champs minimaux', () {
      final village = VillageModel.fromJson(villageMinimalJson);

      expect(village.id, 'v-002');
      expect(village.name, 'Bafoussam');
      expect(village.country, 'CMR');
      expect(village.description, isNull);
      expect(village.memberCount, 0);
      expect(village.verified, false);
      expect(village.latitude, isNull);
    });

    test('toJson puis fromJson preservent les donnees', () {
      final original = VillageModel.fromJson(villageJson);
      final roundTrip = VillageModel.fromJson(original.toJson());

      expect(roundTrip, original);
    });

    test('egalite entre deux instances identiques', () {
      final a = VillageModel.fromJson(villageJson);
      final b = VillageModel.fromJson(villageJson);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('copyWith modifie un champ', () {
      final village = VillageModel.fromJson(villageJson);
      final updated = village.copyWith(memberCount: 100);

      expect(updated.memberCount, 100);
      expect(updated.name, village.name);
    });

    test('defaults appliques correctement', () {
      final village = VillageModel.fromJson(villageMinimalJson);

      expect(village.memberCount, 0);
      expect(village.verified, false);
    });
  });

  group('VillageModelX extension', () {
    test('slug simple', () {
      final village = VillageModel.fromJson(villageJson);
      expect(village.slug, 'edea');
    });

    test('slug avec espaces et caracteres speciaux', () {
      final village = VillageModel.fromJson(villageJson).copyWith(
        name: 'Ile-Ife (Yoruba)',
      );
      expect(village.slug, 'ile-ife-yoruba-');
    });

    test('slug majuscules converties', () {
      final village =
          VillageModel.fromJson(villageJson).copyWith(name: 'BAFOUSSAM');
      expect(village.slug, 'bafoussam');
    });
  });
}
