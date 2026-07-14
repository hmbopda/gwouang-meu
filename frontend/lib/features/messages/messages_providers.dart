import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gwangmeu/core/network/api_client.dart';
import 'package:gwangmeu/features/chat/chat_notifier.dart';
import 'package:gwangmeu/features/chat/direct_chat.dart';
import 'package:gwangmeu/features/genealogy/genealogy_notifier.dart';
import 'package:gwangmeu/features/profile/profile_notifier.dart';
import 'package:gwangmeu/features/villages/villages_notifier.dart';
import 'package:gwangmeu/shared/models/chat_group_model.dart';

/// Portée d'une conversation dans la liste Messages.
enum ConversationKind { village, family, direct }

/// Une conversation de la liste Messages (#3a) : groupe de discussion +
/// libellé de portée (village, famille) + type.
class Conversation {
  const Conversation({
    required this.group,
    required this.scopeLabel,
    required this.kind,
    this.unreadCount = 0,
  });

  final ChatGroupModel group;

  /// Libellé mono affiché sous l'aperçu : nom du village ou « Famille … ».
  final String scopeLabel;

  final ConversationKind kind;

  /// Messages non lus. Le backend ne l'expose PAS encore : `ChatGroupDto` ne
  /// porte ni compteur de non-lus ni dernier message. La valeur reste donc 0
  /// (badge masqué) tant qu'un champ dédié n'est pas ajouté côté API.
  final int unreadCount;

  bool get isDirect => kind == ConversationKind.direct;
  bool get isFamily => kind == ConversationKind.family;
}

ConversationKind _kindOfGroup(ChatGroupModel g) {
  switch (g.type.toUpperCase()) {
    case 'DM':
    case 'DIRECT':
      return ConversationKind.direct;
    case 'FAMILY':
      return ConversationKind.family;
    default:
      return ConversationKind.village;
  }
}

int _byRecent(Conversation a, Conversation b) {
  final da = a.group.createdAt ?? DateTime(2000);
  final db = b.group.createdAt ?? DateTime(2000);
  return db.compareTo(da);
}

/// Conversations de villages (groupes + directs), agrégées sur les villages
/// de l'utilisateur.
final myConversationsProvider =
    FutureProvider.autoDispose<List<Conversation>>((ref) async {
  final villages = await ref.watch(myVillagesNotifierProvider.future);
  final conversations = <Conversation>[];

  for (final village in villages) {
    try {
      final groups = await ref.watch(chatGroupsProvider(village.id).future);
      conversations.addAll(groups.map((g) => Conversation(
            group: g,
            scopeLabel: village.name,
            kind: _kindOfGroup(g),
          )));
    } catch (_) {
      // Un village sans chat ne bloque pas la liste.
    }
  }

  conversations.sort(_byRecent);
  return conversations;
});

/// Messages directs GLOBAUX (sans village) de l'utilisateur, via /chat/my-groups.
/// Les DM rattachés à un village arrivent déjà via [myConversationsProvider] ;
/// on ne garde ici que ceux sans village pour éviter les doublons.
final myDirectConversationsProvider =
    FutureProvider.autoDispose<List<Conversation>>((ref) async {
  final groups = await ref.watch(myChatGroupsProvider.future);
  return groups
      .where((g) {
        final k = g.type.toUpperCase();
        return (k == 'DIRECT' || k == 'DM') && g.villageId == null;
      })
      .map((g) => Conversation(
            group: g,
            scopeLabel: 'Message direct',
            kind: ConversationKind.direct,
          ))
      .toList()
    ..sort(_byRecent);
});

/// Discussions de FAMILLE de l'utilisateur, dérivées de son clan (généalogie).
/// Le backend crée la discussion « Famille {clan} » à la demande.
final myFamilyConversationsProvider =
    FutureProvider.autoDispose<List<Conversation>>((ref) async {
  final person = await ref.watch(genealogyNotifierProvider.future);
  final clan = person.clan?.trim() ?? '';
  if (clan.isEmpty) return const [];

  final groups = await ref.watch(familyChatGroupsProvider(clan).future);
  final conversations = groups
      .map((g) => Conversation(
            group: g,
            scopeLabel: 'Famille ${g.familyClan ?? clan}',
            kind: ConversationKind.family,
          ))
      .toList()
    ..sort(_byRecent);
  return conversations;
});

/// Le clan de l'utilisateur, s'il est renseigné (pour l'état vide « Famille »).
final myClanProvider = FutureProvider.autoDispose<String?>((ref) async {
  final person = await ref.watch(genealogyNotifierProvider.future);
  final clan = person.clan?.trim();
  return (clan == null || clan.isEmpty) ? null : clan;
});

/// Nombre de messages non lus toutes conversations confondues.
/// Alimente le badge ember de la bottom nav (destination Messages).
final unreadMessagesCountProvider = Provider<int>((ref) {
  // TODO(messages): brancher sur l'API chat quand le backend expose le compteur.
  // En attendant, pas de faux badge : 0 non-lu.
  return 0;
});

/// Id de l'AUTRE participant d'une conversation directe (1:1), pour la pastille
/// de présence « en ligne ». Best-effort via /chat/groups/{id}/members : on
/// prend le premier membre différent de soi. En cas d'erreur (ou si la
/// conversation n'a pas encore de membres résolus) → null : pas de pastille.
///
/// N'est lu QUE pour les lignes de type DIRECT (les groupes village/famille ne
/// déclenchent aucun appel), et mis en cache par groupe (autoDispose.family).
final directPeerIdProvider =
    FutureProvider.autoDispose.family<String?, String>((ref, groupId) async {
  final myId = ref.watch(profileNotifierProvider).valueOrNull?.id;
  if (myId == null) return null;
  final client = ref.read(apiClientProvider);
  final json = await client.get('/api/v1/chat/groups/$groupId/members');
  final list = json['data'] as List? ?? const [];
  for (final e in list) {
    if (e is! Map<String, dynamic>) continue;
    final uid = (e['userId'] ?? e['id'])?.toString();
    if (uid != null && uid.isNotEmpty && uid != myId) return uid;
  }
  return null;
});
