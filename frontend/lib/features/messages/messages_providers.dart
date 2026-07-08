import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gwangmeu/features/chat/chat_notifier.dart';
import 'package:gwangmeu/features/villages/villages_notifier.dart';
import 'package:gwangmeu/shared/models/chat_group_model.dart';

/// Une conversation de la liste Messages (#3a) :
/// groupe de discussion + village d'appartenance.
class Conversation {
  const Conversation({required this.group, required this.villageName});

  final ChatGroupModel group;
  final String villageName;

  bool get isDirect =>
      group.type.toUpperCase() == 'DM' || group.type.toUpperCase() == 'DIRECT';
}

/// Toutes les conversations de l'utilisateur, agrégées sur ses villages.
final myConversationsProvider =
    FutureProvider.autoDispose<List<Conversation>>((ref) async {
  final villages = await ref.watch(myVillagesNotifierProvider.future);
  final conversations = <Conversation>[];

  for (final village in villages) {
    try {
      final groups = await ref.watch(chatGroupsProvider(village.id).future);
      conversations.addAll(
        groups.map((g) => Conversation(group: g, villageName: village.name)),
      );
    } catch (_) {
      // Un village sans chat ne bloque pas la liste.
    }
  }

  conversations.sort((a, b) {
    final da = a.group.createdAt ?? DateTime(2000);
    final db = b.group.createdAt ?? DateTime(2000);
    return db.compareTo(da);
  });
  return conversations;
});

/// Nombre de messages non lus toutes conversations confondues.
/// Alimente le badge ember de la bottom nav (destination Messages).
final unreadMessagesCountProvider = Provider<int>((ref) {
  // TODO(messages): brancher sur l'API chat quand le backend expose le compteur.
  // En attendant, pas de faux badge : 0 non-lu.
  return 0;
});
