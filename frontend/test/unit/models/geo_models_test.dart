import 'package:flutter_test/flutter_test.dart';
import 'package:gwangmeu/shared/models/country_model.dart';
import 'package:gwangmeu/shared/models/language_model.dart';

import '../../helpers/test_data.dart';

void main() {
  group('CountryModel', () {
    test('fromJson avec tous les champs', () {
      final country = CountryModel.fromJson(countryJson);

      expect(country.id, 'c-001');
      expect(country.isoCode, 'CMR');
      expect(country.name, 'Cameroun');
      expect(country.continentCode, 'AF-CENTRAL');
      expect(country.flagEmoji, isNotNull);
      expect(country.phoneCode, '+237');
      expect(country.villageCount, 3);
    });

    test('fromJson avec champs minimaux', () {
      final country = CountryModel.fromJson({
        'id': 'c-min',
        'isoCode': 'SEN',
        'name': 'Senegal',
      });

      expect(country.villageCount, 0);
      expect(country.continentCode, isNull);
      expect(country.flagEmoji, isNull);
    });

    test('toJson puis fromJson preservent les donnees', () {
      final original = CountryModel.fromJson(countryJson);
      final roundTrip = CountryModel.fromJson(original.toJson());

      expect(roundTrip, original);
    });

    test('egalite', () {
      final a = CountryModel.fromJson(countryJson);
      final b = CountryModel.fromJson(countryJson);

      expect(a, b);
    });
  });

  group('LanguageModel', () {
    test('fromJson avec tous les champs', () {
      final lang = LanguageModel.fromJson(languageJson);

      expect(lang.id, 'l-001');
      expect(lang.name, 'French');
      expect(lang.nameLocal, 'Francais');
      expect(lang.official, true);
    });

    test('fromJson avec champs minimaux', () {
      final lang = LanguageModel.fromJson({
        'id': 'l-min',
        'name': 'Bassa',
      });

      expect(lang.nameLocal, isNull);
      expect(lang.official, false);
    });

    test('toJson puis fromJson preservent les donnees', () {
      final original = LanguageModel.fromJson(languageJson);
      final roundTrip = LanguageModel.fromJson(original.toJson());

      expect(roundTrip, original);
    });

    test('egalite', () {
      final a = LanguageModel.fromJson(languageJson);
      final b = LanguageModel.fromJson(languageJson);

      expect(a, b);
    });
  });
}
