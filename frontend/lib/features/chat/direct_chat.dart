import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gwangmeu/core/network/api_client.dart';
import 'package:gwangmeu/shared/models/chat_group_model.dart';

/// Messagerie directe : recherche de contacts LIÉS (famille/mariage/clan/village)
/// et ouverture d'une conversation 1-à-1 sans contexte village.
/// Providers « plain » (pas de codegen) pour éviter la régénération Riverpod.

/// Une personne à qui l'utilisateur peut écrire (résultat de /chat/contacts).
class ChatContact {
  const ChatContact({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;

  factory ChatContact.fromJson(Map<String, dynamic> json) => ChatContact(
        userId: (json['userId'] ?? json['id'])?.toString() ?? '',
        displayName: json['displayName'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String?,
      );
}

/// Contacts avec qui l'utilisateur peut discuter, filtrés par [query] (nom).
final chatContactsProvider =
    FutureProvider.autoDispose.family<List<ChatContact>, String>((ref, query) async {
  final client = ref.read(apiClientProvider);
  final json = await client.get(
    '/api/v1/chat/contacts',
    queryParameters: {'q': query},
  );
  final list = json['data'] as List? ?? const [];
  return list
      .map((e) => ChatContact.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Toutes les conversations de l'utilisateur (village, famille, directes).
/// Sert notamment à faire apparaître les DM (sans village) dans la liste.
final myChatGroupsProvider =
    FutureProvider.autoDispose<List<ChatGroupModel>>((ref) async {
  final client = ref.read(apiClientProvider);
  final json = await client.get('/api/v1/chat/my-groups');
  final list = json['data'] as List? ?? const [];
  return list
      .map((e) => ChatGroupModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Ouvre (ou récupère) la conversation directe avec [targetUserId].
/// Idempotent côté backend. Renvoie le groupe DIRECT.
final directChatOpenerProvider = Provider<DirectChatOpener>((ref) {
  return DirectChatOpener(ref.read(apiClientProvider));
});

class DirectChatOpener {
  DirectChatOpener(this._api);
  final ApiClient _api;

  Future<ChatGroupModel> openWith(String targetUserId) async {
    final json = await _api.post(
      '/api/v1/chat/direct',
      data: {'targetUserId': targetUserId},
    );
    return ChatGroupModel.fromJson(json['data'] as Map<String, dynamic>);
  }
}
