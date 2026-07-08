import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:gwangmeu/features/genealogy/models/person_genealogy.dart';
import 'package:gwangmeu/features/genealogy/services/genealogy_api_service.dart';

part 'genealogy_notifier.g.dart';

/// keepAlive : la fiche personne du sujet est réutilisée partout
/// (généalogie, profil, notifications) et préchargée au démarrage
/// dans app.dart — un provider autoDispose jetterait cet état.
@Riverpod(keepAlive: true)
class GenealogyNotifier extends _$GenealogyNotifier {
  @override
  Future<PersonGenealogy> build() async {
    return ref.read(genealogyApiServiceProvider).getMyPerson();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Cree un ancetre (parent) et le lie a la personne.
  /// Si sendInvite=true et email/phone fourni, envoie une invitation.
  Future<void> addParent({
    required String childId,
    required String firstName,
    required String lastName,
    required String gender,
    required String role,
    String? clan,
    String? totem,
    String? nativeLanguage,
    String? birthPlace,
    List<String>? villageIds,
    bool sendInvite = false,
    String? email,
    String? phone,
  }) async {
    final api = ref.read(genealogyApiServiceProvider);
    final parent = await api.createPerson({
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      if (clan != null) 'clan': clan,
      if (totem != null) 'totem': totem,
      if (nativeLanguage != null) 'nativeLanguage': nativeLanguage,
      if (birthPlace != null) 'birthPlace': birthPlace,
      if (villageIds != null) 'villageIds': villageIds,
    });
    await api.linkParentChild(
      parentId: parent.id,
      childId: childId,
      role: role,
    );
    if (sendInvite) {
      await api.invitePerson(
        personId: parent.id,
        email: email,
        phone: phone,
      );
    }
    ref.invalidate(familyTreeProvider(childId));
    _invalidateSubjectTree(childId);
  }

  /// Cree un enfant et le lie a la personne (endpoint atomique).
  /// Supporte coParentPersonId (demande d'association au co-parent)
  /// et existingPersonId (reutiliser un doublon confirme).
  /// Si sendInvite=true et email/phone fourni, envoie une invitation.
  Future<void> addChild({
    required String parentId,
    required String firstName,
    required String lastName,
    required String gender,
    required String parentRole,
    String? clan,
    String? totem,
    String? nativeLanguage,
    String? birthPlace,
    String? birthDate,
    List<String>? villageIds,
    bool sendInvite = false,
    String? email,
    String? phone,
    String? coParentPersonId,
    String? existingPersonId,
  }) async {
    final api = ref.read(genealogyApiServiceProvider);
    await api.createChild(
      parentId: parentId,
      firstName: firstName,
      lastName: lastName,
      gender: gender,
      birthDate: birthDate,
      clan: clan,
      email: email,
      coParentPersonId: coParentPersonId,
      existingPersonId: existingPersonId,
    );
    if (sendInvite && email != null) {
      // L'invitation est geree par le backend via PersonInvitationService
    }
    ref.invalidate(familyTreeProvider(parentId));
    _invalidateSubjectTree(parentId);
  }

  /// Lie une personne existante comme parent.
  Future<void> linkExistingParent({
    required String childId,
    required String existingPersonId,
    required String role,
  }) async {
    final api = ref.read(genealogyApiServiceProvider);
    await api.linkParentChild(
      parentId: existingPersonId,
      childId: childId,
      role: role,
    );
    ref.invalidate(familyTreeProvider(childId));
    _invalidateSubjectTree(childId);
  }

  /// Lie une personne existante comme enfant.
  Future<void> linkExistingChild({
    required String parentId,
    required String existingPersonId,
    required String parentRole,
  }) async {
    final api = ref.read(genealogyApiServiceProvider);
    await api.linkParentChild(
      parentId: parentId,
      childId: existingPersonId,
      role: parentRole,
    );
    ref.invalidate(familyTreeProvider(parentId));
    _invalidateSubjectTree(parentId);
  }

  /// Invalide l'arbre du sujet si le personId modifié n'est pas le sujet.
  void _invalidateSubjectTree(String modifiedPersonId) {
    final myPerson = state.valueOrNull;
    if (myPerson != null && myPerson.id != modifiedPersonId) {
      ref.invalidate(familyTreeProvider(myPerson.id));
    }
  }
}
