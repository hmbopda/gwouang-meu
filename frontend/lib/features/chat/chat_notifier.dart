import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/network/api_client.dart';
import '../../shared/models/chat_group_model.dart';
import '../../shared/models/chat_message_model.dart';

part 'chat_notifier.g.dart';

/// Groupes de chat d'un village
@riverpod
Future<List<ChatGroupModel>> chatGroups(ChatGroupsRef ref, String villageId) async {
  final client = ref.read(apiClientProvider);
  final json = await client.get('/api/v1/chat/groups/village/$villageId');
  final data = json['data'];
  final list = data is List ? data : <dynamic>[];
  return list
      .map((e) => ChatGroupModel.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// Messages d'un groupe — pull-to-refresh (léger, pas de polling auto)
@riverpod
class ChatMessagesNotifier extends _$ChatMessagesNotifier {
  late String _groupId;

  @override
  Future<List<ChatMessageModel>> build(String groupId) async {
    _groupId = groupId;
    return _fetchMessages();
  }

  Future<List<ChatMessageModel>> _fetchMessages() async {
    final client = ref.read(apiClientProvider);
    final json = await client.get(
      '/api/v1/chat/groups/$_groupId/messages',
      queryParameters: {'limit': 50},
    );
    final data = json['data'];
    final list = data is List ? data : <dynamic>[];
    return list
        .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> sendMessage(String content) async {
    final client = ref.read(apiClientProvider);
    await client.post(
      '/api/v1/chat/groups/$_groupId/messages',
      data: {'content': content},
    );
    ref.invalidateSelf();
    await future;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

/// Créer un groupe de chat
@riverpod
class CreateChatGroup extends _$CreateChatGroup {
  @override
  FutureOr<void> build() {}

  Future<ChatGroupModel> create({
    required String villageId,
    required String name,
    String? description,
    String type = 'GENERAL',
  }) async {
    final client = ref.read(apiClientProvider);
    final json = await client.post('/api/v1/chat/groups', data: {
      'villageId': villageId,
      'name': name,
      if (description != null) 'description': description,
      'type': type,
    });
    ref.invalidate(chatGroupsProvider(villageId));
    return ChatGroupModel.fromJson(json['data'] as Map<String, dynamic>);
  }
}

/// Rejoindre un groupe
Future<void> joinChatGroup(ApiClient client, String groupId) async {
  await client.post('/api/v1/chat/groups/$groupId/join');
}
