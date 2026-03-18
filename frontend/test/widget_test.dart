import 'package:flutter_test/flutter_test.dart';
import 'package:gwangmeu/shared/models/user_model.dart';
import 'package:gwangmeu/shared/models/village_model.dart';
import 'package:gwangmeu/shared/models/village_member_model.dart';
import 'package:gwangmeu/shared/models/post_model.dart';
import 'package:gwangmeu/features/genealogy/models/person_genealogy.dart';
import 'package:gwangmeu/features/genealogy/models/family_tree.dart';
import 'package:gwangmeu/features/notifications/models/notification_model.dart';

import 'helpers/test_data.dart';

/// Smoke test : verifie que tous les modeles Freezed se deserialisent correctement.
void main() {
  test('Smoke test — tous les modeles Freezed se deserialisent', () {
    // Ce test valide que le code genere (*.freezed.dart, *.g.dart) est coherent
    // avec les classes source. Si build_runner n'a pas ete lance, ce test echoue.

    final user = UserModel.fromJson(userJson);
    expect(user.id, isNotEmpty);

    final village = VillageModel.fromJson(villageJson);
    expect(village.name, isNotEmpty);

    final member = VillageMemberModel.fromJson(villageMemberJson);
    expect(member.userId, isNotEmpty);

    final post = PostModel.fromJson(postTextJson);
    expect(post.content, isNotEmpty);

    final person = PersonGenealogy.fromJson(personJson);
    expect(person.firstName, isNotEmpty);

    final tree = FamilyTree.fromJson(familyTreeJson);
    expect(tree.subject.id, isNotEmpty);

    final notif = NotificationModel.fromJson(notificationJson);
    expect(notif.type, isNotEmpty);
  });
}
