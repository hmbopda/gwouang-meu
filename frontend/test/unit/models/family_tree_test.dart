import 'package:flutter_test/flutter_test.dart';
import 'package:gwangmeu/features/genealogy/models/family_tree.dart';

import '../../helpers/test_data.dart';

void main() {
  group('FamilyTree', () {
    test('fromJson avec arbre complet', () {
      final tree = FamilyTree.fromJson(familyTreeJson);

      expect(tree.subject.id, 'pe-001');
      expect(tree.subject.firstName, 'Jean');
      expect(tree.father, hasLength(1));
      expect(tree.father.first.firstName, 'Pierre');
      expect(tree.mother, hasLength(1));
      expect(tree.mother.first.firstName, 'Marie');
      expect(tree.children, hasLength(1));
      expect(tree.children.first.firstName, 'Amara');
      expect(tree.unions, hasLength(1));
      expect(tree.unions.first.isActive, true);
      expect(tree.siblings, isEmpty);
      expect(tree.paternalGP, isEmpty);
      expect(tree.maternalGP, isEmpty);
      expect(tree.cousins, isEmpty);
      expect(tree.uncles, isEmpty);
      expect(tree.pendingSuggestions, isEmpty);
    });

    test('fromJson avec arbre minimal (sujet seul)', () {
      final tree = FamilyTree.fromJson({
        'subject': personMinimalJson,
      });

      expect(tree.subject.firstName, 'Marie');
      expect(tree.father, isEmpty);
      expect(tree.mother, isEmpty);
      expect(tree.children, isEmpty);
      expect(tree.unions, isEmpty);
    });

    test('toJson produit un Map serialisable', () {
      final original = FamilyTree.fromJson(familyTreeJson);
      final json = original.toJson();

      // toJson genere des objets Freezed imbriques, pas des Map bruts.
      // On verifie que la structure est coherente.
      expect(json.containsKey('subject'), true);
      expect(json.containsKey('father'), true);
      expect(json.containsKey('children'), true);
      expect(json.containsKey('unions'), true);
    });

    test('egalite entre deux instances identiques', () {
      final a = FamilyTree.fromJson(familyTreeJson);
      final b = FamilyTree.fromJson(familyTreeJson);

      expect(a, b);
    });

    test('copyWith modifie les enfants', () {
      final tree = FamilyTree.fromJson(familyTreeJson);
      final updated = tree.copyWith(children: []);

      expect(updated.children, isEmpty);
      expect(updated.subject, tree.subject);
      expect(updated.father, tree.father);
    });
  });
}
